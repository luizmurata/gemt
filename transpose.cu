#include <iostream>
#include <iomanip>

// Parameters
#define TILE_N 64     // tile dimension
#define THREAD_N 16   // number of threads for each
#define TRIALS_N 5000 // trials to run and average over

__global__ void transpose(float *a, float *b);
#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true);
inline void fillMatrix(float *m, size_t n);
inline void printMatrix(float *m, size_t n);

__global__ void transpose(float *a, float *b) {
    /* Calculate global tile indices for the thread w.r.t the input matrix */
    int x = blockIdx.x * TILE_N + threadIdx.x;
    int y = blockIdx.y * TILE_N + threadIdx.y;
    int width = gridDim.x * TILE_N;
    
    /* Load data into the tiles */
    __shared__ float tile[TILE_N][TILE_N+1];
    for (int j = 0; j < TILE_N; j += THREAD_N)
        tile[threadIdx.y+j][threadIdx.x] = a[(y+j)*width + x];
    
    /* Wait for all threads to finish */
    __syncthreads();

    /* Calculate global tile indices for the thread w.r.t the output matrix */
    x = blockIdx.y * TILE_N + threadIdx.x;
    y = blockIdx.x * TILE_N + threadIdx.y;

    /* Load data into the output matrix */
    for (int j = 0; j < TILE_N; j += THREAD_N)
        b[(y+j)*width + x] = tile[threadIdx.x][threadIdx.y + j];
}

int main(int argc, char **argv) {
    /* Check that the necessary parameter is passed */
    if (argc < 2) {
        fprintf(stderr, "Error: Missing size.\n");
        fprintf(stderr, "Usage: transpose <n> [OPTIONAL: <device>]\n");
        return -1;
    }

    /* Parse parameters */
    size_t N = 1 << atoi(argv[1]);
    int device = (argc > 2) ? atoi(argv[2]) : 0;

    std::cout << "N = " << N << std::endl;

    /* Allocate the required host memory */
    float *a = new float[N*N];
    float *b = new float[N*N];
    fillMatrix(a, N); // fill with test data
    
    /* Allocate the required device memory */
    float *d_a, *d_b;
    gpuErrchk(cudaMalloc((void**)&d_a, (N * N) * sizeof(float)));
    gpuErrchk(cudaMalloc((void**)&d_b, (N * N) * sizeof(float)));

    /* Copy the matrix into device memory */
    gpuErrchk(cudaMemcpy(d_a, a, (N * N) * sizeof(float), cudaMemcpyHostToDevice));

    /* Prepare timing events */
    cudaEvent_t start, stop;
    float time;
    gpuErrchk(cudaEventCreate(&start));
    gpuErrchk(cudaEventCreate(&stop));

    /* Calculate number of blocks and threads per block */
    dim3 gridDim(N / TILE_N, N / TILE_N);
    dim3 blockDim(TILE_N, THREAD_N);

    /* Run the kernel many times to get a statistically significant amount of data */
    gpuErrchk(cudaEventRecord(start, 0)); // start timer
    for (int i = 0; i < TRIALS_N; i++)
        transpose<<<gridDim, blockDim>>>(d_a, d_b);
    
    /* Copy back the results */
    gpuErrchk(cudaMemcpy(b, d_b, (N * N) * sizeof(float), cudaMemcpyDeviceToHost));
    gpuErrchk(cudaPeekAtLastError());

    /* Stop timer and estimate bandwidth */
    gpuErrchk(cudaEventRecord(stop, 0));
    gpuErrchk(cudaEventSynchronize(stop));
    gpuErrchk(cudaEventElapsedTime(&time, start, stop));
    size_t bytes = 2 * 4 * N * N * TRIALS_N;
    double gb = bytes / 1024. / 1024. / 1024.;
    double bandwidth = gb / (time / 1000.);
    std::cout << "Bandwidth: " << bandwidth << " GB/s" << std::endl;

#ifdef DEBUG
    /* Print before and after */
    std::cout << "A: " << std::endl;
    printMatrix(a, N);

    std::cout << "B: " << std::endl;
    printMatrix(b, N);
#endif

    /* Free up resources */
    cudaFree(d_a);
    cudaFree(d_b);
    delete []a;
    delete []b;

    return 0;
}

inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort) {
   if (code != cudaSuccess) 
   {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}

void fillMatrix(float *m, size_t n) {
    for (size_t i = 0; i < n; i++)
        for (size_t j = 0; j < n; j++)
            m[(i*n)+j] = j*i+1 / (float)(i+1);
}

void printMatrix(float *m, size_t n) {
    std::cout.setf(std::ios::fixed);
    std::cout.setf(std::ios::showpoint);
    std::cout.precision(2);
    for (size_t j = 0; j < n; j++) {
        for (size_t i = 0; i < n; i++) {
            std::cout << std::setw(8) << m[(j*n) + i] << " ";
        }
        std::cout << std::endl;
    }
}