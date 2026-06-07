/*
 * ili9341.h
 * Display driver for the ILI9341 SPI TFT LCD (240x320 resolution).
 */
#ifndef ILI9341_H
#define ILI9341_H

#include <stdint.h>

/* Hardware Register Mapping for the SPI Master */
#define SPI_DATA_8  *((volatile uint8_t  *)0x03000000)
#define SPI_DATA_16 *((volatile uint16_t *)0x03000000)
#define SPI_DATA_32 *((volatile uint32_t *)0x03000000)
#define SPI_CTRL    *((volatile uint32_t *)0x03000004)

/* SPI Control Bitmasks */
#define CTRL_DC    0x01
#define CTRL_CS_N  0x02
#define CTRL_RST_N 0x04

/* Standard 16-bit RGB565 Colors */
#define COLOR_BLACK   0x0000
#define COLOR_WHITE   0xFFFF
#define COLOR_RED     0xF800
#define COLOR_GREEN   0x07E0
#define COLOR_BLUE    0x001F
#define COLOR_YELLOW  0xFFE0
#define COLOR_CYAN    0x07FF
#define COLOR_MAGENTA 0xF81F
#define COLOR_ORANGE  0xFC00
#define COLOR_PURPLE  0x8010

/* Initializes the display controller and wakes it from sleep */
void tft_init(void);

/* Fills the entire 240x320 screen with a single 16-bit color */
void tft_fill_screen(uint16_t color);

/* Draws a filled rectangle spanning from (x, y) with dimensions w * h */
void tft_draw_rect(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t color);

/* Draws a single 8x8 ASCII character at the specified coordinates */
void tft_draw_char(uint16_t x, uint16_t y, char c, uint16_t color, uint16_t bg);

/* Draws a null-terminated string of 8x8 ASCII characters */
void tft_draw_string(uint16_t x, uint16_t y, const char *str, uint16_t color, uint16_t bg);

#endif
