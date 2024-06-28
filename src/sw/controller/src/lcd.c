#include "lcd.h"
#include "platform.h"
#include "sleep.h"
#include "xiic.h"
#include "xintc.h"
#include "xparameters.h"
#include <xiic_l.h>
#include <xil_types.h>
#include "xil_printf.h"


#define LCD_SLAVE_ADDR 0x27
#define IIC_INTR_ID 0
#define MAX_WAIT_ITER 500000 

volatile u8 tx_done = 0;

volatile u8 rx_done = 0;

void lcd_begin_tx(LCD *lcd) {
  tx_done = 0;
  rx_done = 0;
  XIic_Start(lcd->iic);
}

void lcd_end_tx(LCD *lcd) { XIic_Stop(lcd->iic); }

void lcd_write_byte(LCD *lcd, u8 data) {
  lcd_begin_tx(lcd);
  u8 value = data | lcd->backlight;
  XIic_WaitBusFree(lcd->iic->BaseAddress);
  XIic_MasterSend(lcd->iic, &value, 1);

  // Wait for interrupt telling us transmission is done
  for (int i = 0; (!tx_done || XIic_IsIicBusy(lcd->iic)) && i < MAX_WAIT_ITER; i++) {
  }
  lcd_end_tx(lcd);
}

void lcd_toggle_enable(LCD *lcd, u8 data) {
  lcd_write_byte(lcd, data | En); // En high
  usleep(1);                  // enable pulse must be >450ns

  lcd_write_byte(lcd, data & ~En); // En low
  usleep(50);                  // commands need > 37us to settle
}

void lcd_write4bits(LCD *lcd, u8 value) {
  lcd_write_byte(lcd, value);
  lcd_toggle_enable(lcd, value);
}

void lcd_send(LCD *lcd, u8 value, u8 mode) {
  uint8_t highnib = value & 0xf0;
  uint8_t lownib = (value << 4) & 0xf0;
  lcd_write4bits(lcd, (highnib) | mode);
  lcd_write4bits(lcd, (lownib) | mode);
}

void lcd_command(LCD *lcd, u8 value) { lcd_send(lcd, value, 0); }

// Exposed commands
void lcd_set_backlight(LCD *lcd, u8 backlight) {
  lcd->backlight = backlight ? LCD_BACKLIGHT : LCD_NOBACKLIGHT;
}

void lcd_display_off(LCD *lcd) {
  lcd->display_control &= ~LCD_DISPLAYON;
  lcd_command(lcd, LCD_DISPLAYCONTROL | lcd->display_control);
}

void lcd_display_on(LCD *lcd) {
  lcd->display_control |= LCD_DISPLAYON;
  lcd_command(lcd, LCD_DISPLAYCONTROL | lcd->display_control);
}

void lcd_clear(LCD *lcd) {
  lcd_command(lcd, LCD_CLEARDISPLAY); // clear display, set cursor position to zero
  usleep(2000);                   // this command takes a long time!
}

void lcd_home(LCD *lcd) {
  lcd_command(lcd, LCD_RETURNHOME); // set cursor position to zero
  usleep(2000);                 // this command takes a long time!
}

void lcd_print_char(LCD *lcd, char ch) { lcd_send(lcd, ch, Rs); }

void lcd_print_string(LCD *lcd, char *s) {
  while (*s) {
    lcd_print_char(lcd, *s);
    ++s;
  }
}

void lcd_cursor_off(LCD *lcd) {
	lcd->display_control &= ~LCD_CURSORON;
	lcd_command(lcd, LCD_DISPLAYCONTROL | lcd->display_control);
}

void lcd_cursor_on(LCD* lcd) {
	lcd->display_control |= LCD_CURSORON;
	lcd_command(lcd, LCD_DISPLAYCONTROL | lcd->display_control);
}

