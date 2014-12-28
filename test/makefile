all: test

test: test.cu
	nvcc -arch=sm_30 $< -o $@ -Xlinker --dynamic-linker=$(shell pwd)/../install/lib/ld-linux-x86-64.so.2

clean:
	rm -rf test

test:
	LD_LIBRARY_PATH=$LD_LIBRAYR_PATH:/usr/lib ./test

