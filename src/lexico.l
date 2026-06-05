/*
 * lexico.l — Analizador lexico de FerxxLang (Flex)
 *
 * FUNCION GENERAL
 * ───────────────
 * Este archivo define el analizador lexico (scanner) de FerxxLang usando Flex.
 * Flex transforma este archivo en lexico.yy.c, que implementa la funcion yylex().
 * yylex() es llamada repetidamente por el parser de Bison (yyparse()) para
 * obtener el siguiente token de la entrada.
 *
 * ESTRUCTURA DE UN ARCHIVO FLEX
 * ─────────────────────────────
 * Seccion 1 (antes del primer %%): opciones, definiciones de macros y codigo C.
 * Seccion 2 (entre los dos %%): reglas patron -> accion.
 * Seccion 3 (despues del segundo %%): codigo C adicional (no usado aqui).
 *
 * OPCIONES
 * ────────
 * %option noyywrap  — indica que no existe yyrap() para multiples archivos de
 *                     entrada; Flex generara codigo que termina en EOF sin llamar
 *                     a yywrap(). Sin esta opcion el scanner intenta enlazar
 *                     yywrap() que no definimos.
 * %option yylineno  — activa el contador de lineas automatico yylineno.
 *                     Cada vez que el scanner consume un '\n', Flex incrementa
 *                     yylineno. Esto permite que yyerror() (en sintaxis.y)
 *                     reporte la linea exacta del error.
 *
 * FLUJO DE EJECUCION
 * ──────────────────
 * 1. El parser llama yylex().
 * 2. yylex() lee caracteres de yyin (por defecto stdin; sustituido por main()
 *    para leer un archivo .fxx).
 * 3. Flex intenta la regla mas larga que coincida con el prefijo de la entrada
 *    (regla del "maximal munch").
 * 4. Si la regla tiene "return TOKEN", yylex() devuelve ese token al parser.
 *    Si la regla no tiene return (espacios, comentarios), el scanner continua
 *    buscando el siguiente token.
 * 5. Al llegar a EOF, yylex() devuelve 0, senalizando al parser que termino.
 *
 * ORDEN DE PRIORIDAD EN FLEX
 * ──────────────────────────
 * Cuando dos reglas coinciden el mismo prefijo, Flex elige:
 *   a) La que produce la coincidencia mas larga (maximal munch).
 *   b) Si la longitud es igual, la que aparece primero en el archivo.
 * Por eso las palabras reservadas DEBEN preceder a la regla {ID}: si "luka"
 * estuviera despues de {ID}, Flex lo reconoceria como identificador (ID) en
 * vez de como keyword (INT).
 * Por la misma razon, "!=" precede a "!" y ">=" precede a ">".
 *
 * VARIABLE yytext
 * ───────────────
 * Flex mantiene yytext como un puntero al texto del token actual.
 * Se usa en la regla de error lexico para imprimir el caracter invalido:
 *   fprintf(stderr, "... '%c' ...", *yytext)
 */

%option noyywrap yylineno
%{
/*
 * Bloque de codigo C incluido literalmente al inicio de lexico.yy.c.
 * Incluimos sintaxis.tab.h para tener los #define de los tokens
 * (INT, FLOAT, ID, etc.) generados por Bison. Sin esta inclusion,
 * las constantes numericas de los tokens no estarian definidas y
 * el codigo no compilaria.
 */
#include <stdio.h>
#include "sintaxis.tab.h"
%}

/*
 * DEFINICIONES DE MACROS (expresiones regulares nombradas)
 * ─────────────────────────────────────────────────────────
 * Las macros se expanden en las reglas de la seccion 2 usando {NOMBRE}.
 * Esto evita repetir patrones complejos y mejora la legibilidad.
 *
 * DIGITO    [0-9]        — un digito decimal; equivale a \d en otros motores
 * LETRA     [a-zA-Z_]    — una letra (mayuscula, minuscula) o guion bajo;
 *                          primer caracter valido de un identificador
 * ID        {LETRA}({LETRA}|{DIGITO})*
 *                        — identificador: letra/_ seguida de cero o mas
 *                          letras/digitos/_; esta es la definicion clasica
 *                          de identificador en lenguajes tipo C
 * LIT_INT   {DIGITO}+    — uno o mas digitos = entero decimal sin signo
 *                          (el signo negativo se maneja como UMINUS en sintaxis.y)
 * LIT_FLOAT {DIGITO}+\.{DIGITO}+
 *                        — flotante: digitos, punto literal, digitos.
 *                          El '.' es escapado con '\' porque en regex '.' es
 *                          "cualquier caracter"; lo queremos como punto literal.
 *                          Ejemplos: 3.14, 0.5, 99.99
 *                          NO acepta: 3. ni .5 (requiere digito a ambos lados)
 *
 * IMPORTANTE: LIT_FLOAT debe preceder a LIT_INT en la seccion de reglas.
 * Si el scanner ve "3.14", LIT_FLOAT produce coincidencia de 4 caracteres;
 * LIT_INT solo produciria 1 caracter ("3"). Maximal munch elige LIT_FLOAT.
 */
