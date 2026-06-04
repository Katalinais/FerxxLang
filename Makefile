all:
	bison -d -v src/sintaxis.y -o src/sintaxis.tab.c
	flex -o src/lexico.yy.c src/lexico.l
	gcc src/sintaxis.tab.c src/lexico.yy.c -o ferxxlang -lfl

test: all
	for f in tests/*.fxx; do \
	  ./ferxxlang "$$f" && echo "OK: $$f" || echo "FAIL: $$f"; \
	done

clean:
	rm -f src/sintaxis.tab.c src/sintaxis.tab.h src/lexico.yy.c \
	      src/sintaxis.output ferxxlang

.PHONY: all test clean
