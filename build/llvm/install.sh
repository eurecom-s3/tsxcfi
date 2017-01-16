echo "[+] Downloading llvm, clang and compiler-rt"
wget http://llvm.org/releases/3.8.0/llvm-3.8.0.src.tar.xz; tar xf llvm-3.8.0.src.tar.xz; mv llvm-3.8.0.src llvm;
(cd llvm &&
    (cd tools && wget http://llvm.org/releases/3.8.0/cfe-3.8.0.src.tar.xz && tar xf cfe-3.8.0.src.tar.xz && mv cfe-3.8.0.src clang) &&
    (cd projects && wget http://llvm.org/releases/3.8.0/compiler-rt-3.8.0.src.tar.xz && tar xf compiler-rt-3.8.0.src.tar.xz && mv compiler-rt-3.8.0.src compiler-rt)
)


echo "[+] Applying Patches"

patch -p0 <  ../../patches/clang_tsxcfi.diff
cp -r ../../src/llvm/* ./llvm/

echo "[+] Building..."
mkdir llvm-build;
cd llvm-build;
  CC=clang CXX=clang++ cmake -G "Ninja" -DCMAKE_BUILD_TYPE="RelWithDebInfo"  \
    -DLLVM_TARGETS_TO_BUILD=X86        \
    -DLLVM_OPTIMIZED_TABLEGEN=ON       \
    -DLLVM_INCLUDE_EXAMPLES=OFF        \
    -DLLVM_INCLUDE_TESTS=OFF           \
    -DLLVM_INCLUDE_DOCS=OFF            \
    -DLLVM_ENABLE_SPHINX=OFF           \
    -DLLVM_PARALLEL_COMPILE_JOBS=12    \
    -DLLVM_PARALLEL_LINK_JOBS=4        \
    -DLLVM_ENABLE_ASSERTIONS=ON        \
    -DCMAKE_C_FLAGS:STRING="-gsplit-dwarf"  \
    -DCMAKE_CXX_FLAGS:STRING="-gsplit-dwarf" \
    ../llvm > log.txt
  ninja -j$(nproc);
  r=$?
cd ../
exit $r;


