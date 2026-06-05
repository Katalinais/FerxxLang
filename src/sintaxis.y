/*
 * sintaxis.y — Analizador sintactico de FerxxLang (Bison)
 *
 * FUNCION GENERAL
 * ───────────────
 * Define la gramatica libre de contexto (GLC) de FerxxLang en notacion BNF
 * con extensiones de Bison. Bison transforma este archivo en sintaxis.tab.c,
 * que implementa un parser LALR(1) para la gramatica definida.
 *
 * CAPAS DE GRAMATICA (orden de implementacion)
 * ─────────────────────────────────────────────
 * Capa 1: declaraciones de variables, asignaciones, expresiones con precedencia
 * Capa 2: control de flujo — if/else, while, for, switch/case
 * Capa 3: funciones — definicion, llamada, return, print, input
 * Capa 4: excepciones — try/catch, assert, throw; literales de coleccion;
 *         operadores de reduccion; acceso a campos/metodos con DOT
 *
 * CONFLICTOS CONOCIDOS: 0 shift/reduce, 0 reduce/reduce
 * (verificado en src/sintaxis.output con bison -v)
 *
 * TECNICAS DE RESOLUCION DE CONFLICTOS USADAS
 * ─────────────────────────────────────────────
 * 1. Dangling-else: tokens ficticios SIN_ELSE / ELSE en %nonassoc.
 *    Cuando el parser tiene IF bloque . y ve ELSE, el lookahead ELSE
 *    tiene mayor precedencia que SIN_ELSE → shift gana → ELSE se une
 *    al IF mas cercano. Resultado: 0 conflictos pendientes.
 *
 * 2. Precedencia de operadores binarios: declaraciones %left / %right
 *    de menor a mayor prioridad. Bison resuelve los shift/reduce potenciales
 *    comparando la precedencia del token entrante con la de la regla de reduccion.
 *    Todas las expresiones binarias se resuelven sin conflictos.
 *
 * 3. sentencia_throw → THROW | THROW expr:
 *    Sin conflicto porque FOLLOW(sentencia_throw) = {SEMI} y SEMI no esta en
 *    FIRST(expr). Al ver SEMI despues de THROW, el parser reduce la alternativa
 *    vacia; al ver cualquier token de expr, hace shift hacia THROW expr.
 *
 * 4. arg → ID COLON expr vs expr → ID (en lista_args):
 *    Sin conflicto: LALR(1) crea estados distintos para el contexto de
 *    lista_args y el de caso. En lista_args, COLON puede hacer shift hacia
 *    arg nombrado. En caso, COLON no esta en FOLLOW(expr) de ese estado.
 *
 * 5. ID DOT ID vs ID DOT llamada_funcion (en expr):
 *    Sin conflicto: despues de ID DOT ID, el lookahead LPAREN no pertenece
 *    a FOLLOW(expr) → el parser puede hacer shift correctamente.
 */

%{
/*
 * Bloque de codigo C incluido al inicio de sintaxis.tab.c.
 *
 * stdio.h  — para printf() y fprintf()
 * stdlib.h — para exit() (no usado directamente, pero incluido por convencion)
 *
 * extern int yylineno  — yylineno esta definido en lexico.yy.c (generado por Flex)
 *                        gracias a %option yylineno. Lo declaramos extern para
 *                        poder usarlo en yyerror().
 *
 * extern FILE *yyin    — yyin es el puntero al archivo de entrada del scanner.
 *                        Esta declarado en lexico.yy.c. Lo declaramos extern para
 *                        poder asignarle el archivo .fxx en main().
 *
 * int yylex(void)      — prototipo de la funcion del scanner (generada por Flex).
 *                        Bison la llama internamente para obtener el siguiente token.
 *                        La declaracion explicita evita warnings de funcion implicita
 *                        en algunos compiladores.
 *
 * static int hubo_error — flag interno que se activa cuando yyerror() es llamada.
 *                         Se necesita porque yyparse() puede devolver 0 (exito)
 *                         incluso si llamo a yyerror() con recuperacion de errores.
 *                         Al verificar !yyparse() && !hubo_error en main(), garantizamos
 *                         que el mensaje de exito solo se imprime si no hubo ningun error.
 */
#include <stdio.h>
#include <stdlib.h>

extern int yylineno;
extern FILE *yyin;

int yylex(void);

static int hubo_error = 0;

/*
 * yyerror — funcion de reporte de errores sintacticos.
 *
 * Bison llama a yyerror() cuando encuentra un token que no puede
 * ser aceptado por ninguna regla gramatical en el estado actual.
 *
 * Parametro s: el mensaje de error de Bison, tipicamente "syntax error".
 * Usamos yylineno (del scanner) para reportar la linea exacta del error.
 *
 * hubo_error = 1: garantiza exit code != 0 aunque yyparse() devuelva 0.
 * Este caso ocurre cuando Bison recupera el error mediante la regla especial
 * 'error' (que no usamos aqui, pero es una salvaguarda).
 */
void yyerror(const char *s) {
    hubo_error = 1;
    fprintf(stderr, "Error sintactico en linea %d: %s\n", yylineno, s);
}
%}

