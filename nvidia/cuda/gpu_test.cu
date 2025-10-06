// Build and run
// nvcc -O3 -arch=native -o gpu_test gpu_test.cu
// ./gpu_test.cu

#include <cstdio>
#include <cuda_runtime.h>

#define CHECK_CUDA(cmd) do { \
  cudaError_t e = (cmd); \
  if (e != cudaSuccess) { \
    fprintf(stderr, "CUDA error %s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(e)); \
    exit(EXIT_FAILURE); \
  } \
} while (0)

__global__ void saxpy(const float a, const float* __restrict__ x, float* __restrict__ y, size_t n) {
  size_t i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) y[i] = a * x[i] + y[i];
}

__global__ void device_memcopy(const float* __restrict__ src, float* __restrict__ dst, size_t n) {
  size_t i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) dst[i] = src[i];
}

int main() {
  int count = 0;
  CHECK_CUDA(cudaGetDeviceCount(&count));
  if (count == 0) { printf("No CUDA devices found.\n"); return 0; }

  int dev = 0;
  CHECK_CUDA(cudaSetDevice(dev));
  cudaDeviceProp prop{};
  CHECK_CUDA(cudaGetDeviceProperties(&prop, dev));

  printf("CUDA Device 0: %s\n", prop.name);
  printf("  Compute Capability: %d.%d\n", prop.major, prop.minor);
  printf("  Global Memory: %.2f GB\n", prop.totalGlobalMem / (1024.0*1024.0*1024.0));
  printf("  Memory Bus Width: %d-bit\n", prop.memoryBusWidth);
  printf("  Memory Clock Rate: %.2f GHz (effective: vendor-specific)\n", prop.memoryClockRate/1e6);
  printf("  Multiprocessors: %d\n\n", prop.multiProcessorCount);

  // Problem size (~64 MB per vector)
  const size_t N = 1ull << 24;  // 16,777,216
  const size_t BYTES = N * sizeof(float);

  // Host buffers
  float *h_x=nullptr, *h_y=nullptr;
  CHECK_CUDA(cudaMallocHost(&h_x, BYTES));
  CHECK_CUDA(cudaMallocHost(&h_y, BYTES));
  for (size_t i=0; i<N; ++i) { h_x[i] = 1.0f; h_y[i] = 2.0f; }

  // Device buffers
  float *d_x=nullptr, *d_y=nullptr, *d_z=nullptr;
  CHECK_CUDA(cudaMalloc(&d_x, BYTES));
  CHECK_CUDA(cudaMalloc(&d_y, BYTES));
  CHECK_CUDA(cudaMalloc(&d_z, BYTES));

  cudaEvent_t start, stop;
  CHECK_CUDA(cudaEventCreate(&start));
  CHECK_CUDA(cudaEventCreate(&stop));

  // H2D bandwidth
  CHECK_CUDA(cudaEventRecord(start));
  CHECK_CUDA(cudaMemcpy(d_x, h_x, BYTES, cudaMemcpyHostToDevice));
  CHECK_CUDA(cudaMemcpy(d_y, h_y, BYTES, cudaMemcpyHostToDevice));
  CHECK_CUDA(cudaEventRecord(stop));
  CHECK_CUDA(cudaEventSynchronize(stop));
  float ms_h2d=0.f; CHECK_CUDA(cudaEventElapsedTime(&ms_h2d, start, stop));
  double gb_h2d = (2.0 * BYTES) / 1e9;
  printf("H2D memcpy:  %.2f GB in %.3f ms  =>  %.2f GB/s\n", gb_h2d, ms_h2d, gb_h2d / (ms_h2d/1e3));

  // Device memory bandwidth - memcopy kernel
  const int block=256;
  const int grid = (int)((N + block - 1)/block);
  CHECK_CUDA(cudaEventRecord(start));
  device_memcopy<<<grid, block>>>(d_x, d_z, N);
  CHECK_CUDA(cudaEventRecord(stop));
  CHECK_CUDA(cudaEventSynchronize(stop));
  float ms_dev=0.f; CHECK_CUDA(cudaEventElapsedTime(&ms_dev, start, stop));

  // Reads + writes = 2 * BYTES
  double gb_dev = (2.0 * BYTES) / 1e9;
  printf("Device memcopy kernel: %.2f GB in %.3f ms  =>  %.2f GB/s\n", gb_dev, ms_dev, gb_dev / (ms_dev/1e3));

  // SAXPY compute ~2 flops/element
  const float a = 3.14159f;
  CHECK_CUDA(cudaEventRecord(start));
  saxpy<<<grid, block>>>(a, d_x, d_y, N);
  CHECK_CUDA(cudaEventRecord(stop));
  CHECK_CUDA(cudaEventSynchronize(stop));
  float ms_saxpy=0.f; CHECK_CUDA(cudaEventElapsedTime(&ms_saxpy, start, stop));
  double gflops = (2.0 * N) / 1e9 / (ms_saxpy/1e3);
  printf("SAXPY kernel: N=%zu in %.3f ms  =>  %.2f GFLOP/s\n", N, ms_saxpy, gflops);

  // D2H bandwidth
  CHECK_CUDA(cudaEventRecord(start));
  CHECK_CUDA(cudaMemcpy(h_y, d_y, BYTES, cudaMemcpyDeviceToHost));
  CHECK_CUDA(cudaEventRecord(stop));
  CHECK_CUDA(cudaEventSynchronize(stop));
  float ms_d2h=0.f; CHECK_CUDA(cudaEventElapsedTime(&ms_d2h, start, stop));
  double gb_d2h = BYTES / 1e9;
  printf("D2H memcpy:  %.2f GB in %.3f ms  =>  %.2f GB/s\n", gb_d2h, ms_d2h, gb_d2h / (ms_d2h/1e3));

  // Correctness check
  bool ok = true;
  for (size_t i=0; i<10; ++i) {
    if (h_y[i] != a*1.0f + 2.0f) { ok = false; break; }
  }
  printf("\nCorrectness: %s\n", ok ? "OK" : "FAILED");

  // Cleanup
  cudaEventDestroy(start); cudaEventDestroy(stop);
  cudaFree(d_x); cudaFree(d_y); cudaFree(d_z);
  cudaFreeHost(h_x); cudaFreeHost(h_y);
  return ok ? 0 : 1;
}
