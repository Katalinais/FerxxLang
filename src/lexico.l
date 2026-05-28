%option noyywrap
%{
#include <stdio.h>

extern FILE *yyin;
%}

DIGITO      [0-9]
LETRA       [a-zA-Z_]
ID          {LETRA}({LETRA}|{DIGITO})*
ENTERO      {DIGITO}+
FLOTANTE    {DIGITO}+\.{DIGITO}+

%%

"#"[^\n]*               { }
"//"[^\n]*              { }

"frase"                 { printf("Tipo:      %s\n", yytext); }
"luka"                  { printf("Tipo:      %s\n", yytext); }
"vuelto"                { printf("Tipo:      %s\n", yytext); }
"firme"                 { printf("Tipo:      %s\n", yytext); }
"combo"                 { printf("Tipo:      %s\n", yytext); }
"parche"                { printf("Tipo:      %s\n", yytext); }
"parcero"               { printf("Tipo:      %s\n", yytext); }
"fila"                  { printf("Tipo:      %s\n", yytext); }
"cuadro"                { printf("Tipo:      %s\n", yytext); }

"si_ve"                 { printf("Reservada: %s\n", yytext); }
"o_si_no"               { printf("Reservada: %s\n", yytext); }
"siga_pues"             { printf("Reservada: %s\n", yytext); }
"dele"                  { printf("Reservada: %s\n", yytext); }
"haga"                  { printf("Reservada: %s\n", yytext); }
"vuelva"                { printf("Reservada: %s\n", yytext); }
"diga"                  { printf("Reservada: %s\n", yytext); }
"responda"              { printf("Reservada: %s\n", yytext); }
"paila"                 { printf("Reservada: %s\n", yytext); }
"segun"                 { printf("Reservada: %s\n", yytext); }
"toca"                  { printf("Reservada: %s\n", yytext); }
"ensaye"                { printf("Reservada: %s\n", yytext); }
"ojo_pues"              { printf("Reservada: %s\n", yytext); }
"cuadre"                { printf("Reservada: %s\n", yytext); }
"sume"                  { printf("Reservada: %s\n", yytext); }
"multiplique"           { printf("Reservada: %s\n", yytext); }
"el_mas"                { printf("Reservada: %s\n", yytext); }
"el_menos"              { printf("Reservada: %s\n", yytext); }

"de_una"                { printf("Bool:      %s\n", yytext); }
"nel"                   { printf("Bool:      %s\n", yytext); }

{FLOTANTE}              { printf("Flotante:  %s\n", yytext); }
{ENTERO}                { printf("Entero:    %s\n", yytext); }

\"[^\"]*\"              { printf("String:    %s\n", yytext); }

{ID}                    { printf("Identif.:  %s\n", yytext); }

"=="                    { printf("Operador:  %s\n", yytext); }
"!="                    { printf("Operador:  %s\n", yytext); }
"<="                    { printf("Operador:  %s\n", yytext); }
">="                    { printf("Operador:  %s\n", yytext); }
"<"                     { printf("Operador:  %s\n", yytext); }
">"                     { printf("Operador:  %s\n", yytext); }
"+"                     { printf("Operador:  %s\n", yytext); }
"-"                     { printf("Operador:  %s\n", yytext); }
"*"                     { printf("Operador:  %s\n", yytext); }
"/"                     { printf("Operador:  %s\n", yytext); }
"^"                     { printf("Operador:  %s\n", yytext); }
"%"                     { printf("Operador:  %s\n", yytext); }

"="                     { printf("Asignac.:  %s\n", yytext); }

"("                     { printf("Paren.:    %s\n", yytext); }
")"                     { printf("Paren.:    %s\n", yytext); }
"{"                     { printf("Bloque:    %s\n", yytext); }
"}"                     { printf("Bloque:    %s\n", yytext); }
"["                     { printf("Corchete:  %s\n", yytext); }
"]"                     { printf("Corchete:  %s\n", yytext); }
":"                     { printf("DosPuntos\n"); }
";"                     { printf("PuntoComa\n"); }
","                     { printf("Coma\n"); }

[ \t\n]+                { }

.                       { printf("Error lexico: '%c'\n", *yytext); }

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
        printf("FerxxLang Lexer (Ctrl+D para terminar):\n");
    }

    yylex();

    if (yyin != stdin) fclose(yyin);
    return 0;
}