/* ── DECLARACION DE TOKENS ──────────────────────────────────────────────────
 * %token declara los terminales que el parser puede recibir del scanner.
 * Los valores numericos son asignados automaticamente por Bison (empezando
 * en 258 para no colisionar con valores ASCII).
 * Bison genera un #define por cada token en sintaxis.tab.h, que lexico.l
 * incluye para poder devolver los valores correctos en yylex().
 */
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
 * TABLA DE PRECEDENCIA Y ASOCIATIVIDAD
 * ─────────────────────────────────────
 * Se declara de MENOR a MAYOR prioridad (las ultimas declaraciones tienen
 * mayor precedencia). Bison usa esta tabla para resolver conflictos
 * shift/reduce en la gramatica de expresiones.
 *
 * MECANISMO:
 * Cuando el parser tiene una regla en la pila (con cierta precedencia) y
 * ve un token de entrada (con cierta precedencia):
 *   - Si la precedencia del token > la de la regla → shift (el operador
 *     se une mas fuerte → expresion se construye desde la derecha)
 *   - Si la precedencia del token < la de la regla → reduce (la regla
 *     se aplica primero → expresion se construye desde la izquierda)
 *   - Si son iguales → asociatividad decide:
 *       %left  → reduce (asocia por la izquierda: a-b-c = (a-b)-c)
 *       %right → shift  (asocia por la derecha:   a^b^c = a^(b^c))
 *
 * TABLA COMPLETA:
 *
 * Nivel | Decl      | Tokens          | Descripcion
 * ──────┼───────────┼─────────────────┼────────────────────────────────────
 *   1   | %nonassoc | SIN_ELSE, ELSE  | pseudo-token para dangling-else
 *   2   | %right    | ASSIGN          | asignacion (no usada como op en expr)
 *   3   | %left     | OR              | o logico — menor prioridad logica
 *   4   | %left     | AND             | y logico
 *   5   | %right    | NOT             | negacion logica (unaria, asocia der)
 *   6   | %left     | EQ, NEQ         | igualdad / desigualdad
 *   7   | %left     | LT GT LEQ GEQ   | comparacion relacional
 *   8   | %left     | PLUS, MINUS     | suma y resta
 *   9   | %left     | TIMES DIV MOD   | multiplicacion, division, modulo
 *  10   | %right    | POW             | potencia (asocia derecha: 2^3^2=2^9)
 *  11   | %right    | UMINUS          | negacion unaria (pseudo-token)
 *
 * UMINUS no es un token real del scanner; es un pseudo-token usado
 * exclusivamente para dar precedencia a la regla de negacion unaria:
 *   | MINUS expr  %prec UMINUS
 * La directiva %prec UMINUS hace que esta regla use la precedencia de
 * UMINUS (la mas alta) en vez de la de MINUS, evitando el conflicto con
 * la resta binaria.
 *
 * EJEMPLO: -x^2  →  -(x^2)  porque POW < UMINUS
 * EJEMPLO: a+b*c →  a+(b*c) porque PLUS < TIMES
 * EJEMPLO: a&&b||c → (a&&b)||c porque OR < AND (OR tiene menor precedencia)
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
 * programa — regla raiz de la gramatica.
 * El parser aplica esta regla cuando ha consumido toda la entrada.
 * El mensaje de exito se imprime en main() despues de yyparse() para
 * evitar la condicion de carrera donde la accion de la regla raiz se
 * ejecuta ANTES de que yyerror() sea llamada en errores tardios.
 */
