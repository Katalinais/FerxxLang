# FerxxLang

**FerxxLang** es un lenguaje de scripting con vocabulario en argot colombiano, diseñado para la construcción modular de scripts científicos. Sus archivos tienen extensión `.fxx`. El analizador léxico y sintáctico está implementado con **Flex** y **Bison** sobre C.

---

## Tabla de contenidos

1. [Requisitos](#requisitos)
2. [Compilar y ejecutar](#compilar-y-ejecutar)
3. [Vocabulario del lenguaje](#vocabulario-del-lenguaje)
4. [Reglas léxicas](#reglas-léxicas)
5. [Ejemplos de código](#ejemplos-de-código)
6. [Manejo de errores léxicos](#manejo-de-errores-léxicos)
7. [Pruebas](#pruebas)
8. [Estructura del repositorio](#estructura-del-repositorio)

---

## Requisitos

| Herramienta | Versión mínima | Verificar con         |
|-------------|----------------|-----------------------|
| GCC         | 12+            | `gcc --version`       |
| Flex        | 2.6+           | `flex --version`      |
| Bison       | 3.8+           | `bison --version`     |

Instalación en Debian/Ubuntu/Kali:

```bash
sudo apt install flex bison gcc
```

---

## Compilar y ejecutar

```bash
make                         # compila → genera ./ferxxlang
./ferxxlang archivo.fxx      # analiza un archivo
./ferxxlang < archivo.fxx    # alternativa por stdin
make test                    # corre todos los tests en tests/
make clean                   # elimina archivos generados
```

El ejecutable imprime `✓ Analisis sintactico exitoso` en stdout si el archivo es válido, o mensajes de error en stderr indicando la línea exacta del problema.

---

## Vocabulario del lenguaje

FerxxLang mapea cada concepto del lenguaje a una palabra en argot colombiano.

### Tipos de dato

| Keyword FerxxLang | Token   | Equivalente convencional |
|-------------------|---------|--------------------------|
| `luka`            | INT     | int                      |
| `vuelto`          | FLOAT   | float                    |
| `firme`           | BOOL    | bool                     |
| `frase`           | STRING  | string                   |
| `combo`           | VECTOR  | vector                   |
| `parche`          | MATRIZ  | matrix                   |
| `fila`            | LIST    | list                     |
| `llave`           | MAP     | map                      |
| `cuadro`          | GRID    | grid                     |
| `parcero`         | CLASS   | class                    |

### Literales booleanos

| Keyword FerxxLang | Valor |
|-------------------|-------|
| `firme_si`        | true  |
| `de_una`          | true  |
| `firme_no`        | false |
| `nel`             | false |

Los cuatro son sinónimos: `firme_si` y `de_una` producen el mismo token `LIT_BOOL`; lo mismo `firme_no` y `nel`.

### Control de flujo

| Keyword FerxxLang | Token  | Equivalente |
|-------------------|--------|-------------|
| `si_ve`           | IF     | if          |
| `o_si_no`         | ELSE   | else        |
| `siga_pues`       | WHILE  | while       |
| `dele`            | FOR    | for         |
| `segun`           | SWITCH | switch      |
| `toca`            | CASE   | case        |

### Funciones y entrada/salida

| Keyword FerxxLang | Token  | Equivalente |
|-------------------|--------|-------------|
| `haga`            | FUNC   | function    |
| `vuelva`          | RETURN | return      |
| `diga`            | PRINT  | print       |
| `responda`        | INPUT  | input       |

### Manejo de errores

| Keyword FerxxLang | Token  | Equivalente |
|-------------------|--------|-------------|
| `ensaye`          | TRY    | try         |
| `ojo_pues`        | CATCH  | catch       |
| `paila`           | THROW  | throw       |
| `cuadre`          | ASSERT | assert      |

### Operadores de reducción

Actúan sobre colecciones (`combo`, `fila`, `parche`):

| Keyword FerxxLang | Token | Equivalente |
|-------------------|-------|-------------|
| `sume`            | SUM   | sum()       |
| `multiplique`     | PROD  | product()   |
| `el_mas`          | MAX   | max()       |
| `el_menos`        | MIN   | min()       |

### Operadores lógicos

Disponibles en dos formas: palabra clave y símbolo. Ambas producen el mismo token.

| Keyword / Símbolo | Token | Equivalente |
|-------------------|-------|-------------|
| `y_es` / `&&`     | AND   | and / &&    |
| `o_bien` / `\|\|` | OR    | or / \|\|   |
| `no_es` / `!`     | NOT   | not / !     |

### Operadores aritméticos y relacionales

| Símbolo | Token | Descripción           |
|---------|-------|-----------------------|
| `+`     | PLUS  | suma                  |
| `-`     | MINUS | resta / negación      |
| `*`     | TIMES | multiplicación        |
| `/`     | DIV   | división              |
| `%`     | MOD   | módulo                |
| `^`     | POW   | potencia              |
| `=`     | ASSIGN| asignación            |
| `==`    | EQ    | igualdad              |
| `!=`    | NEQ   | desigualdad           |
| `<`     | LT    | menor que             |
| `>`     | GT    | mayor que             |
| `<=`    | LEQ   | menor o igual         |
| `>=`    | GEQ   | mayor o igual         |

### Puntuación

| Símbolo | Token    |
|---------|----------|
| `(`     | LPAREN   |
| `)`     | RPAREN   |
| `{`     | LBRACE   |
| `}`     | RBRACE   |
| `[`     | LBRACKET |
| `]`     | RBRACKET |
| `;`     | SEMI     |
| `,`     | COMMA    |
| `:`     | COLON    |

---

## Reglas léxicas

### Expresiones regulares para literales

| Categoría        | Expresión regular        | Ejemplos válidos           |
|------------------|--------------------------|----------------------------|
| Entero           | `[0-9]+`                 | `0`, `42`, `1000`          |
| Flotante         | `[0-9]+\.[0-9]+`         | `3.14`, `0.5`, `99.99`     |
| Cadena (dobles)  | `"[^"]*"`                | `"parcero"`, `"hola"`      |
| Cadena (simples) | `'[^']*'`                | `'bacano'`, `'ferxxo'`     |
| Identificador    | `[a-zA-Z_][a-zA-Z0-9_]*` | `x`, `mi_var`, `_privado`  |

### Comentarios

FerxxLang reconoce dos formas de comentario de línea. Ambas son ignoradas completamente por el analizador:

```fxx
# esto es un comentario con almohadilla
// esto también es un comentario de línea
```

No existen comentarios multilínea.

### Prioridad de reconocimiento: regla de maximal munch

Flex aplica siempre la coincidencia más larga posible (*maximal munch*). Esto tiene dos implicaciones clave:

**1. Keywords antes que identificadores:**
Las palabras reservadas están listadas antes de la regla `{ID}` en el scanner. Si el lexer lee `luka`, devuelve INT (keyword), no ID. Si lee `lukax`, devuelve ID porque ningún keyword completo coincide con esa cadena.

```fxx
luka   # → token INT  (keyword exacto)
lukax  # → token ID   (no es keyword)
luka2  # → token ID
```

**2. Operadores de dos caracteres antes que de uno:**
`!=` devuelve NEQ (2 chars) y no un `!` + `=` separados. Lo mismo con `==`, `<=`, `>=`, `&&`, `||`.

```fxx
!=   # → NEQ  (un solo token)
!    # → NOT  (solo cuando no sigue =)
```

**3. Flotantes antes que enteros:**
`3.14` devuelve `LIT_FLOAT`. Si la regla de enteros tuviera prioridad, `3.14` se partiría en `LIT_INT` + `.` + `LIT_INT`.

### Identificadores válidos

Un identificador comienza con letra o guion bajo, seguido de cualquier combinación de letras, dígitos y guiones bajos. Las palabras reservadas no pueden usarse como identificadores.

```fxx
x          # válido
mi_var     # válido
_privado   # válido
Resultado2 # válido
luka       # NO — es keyword INT
2x         # NO — no puede empezar con dígito
```

### Espacios en blanco

Espacios, tabs y saltos de línea (`[ \t\n]`) se ignoran completamente. Son separadores transparentes al análisis.

---

## Ejemplos de código

### Declaración e inicialización de variables

```fxx
luka   entero  = 42;
vuelto decimal = 3.14;
firme  activo  = firme_si;
firme  inactivo = nel;
frase  texto   = "parcero";
frase  otro    = 'bacano';
```

### Tipos compuestos

```fxx
combo  numeros;        # vector (sin inicializar)
parche tabla;          # matrix
fila   elementos;      # list
llave  config;         # map
cuadro tablero;        # grid
```

### Expresiones aritméticas

```fxx
luka resultado = (x + 2) * 3 - 1 % 2;
vuelto potencia = base ^ exponente;
luka negativo   = -x;
```

### Expresiones lógicas

```fxx
# Con palabras clave
firme cond1 = x > 0 y_es no_es activo;
firme cond2 = a == b o_bien c != d;

# Con símbolos equivalentes
firme cond3 = x > 0 && !activo;
firme cond4 = a == b || c != d;
```

### Acceso a elementos de arreglo

```fxx
combo nums;
nums[0] = 5;
nums[i] = nums[i] + 1;
luka val = nums[0];
```

### Control de flujo

```fxx
si_ve (x > 0) {
    diga(x);
} o_si_no {
    diga("negativo");
}

siga_pues (x > 0) {
    x = x - 1;
}

dele (luka i = 0; i < 10; i = i + 1) {
    diga(i);
}

segun (opcion) {
    toca 1: diga("uno");
    toca 2: diga("dos");
}
```

### Funciones

```fxx
haga factorial(luka n) {
    si_ve (n <= 1) {
        vuelva 1;
    }
    vuelva n * factorial(n - 1);
}
```

### Operadores de reducción

```fxx
combo nums = [1, 2, 3, 4, 5];
luka total   = sume(nums);
luka producto = multiplique(nums);
luka maximo  = el_mas(nums);
luka minimo  = el_menos(nums);
```

### Manejo de excepciones

```fxx
ensaye {
    cuadre(pi > 0, "pi debe ser positivo");
} ojo_pues (e) {
    paila e;
}
```

### Programa completo

```fxx
# Calculo de factorial con manejo de error

luka n = 10;
firme valido = n > 0;

haga factorial(luka x) {
    si_ve (x <= 1) {
        vuelva 1;
    }
    vuelva x * factorial(x - 1);
}

ensaye {
    cuadre(valido, "n debe ser positivo");
    luka resultado = factorial(n);
    diga(resultado);
} ojo_pues (e) {
    diga("Error en el calculo");
    paila e;
}
```

---

## Manejo de errores léxicos

Cualquier carácter que no forme parte del vocabulario de FerxxLang genera un error léxico. El analizador reporta la línea exacta y el carácter problemático, y continúa procesando el resto del archivo:

```
Error lexico en linea N: 'X'
```

**Ejemplo:**

```fxx
luka x = 10;
@ esto genera error
luka y = 20;
```

Salida:
```
Error lexico en linea 2: '@'
```

Los caracteres que siempre generan error léxico incluyen: `@`, `$`, `~`, `\`, `` ` ``, `?`, `#!` (fuera de comentario), entre otros.

---

## Pruebas

Los archivos de prueba se encuentran en `tests/` con extensión `.fxx`.

### Ejecutar todas las pruebas

```bash
make test
```

Por cada archivo reporta `OK` (análisis exitoso, exit 0) o `FAIL` (hubo errores, exit 1).

### Pruebas incluidas

#### `tests/test_lexico.fxx`
Cubre todos los tokens del vocabulario en una sola pasada:
- Los 10 tipos de dato
- Los 4 literales booleanos en sus dos variantes
- Operadores lógicos en forma de keyword (`y_es`, `o_bien`, `no_es`) y símbolo (`&&`, `||`, `!`)
- Strings con comillas dobles y simples
- Literales enteros y flotantes
- Todos los operadores aritméticos, relacionales y de reducción
- Un carácter inválido `@` al final (error léxico intencional)

#### `tests/test_declaraciones.fxx`
Cubre la capa de declaraciones y expresiones:
- Declaraciones sin inicializar de los 10 tipos
- Declaraciones con inicialización (entero, flotante, booleano, string)
- Asignaciones simples y a elementos de arreglo
- Expresiones aritméticas anidadas con paréntesis
- Expresiones lógicas combinadas (AND + NOT)
- Bloques anidados con variable shadowing
- Sentencia vacía `;`

#### `tests/test_basic.fxx`
Prueba de referencia que combina múltiples construcciones del lenguaje.

### Probar un archivo individual

```bash
./ferxxlang tests/test_lexico.fxx
./ferxxlang mi_script.fxx
```

### Verificar un fragmento rápido desde la terminal

```bash
# Declaración válida
printf 'luka x = 42;\n' | ./ferxxlang /dev/stdin

# Error léxico
printf 'luka x = @;\n' | ./ferxxlang /dev/stdin
# → Error lexico en linea 1: '@'

# Operadores lógicos — ambas formas equivalentes
printf 'firme c = x > 0 y_es no_es activo;\n' | ./ferxxlang /dev/stdin
printf 'firme c = x > 0 && !activo;\n'         | ./ferxxlang /dev/stdin
```

---

## Estructura del repositorio

```
FerxxLang/
├── Makefile                  ← targets: all / test / clean
├── src/
│   ├── lexico.l              ← analizador léxico (Flex)
│   └── sintaxis.y            ← analizador sintáctico (Bison)
└── tests/
    ├── test_basic.fxx        ← prueba de referencia general
    ├── test_lexico.fxx       ← cobertura léxica completa
    └── test_declaraciones.fxx← declaraciones y expresiones
```

Archivos generados por el build (no editar):

```
src/sintaxis.tab.c   ← parser C generado por Bison
src/sintaxis.tab.h   ← cabeceras de tokens
src/lexico.yy.c      ← scanner C generado por Flex
src/sintaxis.output  ← reporte de estados LALR y conflictos
ferxxlang            ← ejecutable final
```

---

## Información del entorno de desarrollo

| Campo              | Valor                          |
|--------------------|--------------------------------|
| Lenguaje base      | C (estándar C11)               |
| Generador léxico   | Flex 2.6.4                     |
| Generador sintáctico | Bison 3.8.2                  |
| Compilador         | GCC 14.2.0 (Debian)            |
| Sistema operativo  | Kali Linux (kernel 6.12, x64)  |
| Extensión de archivos | `.fxx`                      |
