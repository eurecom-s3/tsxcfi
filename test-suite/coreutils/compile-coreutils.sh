# This script takes the "mode" as first parameter.

if [ ! -f "coreutils-8.25.tar.xz" ]; then
    echo "Downloading coreutils...";
    wget -q https://ftp.gnu.org/gnu/coreutils/coreutils-8.25.tar.xz ||
        ( echo "Download failed, check the url is still valid..";
          exit 1;
        )
    tar xf coreutils-8.25.tar.xz     
fi;

cp -r coreutils-8.25 coreutils-$1-$2
(
    cd coreutils-$1-$2;    
    CC="$2" CFLAGS="-U_FORTIFY_SOURCE" ./configure --without-selinux --disable-libcap &> configure.log;
    make -j$(nproc) IGNORE_UNUSED_LIBRARIES_CFLAGS=""  &> make.log;
    exit $?;
)