DIGITO      [0-9]
LETRA       [a-zA-Z_]
ID          {LETRA}({LETRA}|{DIGITO})*
LIT_INT     {DIGITO}+
LIT_FLOAT   {DIGITO}+\.{DIGITO}+

%%

	/* ── COMENTARIOS ────────────────────────────────────────────
	 * FerxxLang soporta dos formas de comentario de linea.
	 * La accion esta vacia (sin return): el scanner descarta el
	 * comentario completo y busca el siguiente token.
	 * [^\n]* — cualquier caracter excepto salto de linea, 0 o mas veces.
	 * El '\n' al final NO es consumido por este patron (no esta incluido),
	 * por lo que el salto de linea se consumira en la regla de espacios
	 * e incrementara yylineno correctamente.
	 */
"#"[^\n]*               { }
"//"[^\n]*              { }

	/* ── TIPOS DE DATO ──────────────────────────────────────────
	 * Palabras reservadas que declaran el tipo de una variable.
	 * El token devuelto es el nombre del tipo (INT, FLOAT, etc.).
	 * En la gramatica, estos tokens forman la regla 'tipo'.
	 * DEBEN preceder a la regla {ID} para que "luka" → INT y no ID.
	 */
"luka"                  { return INT; }      /* int    */
"vuelto"                { return FLOAT; }    /* float  */
"firme"                 { return BOOL; }     /* bool   */
"frase"                 { return STRING; }   /* string */
"combo"                 { return VECTOR; }   /* vector */
"parche"                { return MATRIZ; }   /* matrix */
"parcero"               { return CLASS; }    /* class  */
"fila"                  { return LIST; }     /* list   */
"cuadro"                { return GRID; }     /* grid   */
"llave"                 { return MAP; }      /* map    */

	/* ── CONTROL DE FLUJO ───────────────────────────────────────
	 * Keywords que abren estructuras de control.
	 * La gramatica usa IF/ELSE/WHILE/FOR/SWITCH/CASE para construir
	 * sentencia_if, sentencia_while, sentencia_for y sentencia_switch.
	 */
"si_ve"                 { return IF; }       /* if     */
"o_si_no"               { return ELSE; }     /* else   */
"siga_pues"             { return WHILE; }    /* while  */
"dele"                  { return FOR; }      /* for    */
"segun"                 { return SWITCH; }   /* switch */
"toca"                  { return CASE; }     /* case   */

	/* ── FUNCIONES ──────────────────────────────────────────────
	 * Keywords para definicion y uso de funciones.
	 * FUNC (haga) inicia def_funcion.
	 * RETURN (vuelva) inicia sentencia_return.
	 * PRINT (diga) inicia sentencia_print.
	 * INPUT (responda) inicia sentencia_input.
	 */
"haga"                  { return FUNC; }     /* function */
"vuelva"                { return RETURN; }   /* return   */
"diga"                  { return PRINT; }    /* print    */
"responda"              { return INPUT; }    /* input    */

	/* ── MANEJO DE ERRORES ──────────────────────────────────────
	 * Keywords para el bloque try/catch/throw/assert.
	 * TRY (ensaye) inicia sentencia_try.
	 * CATCH (ojo_pues) cierra el bloque try e inicia el handler.
	 * THROW (paila) inicia sentencia_throw (con o sin expresion).
	 * ASSERT (cuadre) inicia sentencia_assert (con o sin mensaje).
	 */
"ensaye"                { return TRY; }      /* try    */
"ojo_pues"              { return CATCH; }    /* catch  */
"paila"                 { return THROW; }    /* throw  */
"cuadre"                { return ASSERT; }   /* assert */

	/* ── OPERADORES DE REDUCCION ────────────────────────────────
	 * Operadores que agregan colecciones (combo, fila, parche).
	 * En la gramatica aparecen como funciones unarias dentro de expr:
	 *   sume(coleccion)  multiplique(coleccion)  el_mas(coleccion)  el_menos(coleccion)
	 * El token unico por operador permite distinguirlos de llamadas a
	 * funciones ordinarias (que usan el token ID).
	 */
