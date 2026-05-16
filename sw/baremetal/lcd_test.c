#include <stdint.h>

/* Hardware Register Mapping */
#define SPI_DATA *((volatile uint32_t *)0x03000000)
#define SPI_CTRL *((volatile uint32_t *)0x03000004)
#define MTIME_LOW *((volatile uint32_t *)0x0200BFF8)

/* SPI Control Bits */
#define CTRL_DC    0x01  // Bit 0: Data/Command (0=Cmd, 1=Data)
#define CTRL_CS_N  0x02  // Bit 1: Chip Select (Active Low)
#define CTRL_RST_N 0x04  // Bit 2: Reset (Active Low)

/* RGB565 Colors */
#define COLOR_RED   0xF800
#define COLOR_GREEN 0x07E0
#define COLOR_BLUE  0x001F

/* Hardware Timer Delay (Assumes 12 MHz clock) */
void delay_ms(uint32_t ms) {
    uint32_t start = MTIME_LOW;
    uint32_t ticks = ms * (12000000 / 1000);
    while ((MTIME_LOW - start) < ticks);
}

/* SPI Primitives */
void spi_cmd(uint8_t cmd) {
    // DC=0, CS=0, RST=1
    SPI_CTRL = CTRL_RST_N; 
    SPI_DATA = cmd;
}

void spi_data8(uint8_t data) {
    // DC=1, CS=0, RST=1
    SPI_CTRL = CTRL_RST_N | CTRL_DC; 
    SPI_DATA = data;
}

void spi_data16(uint16_t data) {
    // DC=1, CS=0, RST=1
    SPI_CTRL = CTRL_RST_N | CTRL_DC; 
    SPI_DATA = data;
}

/* ILI9341 Initialization Sequence */
void tft_init() {
    // 1. Hardware Reset Pulse
    SPI_CTRL = CTRL_DC | CTRL_CS_N; // RST_N = 0
    delay_ms(50);
    SPI_CTRL = CTRL_RST_N | CTRL_DC | CTRL_CS_N; // RST_N = 1
    delay_ms(150);

    // 2. Wake Up
    spi_cmd(0x01); // Software Reset
    delay_ms(150);
    spi_cmd(0x11); // Sleep Out
    delay_ms(500);

    // 3. Configure Pixel Format (16-bit RGB565)
    spi_cmd(0x3A); 
    spi_data8(0x55); 

    // 4. Configure Memory Access Control (Orientation/Colors)
    // Note: 0x48 sets standard orientation and BGR color order. 
    // If your colors are swapped (red looks blue), change this to 0x08 (RGB).
    spi_cmd(0x36); 
    spi_data8(0x48); 

    // 5. Turn Display On
    spi_cmd(0x29); 
    delay_ms(150);
}

/* Fill the entire 240x320 screen with a single color */
void tft_fill(uint16_t color) {
    // Define the drawing window (Column Address Set)
    spi_cmd(0x2A); 
    spi_data16(0x0000); // Start Column: 0
    spi_data16(0x00EF); // End Column: 239

    // Define the drawing window (Page Address Set)
    spi_cmd(0x2B); 
    spi_data16(0x0000); // Start Page: 0
    spi_data16(0x013F); // End Page: 319

    // Instruct the display to receive pixel data
    spi_cmd(0x2C); 

    // Blast the 16-bit color to the screen.
    // The hardware optimization allows us to send 16 bits in one bus write.
    for (uint32_t i = 0; i < (240 * 320); i++) {
        spi_data16(color);
    }
}

int main(void) {
    // Initialize the display
    tft_init();

    // Loop forever: Red -> Green -> Blue
    while (1) {
        tft_fill(COLOR_RED);
        delay_ms(1000);
        
        tft_fill(COLOR_GREEN);
        delay_ms(1000);
        
        tft_fill(COLOR_BLUE);
        delay_ms(1000);
    }

    return 0;
}
