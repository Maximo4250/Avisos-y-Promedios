#include <snappy.h>
#include <cstdio>
#include <string>
int main() {
  for (size_t n : {size_t(0), size_t(1), size_t(61), size_t(255), size_t(65536), size_t(180000)}) {
    std::string original(n, 'a');
    for (size_t i = 0; i < n; ++i) original[i] = static_cast<char>((i * 37 + i / 100) % 256);
    std::string compressed, recovered;
    snappy::Compress(original.data(), original.size(), &compressed);
    if (!snappy::Uncompress(compressed.data(), compressed.size(), &recovered) || recovered != original) return 1;
  }
  std::puts("Snappy: compresion y descompresion compatibles, sin BMI2.");
  return 0;
}
