#include <cmath>
#include <iostream>

/**
 * \brief Performs a simple transposition of an asymmetric square matrix.
 * \param m Input matrix.
 * \param size Size of the matrix.
 */
void transpose(float **m, size_t size);

/**
 * \brief Allocates a square matrix.
 * \param size Size of the matrix.
 */
float **new_matrix(size_t size);

/**
 * \brief Dellocates a square matrix.
 * \param size Size of the matrix.
 */
void free_matrix(float **m, size_t size);

/**
 * \brief Fills a square matrix with values.
 * \param size Size of the matrix.
 */
void fill_matrix(float **matrix, size_t size);

/**
 * \brief Prints a square matrix.
 * \param size Size of the matrix.
 */
void print_matrix(float **matrix, size_t size);

int main(int argc, char **argv) {
  if (argc < 2) {
    std::cerr << "[ERR] Missing size." << std::endl;
    std::cerr << "Usage: gemt <n>" << std::endl;
    return -1;
  }

  size_t size = atoi(argv[1]);
  size_t N = pow(2.0, size);

  float **m __attribute__((aligned(64)));

  m = new_matrix(N);

  std::cout << "[INFO] Finished allocating memory." << std::endl;

  fill_matrix(m, N);

  std::cout << "[INFO] Finished populating with values." << std::endl;

#ifdef DEBUG
  std::cout << "[DEBUG] Contents of the matrix: " << std::endl;
  print_matrix(m, N);
#endif
  /* Calculate how many ms it takes to perform the transposition */
  auto t1 = std::chrono::high_resolution_clock::now();

  transpose(m, N);

  auto t2 = std::chrono::high_resolution_clock::now();

  auto ms_int = std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1);
  std::chrono::duration<double, std::milli> ms_double = t2 - t1;

  std::cout << "[INFO] Finished transposing the matrix." << std::endl;

  std::cout << "[INFO] Time: " << ms_double.count() << "ms" << std::endl;

#ifdef DEBUG
  std::cout << "[DEBUG] Contents of the matrix: " << std::endl;
  print_matrix(m, N);
#endif

  return 0;
}

void transpose(float **m, size_t size) {
  for (size_t i = 0; i < size; i++) {
    for (size_t j = i + 1; j < size; j++) {
      float tmp = m[j][i];
      m[j][i] = m[i][j];
      m[i][j] = tmp;
      __builtin_prefetch(&m[i][j + 1]);
    }
  }
}

float **new_matrix(size_t n) {
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
