##Introduction##

This repository contains the prototye implementation of TSX-based CFI enforcement, as described in [1].

##Getting Started - The Easy Way##
0. `cd tsxcfi && docker build -t=tsxcfi .`
1. `docker run -ti tsxcfi`
    
##Getting Started - The Hard Way##
0. Install the following packages:
    `cmake ninja-build clang git patch build-essential nasm wget bison texinfo gawk`
1. Run `bash install.sh`.
  This automatically fetches, patches and build llvm/clang, ld from glibc, musl-libc and libtsxcfifb. 
  This can take a while.
2. Run `source switch.sh` inside your shell.
   This setups the required environment variables for compiling and executing tsxcfied binaries.
3. Go in the test folder and run `bash test.sh`. This compiles and run bzip2 and sqlite in 6 different flavors:
    native, hle, rtm, native-relro, hle-relro and rtm-relro.
3. Switch to the desired mode with `switch-native`, `switch-rtm` or `switch-hle` and compile your program with `clang-tsx` or `clang-tsx-relro`.

##Folders & Files##

- **/:** Contains the main install script, the scripts for compiling and a script for setting up the required environment variables.
- **build:** Contains the install scripts and build folders for llvm/clang, glibc, musl-libc and libtsxcfifb
- **patches:** Contains minor patch-files which are applied to the LLVM-backend and to glibc
- **src:** Contains the source code for tsxcfi - mainly assembly-code for fallback-paths, the LLVM-Backend passes and the pre- and postprocessing scripts. 
- **test:** Contains the test-programs instrumented in the paper.



[1] Muench, M., Pagani, F., Shoshitaishvili, Y., Kruegel, C., Vigna, G., Balzarotti, D.: ["Taming Transactions: Towards Hardware-Assisted Control Flow Integrity Using Transactional Memory"](http://www.s3.eurecom.fr/docs/raid16_muench.pdf), 19th Symposium on Research in Attacks, Intrusions and Defenses (RAID), Lecture Notes in Computer Science, Springer Verlag.
France, September 2016.
