#include "xiic.h"
// commands
#define LCD_CLEARDISPLAY 0x01
#define LCD_RETURNHOME 0x02
#define LCD_ENTRYMODESET 0x04
#define LCD_DISPLAYCONTROL 0x08
#define LCD_CURSORSHIFT 0x10
#define LCD_FUNCTIONSET 0x20
#define LCD_SETCGRAMADDR 0x40
#define LCD_SETDDRAMADDR 0x80

// flags for display entry mode
#define LCD_ENTRYRIGHT 0x00
#define LCD_ENTRYLEFT 0x02
#define LCD_ENTRYSHIFTINCREMENT 0x01
#define LCD_ENTRYSHIFTDECREMENT 0x00

// flags for display on/off control
#define LCD_DISPLAYON 0x04
#define LCD_DISPLAYOFF 0x00
#define LCD_CURSORON 0x02
#define LCD_CURSOROFF 0x00
#define LCD_BLINKON 0x01
#define LCD_BLINKOFF 0x00

// flags for display/cursor shift
#define LCD_DISPLAYMOVE 0x08
#define LCD_CURSORMOVE 0x00
#define LCD_MOVERIGHT 0x04
#define LCD_MOVELEFT 0x00

// flags for function set
#define LCD_8BITMODE 0x10
#define LCD_4BITMODE 0x00
#define LCD_2LINE 0x08
#define LCD_1LINE 0x00
#define LCD_5x10DOTS 0x04
#define LCD_5x8DOTS 0x00

// flags for backlight control
#define LCD_BACKLIGHT 0x08
#define LCD_NOBACKLIGHT 0x00

#define En 0b00000100  // Enable bit
#define Rw 0b00000010  // Read/Write bit
#define Rs 0b00000001  // Register select bit

typedef struct LCD_s {
    XIic* iic;
    u8 address;
    u8 display_mode;
    u8 display_control;
    u8 display_function;
    u8 backlight;    
    u8 num_lines;
} LCD;

void lcd_init(LCD *lcd, XIic *iic, u8 address, u8 num_lines, u8 backlight);

void LDC_shutdown(LCD* lcd);

int LCD_send_single(LCD* lcd, u8 value);

void lcd_set_backlight(LCD* lcd, u8 backlight);

int LCD_send_single(LCD* lcd, u8 value);

void lcd_display_off(LCD* lcd);

void lcd_display_on(LCD* lcd);

void lcd_print_char(LCD *lcd, char ch);

void lcd_print_string(LCD *lcd, char *s);

void lcd_clear(LCD *lcd);

void lcd_home(LCD *lcd);

void lcd_cursor_off(LCD *lcd);

void lcd_cursor_on(LCD* lcd);

void lcd_blink_off(LCD *lcd);

void lcd_blink_on(LCD* lcd);

void lcd_set_cursor(LCD *lcd, u8 col, u8 row);