programa
    : lista_sent    { /* exito: main() imprime el mensaje tras yyparse() */ }
    ;

/*
 * lista_sent — secuencia de cero o mas sentencias.
 * La alternativa vacia (epsilon) permite programas vacios y bloques vacios.
 * La recursion izquierda ( lista_sent sentencia ) genera una pila LR
 * eficiente en memoria: el parser no necesita apilar toda la secuencia.
 *
 * GRAMATICA BNF:
 *   lista_sent → ε
 *              | lista_sent sentencia
 */
lista_sent
    : /* vacio */
    | lista_sent sentencia
    ;

/*
 * sentencia — unidad basica de ejecucion.
 * Cada alternativa corresponde a una construccion del lenguaje.
 *
 * NOTA SOBRE SEMI:
 * Las sentencias terminadas en ; tienen el SEMI aqui, NO dentro de cada
 * regla hija. Esto centraliza el manejo del terminador y simplifica las
 * reglas hijas (declaracion, asignacion, etc. no necesitan saber sobre SEMI).
 *
 * EXCEPCIONES (sin SEMI al final):
 *   bloque, sentencia_if, sentencia_while, sentencia_for, sentencia_switch,
 *   def_funcion, sentencia_try — terminan en '}', no en ';'.
 *
 * SENTENCIA VACIA: la alternativa SEMI permite escribir ";" solo,
 * lo que es valido en FerxxLang (equivalente a un no-op).
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
 * declaracion — introduccion de una nueva variable.
 * Primera alternativa: solo declara, sin valor inicial.
 * Segunda alternativa: declara e inicializa con una expresion.
 *
 * VARIABLE SHADOWING:
 * El parser no mantiene tabla de simbolos, por lo que permite re-declarar
 * el mismo identificador en cualquier bloque. La regla gramatical
 *   declaracion → tipo ID ASSIGN expr
 * es valida para cualquier ID, incluyendo IDs ya declarados en bloques
 * exteriores. El shadowing es "silencioso" a nivel sintactico.
 *
 * GRAMATICA BNF:
 *   declaracion → tipo ID
 *               | tipo ID = expr
 */
declaracion
    : tipo ID
    | tipo ID ASSIGN expr
    ;

/*
 * tipo — todos los tipos de dato de FerxxLang.
 * Se usan como:
 *   1. Prefijo en declaracion (luka x = 10)
 *   2. Tipo del parametro formal en def_funcion (haga f(luka n))
 *   3. Tipo de la variable catch en sentencia_try (ojo_pues (frase e))
 *
 * TIPOS PRIMITIVOS: INT, FLOAT, BOOL, STRING
 * TIPOS COMPUESTOS: VECTOR (combo), MATRIZ (parche), LIST (fila),
 *                   MAP (llave), GRID (cuadro), CLASS (parcero)
 */
tipo
    : INT       /* luka    — entero    */
    | FLOAT     /* vuelto  — flotante  */
    | BOOL      /* firme   — booleano  */
    | STRING    /* frase   — cadena    */
    | VECTOR    /* combo   — vector    */
    | MATRIZ    /* parche  — matriz    */
    | LIST      /* fila    — lista     */
    | MAP       /* llave   — mapa      */
    | GRID      /* cuadro  — cuadricula*/
    | CLASS     /* parcero — clase     */
    ;

/*
 * asignacion — modificacion del valor de una variable existente.
 * Primera alternativa: asignacion simple.
 * Segunda alternativa: asignacion a un elemento de arreglo por indice.
 *
 * NOTA: La asignacion es una SENTENCIA en FerxxLang; no es una expresion
 * que pueda aparecer dentro de otra expresion (a diferencia de C).
 * El token ASSIGN (=) aparece en la tabla de precedencia como %right
 * solo para resolver posibles conflictos, no porque se use en expresiones.
 *
 * GRAMATICA BNF:
 *   asignacion → ID = expr
 *              | ID [ expr ] = expr
 */
asignacion
    : ID ASSIGN expr
    | ID LBRACKET expr RBRACKET ASSIGN expr
    ;

