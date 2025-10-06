#pragma once
#include <stdint.h>
#include <stdbool.h>

#ifdef _WIN32
  #ifdef ABI_BUILD
    #define ABI_API __declspec(dllexport)
  #else
    #define ABI_API __declspec(dllimport)
  #endif
  #define ABI_CALL __cdecl
#else
  #define ABI_API
  #define ABI_CALL
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  int32_t x;
  int32_t y;
} abi_point_t;

ABI_API int32_t     ABI_CALL abi_add_i32(int32_t a, int32_t b);
ABI_API double      ABI_CALL abi_dot2f(float a0, float a1, float b0, float b1);
ABI_API bool        ABI_CALL abi_is_positive(double v);
ABI_API abi_point_t ABI_CALL abi_make_point(int32_t x, int32_t y);
ABI_API int64_t     ABI_CALL abi_manhattan(abi_point_t p);

ABI_API const char* ABI_CALL abi_hello(const char* name);
ABI_API void        ABI_CALL abi_free(const void* p);

#ifdef __cplusplus
}
#endif
