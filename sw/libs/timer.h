/*
 * timer.h
 * Interface for the Core Local Interrupt (CLINT) timer.
 */
#ifndef TIMER_H
#define TIMER_H

#include <stdint.h>

#define MTIME_LOW *((volatile uint32_t *)0x0200BFF8)
#define CLK_FREQ 12000000

/* Returns the current 32-bit hardware cycle count (mtime) */
uint32_t timer_get_ticks(void);

/* Blocks execution for the specified number of milliseconds */
void delay_ms(uint32_t ms);

#endif