"sume"                  { return SUM; }      /* sum()     */
"multiplique"           { return PROD; }     /* product() */
"el_mas"                { return MAX; }      /* max()     */
"el_menos"              { return MIN; }      /* min()     */

	/* ── LITERALES BOOLEANOS ────────────────────────────────────
	 * FerxxLang acepta dos sinonimos para verdadero y dos para falso.
	 * Todos producen el mismo token LIT_BOOL; el parser no distingue
	 * entre firme_si y de_una (ambos son "true" sintaticamente).
	 * La verificacion semantica del valor no es parte de este analizador.
	 */
"firme_si"              { return LIT_BOOL; } /* true  */
"firme_no"              { return LIT_BOOL; } /* false */
"de_una"                { return LIT_BOOL; } /* true  */
"nel"                   { return LIT_BOOL; } /* false */

	/* ── OPERADORES LOGICOS (palabras clave) ────────────────────
	 * Forma de palabra clave para AND, OR, NOT.
	 * Deben preceder a la regla {ID} para que no sean reconocidos
	 * como identificadores.
	 * La forma simbolica (&&, ||, !) se define mas abajo pero produce
	 * el mismo token — el parser los trata de forma identica.
	 */
"y_es"                  { return AND; }      /* and (keyword form) */
"o_bien"                { return OR; }       /* or  (keyword form) */
"no_es"                 { return NOT; }      /* not (keyword form) */

	/* ── LITERALES NUMERICOS ────────────────────────────────────
	 * LIT_FLOAT DEBE ir antes de LIT_INT.
	 * Para "3.14": LIT_FLOAT coincide 4 chars, LIT_INT solo 1 char.
	 * Maximal munch elige LIT_FLOAT. Si LIT_INT fuera primero,
	 * la regla de igual longitud no aplica porque LIT_FLOAT es mas larga.
	 * En Flex la longitud de la coincidencia prima sobre el orden,
	 * pero poner LIT_FLOAT primero es la convencion defensiva correcta.
	 */
{LIT_FLOAT}             { return LIT_FLOAT; }
{LIT_INT}               { return LIT_INT; }

	/* ── LITERALES DE CADENA ────────────────────────────────────
	 * FerxxLang acepta strings con comillas dobles o simples.
	 * \"[^\"]*\"  — abre ", cualquier caracter excepto ", cierra "
	 * \'[^\']*\'  — abre ', cualquier caracter excepto ', cierra '
	 * No se manejan secuencias de escape (\n, \\, etc.) en esta version.
	 * El string completo (incluyendo comillas) queda en yytext.
	 */
\"[^\"]*\"              { return LIT_STRING; }
\'[^\']*\'              { return LIT_STRING; }

	/* ── IDENTIFICADORES ────────────────────────────────────────
	 * La regla {ID} DEBE ir despues de TODAS las palabras reservadas.
	 * Flex elige la regla de mayor longitud: "luka" coincide con la
	 * regla exacta "luka" (4 chars) Y con {ID} (4 chars).
	 * Al tener igual longitud, Flex elige la primera regla declarada,
	 * que es la de keyword. Si {ID} fuera primero, "luka" seria ID.
	 *
	 * Identificadores validos: x, mi_var, _privado, Resultado2
	 * NO validos como ID (son keywords): luka, firme, si_ve, etc.
	 */
{ID}                    { return ID; }

	/* ── OPERADORES RELACIONALES ────────────────────────────────
	 * Los de dos caracteres (==, !=, <=, >=) DEBEN preceder a los de
	 * un caracter (=, !, <, >) para que maximal munch los prefiera.
	 * Ejemplo: al ver "!=", Flex intenta "!=" (2 chars) vs "!" (1 char);
	 * como 2 > 1, elige NEQ. Si "!" fuera primero EN LONGITUD, no
	 * importaria el orden — Flex siempre prefiere la coincidencia mas larga.
	 * Pero Flex evalua por longitud de patron potencial, no de regla, asi
	 * que el orden aqui es documentacion de la intencion.
	 */
"=="                    { return EQ; }
"!="                    { return NEQ; }
"<="                    { return LEQ; }
">="                    { return GEQ; }
"<"                     { return LT; }
">"                     { return GT; }

	/* ── OPERADORES ARITMETICOS ─────────────────────────────────
	 * Operadores de un caracter. El "=" es ASSIGN (no EQ).
	 * La precedencia y asociatividad se declaran en sintaxis.y, no aqui;
	 * el lexer solo devuelve el token sin saber su precedencia.
	 * "^" es el operador de potenciacion (pow) en FerxxLang.
	 */
