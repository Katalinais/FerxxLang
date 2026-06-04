%{
#include <stdio.h>
#include <stdlib.h>

extern int yylineno;
extern FILE *yyin;

int yylex(void);

void yyerror(const char *s) {
    fprintf(stderr, "Error sintactico en linea %d: %s\n", yylineno, s);
}
%}

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

%%

programa
    : /* vacio */
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

    yyparse();

    if (yyin != stdin) fclose(yyin);
    return 0;
}
