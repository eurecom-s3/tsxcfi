# This script takes the "mode" (rtm, hle, native) as first parameter.


if [ ! -f "sqlite-autoconf-3160200.tar.gz" ]; then
    echo "Downloading sqlite...";
    wget -q https://sqlite.org/2017/sqlite-autoconf-3160200.tar.gz ||
        ( echo "Download failed, check the url is still valid..";
          exit 1;
        )
    tar xf sqlite-autoconf-3160200.tar.gz
fi;


cp -R sqlite-autoconf-3160200 sqlite-$1-$2

(
    cd sqlite-$1-$2
    CC=$2 CFLAGS="-Os" ./configure  &> configure.log;
    make -j$(nproc) &> make.log;
    exit $?;
)