/*
 * bloque — secuencia de sentencias entre llaves.
 * Las llaves son OBLIGATORIAS en FerxxLang para todos los cuerpos de
 * estructuras de control (if, while, for, switch, funcion, try/catch).
 * Esto elimina la ambiguedad del dangling-else cuando hay mas de un nivel,
 * y hace el anidamiento mas explicitamente visible.
 *
 * Los bloques permiten variable shadowing: una declaracion dentro del bloque
 * puede usar el mismo nombre que una variable del bloque exterior.
 *
 * GRAMATICA BNF:
 *   bloque → { lista_sent }
 */
bloque
    : LBRACE lista_sent RBRACE
    ;

/* ====================================================================
 * CAPA 2 — CONTROL DE FLUJO
 * ==================================================================== */

/*
 * sentencia_if — estructura condicional.
 *
 * Tres formas:
 *   1. si_ve (cond) { ... }                   — solo rama verdadera
 *   2. si_ve (cond) { ... } o_si_no { ... }   — rama verdadera y falsa
 *   3. si_ve (cond) { ... } o_si_no si_ve ... — else-if encadenado
 *
 * RESOLUCION DEL DANGLING-ELSE
 * La primera alternativa usa %prec SIN_ELSE, un pseudo-token con precedencia
 * menor que ELSE. Cuando el parser tiene:
 *   pila: IF LPAREN expr RPAREN bloque .
 *   lookahead: ELSE
 * Compara la precedencia de la regla (SIN_ELSE, nivel bajo) con la del
 * token ELSE (nivel alto). Como ELSE > SIN_ELSE → shift gana.
 * El ELSE se asocia al IF mas cercano. Este es el comportamiento correcto
 * ("greedy else" o "closest if" semantics).
 *
 * La tercera alternativa (else-if) permite cadenas arbitrarias:
 *   si_ve (a) { } o_si_no si_ve (b) { } o_si_no { }
 * sin necesidad de bloques anidados explicitos.
 *
 * GRAMATICA BNF:
 *   sentencia_if → IF ( expr ) bloque                          %prec SIN_ELSE
 *               |  IF ( expr ) bloque ELSE bloque
 *               |  IF ( expr ) bloque ELSE sentencia_if
 */
sentencia_if
    : IF LPAREN expr RPAREN bloque                        %prec SIN_ELSE
    | IF LPAREN expr RPAREN bloque ELSE bloque
    | IF LPAREN expr RPAREN bloque ELSE sentencia_if
    ;

/*
 * sentencia_while — bucle con condicion de entrada.
 * El cuerpo es un bloque (llaves obligatorias).
 * La condicion puede ser cualquier expresion booleana.
 *
 * GRAMATICA BNF:
 *   sentencia_while → WHILE ( expr ) bloque
 */
sentencia_while
    : WHILE LPAREN expr RPAREN bloque
    ;

/*
 * sentencia_for — bucle con inicializacion, condicion y actualizacion.
 *
 * Dos variantes:
 *   1. Con actualizacion explicita: for (init; cond; update) { ... }
 *   2. Sin actualizacion: for (init; cond; ) { ... }
 *
 * for_init puede ser una declaracion (introduce variable nueva) o una
 * asignacion (usa variable existente). La variable declarada en for_init
 * esta en el scope del cuerpo del for; puede ser sombreada dentro del bloque.
 *
 * GRAMATICA BNF:
 *   sentencia_for → FOR ( for_init ; expr ; asignacion ) bloque
 *                |  FOR ( for_init ; expr ; ) bloque
 */
sentencia_for
    : FOR LPAREN for_init SEMI expr SEMI asignacion RPAREN bloque
    | FOR LPAREN for_init SEMI expr SEMI             RPAREN bloque
    ;

/*
 * for_init — inicializador de la primera seccion del for.
 * Acepta declaracion (luka i = 0) o asignacion (i = 0).
 *
 * GRAMATICA BNF:
 *   for_init → declaracion | asignacion
 */
for_init
    : declaracion
    | asignacion
    ;

/*
 * sentencia_switch — seleccion multiple.
 * La expresion entre parentesis se compara con los valores de cada caso.
 * La segunda alternativa permite un switch vacio (sin casos).
 *
 * GRAMATICA BNF:
 *   sentencia_switch → SWITCH ( expr ) { lista_casos }
 *                    | SWITCH ( expr ) { }
 */
