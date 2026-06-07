/*
 * util.c
 *
 * Software implementations of standard C library functions (memset)
 * and GCC built-ins (__mulsi3, __divsi3, etc.) necessary for bare-metal
 * compilation on RV32I targets lacking the M extension.
 */
#include <stdint.h>

void *memset(void *s, int c, uint32_t n) {
   uint8_t *p = (uint8_t *)s;
   while (n--) {
      *p++ = (uint8_t)c;
   }
   return s;
}

uint32_t __mulsi3(uint32_t a, uint32_t b) {
   uint32_t res = 0;
   while (a) {
      if (a & 1) res += b;
      a >>= 1;
      b <<= 1;
   }
   return res;
}

uint32_t __udivsi3(uint32_t n, uint32_t d) {
   if (d == 0) return 0;
   uint32_t q = 0;
   uint32_t r = 0;
   for (int i = 31; i >= 0; i--) {
      r = (r << 1) | ((n >> i) & 1);
      if (r >= d) {
         r -= d;
         q |= (1U << i);
      }
   }
   return q;
}

uint32_t __umodsi3(uint32_t n, uint32_t d) {
   if (d == 0) return 0;
   uint32_t r = 0;
   for (int i = 31; i >= 0; i--) {
      r = (r << 1) | ((n >> i) & 1);
      if (r >= d) {
         r -= d;
      }
   }
   return r;
}

int32_t __divsi3(int32_t n, int32_t d) {
   int sign = 1;
   if (n < 0) { n = -n; sign = -sign; }
   if (d < 0) { d = -d; sign = -sign; }
   uint32_t q = __udivsi3((uint32_t)n, (uint32_t)d);
   return sign > 0 ? (int32_t)q : -(int32_t)q;
}

int32_t __modsi3(int32_t n, int32_t d) {
   int sign = 1;
   if (n < 0) { n = -n; sign = -1; }
   if (d < 0) { d = -d; }
   uint32_t r = __umodsi3((uint32_t)n, (uint32_t)d);
   return sign > 0 ? (int32_t)r : -(int32_t)r;
}
