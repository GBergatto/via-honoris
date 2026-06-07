/*
 * buttons.h
 * Hardware abstraction for the memory-mapped pushbuttons on the SoC.
 */
#ifndef BUTTONS_H
#define BUTTONS_H

#include <stdint.h>

#define BUTTONS_REG *((volatile uint32_t *)0x04000000)

/*
 * Reads the current state of the 4 hardware pushbuttons.
 * Returns a 4-bit bitmask where '1' indicates the button is pressed
 * and '0' indicates it is released.
 */
uint32_t btn_read(void);

#endif
