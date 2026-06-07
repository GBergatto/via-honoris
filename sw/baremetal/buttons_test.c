/*
 * Buttons Test
 * Turn on an LED when the corresponding button is pressed.
 */

#include <stdint.h>

/* Hardware Register Mapping */
#define BUTTONS *((volatile uint32_t *)0x04000000)
#define LEDS    *((volatile uint32_t *)0x01000000)

int main(void) {
   while (1) {
      // Read the 4 button inputs
      uint32_t btn_state = BUTTONS;

      // Output the state to the LEDs
      LEDS = btn_state;
   }
   return 0;
}
