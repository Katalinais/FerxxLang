/*
 * FerxxLang — Analizador sintactico (Bison)
 * Capa 1: declaraciones, asignaciones y expresiones
 * Capa 2: control de flujo (if/else, while, for, switch)
 *
 * Conflictos conocidos: 0 shift/reduce sin resolver.
 *   - Dangling-else: resuelto por %nonassoc SIN_ELSE / %nonassoc ELSE.
 *     El ELSE siempre se asocia al IF mas cercano (shift gana).
 *   - Operadores binarios: resueltos por las declaraciones %left/%right.
 *   - expr -> ID . vs expr -> ID . LBRACKET expr RBRACKET: no existe
 *     porque LBRACKET no esta en FOLLOW(expr) con esta gramatica.
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
 *
 * SIN_ELSE / ELSE resuelven el dangling-else:
 *   si_ve (cond) bloque  o_si_no  bloque
 *   La regla sin ELSE usa %prec SIN_ELSE (menor prioridad);
 *   al ver ELSE en la entrada, el shift gana y lo asocia al IF mas cercano.
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
 * Recursion izquierda para evitar stack overflow en archivos grandes.
 */
lista_sent
    : /* vacio */
    | lista_sent sentencia
    ;

/*
 * sentencia — unidad basica de ejecucion.
 * Incluye declaraciones, asignaciones, bloques, control de flujo
 * y el punto-y-coma vacio (sentencia nula).
 */
sentencia
    : declaracion    SEMI
    | asignacion     SEMI
    | bloque
    | sentencia_if
    | sentencia_while
    | sentencia_for
    | sentencia_switch
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
 * tipo — todos los tipos primitivos y compuestos de FerxxLang.
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
 * Permite bloques vacios y variable shadowing (re-declarar un ID
 * dentro de un bloque anidado oculta el identificador externo).
 */
bloque
    : LBRACE lista_sent RBRACE
    ;

/* ================================================================
 * CONTROL DE FLUJO
 * ================================================================ */

/*
 * sentencia_if — si_ve / o_si_no
 *
 * Tres formas:
 *   1. si_ve (cond) bloque                       (sin else)
 *   2. si_ve (cond) bloque o_si_no bloque        (con else)
 *   3. si_ve (cond) bloque o_si_no sentencia_if  (else-if encadenado)
 *
 * El %prec SIN_ELSE en la primera alternativa resuelve el dangling-else:
 * el token ELSE tiene mayor precedencia que SIN_ELSE, por lo que el
 * parser siempre hace shift del ELSE y lo asocia al IF mas cercano.
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
 *
 * Dos variantes: con actualizacion (ID = expr) o sin ella.
 * for_init acepta declaracion o asignacion como inicializador.
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
 *
 * Permite switch vacio y multiples casos.
 * Cada caso puede tener cero o mas sentencias (lista_sent es nullable).
 * No se usa DEFAULT porque el vocabulario de FerxxLang no lo incluye.
 */
sentencia_switch
    : SWITCH LPAREN expr RPAREN LBRACE lista_casos RBRACE
    | SWITCH LPAREN expr RPAREN LBRACE              RBRACE
    ;

/*
 * lista_casos — uno o mas casos dentro del switch.
 */
lista_casos
    : caso
    | lista_casos caso
    ;

/*
 * caso — toca expr: lista_sent
 *
 * Se usa lista_sent (nullable) en lugar de dos alternativas separadas
 * (con y sin cuerpo) para evitar un conflicto reduce/reduce: si
 * hubiera `caso : CASE expr COLON` como alternativa adicional, ambas
 * podrían reducirse ante lookahead CASE o RBRACE.
 */
caso
    : CASE expr COLON lista_sent
    ;

/* ================================================================
 * EXPRESIONES
 * ================================================================ */

/*
 * expr — expresiones con precedencia completa.
 *
 * Binarios (resueltos por %left/%right):
 *   Aritmeticos : + - * / % ^
 *   Relacionales: == != < > <= >=
 *   Logicos     : y_es/&&  o_bien/||
 *
 * Unarios:
 *   no_es/!  con %right NOT
 *   negacion con %prec UMINUS
 *
 * Primarios: ID, ID[expr], (expr), literales
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
