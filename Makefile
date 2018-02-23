all:
	clang -fPIC -Wall -Wextra -O3 -c -o alpn.o alpn.c
	clang -shared -lm -o libalpn.so alpn.o
	ponyc -p `pwd`
