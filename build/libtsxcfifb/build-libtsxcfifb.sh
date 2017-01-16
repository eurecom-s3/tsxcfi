
PREFIX=../../src/libtsxcfifb/

nasm -felf64 $PREFIX/librtmfb.s -o librtmfb.o
ar rcs ./librtmfb.a ./librtmfb.o
nasm -felf64 $PREFIX/libhlefb.s -o libhlefb.o
ar rcs ./libhlefb.a ./libhlefb.o

nasm -felf64 $PREFIX/librtmfb-relro.s -o librtmfb-relro.o
ar rcs ./librtmfb-relro.a ./librtmfb-relro.o

nasm -felf64 $PREFIX/libhlefb-relro.s -o libhlefb-relro.o
ar rcs ./libhlefb-relro.a ./libhlefb-relro.o
