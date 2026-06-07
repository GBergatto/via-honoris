/*
 * buttons.c
 * Implementation of the hardware button abstraction.
 */
#include "buttons.h"

uint32_t btn_read(void) {
   return BUTTONS_REG;
}