sentencia_switch
    : SWITCH LPAREN expr RPAREN LBRACE lista_casos RBRACE
    | SWITCH LPAREN expr RPAREN LBRACE              RBRACE
    ;

/*
 * lista_casos — uno o mas casos en un switch.
 * Recursion izquierda: permite N casos sin limites.
 *
 * GRAMATICA BNF:
 *   lista_casos → caso | lista_casos caso
 */
lista_casos
    : caso
    | lista_casos caso
    ;

/*
 * caso — una rama del switch.
 * Forma: toca expr : lista_sent
 * La lista_sent puede estar vacia (caso sin sentencias).
 *
 * DECISION DE DISENO: se usa una sola alternativa con lista_sent nullable.
 * Si se agregara "| CASE expr COLON" como alternativa separada, se generaria
 * un conflicto reduce/reduce: con lookahead CASE o RBRACE, el parser no
 * podria decidir entre reducir "caso → CASE expr COLON" o "lista_sent → ε".
 * Una sola alternativa elimina el conflicto.
 *
 * GRAMATICA BNF:
 *   caso → CASE expr : lista_sent
 */
caso
    : CASE expr COLON lista_sent
    ;

/* ====================================================================
 * CAPA 3 — FUNCIONES
 * ==================================================================== */

/*
 * def_funcion — definicion de una funcion con nombre y cuerpo.
 *
 * Dos variantes:
 *   1. Con parametros: haga nombre(tipo1 p1, tipo2 p2) { ... }
 *   2. Sin parametros: haga nombre() { ... }
 *
 * CARACTERISTICAS SOPORTADAS:
 *
 * a) Sobrecarga sintactica: el parser acepta multiples definiciones
 *    con el mismo nombre. No hay tabla de simbolos, por lo que no se
 *    valida si los tipos difieren. El usuario puede definir:
 *      haga f(luka n) { ... }
 *      haga f(frase s) { ... }
 *    y ambas son sintacticamente validas.
 *
 * b) Funciones anidadas: def_funcion es una sentencia, por lo tanto
 *    puede aparecer dentro del bloque de otra funcion:
 *      haga exterior(luka x) {
 *          haga interior(luka y) { ... }  ← valido
 *          ...
 *      }
 *
 * c) Recursion: la llamada al mismo nombre dentro del cuerpo es
 *    sintacticamente valida porque llamada_funcion → ID (...) acepta
 *    cualquier ID, incluyendo el nombre de la funcion actual.
 *
 * GRAMATICA BNF:
 *   def_funcion → FUNC ID ( lista_params ) bloque
 *               | FUNC ID ( ) bloque
 */
def_funcion
    : FUNC ID LPAREN lista_params RPAREN bloque
    | FUNC ID LPAREN              RPAREN bloque
    ;

/*
 * lista_params — lista de parametros formales separados por coma.
 * Uno o mas parametros tipados. Recursion izquierda.
 *
 * GRAMATICA BNF:
 *   lista_params → param | lista_params , param
 */
lista_params
    : param
    | lista_params COMMA param
    ;

/*
 * param — un parametro formal tipado.
 * El tipo es obligatorio (no hay parametros sin tipo en FerxxLang).
 *
 * GRAMATICA BNF:
 *   param → tipo ID
 */
param
    : tipo ID
    ;

/* ====================================================================
 * CAPA 4 — MANEJO DE EXCEPCIONES
 * ==================================================================== */

/*
 * sentencia_try — bloque try/catch.
 *
 * Dos formas del catch:
 *   1. Sin tipo explicito: ojo_pues (e) { ... }
 *      La variable e captura la excepcion sin declarar su tipo.
 *   2. Con tipo explicito: ojo_pues (frase e) { ... }
 *      La variable e se declara con un tipo especifico.
 *
 * La estructura completa es:
 *   ensaye { ... } ojo_pues (var) { ... }
 *
 * NOTA: No existe "finally" en FerxxLang. Un try SIEMPRE debe tener
 * exactamente un catch. Un try sin catch es un error sintactico.
 *
 * GRAMATICA BNF:
 *   sentencia_try → TRY bloque CATCH ( ID ) bloque
 *                 | TRY bloque CATCH ( tipo ID ) bloque
 */
