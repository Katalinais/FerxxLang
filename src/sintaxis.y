/*
 * FerxxLang — Analizador sintactico (Bison)
 * Capa 1: declaraciones, asignaciones y expresiones
 * Capa 2: control de flujo (if/else, while, for, switch)
 * Capa 3: funciones (definicion, llamada, return, print, input)
 * Capa 4: excepciones (try/catch, assert, throw), literales de coleccion,
 *         operadores de reduccion, acceso a campos con DOT
 *
 * Conflictos conocidos: 0 shift/reduce, 0 reduce/reduce
 *   - Dangling-else: resuelto por %nonassoc SIN_ELSE / %nonassoc ELSE.
 *   - Operadores binarios: resueltos por tabla %left / %right.
 *   - arg -> ID COLON expr vs expr -> ID: sin conflicto porque LALR(1)
 *     separa los estados de lista_args y caso; COLON no esta en
 *     FOLLOW(expr) dentro del estado de lista_args.
 *   - expr -> ID DOT ID vs expr -> ID DOT llamada_funcion: sin conflicto
 *     porque LPAREN no esta en FOLLOW(expr).
 *   - sentencia_throw -> THROW | THROW expr: sin conflicto porque
 *     FOLLOW(sentencia_throw) = {SEMI} y SEMI no inicia expr.
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
%token SEMI COMMA COLON DOT

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
    | sentencia_try
    | sentencia_return   SEMI
    | sentencia_print    SEMI
    | sentencia_input    SEMI
    | sentencia_assert   SEMI
    | sentencia_throw    SEMI
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

/* ================================================================
 * MANEJO DE EXCEPCIONES — Capa 4
 * ================================================================ */

/*
 * sentencia_try — ensaye bloque ojo_pues (var) bloque
 *
 * Dos formas del bloque catch:
 *   ojo_pues (e)        — variable sin tipo explicito
 *   ojo_pues (luka e)   — variable con tipo explicito
 */
sentencia_try
    : TRY bloque CATCH LPAREN ID       RPAREN bloque
    | TRY bloque CATCH LPAREN tipo ID  RPAREN bloque
    ;

/*
 * sentencia_assert — cuadre(expr)  o  cuadre(expr, "mensaje")
 */
sentencia_assert
    : ASSERT LPAREN expr                   RPAREN
    | ASSERT LPAREN expr COMMA LIT_STRING  RPAREN
    ;

/*
 * sentencia_throw — paila expr  o  paila  (re-lanza excepcion activa)
 *
 * Sin conflicto: FOLLOW(sentencia_throw) = {SEMI}, que no intersecta
 * con FIRST(expr). Bison elige shift si hay una expr, reduce si ve SEMI.
 */
sentencia_throw
    : THROW expr
    | THROW
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
 * Orden de las alternativas que empiezan con ID:
 *   1. ID DOT llamada_funcion  (metodo: obj.f())
 *   2. ID DOT ID               (campo: obj.campo)
 *   3. ID LBRACKET expr ]      (indexacion: arr[i])
 *   4. llamada_funcion         (llamada libre: f())
 *   5. ID                      (variable simple)
 * Sin conflictos: LPAREN y DOT no pertenecen a FOLLOW(expr);
 * FOLLOW(sentencia_throw) = {SEMI} disjunto de FIRST(expr).
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
    | ID DOT llamada_funcion        { }
    | ID DOT ID                     { }
    | llamada_funcion               { }
    | SUM  LPAREN expr RPAREN       { }
    | PROD LPAREN expr RPAREN       { }
    | MAX  LPAREN expr RPAREN       { }
    | MIN  LPAREN expr RPAREN       { }
    | LBRACKET lista_exprs RBRACKET { }
    | LBRACKET             RBRACKET { }
    | ID                            { }
    | LIT_INT                       { }
    | LIT_FLOAT                     { }
    | LIT_STRING                    { }
    | LIT_BOOL                      { }
    ;

/*
 * lista_exprs — uno o mas elementos separados por coma.
 * Usada en literales de coleccion: [1, 2, 3].
 * Sin conflicto: COMMA y RBRACKET no son operadores de expr,
 * asi que la regla izquierda recursiva no genera shift/reduce.
 */
lista_exprs
    : expr
    | lista_exprs COMMA expr
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
