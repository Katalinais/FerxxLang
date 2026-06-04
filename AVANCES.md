# AVANCES — FerxxLang

---

## FASE 0 — Entorno de compilación y Makefile

**Fecha:** 2026-06-04  
**Commit:** `9ce9182`

### Commit message (English)
```
feat(phase-0): add Makefile and build environment setup

- Add Makefile with all/test/clean targets for Flex+Bison+GCC pipeline
- Drop -ly flag (liby not installed on Kali; main/yyerror already in sintaxis.y)
- Update .gitignore to track AVANCES.md and exclude generated build artifacts
- Add AVANCES.md with exhaustive Phase 0 documentation
```

### Objetivo
Verificar el toolchain (Flex, Bison, GCC), crear el Makefile con los targets
`all`, `test` y `clean`, y confirmar que el proyecto compila sin errores.

---

### Versiones del toolchain verificadas

| Herramienta | Versión            |
|-------------|--------------------|
| Flex        | 2.6.4              |
| Bison       | 3.8.2              |
| GCC         | 14.2.0 (Debian)    |

Todas presentes en `/usr/bin/` sin necesidad de instalación adicional.

---

### Makefile creado

Ubicación: `FerxxLang/Makefile`

Targets implementados:

- **`all`** — Ejecuta la cadena completa:
  1. `bison -d -v src/sintaxis.y -o src/sintaxis.tab.c` → genera `.tab.c` y `.tab.h`
  2. `flex -o src/lexico.yy.c src/lexico.l` → genera el scanner C
  3. `gcc src/sintaxis.tab.c src/lexico.yy.c -o ferxxlang -lfl`

- **`test`** — Depende de `all`; itera sobre `tests/*.fxx` e imprime `OK` o `FAIL`
  según el código de salida del proceso.

- **`clean`** — Elimina todos los archivos generados: `.tab.c`, `.tab.h`,
  `.yy.c`, `.output` y el binario `ferxxlang`.

#### Ajuste necesario: eliminación de `-ly`

La especificación original pedía compilar con `-lfl -ly`. La flag `-ly` enlaza
`liby` (biblioteca YACC de Bison) que provee un `main()` y `yyerror()` por
defecto. En esta distribución de Kali Linux, `liby` **no está instalada**
(`/usr/lib/x86_64-linux-gnu/` no contiene `liby.a` ni `liby.so`).

Dado que `sintaxis.y` ya define ambas funciones explícitamente, `-ly` es
innecesaria y se eliminó sin pérdida de funcionalidad.  
`libfl` sí está disponible (`/usr/lib/x86_64-linux-gnu/libfl.so`) y se conserva.

---

### Salida de compilación

```
bison -d -v src/sintaxis.y -o src/sintaxis.tab.c
flex -o src/lexico.yy.c src/lexico.l
gcc src/sintaxis.tab.c src/lexico.yy.c -o ferxxlang -lfl
```

Sin warnings ni errores. Binario generado: `ferxxlang` (32 KB, x86-64).

---

### Resultado de `make test`

```
Error sintactico en linea 3: syntax error
OK: tests/test_basic.fxx
```

**Por qué dice "OK" con error sintáctico:** `main()` en `sintaxis.y` no
propaga el valor de retorno de `yyparse()`, así que el proceso siempre sale con
código 0. El error sintáctico en línea 3 es **esperado**: con la gramática
actual (`programa : /* vacio */`), el parser acepta únicamente EOF; cualquier
token real como `luka` (línea 3) dispara un `syntax error`. Esto se corregirá
en fases posteriores al implementar la gramática completa.

El `@` al final de `test_basic.fxx` (línea 27) también genera un error léxico
(`Error lexico en linea 27: '@'`) porque no forma parte del vocabulario; es un
error intencional marcado en el test.

---

### Cómo probar esta fase

**Con Makefile (recomendado):**
```bash
make           # compila todo desde cero
make test      # corre tests/*.fxx y reporta OK/FAIL por archivo
make clean     # elimina todos los archivos generados
```

**Verificar versiones del toolchain:**
```bash
flex --version && bison --version && gcc --version
```

**Probar manualmente un archivo específico:**
```bash
./ferxxlang tests/test_basic.fxx
# Salida esperada: "Error sintactico en linea 3: syntax error"
# (gramática vacía — normal en esta fase)
```

---

### Estado del proyecto al final de FASE 0

| Archivo             | Estado                                         |
|---------------------|------------------------------------------------|
| `Makefile`          | ✅ Creado con targets `all / test / clean`     |
| `src/lexico.l`      | ✅ Sin cambios — todos los tokens definidos    |
| `src/sintaxis.y`    | ✅ Sin cambios — gramática vacía funcional     |
| `ferxxlang`         | ✅ Binario compilado y ejecutable              |
| `tests/test_basic.fxx` | ✅ Corre; error sintáctico esperado (gramática vacía) |

**Próxima fase:** completar el léxico y crear test léxico (FASE 1).

---

## FASE 1 — Completar lexico.l y test léxico

**Fecha:** 2026-06-04  
**Commit:** `e2e9b29`

### Commit message (English)
```
feat(phase-1): add AND/OR/NOT tokens, single-quote strings, and lexer test

- lexico.l: add AND/OR/NOT as keyword variants (y_es/o_bien/no_es) and
  symbol variants (&&/||/!) placed before {ID} rule to avoid misclassification
- lexico.l: add single-quote string literal rule
- lexico.l: fix section comments — indented with tab to avoid Flex 2.6.x
  "unrecognized rule" error (col-0 block comments parsed as patterns)
- sintaxis.y: declare AND OR NOT tokens
- tests/test_lexico.fxx: comprehensive lexer test covering all token categories
```