"+"                     { return PLUS; }
"-"                     { return MINUS; }
"*"                     { return TIMES; }
"/"                     { return DIV; }
"%"                     { return MOD; }
"^"                     { return POW; }
"="                     { return ASSIGN; }

	/* ── OPERADORES LOGICOS (simbolos) ──────────────────────────
	 * Formas simbolicas de AND, OR, NOT. Producen los mismos tokens
	 * que sus equivalentes en palabras clave (y_es, o_bien, no_es).
	 * "&&" y "||" son de 2 caracteres: maximal munch los reconoce
	 * correctamente frente a "&" o "|" sueltos (que no son tokens validos
	 * en FerxxLang y dispararlan el error lexico).
	 * "!" debe preceder al "." del catch-all para no confundirse,
	 * pero ya esta listado antes.
	 */
"&&"                    { return AND; }
"||"                    { return OR; }
"!"                     { return NOT; }

	/* ── PUNTUACION ─────────────────────────────────────────────
	 * Delimitadores y separadores del lenguaje.
	 * LPAREN/RPAREN — parentesis para condiciones, argumentos, assert
	 * LBRACE/RBRACE — llaves para bloques de codigo
	 * LBRACKET/RBRACKET — corchetes para literales de coleccion y acceso a arreglos
	 * SEMI  — punto y coma como terminador de sentencias (obligatorio)
	 * COMMA — coma como separador de argumentos y elementos de lista
	 * COLON — dos puntos en: casos de switch (toca X:) y args nombrados (id: val)
	 * DOT   — punto para acceso a campos (obj.campo) y metodos (obj.metodo())
	 *
	 * NOTA sobre DOT y LIT_FLOAT:
	 * "3.14" produce LIT_FLOAT (4 chars) en lugar de LIT_INT + DOT + LIT_INT
	 * porque LIT_FLOAT tiene patron mas largo. El DOT solo se produce cuando
	 * el punto no esta flanqueado por digitos a ambos lados en una posicion
	 * donde LIT_FLOAT podria coincidir.
	 */
"("                     { return LPAREN; }
")"                     { return RPAREN; }
"{"                     { return LBRACE; }
"}"                     { return RBRACE; }
"["                     { return LBRACKET; }
"]"                     { return RBRACKET; }
";"                     { return SEMI; }
","                     { return COMMA; }
":"                     { return COLON; }
"."                     { return DOT; }

	/* ── ESPACIOS EN BLANCO ──────────────────────────────────────
	 * Espacios, tabulaciones y saltos de linea son separadores
	 * transparentes: se descartan sin devolver ningun token.
	 * Flex actualiza yylineno automaticamente al ver '\n' gracias
	 * a la opcion %option yylineno declarada arriba.
	 * El patron [ \t\n]+ consume secuencias de espacios en bloque
	 * (mas eficiente que un solo caracter a la vez).
	 */
[ \t\n]+                { }

	/* ── ERROR LEXICO ────────────────────────────────────────────
	 * El patron "." (punto sin escapar) en la seccion de reglas es
	 * el "catch-all": coincide con CUALQUIER caracter que no haya
	 * sido consumido por una regla anterior.
	 * En FerxxLang, cualquier caracter no reconocido (ej. @, $, ~, \)
	 * genera un error lexico.
	 *
	 * COMPORTAMIENTO:
	 *   1. Se imprime el error en stderr con el numero de linea exacto.
	 *   2. NO se devuelve ningun token (sin "return").
	 *   3. El scanner descarta el caracter invalido y continua buscando
	 *      el siguiente token.
	 * Esto significa que los errores lexicos son "suaves": el analisis
	 * continua despues del caracter invalido. El parser puede ver un
	 * token inesperado a continuacion y generar un error sintactico
	 * adicional si la secuencia resultante no es valida.
	 *
	 * DIFERENCIA CON ERRORES SINTACTICOS:
	 *   - Error lexico: caracter invalido; reportado aqui; hubo_error NO se activa.
	 *   - Error sintactico: secuencia invalida de tokens; reportado por yyerror()
	 *     en sintaxis.y; activa hubo_error = 1 → exit code 1.
	 * Un archivo con solo errores lexicos (sin errores sintacticos) producira
	 * mensajes en stderr pero exit code 0.
	 */
.                       { fprintf(stderr, "Error lexico en linea %d: '%c'\n", yylineno, *yytext); }

%%
