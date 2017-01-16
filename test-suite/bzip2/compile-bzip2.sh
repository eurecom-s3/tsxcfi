# This script takes the "mode" as first parameter.
# and the compiler as second parameter

if [ ! -f "./bzip2-1.0.6.tar.gz" ]; then
    echo "Downloading bzip2...";
    wget -q http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz ||
        (
            echo "Download failed, check the url is still valid..";
            exit 1;
        )
    tar xf bzip2-1.0.6.tar.gz     
fi;


cp -r bzip2-1.0.6 bzip2-$1-$2
(
    cd bzip2-$1-$2
    sed -i "s/CC=gcc/CC=$2/" ./Makefile
    make -j$(nproc) &> make.log;
    exit $?;
)