sentencia_try
    : TRY bloque CATCH LPAREN ID       RPAREN bloque
    | TRY bloque CATCH LPAREN tipo ID  RPAREN bloque
    ;

/*
 * sentencia_assert — validacion en tiempo de ejecucion.
 *
 * Dos formas:
 *   1. Sin mensaje: cuadre(expr)
 *   2. Con mensaje: cuadre(expr, "mensaje de error")
 *      El mensaje DEBE ser un literal de cadena (LIT_STRING), no una variable.
 *
 * GRAMATICA BNF:
 *   sentencia_assert → ASSERT ( expr )
 *                    | ASSERT ( expr , LIT_STRING )
 */
sentencia_assert
    : ASSERT LPAREN expr                   RPAREN
    | ASSERT LPAREN expr COMMA LIT_STRING  RPAREN
    ;

/*
 * sentencia_throw — lanzamiento de excepcion.
 *
 * Dos formas:
 *   1. Con expresion: paila expr  — lanza la expresion como excepcion
 *   2. Vacio: paila              — re-lanza la excepcion activa (re-throw)
 *
 * SIN CONFLICTO SHIFT/REDUCE:
 * Esta regla produce un potencial conflicto porque THROW puede ir solo
 * o seguido de expr. Al ver THROW en la pila y luego el lookahead:
 *   - Si lookahead es SEMI: debe reducirse a la alternativa vacia.
 *   - Si lookahead es el inicio de expr: debe hacerse shift para consumir expr.
 * El conflicto no ocurre porque FOLLOW(sentencia_throw) = {SEMI} y
 * SEMI ∉ FIRST(expr). El parser nunca duda: SEMI → reduce vacio, expr → shift.
 *
 * GRAMATICA BNF:
 *   sentencia_throw → THROW expr | THROW
 */
sentencia_throw
    : THROW expr
    | THROW
    ;

/*
 * sentencia_return — valor de retorno de una funcion.
 *
 * Dos formas:
 *   1. Con valor: vuelva expr  — devuelve el valor de la expresion
 *   2. Vacio: vuelva           — retorno sin valor (funcion void)
 *
 * El mismo analisis que sentencia_throw aplica aqui: sin conflicto porque
 * FOLLOW(sentencia_return) = {SEMI} y SEMI ∉ FIRST(expr).
 *
 * GRAMATICA BNF:
 *   sentencia_return → RETURN expr | RETURN
 */
sentencia_return
    : RETURN expr
    | RETURN
    ;

/*
 * sentencia_print — impresion en la salida estandar.
 *
 * Dos formas:
 *   1. Con argumento: diga(expr)  — imprime el valor de expr
 *   2. Sin argumento: diga()      — imprime una linea vacia (newline)
 *
 * GRAMATICA BNF:
 *   sentencia_print → PRINT ( expr ) | PRINT ( )
 */
sentencia_print
    : PRINT LPAREN expr RPAREN
    | PRINT LPAREN      RPAREN
    ;

/*
 * sentencia_input — lectura de la entrada estandar.
 *
 * Dos formas:
 *   1. Con prompt: responda("texto")  — muestra el prompt y lee
 *   2. Sin prompt: responda()         — lee directamente
 *
 * El prompt DEBE ser un literal de cadena (LIT_STRING), no una variable.
 * Este es el unico lugar en la gramatica donde LIT_STRING es obligatorio
 * como argumento (por contraste con sentencia_assert donde es opcional).
 *
 * GRAMATICA BNF:
 *   sentencia_input → INPUT ( LIT_STRING ) | INPUT ( )
 */
sentencia_input
    : INPUT LPAREN LIT_STRING RPAREN
    | INPUT LPAREN            RPAREN
    ;

/*
 * llamada_funcion — invocacion de una funcion por nombre.
 *
 * Dos formas:
 *   1. Con argumentos: nombre(arg1, arg2, ...)
 *   2. Sin argumentos: nombre()
 *
 * Aparece como:
 *   a) Sentencia standalone: funcion(); (con SEMI en la regla sentencia)
 *   b) Dentro de expr: luka r = funcion() + 1; (via la regla expr → llamada_funcion)
 *
 * Para el caso (b), llamada_funcion se incluye en expr ANTES de la regla
 * expr → ID, de modo que al ver ID LPAREN, el parser prefiera llamada_funcion
 * sobre la reduccion prematura ID → expr. Esto es posible porque LPAREN
 * no pertenece a FOLLOW(expr).
 *
 * GRAMATICA BNF:
 *   llamada_funcion → ID ( lista_args ) | ID ( )
 */
