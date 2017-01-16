#!/bin/bash

source ../switch.sh

TESTS=(sqlite bzip2 coreutils lame)
MODES=(native hle rtm)
COMPILERS=(clang-tsx clang-tsx-relro)

for compiler in ${COMPILERS[@]}; do
    for test in ${TESTS[@]}; do
	for mode in ${MODES[@]}; do
	    (
		cd $test;
		if [ -d "$test-$mode-$compiler" ]; then
		    echo "[-] $test with $mode ($compiler) is ALREADY compiled";
		    continue;
		fi;
		
		echo "[~] Compiling $test $mode ($compiler)... "

        switch-$mode;
        
		bash compile-$test.sh $mode $compiler;
		
		if [ $? == 0 ];
        then echo "Compilation OK";
	    else echo "Compilation FAIL";
		fi;

        bash test-$test.sh $mode $compiler;

		if [ $? == 0 ];
        then echo "Test OK";
	    else echo "Test FAIL";
		fi;
        
	    )
	done
    done
done
