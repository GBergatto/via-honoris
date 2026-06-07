#include <stdint.h>
#include <stdbool.h>
#include "ili9341.h"
#include "buttons.h"
#include "timer.h"

// Tetris config
#define FIELD_W 10
#define FIELD_H 20
#define CELL_SIZE 16
#define OFFSET_X 0 // (240 - 160)
#define OFFSET_Y 0

// Tetromino definitions
// 0=I, 1=J, 2=L, 3=O, 4=S, 5=T, 6=Z
const char* tetromino[7] = {
   "..X...X...X...X.", // I
   "..X..XX...X.....", // Z
   ".....XX..XX.....", // O
   "..X..XX..X......", // T
   ".X...XX...X.....", // S
   ".X...X...XX.....", // L
   "..X...X..XX....."  // J
};

// Colors for each piece
uint16_t t_colors[8] = {
   COLOR_BLACK,   // 0 = empty
   COLOR_CYAN,    // 1 = I
   COLOR_MAGENTA, // 2 = T
   COLOR_YELLOW,  // 3 = O
   COLOR_RED,     // 4 = Z
   COLOR_GREEN,   // 5 = S
   COLOR_ORANGE,  // 6 = L
   COLOR_BLUE     // 7 = J
};

const int init_rot[7] = {3, 1, 0, 1, 1, 3, 1};

uint8_t field[FIELD_W * FIELD_H];
uint8_t display_cache[FIELD_W * FIELD_H];

/* Pseudo-random number generator using XOR and bit shifts. */
uint32_t xorshift32(uint32_t state) {
   uint32_t x = state;
   x ^= x << 13;
   x ^= x >> 17;
   x ^= x << 5;
   return x;
}

uint32_t rng_state = 1;

uint8_t bag[7];
uint8_t bag_idx = 7;

/* Implements the Fisher-Yates shuffle to randomize the bag array. */
void shuffle_bag() {
   for (int i = 0; i < 7; i++) bag[i] = i;
   for (int i = 6; i > 0; i--) {
      int j = xorshift32(rng_state) % (i + 1);
      rng_state = xorshift32(rng_state);
      uint8_t temp = bag[i];
      bag[i] = bag[j];
      bag[j] = temp;
   }
}

int get_next_piece() {
   if (bag_idx >= 7) {
      shuffle_bag();
      bag_idx = 0;
   }
   return bag[bag_idx++];
}

/*
 * Maps a logical 2D coordinate (px, py) to its rotated 1D index
 * based on Javidx9's mathematical rotation algorithm.
 * r: 0=0deg, 1=90deg, 2=180deg, 3=270deg.
 */
int rotate(int px, int py, int r) {
   int pi = 0;
   switch (r % 4) {
      case 0: pi = py * 4 + px; break;
      case 1: pi = 12 + py - (px * 4); break;
      case 2: pi = 15 - (py * 4) - px; break;
      case 3: pi = 3 - py + (px * 4); break;
   }
   return pi;
}

/*
 * Collision detection logic. Checks if the requested piece at rotation
 * can safely exist at the grid coordinate (pos_x, pos_y).
 * Returns false if it hits the floor, walls, or an existing locked piece.
 */
bool does_piece_fit(int piece, int rotation, int pos_x, int pos_y) {
   for (int px = 0; px < 4; px++) {
      for (int py = 0; py < 4; py++) {
         int pi = rotate(px, py, rotation);
         int fi = (pos_y + py) * FIELD_W + (pos_x + px);

         if (tetromino[piece][pi] != '.') {
            if (pos_x + px >= 0 && pos_x + px < FIELD_W && pos_y + py >= 0 && pos_y + py < FIELD_H) {
               if (field[fi] != 0)
                  return false;
            } else {
               return false;
            }
         }
      }
   }
   return true;
}

void draw_cell(int x, int y, uint8_t val) {
   tft_draw_rect(OFFSET_X + x * CELL_SIZE, OFFSET_Y + y * CELL_SIZE, CELL_SIZE, CELL_SIZE, t_colors[val]);
}

/* Bare-metal integer-to-ASCII string converter. */
void itoa_simple(int num, char* str) {
   int i = 0;
   int isNegative = 0;

   if (num == 0) {
      str[i++] = '0';
      str[i] = '\0';
      return;
   }

   if (num < 0) {
      isNegative = 1;
      num = -num;
   }

   while (num != 0) {
      int rem = num % 10;
      str[i++] = (rem > 9) ? (rem - 10) + 'a' : rem + '0';
      num = num / 10;
   }

   if (isNegative)
      str[i++] = '-';

   str[i] = '\0';

   int start = 0;
   int end = i - 1;
   while (start < end) {
      char temp = str[start];
      str[start] = str[end];
      str[end] = temp;
      start++;
      end--;
   }
}

