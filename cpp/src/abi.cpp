#define ABI_BUILD
#include "abi.h"
#include <string>
#include <cstring>
#include <cstdlib>

extern "C" {

int32_t ABI_CALL abi_add_i32(int32_t a, int32_t b) { return a + b; }

double ABI_CALL abi_dot2f(float a0, float a1, float b0, float b1) {
  return static_cast<double>(a0*b0 + a1*b1);
}

bool ABI_CALL abi_is_positive(double v) { return v > 0.0; }

abi_point_t ABI_CALL abi_make_point(int32_t x, int32_t y) { return abi_point_t{ x, y }; }

int64_t ABI_CALL abi_manhattan(abi_point_t p) {
  auto ax = (p.x < 0) ? -static_cast<int64_t>(p.x) : static_cast<int64_t>(p.x);
  auto ay = (p.y < 0) ? -static_cast<int64_t>(p.y) : static_cast<int64_t>(p.y);
  return ax + ay;
}

const char* ABI_CALL abi_hello(const char* name) {
  std::string s = "Hello, ";
  s += (name ? name : "world");
  s += " from C++!";
  char* out = (char*)std::malloc(s.size() + 1);
  if (!out) return nullptr;
  std::memcpy(out, s.c_str(), s.size() + 1);
  return out;
}

void ABI_CALL abi_free(const void* p) { std::free(const_cast<void*>(p)); }

} // extern "C"