llamada_funcion
    : ID LPAREN lista_args RPAREN
    | ID LPAREN            RPAREN
    ;

/*
 * lista_args — argumentos reales de una llamada a funcion.
 * Uno o mas argumentos. Recursion izquierda.
 *
 * GRAMATICA BNF:
 *   lista_args → arg | lista_args , arg
 */
lista_args
    : arg
    | lista_args COMMA arg
    ;

/*
 * arg — un argumento real en una llamada a funcion.
 *
 * Dos formas:
 *   1. Posicional: expr              — argumento por posicion
 *   2. Nombrado:   ID COLON expr     — argumento por nombre (nombre: valor)
 *
 * SIN CONFLICTO CON CASO:
 * La forma ID COLON podria confundirse con el patron de caso (toca ID: ...)
 * pero LALR(1) crea estados separados para el contexto de lista_args
 * (dentro de una llamada a funcion) y el contexto de caso (dentro de switch).
 * En el estado de lista_args, COLON despues de ID produce shift hacia
 * arg → ID COLON expr. En el estado de caso, ese estado no existe.
 *
 * GRAMATICA BNF:
 *   arg → expr | ID : expr
 */
arg
    : expr
    | ID COLON expr
    ;

/* ====================================================================
 * EXPRESIONES — Capa 1 + Capa 4
 * ==================================================================== */

/*
 * expr — expresiones con precedencia y asociatividad completas.
 *
 * Las alternativas estan ordenadas para que el parser LALR(1) pueda
 * distinguirlas sin conflictos. El orden critico es:
 *
 *   POSICION 1: ID DOT llamada_funcion — metodo: obj.f() o obj.f(args)
 *               Debe ir antes de ID DOT ID y antes de llamada_funcion.
 *               Despues de ID DOT ID, lookahead LPAREN → shift (metodo).
 *
 *   POSICION 2: ID DOT ID — acceso a campo: obj.campo
 *               Despues de reducir a esta forma, lookahead LPAREN no esta
 *               en FOLLOW(expr), asi que no hay conflicto.
 *
 *   POSICION 3: ID LBRACKET expr RBRACKET — indexacion: arr[i]
 *               Lookhead LBRACKET despues de ID → shift hacia esta alternativa.
 *
 *   POSICION 4: llamada_funcion — llamada libre: f() o f(args)
 *               Debe ir antes de expr → ID para que ID LPAREN sea una llamada,
 *               no un ID seguido de un LPAREN de otro contexto.
 *
 *   POSICION 5: ID — variable simple; ultima alternativa con ID porque
 *               cualquier combinacion ID+{DOT,LBRACKET,LPAREN} fue capturada antes.
 *
 * OPERADORES BINARIOS:
 * Las reglas "expr OP expr" usan las precedencias declaradas en la tabla
 * de precedencias para resolver los shift/reduce. No hay ambiguedad
 * residual porque todas las combinaciones estan cubiertas por esa tabla.
 *
 * REDUCTORES (SUM, PROD, MAX, MIN):
 * Tokens propios para operadores de reduccion. No son llamadas a funcion
 * ordinarias (no usan ID): usar tokens propios evita confusiones con
 * funciones definidas por el usuario que se llamen "sume", etc.
 *
 * LITERALES DE COLECCION:
 * LBRACKET lista_exprs RBRACKET — [1, 2, 3]  (no vacio)
 * LBRACKET RBRACKET             — []          (coleccion vacia)
 * El LBRACKET al inicio de una expr no conflictua con ID LBRACKET
 * porque la segunda alternativa empieza con ID, no con LBRACKET.
 *
 * GRAMATICA BNF (simplificada):
 *   expr → expr + expr | expr - expr | ... (operadores binarios)
 *         | ! expr | - expr             (operadores unarios)
 *         | ( expr )                    (subexpresion parentetica)
 *         | ID [ expr ]                 (indexacion de arreglo)
 *         | ID . llamada_funcion        (llamada de metodo)
 *         | ID . ID                     (acceso a campo)
 *         | llamada_funcion             (llamada a funcion)
 *         | sume/multiplique/el_mas/el_menos ( expr )  (reduccion)
 *         | [ lista_exprs ] | []        (literal de coleccion)
 *         | ID | LIT_INT | LIT_FLOAT | LIT_STRING | LIT_BOOL
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
    | MINUS expr  %prec UMINUS      { } /* negacion unaria: -x   prec=UMINUS > POW */
    | LPAREN expr RPAREN            { } /* parentesis: anula la precedencia local   */
    | ID LBRACKET expr RBRACKET     { } /* indexacion: arr[i]                       */
    | ID DOT llamada_funcion        { } /* llamada de metodo: obj.f() o obj.f(args) */
    | ID DOT ID                     { } /* acceso a campo: obj.campo                */
    | llamada_funcion               { } /* llamada libre: f(args) o f()             */
    | SUM  LPAREN expr RPAREN       { } /* sume(coleccion)                          */
    | PROD LPAREN expr RPAREN       { } /* multiplique(coleccion)                   */
    | MAX  LPAREN expr RPAREN       { } /* el_mas(coleccion)                        */
    | MIN  LPAREN expr RPAREN       { } /* el_menos(coleccion)                      */
    | LBRACKET lista_exprs RBRACKET { } /* literal: [1, 2, 3]                       */
    | LBRACKET             RBRACKET { } /* literal vacio: []                        */
    | ID                            { } /* variable simple                          */
    | LIT_INT                       { } /* literal entero: 42                       */
    | LIT_FLOAT                     { } /* literal flotante: 3.14                   */
    | LIT_STRING                    { } /* literal cadena: "hola" o 'hola'          */
    | LIT_BOOL                      { } /* literal booleano: firme_si, nel, etc.    */
    ;

