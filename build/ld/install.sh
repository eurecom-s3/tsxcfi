

echo "[+] Cloning glibc"
git clone git://sourceware.org/git/glibc.git

echo "[+] Applying patches for rtm"
(
    cd glibc
    git checkout 3a188eb4e641d2df0cfd352fd09232347f28fbe1
)

patch -p0 <  ../../patches/glibc_tsxcfi_rtm.diff

echo "[+] Building glibc for rtm"
mkdir glibc_build_rtm
cd glibc_build_rtm
  ../glibc/configure --prefix=$PWD/   --disable-werror &> log-configure.txt
  make -j$(nproc) lib &> log-make.txt
  if [ $? == 0 ]; then echo "OK"; else echo "Make failed.."; exit 1; fi
cd ..

echo "[+] Applying patches for hle"
(
    cd glibc
    git checkout 3a188eb4e641d2df0cfd352fd09232347f28fbe1 -- .
)
patch -p0 <  ../../patches/glibc_tsxcfi_hle.diff


echo "[+] Building glibc for hle"
mkdir glibc_build_hle
cd glibc_build_hle
  ../glibc/configure --prefix=$PWD/   --disable-werror &> log-configure.txt
  make -j$(nproc) lib &> log-make.txt;
  if [ $? == 0 ]; then echo "OK"; else echo "Make failed.."; exit 1; fi
cd ..
  
exit 0;
