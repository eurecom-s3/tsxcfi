#usage: ./make_musl [DIR]

if [  $# != 2 ] 
then 
    echo "usage: ./make_musl DIRECTORY COMPILER"
    exit 1
fi

destdir=$1

if [ ! -d "./musl" ]; then
    echo "Git clone musl"
    git clone git://git.musl-libc.org/musl
    (
        cd musl;
        git reset --hard 6d99ad91e869aab35a4d76d34c3c9eaf29482bad;
    )
    patch -p0 < ../../patches/musl.diff;
fi;

cp -r musl $destdir
cd $destdir

find . -name "*\.s" -type f -exec python ../../../src/asm_patcher.py {} \;

if [ "$TSXCFI_MODE" == "rtm" ]; then
  sed -i 's/call " START "_c/call " START "_c+3/' ./arch/x86_64/crt_arch.h
  sed -i 's/sa_handler = func/sa_handler = (int)func+3/' ./src/signal/signal.c
fi

CC=$2 ./configure

# clang-3.8: error: unknown argument: '-fno-tree-loop-distribute-patterns'
sed -i '/CFLAGS_MEMOPS/d' config.mak

make -j$(nproc)
python ../../../src/bin_patcher.py ./lib/libc.so 
