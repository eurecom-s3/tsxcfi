# This script takes the "mode" as first parameter and compiler as second

rm file.raw &> /dev/null
./bzip2-$1-$2/bzip2 -k -d -f ./file.raw.bz2;
t=`md5sum ./file.raw 2>/dev/null | cut -f 1 -d " "`

if [ "$t" == "4a7492c145d790dbbad95087ff1ba93e" ]; then
   exit 0;
fi

exit 1;
