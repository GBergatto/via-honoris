/*
 * LCD Screen Test
 * Turn the screen red, green, and blue in a loop.
 */
#include <stdint.h>
#include "ili9341.h"
#include "timer.h"

int main(void) {
   // Initialize the display
   tft_init();

   // Loop forever: Red -> Green -> Blue
   while (1) {
      tft_fill_screen(COLOR_RED);
      delay_ms(1000);

      tft_fill_screen(COLOR_GREEN);
      delay_ms(1000);

      tft_fill_screen(COLOR_BLUE);
      delay_ms(1000);
   }

   return 0;
}
