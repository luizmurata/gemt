#include <cmath>
#include <iostream>

float **alloc_matrix(size_t n) {
  float **matrix = new float *[n];
  for (size_t i = 0; i < n; i++)
    matrix[i] = new float[n];
  return matrix;
}

void free_matrix(float **m, size_t n) {
  for (size_t i = 0; i < n; i++)
    delete[] m[i];
  delete[] m;
}

void fill_matrix(float **matrix, size_t n) {
  for (size_t i = 0; i < n; i++)
    for (size_t j = 0; j < n; j++)
      matrix[i][j] = j / ((float)i + 1);
}

void print_matrix(float **matrix, size_t n) {
  for (size_t i = 0; i < n; i++) {
    for (size_t j = 0; j < n; j++)
      std::cout << matrix[i][j] << " ";
    std::cout << std::endl;
  }
  std::cout << std::endl;
}

void transpose(float **m, float **n, size_t size) {

  for (size_t i = 0; i < size; i++) {
    for (size_t j = 0; j < size; j++) {
      n[j][i] = m[i][j];
      __builtin_prefetch(&m[i][j + 1]);
    }
  }
}

int main(int argc, char **argv) {
  if (argc < 2) {
    std::cerr << "missing size" << std::endl;
    return -1;
  }
  size_t size = atoi(argv[1]);
  size_t N = pow(2.0, size);
  float **m __attribute__((aligned(64)));
  float **n __attribute__((aligned(64)));
  m = alloc_matrix(N);
  n = alloc_matrix(N);

  std::cout << "finished allocating" << std::endl;

  fill_matrix(m, N);

  std::cout << "finished populating with random values" << std::endl;

  // printmatrix(m, N);

  transpose(m, n, N);

  std::cout << "done." << std::endl;

  return 0;
}
