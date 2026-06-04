/*
 * FerxxLang — Analizador sintactico (Bison)
 * Capa 1: declaraciones, asignaciones y expresiones
 *
 * Conflictos conocidos: 0 shift/reduce
 *   Todos los conflictos de operadores binarios se resuelven mediante
 *   las declaraciones de precedencia (%left / %right). El conflicto
 *   potencial entre `expr -> ID .` y `expr -> ID . LBRACKET expr RBRACKET`
 *   no existe en LALR(1) porque LBRACKET no pertenece a FOLLOW(expr)
 *   con esta gramatica.
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

/* ── Tokens ─────────────────────────────────────────────── */
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
 * Precedencia de operadores — de MENOR a MAYOR prioridad.
 * SIN_ELSE y ELSE se reservan ya para la resolucion dangling-else
 * que se activara en la capa de control de flujo (Fase 3).
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
 * programa — punto de entrada del analizador.
 * Acepta una secuencia de cero o mas sentencias.
 */
programa
    : lista_sent    { /* exito reportado en main() tras yyparse() */ }
    ;

/*
 * lista_sent — lista de sentencias (puede estar vacia).
 * Se usa recursion izquierda para evitar overflow de pila
 * en archivos largos.
 */
lista_sent
    : /* vacio */
    | lista_sent sentencia
    ;

/*
 * sentencia — unidad basica de ejecucion.
 * Cuatro formas: declaracion, asignacion, bloque, o punto-y-coma vacio.
 */
sentencia
    : declaracion SEMI
    | asignacion  SEMI
    | bloque
    | SEMI
    ;

/*
 * declaracion — introduce una nueva variable con tipo explicito.
 * Formas: `tipo ID;`  o  `tipo ID = expr;`
 */
declaracion
    : tipo ID
    | tipo ID ASSIGN expr
    ;

/*
 * tipo — todos los tipos primitivos y compuestos de FerxxLang.
 */
tipo
    : INT       /* luka   */
    | FLOAT     /* vuelto */
    | BOOL      /* firme  */
    | STRING    /* frase  */
    | VECTOR    /* combo  */
    | MATRIZ    /* parche */
    | LIST      /* fila   */
    | MAP       /* llave  */
    | GRID      /* cuadro */
    | CLASS     /* parcero */
    ;

/*
 * asignacion — modifica el valor de una variable existente.
 * Soporta asignacion simple y acceso a elemento de arreglo/matriz.
 */
asignacion
    : ID ASSIGN expr
    | ID LBRACKET expr RBRACKET ASSIGN expr
    ;

/*
 * bloque — secuencia de sentencias delimitada por llaves.
 * Permite bloques vacios `{}` y bloques con declaraciones locales
 * (variable shadowing: un identificador local oculta al externo).
 */
bloque
    : LBRACE lista_sent RBRACE
    ;

/*
 * expr — expresiones con precedencia completa.
 *
 * Operadores binarios (todos resueltos por %left/%right):
 *   Aritmeticos : + - * / % ^
 *   Relacionales: == != < > <= >=
 *   Logicos     : y_es(&&)  o_bien(||)
 *
 * Operadores unarios:
 *   no_es / !   con %right NOT
 *   negacion    con %prec UMINUS (mayor prioridad que *)
 *
 * Literales: entero, flotante, cadena, booleano.
 * Primarios : ID, ID[expr], (expr)
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