/*
 * lista_exprs — uno o mas elementos separados por coma.
 * Usada exclusivamente en literales de coleccion: [e1, e2, e3].
 * Recursion izquierda: [ expr, expr, expr ] → la coma no es operador binario
 * de expr, asi que no hay conflicto con la tabla de precedencias.
 *
 * GRAMATICA BNF:
 *   lista_exprs → expr | lista_exprs , expr
 */
lista_exprs
    : expr
    | lista_exprs COMMA expr
    ;

%%

/*
 * main — punto de entrada del programa.
 *
 * LOGICA:
 * 1. Si se provee un argumento en la linea de comandos (argc > 1),
 *    se abre ese archivo y se asigna a yyin (el puntero de entrada del scanner).
 *    Si el archivo no se puede abrir, se reporta error y se sale con codigo 1.
 *
 * 2. Si no hay argumentos, yyin es stdin — permite pipes y redirecciones:
 *      echo 'luka x = 1;' | ./ferxxlang
 *      ./ferxxlang < archivo.fxx
 *
 * 3. Se llama a yyparse(). Esta funcion:
 *    a) Llama repetidamente a yylex() para obtener tokens.
 *    b) Aplica las reglas de la gramatica (tablas LALR generadas por Bison).
 *    c) Llama a yyerror() cuando encuentra un error sintactico.
 *    d) Devuelve 0 si el parse termino exitosamente, 1 si hubo error.
 *
 * 4. Si se abrio un archivo, se cierra antes de salir (buena practica).
 *
 * 5. El mensaje de exito se imprime SOLO si:
 *    - yyparse() devolvio 0 (sin errores de parse que no fueron recuperados)
 *    - hubo_error == 0 (yyerror() nunca fue llamada)
 *    Esta doble verificacion es necesaria porque Bison puede recuperar
 *    de errores internamente (via reglas 'error') y devolver 0 aun despues
 *    de haber llamado a yyerror().
 *
 * 6. El codigo de salida es resultado || hubo_error:
 *    - 0: analisis exitoso (sin errores lexicos ni sintacticos que afecten al parser)
 *    - 1: hubo al menos un error sintactico
 *    NOTA: los errores lexicos puros (solo en lexico.l) NO activan hubo_error
 *    y no causan exit code != 0 por si solos.
 */
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
