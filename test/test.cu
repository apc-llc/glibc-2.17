// Test to ensure malloc-allocated memory in CUDA-enabled GLIBC is
// directly accessible from within CUDA kernel

#include <cstdio>

void __global__ kernel(int* val)
{
	printf("GPU value read: %d\n", *val);
}

#include <malloc.h>

#define CUDA_SAFE_CALL(x) \
	do { cudaError_t err = x; if (err != cudaSuccess) { \
		fprintf (stderr, "Error \"%s\" at %s:%d \n", cudaGetErrorString(err), \
			__FILE__, __LINE__); exit(-1); \
	}} while (0);

int main(int argc, char* argv[])
{
	int* val = (int*)malloc(sizeof(int));
	*val = 2015;
	kernel<<<1, 1>>>(val);
	CUDA_SAFE_CALL(cudaGetLastError());
	CUDA_SAFE_CALL(cudaDeviceSynchronize());
	printf("CPU value read: %d\n", *val);

	return 0;
}

