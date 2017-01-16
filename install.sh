# notes for ubuntu 16.04 vagrant machine:
# sudo apt-get build-dep clang libc6 musl
# sudo apt-get install cmake ninja-build clang
# ln -s /usr/include/asm-generic /usr/include/asm
# sudo ln -s /usr/lib/x86_64-linux-gnu/asm/  /usr/include/x86_64-linux-gnu/asm/
# sudo ln -s /usr/include/x86_64-linux-gnu/asm /usr/lib/x86_64-linux-gnu/asm

# building llvm
cd build/llvm
  bash ./install.sh
  r=$?
  if [ $r != 0 ]; then echo "Cannot build llvm"; exit 1; fi
cd ../../

# build ld.so from glibc source
cd build/ld
  bash ./install.sh
  r=$?
  if [ $r != 0 ]; then echo "Cannot build ld"; exit 1; fi;
cd ../../

# build our fallback path
cd build/libtsxcfifb;
  bash ./build-libtsxcfifb.sh
  r=$?
  if [ $r != 0 ]; then echo "Cannot build libtsxcfifb"; exit 1; fi;
cd ../../

# musl libc in various format: {tsx,tsx-relro}{native,rtm,hle}
cd build/libc
  bash ./compile-all-musl.sh
  r=$?
  if [ $r != 0 ]; then echo "Cannot build all the libcs"; exit 1; fi
cd ../../



echo "[+] Done it!"
echo "You can add clang-tsx and clang-tsx-relro to your path with: export PATH=`pwd`/llvm-build/bin/:\$PATH"