// Turn on and off the blinking cursor
void lcd_blink_off(LCD *lcd) {
	lcd->display_control &= ~LCD_BLINKON;
	lcd_command(lcd, LCD_DISPLAYCONTROL | lcd->display_control);
}
void blink_on(LCD *lcd) {
	lcd->display_control |= LCD_BLINKON;
	lcd_command(lcd, LCD_DISPLAYCONTROL | lcd->display_control);
}

void lcd_set_cursor(LCD *lcd, u8 col, u8 row){
	int row_offsets[] = { 0x00, 0x40, 0x14, 0x54 };
	if ( row > _numlines ) {
		row = _numlines-1;    // we count rows starting w/0
	}
	lcd_command(lcd, LCD_SETDDRAMADDR | (col + row_offsets[row]));
}



XIntc intc;

static void tx_handler(XIic *iic, int i) { tx_done = 1; }

static void rx_handler(XIic *iic, int i) { rx_done = 1; }

static void status_handler(XIic *iic, int i  ) { }

static int init_interrupts(XIic *iic)
{
	int Status;

	Status = XIntc_Initialize(&intc, XPAR_AXI_INTC_0_BASEADDR);

	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	Status = XIntc_Connect(&intc, IIC_INTR_ID,
			       (XInterruptHandler) XIic_InterruptHandler,
			       iic);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	Status = XIntc_Start(&intc, XIN_REAL_MODE);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	XIntc_Enable(&intc, IIC_INTR_ID);
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
				     (Xil_ExceptionHandler)XIntc_InterruptHandler, &intc);
	Xil_ExceptionEnable();

    // Hook up IIC interrupt handlers 
    XIic_SetSendHandler(iic, iic,
			    (XIic_Handler) tx_handler);
	XIic_SetRecvHandler(iic, iic,
			    (XIic_Handler) rx_handler);
	XIic_SetStatusHandler(iic, iic,
			      (XIic_StatusHandler) status_handler);


	return XST_SUCCESS;
}


void lcd_init(LCD *lcd, XIic *iic, u8 address, u8 backlight) {
  lcd->address = address;
  lcd->iic = iic;
  init_interrupts(iic);
  lcd->display_function = LCD_4BITMODE | LCD_2LINE | LCD_5x8DOTS;
  lcd_set_backlight(lcd, backlight);
  XIic_SetAddress(lcd->iic, XII_ADDR_TO_SEND_TYPE, address);

  // SEE PAGE 45/46 FOR INITIALIZATION SPECIFICATION!
  // according to datasheet, we need at least 40ms after power rises above 2.7V
  // before sending commands.
  usleep(50000);

  // Now we pull both RS and R/W low to begin commands
  lcd_write_byte(lcd,
             lcd->backlight); // reset expanderand turn backlight off (Bit 8 =1)
  usleep(1000000);

  // we start in 8bit mode, try to set 4 bit mode
  lcd_write4bits(lcd, 0x03 << 4);
  usleep(4500); // wait min 4.1ms

  // second try
  lcd_write4bits(lcd, 0x03 << 4);
  usleep(4500); // wait min 4.1ms

  // third go!
  lcd_write4bits(lcd, 0x03 << 4);
  usleep(150);

  // finally, set to 4-bit interface
  lcd_write4bits(lcd, 0x02 << 4);

  // set # lines, font size, etc.
  lcd_command(lcd, LCD_FUNCTIONSET | lcd->display_function);

  // turn the display on with no cursor or blinking default
  lcd->display_control = LCD_DISPLAYON | LCD_CURSOROFF | LCD_BLINKOFF;
  lcd_display_on(lcd);

  // Clear display
  lcd_clear(lcd);

  // Initialize to default text direction (for roman languages)
  lcd->display_mode = LCD_ENTRYLEFT | LCD_ENTRYSHIFTDECREMENT;

  // set the entry mode
  lcd_command(lcd, LCD_ENTRYMODESET | lcd->display_mode);

  lcd_home(lcd);
}


