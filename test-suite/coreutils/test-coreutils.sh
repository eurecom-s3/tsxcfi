
cd ./coreutils-$1-$2/
timeout 300s make check -j$(nproc) &> makecheck.log;
exit $?;

