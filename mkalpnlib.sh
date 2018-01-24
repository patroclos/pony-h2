#!/bin/bash
clang -fPIC -Wall -Wextra -O0 -g -c -o alpn.o alpn.c
clang -shared -lm -o libalpn.so alpn.o
