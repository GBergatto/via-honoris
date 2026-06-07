/*
 * timer.c
 * Implementation of the CLINT hardware timer interface and delays.
 */
#include "timer.h"

uint32_t timer_get_ticks(void) {
   return MTIME_LOW;
}

void delay_ms(uint32_t ms) {
   uint32_t start = MTIME_LOW;
   uint32_t ticks = ms * (CLK_FREQ / 1000);
   while ((MTIME_LOW - start) < ticks);
}