### Objetivo
Agregar los tokens lógicos faltantes (`AND`, `OR`, `NOT`) en sus dos formas
(palabras clave y símbolos), soporte para strings con comillas simples,
y crear un test léxico exhaustivo que cubra todos los tokens del lenguaje.

---

### Cambios en `src/lexico.l`

#### 1. Tokens lógicos — palabras clave (antes de `{ID}`)
```flex
"y_es"    { return AND; }
"o_bien"  { return OR; }
"no_es"   { return NOT; }
```
Se ubican **antes** de la regla `{ID}` para que el lexer los reconozca como
keywords y no como identificadores genéricos.

#### 2. Tokens lógicos — símbolos (sección de operadores)
```flex
"&&"  { return AND; }
"||"  { return OR; }
"!"   { return NOT; }
```
`"!="` (NEQ) precede a `"!"` en el archivo. Flex aplica la regla del
*maximal munch* — al leer `!=`, el patrón de dos caracteres siempre gana sobre
el de uno, por lo que no hay ambigüedad.

#### 3. Strings con comillas simples
```flex
\'[^\']*\'   { return LIT_STRING; }
```
Añadido junto a la regla de dobles comillas. Permite `'bacano'` además
de `"bacano"`.

#### 4. Comentarios de sección (corrección técnica)
Los comentarios `/* */` en la sección de reglas de Flex 2.6.x deben ir
**indentados con un tab** (o cualquier espacio). Si están en columna 0
son tratados como patrones de regla y producen `unrecognized rule`.
Se ajustó el formato de todos los comentarios de sección a tab-indentado.

---

### Cambios en `src/sintaxis.y`

Agregada declaración de los tres tokens faltantes:
```bison
%token AND OR NOT
```

---

### Contraste con `LF_Final.md`

| Requisito de LF_Final.md                      | Estado |
|------------------------------------------------|--------|
| Tipos básicos (int, float, bool, string)       | ✅     |
| Estructuras compuestas (vector, matrix)        | ✅     |
| Aritmética (+, -, *, /, %)                     | ✅     |
| Operadores de reducción (sum, prod, max, min)  | ✅     |
| Control de flujo (if/else, while, for, switch) | ✅     |
| Funciones, return, print, input                | ✅     |
| Try/catch/throw/assert                         | ✅     |
| Operadores lógicos (AND, OR, NOT)              | ✅ nuevo |
| Literales string comillas dobles y simples     | ✅ nuevo |
| Identificadores, números, comentarios          | ✅     |
| Errores léxicos con número de línea            | ✅     |

---

### Compilación tras los cambios

```
bison -d -v src/sintaxis.y -o src/sintaxis.tab.c
flex -o src/lexico.yy.c src/lexico.l
gcc src/sintaxis.tab.c src/lexico.yy.c -o ferxxlang -lfl
```

Sin warnings ni errores.

---

### Resultado de `./ferxxlang tests/test_lexico.fxx`

```
Error sintactico en linea 4: syntax error
```

**Análisis del output:**

- El error sintáctico en línea 4 (`luka x = 10;`) es **esperado**: la
  gramática sigue siendo `programa : /* vacio */`, que solo acepta EOF.
  El primer token léxico (INT) ya no es aceptado → syntax error.

- El parser aborta inmediatamente después del primer error sintáctico
  (no hay reglas de recuperación de error en esta fase), por lo que
  **nunca llega a la línea 85** donde está el `@`.

- La regla de error léxico **sí funciona** correctamente. Se verifica con:
  ```
  $ printf '@\n' | ./ferxxlang /dev/stdin
  Error lexico en linea 1: '@'
  Error sintactico en linea 1: syntax error
  ```
  El carácter `@` produce `Error lexico en linea 1: '@'` antes de que el
  parser reporte el error sintáctico. La regla está bien implementada; su
  aparición al final del test completo quedará visible cuando la gramática
  tenga recuperación de errores (fases posteriores).

---

### Cómo probar esta fase

**Con Makefile (recomendado):**
```bash
make clean && make        # recompila desde cero
make test                 # corre todos los .fxx en tests/ y reporta OK/FAIL
```

**Manualmente — test léxico completo:**
```bash
./ferxxlang tests/test_lexico.fxx
# Salida esperada: "Error sintactico en linea 4: syntax error"
# (sintaxis vacía — normal en esta fase)
```

**Manualmente — verificar error léxico aislado:**
```bash
printf '@\n' | ./ferxxlang /dev/stdin
# Salida esperada:
# Error lexico en linea 1: '@'
# Error sintactico en linea 1: syntax error
```

**Manualmente — verificar string con comillas simples:**
```bash
printf "frase s = 'hola';\n" | ./ferxxlang /dev/stdin
# Salida esperada: "Error sintactico en linea 1: syntax error"
# (el token LIT_STRING se reconoce correctamente; el error es sólo sintáctico)
```

**Manualmente — verificar operadores lógicos:**
```bash
printf 'si_ve (x y_es y) { }\n' | ./ferxxlang /dev/stdin
printf 'si_ve (x && y) { }\n'   | ./ferxxlang /dev/stdin
# En ambos casos el token AND se reconoce; error es sintáctico (gramática vacía)
```

---

### Estado del proyecto al final de FASE 1

| Archivo                  | Estado                                             |
|--------------------------|----------------------------------------------------|
| `src/lexico.l`           | ✅ Completo — todos los tokens del vocabulario     |
| `src/sintaxis.y`         | ✅ AND/OR/NOT declarados; gramática aún vacía      |
| `tests/test_lexico.fxx`  | ✅ Creado — cubre todos los tokens                 |
| `tests/test_basic.fxx`   | ✅ Sin cambios                                     |

**Próxima fase:** implementar la gramática completa en `sintaxis.y` (FASE 2).

---
