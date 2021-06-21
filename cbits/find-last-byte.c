#include <stddef.h>
#include <stdint.h>

#if __ARM_NEON
#include <arm_neon.h>

static uint8_t const lookup_table[128] = {
  1, 2, 3, 4, 5, 6, 7, 8,
  9, 10, 11, 12, 13, 14, 15, 16,
  17, 18, 19, 20, 21, 22, 23, 24,
  25, 26, 27, 28, 29, 30, 31, 32,
  33, 34, 35, 36, 37, 38, 39, 40,
  41, 42, 43, 44, 45, 46, 47, 48,
  49, 50, 51, 52, 53, 54, 55, 56,
  57, 58, 59, 60, 61, 62, 63, 64,
  65, 66, 67, 68, 69, 70, 71, 72,
  73, 74, 75, 76, 77, 78, 79, 80,
  81, 82, 83, 84, 85, 86, 87, 88,
  89, 90, 91, 92, 93, 94, 95, 96,
  97, 98, 99, 100, 101, 102, 103, 104,
  105, 106, 107, 108, 109, 110, 111, 112,
  113, 114, 115, 116, 117, 118, 119, 120,
  121, 122, 123, 124, 125, 126, 127, 128
};

ptrdiff_t find_last_byte (uint8_t const * const src,
                          size_t const off,
                          size_t const len,
                          int const byte) {
  uint8x16_t lookups[8];
  #pragma GCC unroll 8
  for (ptrdiff_t i = 0; i < 8; i++) {
    lookups[i] = vld1q_u8((uint8_t*)(lookup_table + (i * 16)));
  }
  uint8x16_t matches = vdupq_n_u8(byte);
  // Our stride is 8 SIMD registers at a time.
  // That's 16 bytes times 8 = 128.
  size_t big_strides = len / 128;
  size_t small_strides = len % 128;
  uint8_t* ptr = (uint8_t*)&(src[off + len - 1]);
  // Big strides first.
  for (size_t i = 0; i < big_strides; i++) {
    __builtin_prefetch(ptr - 64);
    uint8x16_t results = vdupq_n_u8(0);
    #pragma GCC unroll 8
    for (size_t j = 0; j < 8; j++) {
      // Load and compare. This will zero out anything not found, so we use the
      // lookup table to compute the offset at which we found each thing.
      //
      // We have to use the lookups in reverse, as we're loading backwards.
      results = vmaxq_u8(results, 
                         vandq_u8(lookups[7 - j], vceqq_u8(vld1q_u8(ptr - 15), matches)));
      ptr -= 16;
    }
    // Horizontally max the results, then evacuate.
    #pragma GCC unroll 4
    for (size_t j = 0; j < 4; j++) {
      results = vpmaxq_u8(results, results);
    }
    ptrdiff_t offset = vgetq_lane_u8(results, 0);
    if (offset != 0) {
      return (ptr + offset) - src;
    }
  }
  // If we still haven't found anything, finish the rest the slow way.
  for (size_t i = 0; i < small_strides; i++) {
    if ((*ptr) == byte) {
      return ptr - src;
      break;
    }
    ptr--;
  }
  // We failed to find.
  return -1;
}
#else
static inline uint64_t broadcast (uint8_t byte) {
  return byte * 0x0101010101010101ULL;
}

ptrdiff_t find_last_byte (uint8_t const * const src,
                          size_t const off,
                          size_t const len,
                          int const byte) {
  // We go a 64-bit word at a time.
  size_t big_strides = len / 8;
  size_t small_strides = len % 8;
  // Start at the end
  uint8_t* ptr = (uint8_t*)&(src[off + len - 1]);
  // We use the method described in "Bit Twiddling Hacks".
  // Source: https://graphics.stanford.edu/~seander/bithacks.html#ZeroInWord
  uint64_t matches = broadcast(byte);
  uint64_t mask = broadcast(0x7f);
  for (size_t i = 0; i < big_strides; i++) {
    uint64_t* big_ptr = (uint64_t*)(ptr - 7);
    uint64_t input = (*big_ptr) ^ matches;
    uint64_t tmp = (input & mask) + mask;
    uint64_t result = ~(tmp | input | mask);
    // Any bits set means we've found a match
    if (result != 0) {
      ptrdiff_t offset = __builtin_clzll(result) / 8;
      return (ptr - offset) - src;
    }
    ptr -= 8;
  }
  // If we still haven't found anything, finish the rest the slow way.
  for (size_t i = 0; i < small_strides; i++) {
    if ((*ptr) == byte) {
      return ptr - src;
      break;
    }
    ptr--;
  }
  // We failed to find
  return -1;
}
#endif
