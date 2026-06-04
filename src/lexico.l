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

	/* -- COMENTARIOS ------------------------------------ */
"#"[^\n]*               { }
"//"[^\n]*              { }

	/* -- TIPOS DE DATO ---------------------------------- */
"luka"                  { return INT; }
"vuelto"                { return FLOAT; }
"firme"                 { return BOOL; }
"frase"                 { return STRING; }
"combo"                 { return VECTOR; }
"parche"                { return MATRIZ; }
"parcero"               { return CLASS; }
"fila"                  { return LIST; }
"cuadro"                { return GRID; }
"llave"                 { return MAP; }

	/* -- CONTROL DE FLUJO ------------------------------- */
"si_ve"                 { return IF; }
"o_si_no"               { return ELSE; }
"siga_pues"             { return WHILE; }
"dele"                  { return FOR; }
"segun"                 { return SWITCH; }
"toca"                  { return CASE; }

	/* -- FUNCIONES -------------------------------------- */
"haga"                  { return FUNC; }
"vuelva"                { return RETURN; }
"diga"                  { return PRINT; }
"responda"              { return INPUT; }

	/* -- MANEJO DE ERRORES ------------------------------ */
"ensaye"                { return TRY; }
"ojo_pues"              { return CATCH; }
"paila"                 { return THROW; }
"cuadre"                { return ASSERT; }

	/* -- OPERADORES DE REDUCCION ------------------------ */
"sume"                  { return SUM; }
"multiplique"           { return PROD; }
"el_mas"                { return MAX; }
"el_menos"              { return MIN; }

	/* -- LITERALES BOOLEANOS ---------------------------- */
"firme_si"              { return LIT_BOOL; }
"firme_no"              { return LIT_BOOL; }
"de_una"                { return LIT_BOOL; }
"nel"                   { return LIT_BOOL; }

	/* -- OPERADORES LOGICOS (palabras clave) ------------ */
"y_es"                  { return AND; }
"o_bien"                { return OR; }
"no_es"                 { return NOT; }

	/* -- LITERALES NUMERICOS ---------------------------- */
{LIT_FLOAT}             { return LIT_FLOAT; }
{LIT_INT}               { return LIT_INT; }

	/* -- LITERALES DE CADENA ---------------------------- */
\"[^\"]*\"              { return LIT_STRING; }
\'[^\']*\'              { return LIT_STRING; }

	/* -- IDENTIFICADORES -------------------------------- */
{ID}                    { return ID; }

	/* -- OPERADORES RELACIONALES ------------------------ */
"=="                    { return EQ; }
"!="                    { return NEQ; }
"<="                    { return LEQ; }
">="                    { return GEQ; }
"<"                     { return LT; }
">"                     { return GT; }

	/* -- OPERADORES ARITMETICOS ------------------------- */
"+"                     { return PLUS; }
"-"                     { return MINUS; }
"*"                     { return TIMES; }
"/"                     { return DIV; }
"%"                     { return MOD; }
"^"                     { return POW; }
"="                     { return ASSIGN; }

	/* -- OPERADORES LOGICOS (simbolos) ------------------ */
"&&"                    { return AND; }
"||"                    { return OR; }
"!"                     { return NOT; }

	/* -- PUNTUACION ------------------------------------- */
"("                     { return LPAREN; }
")"                     { return RPAREN; }
"{"                     { return LBRACE; }
"}"                     { return RBRACE; }
"["                     { return LBRACKET; }
"]"                     { return RBRACKET; }
";"                     { return SEMI; }
","                     { return COMMA; }
":"                     { return COLON; }

	/* -- ESPACIOS --------------------------------------- */
[ \t\n]+                { }

	/* -- ERROR LEXICO ----------------------------------- */
.                       { fprintf(stderr, "Error lexico en linea %d: '%c'\n", yylineno, *yytext); }

%%
