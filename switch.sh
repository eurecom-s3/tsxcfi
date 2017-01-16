root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export PATH=$PATH:$root

function switch-native(){
    libc=$root/build/libc/musl_native/lib/
    export LD_LIBRARY_PATH=$libc;
    export LIBRARY_PATH=$libc;
    export TSXCFI_MODE=native;
}

function switch-hle(){
    libc=$root/build/libc/musl_hle/lib/
    export LD_LIBRARY_PATH=$libc #:$root/build/llvm/llvm-build/lib;
    export LIBRARY_PATH=$libc #:$root/build/llvm/llvm-build/lib;
    export TSXCFI_MODE=hle;
}

function switch-rtm(){
    libc=$root/build/libc/musl_rtm/lib/
    export LD_LIBRARY_PATH=$libc;
    export LIBRARY_PATH=$libc;
    export TSXCFI_MODE=rtm
}
