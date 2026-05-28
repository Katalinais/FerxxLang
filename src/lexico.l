%option noyywrap yylineno
%{
#include <stdio.h>
#include "sintaxis.tab.h"
%}

DIGITO      [0-9]
LETRA       [a-zA-Z_]
ID          {LETRA}({LETRA}|{DIGITO})*
LIT_INT     {DIGITO}+
LIT_FLOAT   {DIGITO}+\.{DIGITO}+

%%

"#"[^\n]*       { }
"//"[^\n]*      { }

"luka"          { return INT; }
"vuelto"        { return FLOAT; }
"firme"         { return BOOL; }
"frase"         { return STRING; }
"combo"         { return VECTOR; }
"parche"        { return MATRIZ; }
"parcero"       { return CLASS; }
"fila"          { return LIST; }
"cuadro"        { return GRID; }
"llave"         { return MAP; }

"si_ve"         { return IF; }
"o_si_no"       { return ELSE; }
"siga_pues"     { return WHILE; }
"dele"          { return FOR; }
"segun"         { return SWITCH; }
"toca"          { return CASE; }
"haga"          { return FUNC; }
"vuelva"        { return RETURN; }
"diga"          { return PRINT; }
"responda"      { return INPUT; }
"ensaye"        { return TRY; }
"ojo_pues"      { return CATCH; }
"paila"         { return THROW; }
"cuadre"        { return ASSERT; }
"sume"          { return SUM; }
"multiplique"   { return PROD; }
"el_mas"        { return MAX; }
"el_menos"      { return MIN; }

"firme_si"      { return LIT_BOOL; }
"firme_no"      { return LIT_BOOL; }
"de_una"        { return LIT_BOOL; }
"nel"           { return LIT_BOOL; }

{LIT_FLOAT}     { return LIT_FLOAT; }
{LIT_INT}       { return LIT_INT; }

\"[^\"]*\"      { return LIT_STRING; }

{ID}            { return ID; }

"=="            { return EQ; }
"!="            { return NEQ; }
"<="            { return LEQ; }
">="            { return GEQ; }
"<"             { return LT; }
">"             { return GT; }
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return TIMES; }
"/"             { return DIV; }
"%"             { return MOD; }
"^"             { return POW; }
"="             { return ASSIGN; }

"("             { return LPAREN; }
")"             { return RPAREN; }
"{"             { return LBRACE; }
"}"             { return RBRACE; }
"["             { return LBRACKET; }
"]"             { return RBRACKET; }
";"             { return SEMI; }
","             { return COMMA; }
":"             { return COLON; }

[ \t\n]+        { }

.               { fprintf(stderr, "Error lexico en linea %d: '%c'\n", yylineno, *yytext); }

%%
