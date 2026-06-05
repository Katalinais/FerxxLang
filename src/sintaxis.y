/*
 * FerxxLang — Analizador sintactico (Bison)
 * Capa 1: declaraciones, asignaciones y expresiones
 * Capa 2: control de flujo (if/else, while, for, switch)
 * Capa 3: funciones (definicion, llamada, return, print, input)
 *
 * Conflictos conocidos: 1 shift/reduce — RESUELTO por shift (correcto).
 *   Causa: `arg -> ID . COLON expr` vs `expr -> ID .` cuando lookahead
 *   es COLON. COLON esta en FOLLOW(expr) porque `caso -> CASE expr COLON`.
 *   El shift gana: dentro de lista_args, ID COLON expr se trata como
 *   argumento nombrado (ej. calcular(base: 10)), que es el comportamiento
 *   deseado.
 *
 * Otros conflictos:
 *   - Dangling-else: resuelto por %nonassoc SIN_ELSE / %nonassoc ELSE.
 *   - Operadores binarios: resueltos por %left / %right.
 *   - expr->ID vs expr->llamada_funcion: no hay conflicto porque LPAREN
 *     no esta en FOLLOW(expr) con esta gramatica.
 */

%{
#include <stdio.h>
#include <stdlib.h>

extern int yylineno;
extern FILE *yyin;

int yylex(void);

static int hubo_error = 0;

void yyerror(const char *s) {
    hubo_error = 1;
    fprintf(stderr, "Error sintactico en linea %d: %s\n", yylineno, s);
}
%}

/* -- Tokens --------------------------------------------------------- */
%token INT FLOAT BOOL STRING VECTOR MATRIZ CLASS LIST GRID MAP
%token IF ELSE WHILE FOR SWITCH CASE
%token FUNC RETURN PRINT INPUT
%token TRY CATCH THROW ASSERT
%token SUM PROD MAX MIN
%token LIT_INT LIT_FLOAT LIT_STRING LIT_BOOL
%token ID
%token AND OR NOT
%token EQ NEQ LEQ GEQ LT GT
%token PLUS MINUS TIMES DIV MOD POW ASSIGN
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET
%token SEMI COMMA COLON

/*
 * Precedencia — de MENOR a MAYOR prioridad.
 * SIN_ELSE/ELSE resuelven dangling-else.
 */
%nonassoc SIN_ELSE
%nonassoc ELSE
%right    ASSIGN
%left     OR
%left     AND
%right    NOT
%left     EQ NEQ
%left     LT GT LEQ GEQ
%left     PLUS MINUS
%left     TIMES DIV MOD
%right    POW
%right    UMINUS

%%

/*
 * programa — punto de entrada. Acepta cero o mas sentencias.
 */
programa
    : lista_sent    { /* exito reportado en main() tras yyparse() */ }
    ;

/*
 * lista_sent — secuencia de sentencias (puede estar vacia).
 */
lista_sent
    : /* vacio */
    | lista_sent sentencia
    ;

/*
 * sentencia — unidad basica de ejecucion.
 */
sentencia
    : declaracion        SEMI
    | asignacion         SEMI
    | bloque
    | sentencia_if
    | sentencia_while
    | sentencia_for
    | sentencia_switch
    | def_funcion
    | sentencia_return   SEMI
    | sentencia_print    SEMI
    | sentencia_input    SEMI
    | llamada_funcion    SEMI
    | SEMI
    ;

/*
 * declaracion — tipo ID  o  tipo ID = expr
 */
declaracion
    : tipo ID
    | tipo ID ASSIGN expr
    ;

/*
 * tipo — todos los tipos primitivos y compuestos.
 */
tipo
    : INT       /* luka    */
    | FLOAT     /* vuelto  */
    | BOOL      /* firme   */
    | STRING    /* frase   */
    | VECTOR    /* combo   */
    | MATRIZ    /* parche  */
    | LIST      /* fila    */
    | MAP       /* llave   */
    | GRID      /* cuadro  */
    | CLASS     /* parcero */
    ;

/*
 * asignacion — ID = expr  o  ID[expr] = expr
 */
asignacion
    : ID ASSIGN expr
    | ID LBRACKET expr RBRACKET ASSIGN expr
    ;

/*
 * bloque — { lista_sent }
 * Variable shadowing: permite re-declarar el mismo ID dentro del bloque.
 */
bloque
    : LBRACE lista_sent RBRACE
    ;

/* ================================================================
 * CONTROL DE FLUJO
 * ================================================================ */

/*
 * sentencia_if — si_ve / o_si_no
 * %prec SIN_ELSE en la primera alternativa resuelve el dangling-else.
 */
sentencia_if
    : IF LPAREN expr RPAREN bloque                        %prec SIN_ELSE
    | IF LPAREN expr RPAREN bloque ELSE bloque
    | IF LPAREN expr RPAREN bloque ELSE sentencia_if
    ;

/*
 * sentencia_while — siga_pues (cond) bloque
 */
