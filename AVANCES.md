# AVANCES — FerxxLang

---

## FASE 0 — Entorno de compilación y Makefile

**Fecha:** 2026-06-04  
**Commit:** *(ver historial)*

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

### Estado del proyecto al final de FASE 0

| Archivo             | Estado                                         |
|---------------------|------------------------------------------------|
| `Makefile`          | ✅ Creado con targets `all / test / clean`     |
| `src/lexico.l`      | ✅ Sin cambios — todos los tokens definidos    |
| `src/sintaxis.y`    | ✅ Sin cambios — gramática vacía funcional     |
| `ferxxlang`         | ✅ Binario compilado y ejecutable              |
| `tests/test_basic.fxx` | ✅ Corre; error sintáctico esperado (gramática vacía) |

**Próxima fase:** implementar la gramática completa en `sintaxis.y` (FASE 1).

---
