all:
	bison -d -v src/sintaxis.y -o src/sintaxis.tab.c
	flex -o src/lexico.yy.c src/lexico.l
	gcc src/sintaxis.tab.c src/lexico.yy.c -o ferxxlang -lfl

test: all
	@echo "=== Tests principales (tests/*.fxx) ==="
	@for f in tests/*.fxx; do \
	  ./ferxxlang "$$f" && echo "OK: $$f" || echo "FAIL: $$f"; \
	done
	@echo ""
	@echo "=== Tests no triviales validos (deben OK) ==="
	@for f in tests/non-trivial/test_shadowing.fxx \
	          tests/non-trivial/test_recursion.fxx \
	          tests/non-trivial/test_anidamiento.fxx \
	          tests/non-trivial/test_overloading.fxx \
	          tests/non-trivial/test_excepciones_completo.fxx; do \
	  ./ferxxlang "$$f" && echo "OK: $$f" || echo "FAIL: $$f"; \
	done
	@echo ""
	@echo "=== Tests de error (deben FAIL con mensaje de linea) ==="
	@for f in tests/non-trivial/test_error_sintactico_01.fxx \
	          tests/non-trivial/test_error_sintactico_02.fxx \
	          tests/non-trivial/test_error_sintactico_03.fxx \
	          tests/non-trivial/test_error_lexico_01.fxx; do \
	  ./ferxxlang "$$f" 2>&1 && echo "PASS (inesperado): $$f" || echo "FAIL (esperado): $$f"; \
	done

clean:
	rm -f src/sintaxis.tab.c src/sintaxis.tab.h src/lexico.yy.c \
	      src/sintaxis.output ferxxlang

.PHONY: all test clean
