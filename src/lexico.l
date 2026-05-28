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

"int"           { return INT; }
"float"         { return FLOAT; }
"bool"          { return BOOL; }
"string"        { return STRING; }
"vector"        { return VECTOR; }
"matriz"        { return MATRIZ; }

"if"            { return IF; }
"else"          { return ELSE; }
"while"         { return WHILE; }
"for"           { return FOR; }
"switch"        { return SWITCH; }
"case"          { return CASE; }
"func"          { return FUNC; }
"return"        { return RETURN; }
"print"         { return PRINT; }
"input"         { return INPUT; }
"try"           { return TRY; }
"catch"         { return CATCH; }
"assert"        { return ASSERT; }
"sum"           { return SUM; }
"prod"          { return PROD; }
"max"           { return MAX; }
"min"           { return MIN; }

"true"          { return LIT_BOOL; }
"false"         { return LIT_BOOL; }

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
