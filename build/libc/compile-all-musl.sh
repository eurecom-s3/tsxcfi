#set -o xtrace

source ../../switch.sh

# type -t switch-hle &> /dev/null
# if [ $? == 1 ]; then
#     echo "switch-hle is not defined. Please go in the root directory of the project and 'source switch.sh'";
#     exit 1;
# fi

export TSXCFI_LIBC=1

switch-hle;

bash ./make_musl.sh musl_hle clang-tsx &> /dev/null
(cd  musl_hle; make; if [ $? == 0 ]; then echo "musl_hle OK"; else exit 1; fi)

bash ./make_musl.sh musl_hle_relro clang-tsx-relro &>/dev/null
(cd  musl_hle_relro; make; if [ $? == 0 ]; then echo "musl_hle_relro OK"; else exit 1; fi)

switch-rtm;
bash ./make_musl.sh musl_rtm_relro clang-tsx-relro  &>/dev/null
(cd  musl_rtm_relro; make; if [ $? == 0 ]; then echo "musl_rtm_relro OK"; else exit 1; fi)

bash ./make_musl.sh musl_rtm clang-tsx  &>/dev/null
(cd  musl_rtm; make; if [ $? == 0 ]; then echo "musl_rtm OK"; else exit 1; fi)

switch-native;
bash ./make_musl.sh musl_native_relro clang-tsx-relro  &>/dev/null
(cd  musl_native_relro; make; if [ $? == 0 ]; then echo "musl_native_relro OK"; else exit 1; fi)

bash ./make_musl.sh musl_native  clang-tsx &>/dev/null
(cd  musl_native; make; if [ $? == 0 ]; then echo "musl_native OK"; else exit 1; fi)

unset TSXCFI_LIBC1
exit 0;