sentencia_while
    : WHILE LPAREN expr RPAREN bloque
    ;

/*
 * sentencia_for — dele (init; cond; update) bloque
 * Segunda alternativa: for sin actualizacion (update vacio).
 */
sentencia_for
    : FOR LPAREN for_init SEMI expr SEMI asignacion RPAREN bloque
    | FOR LPAREN for_init SEMI expr SEMI             RPAREN bloque
    ;

/*
 * for_init — inicializador del for: declaracion o asignacion
 */
for_init
    : declaracion
    | asignacion
    ;

/*
 * sentencia_switch — segun (expr) { casos }
 */
sentencia_switch
    : SWITCH LPAREN expr RPAREN LBRACE lista_casos RBRACE
    | SWITCH LPAREN expr RPAREN LBRACE              RBRACE
    ;

/*
 * lista_casos y caso — cuerpo del switch
 * caso usa lista_sent (nullable) para evitar conflicto reduce/reduce.
 */
lista_casos
    : caso
    | lista_casos caso
    ;

caso
    : CASE expr COLON lista_sent
    ;

/* ================================================================
 * FUNCIONES — Capa 3
 * ================================================================ */

/*
 * def_funcion — haga nombre(params) bloque
 *
 * Permite:
 *   - Cero parametros: haga f() { }
 *   - Uno o mas parametros tipados: haga f(luka n, frase s) { }
 *   - Sobrecarga sintactica: dos funciones con el mismo nombre
 *     difiriendo en tipo del primer parametro (el parser las acepta;
 *     no se valida semanticamente).
 *   - Funciones anidadas: def_funcion es una sentencia, valida dentro
 *     de cualquier bloque, incluido el bloque de otra funcion.
 */
def_funcion
    : FUNC ID LPAREN lista_params RPAREN bloque
    | FUNC ID LPAREN              RPAREN bloque
    ;

/*
 * lista_params — lista de parametros formales separados por coma
 */
lista_params
    : param
    | lista_params COMMA param
    ;

/*
 * param — tipo ID  (parametro posicional tipado)
 */
param
    : tipo ID
    ;

/*
 * sentencia_return — vuelva expr  o  vuelva  (sin valor)
 */
sentencia_return
    : RETURN expr
    | RETURN
    ;

/*
 * sentencia_print — diga(expr)  o  diga()
 */
sentencia_print
    : PRINT LPAREN expr RPAREN
    | PRINT LPAREN      RPAREN
    ;

/*
 * sentencia_input — responda(prompt)  o  responda()
 */
sentencia_input
    : INPUT LPAREN LIT_STRING RPAREN
    | INPUT LPAREN            RPAREN
    ;

/*
 * llamada_funcion — nombre(args)  o  nombre()
 * Aparece tanto como sentencia como dentro de expresiones.
 */
llamada_funcion
    : ID LPAREN lista_args RPAREN
    | ID LPAREN            RPAREN
    ;

/*
 * lista_args — argumentos reales separados por coma
 */
lista_args
    : arg
    | lista_args COMMA arg
    ;

/*
 * arg — argumento posicional o nombrado
 *
 * arg -> ID COLON expr genera 1 shift/reduce (ver cabecera del archivo).
 * Bison resuelve por shift: correcto para args nombrados (base: 10).
 */
arg
    : expr
    | ID COLON expr
    ;

/* ================================================================
 * EXPRESIONES
 * ================================================================ */

/*
 * expr — expresiones con precedencia completa.
 * llamada_funcion se lista ANTES que ID para que el parser pruebe
 * la alternativa mas larga (ID LPAREN ...) antes que la simple (ID).
 * No genera conflicto porque LPAREN no pertenece a FOLLOW(expr).
 */
expr
    : expr PLUS  expr               { }
    | expr MINUS expr               { }
    | expr TIMES expr               { }
    | expr DIV   expr               { }
    | expr MOD   expr               { }
    | expr POW   expr               { }
    | expr EQ    expr               { }
    | expr NEQ   expr               { }
    | expr LT    expr               { }
    | expr GT    expr               { }
    | expr LEQ   expr               { }
    | expr GEQ   expr               { }
    | expr AND   expr               { }
    | expr OR    expr               { }
    | NOT  expr                     { }
    | MINUS expr  %prec UMINUS      { }
    | LPAREN expr RPAREN            { }
    | ID LBRACKET expr RBRACKET     { }
    | llamada_funcion               { }
    | ID                            { }
    | LIT_INT                       { }
    | LIT_FLOAT                     { }
    | LIT_STRING                    { }
    | LIT_BOOL                      { }
    ;

%%

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "No se pudo abrir: %s\n", argv[1]);
            return 1;
        }
    } else {
        yyin = stdin;
    }

    int resultado = yyparse();

    if (yyin != stdin) fclose(yyin);

    if (!resultado && !hubo_error)
        printf("✓ Analisis sintactico exitoso\n");

    return resultado || hubo_error;
}