int main(void) {
   tft_init();
   tft_fill_screen(COLOR_BLACK);

   // Draw boundary line
   tft_draw_rect(160, 0, 2, 320, COLOR_WHITE);

   // Init field
   for (int i = 0; i < FIELD_W * FIELD_H; i++) {
      field[i] = 0;
      display_cache[i] = 255; // force redraw initially
   }

   bool bKey[4];
   bool bKeyOld[4] = {false};

   int cur_piece = 0;
   int cur_rot = 0;
   int cur_x = FIELD_W / 2 - 2;
   int cur_y = 0;

   int speed_delay = 500; // ms
   uint32_t last_drop_time = timer_get_ticks();

   int score = 0;
   int old_score = -1;
   int piece_count = 0;

   char score_str[16];

   tft_draw_string(168, 10, "TETRIS", COLOR_GREEN, COLOR_BLACK);
   tft_draw_string(168, 30, "SCORE:", COLOR_WHITE, COLOR_BLACK);

   rng_state = timer_get_ticks();
   if(rng_state == 0) rng_state = 1;

   cur_piece = get_next_piece();
   cur_rot = init_rot[cur_piece];

   while (1) {
      uint32_t now = timer_get_ticks();

      // Input
      uint32_t btns = btn_read();
      bKey[0] = (btns & 1) != 0; // Left
      bKey[1] = (btns & 2) != 0; // Right
      bKey[2] = (btns & 4) != 0; // Rotate
      bKey[3] = (btns & 8) != 0; // Soft Drop

      // Logic
      if (bKey[0] && !bKeyOld[0]) {
         if (does_piece_fit(cur_piece, cur_rot, cur_x - 1, cur_y)) cur_x--;
      }
      if (bKey[1] && !bKeyOld[1]) {
         if (does_piece_fit(cur_piece, cur_rot, cur_x + 1, cur_y)) cur_x++;
      }
      if (bKey[2] && !bKeyOld[2]) {
         if (does_piece_fit(cur_piece, cur_rot + 1, cur_x, cur_y)) cur_rot++;
      }
      if (bKey[3]) {
         if (does_piece_fit(cur_piece, cur_rot, cur_x, cur_y + 1)) cur_y++;
      }

      for(int i=0; i<4; i++) bKeyOld[i] = bKey[i];

      // Convert ms to ticks for current speed
      uint32_t ticks_delay = speed_delay * (CLK_FREQ / 1000);

      if ((now - last_drop_time) > ticks_delay) {
         last_drop_time = now;

         if (does_piece_fit(cur_piece, cur_rot, cur_x, cur_y + 1)) {
            cur_y++;
         } else {
            // Lock piece
            for (int px = 0; px < 4; px++) {
               for (int py = 0; py < 4; py++) {
                  if (tetromino[cur_piece][rotate(px, py, cur_rot)] != '.') {
                     field[(cur_y + py) * FIELD_W + (cur_x + px)] = cur_piece + 1;
                  }
               }
            }

            score += 25;
            piece_count++;
            if (piece_count % 10 == 0 && speed_delay > 100) {
               speed_delay -= 50;
            }

            // Check lines
            int lines_cleared = 0;
            bool lines_to_clear[FIELD_H] = {false};

            for (int y = 0; y < FIELD_H; y++) {
               bool line = true;
               for (int x = 0; x < FIELD_W; x++) {
                  if (field[y * FIELD_W + x] == 0) line = false;
               }
               if (line) {
                  lines_cleared++;
                  lines_to_clear[y] = true;
               }
            }

            if (lines_cleared > 0) {
               // Animation: Flash the cleared lines white
               for (int y = 0; y < FIELD_H; y++) {
                  if (lines_to_clear[y]) {
                     for (int x = 0; x < FIELD_W; x++) {
                        // Draw a white cell directly
                        tft_draw_rect(OFFSET_X + x * CELL_SIZE, OFFSET_Y + y * CELL_SIZE, CELL_SIZE, CELL_SIZE, COLOR_WHITE);
                     }
                  }
               }

               // Pause to let the player see the flash
               delay_ms(150);

               // Shift lines down
               for (int y = 0; y < FIELD_H; y++) {
                  if (lines_to_clear[y]) {
                     for (int py = y; py > 0; py--) {
                        for (int px = 0; px < FIELD_W; px++) {
                           field[py * FIELD_W + px] = field[(py - 1) * FIELD_W + px];
                        }
                     }
                     for (int px = 0; px < FIELD_W; px++) {
                        field[px] = 0;
                     }
                  }
               }

               // force total redraw
               for(int i=0; i<FIELD_W*FIELD_H; i++) display_cache[i] = 255;
               score += (1 << lines_cleared) * 100;
            }

            // New piece
            cur_x = FIELD_W / 2 - 2;
            cur_y = 0;
            cur_piece = get_next_piece();
            cur_rot = init_rot[cur_piece];

            // Game Over
            if (!does_piece_fit(cur_piece, cur_rot, cur_x, cur_y)) {
               // reset
               for (int i = 0; i < FIELD_W * FIELD_H; i++) field[i] = 0;
               for(int i=0; i<FIELD_W*FIELD_H; i++) display_cache[i] = 255;
               score = 0;
               speed_delay = 500;
            }
         }
      }

      // Render step
      // Create an overlay combining field and current piece
      uint8_t overlay[FIELD_W * FIELD_H];
      for (int i = 0; i < FIELD_W * FIELD_H; i++) {
         overlay[i] = field[i];
      }

      for (int px = 0; px < 4; px++) {
         for (int py = 0; py < 4; py++) {
            if (tetromino[cur_piece][rotate(px, py, cur_rot)] != '.') {
               if (cur_x + px >= 0 && cur_x + px < FIELD_W && cur_y + py >= 0 && cur_y + py < FIELD_H) {
                  int idx = (cur_y + py) * FIELD_W + (cur_x + px);
                  overlay[idx] = cur_piece + 1;
               }
            }
         }
      }

      // Delta drawing
      for (int y = 0; y < FIELD_H; y++) {
         for (int x = 0; x < FIELD_W; x++) {
            int idx = y * FIELD_W + x;
            if (overlay[idx] != display_cache[idx]) {
               draw_cell(x, y, overlay[idx]);
               display_cache[idx] = overlay[idx];
            }
         }
      }

      if (score != old_score) {
         itoa_simple(score, score_str);
         tft_draw_string(168, 40, "        ", COLOR_BLACK, COLOR_BLACK); // clear old
         tft_draw_string(168, 40, score_str, COLOR_YELLOW, COLOR_BLACK);
         old_score = score;
      }
   }

   return 0;
}
