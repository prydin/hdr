#include "lcd.h"
#include "platform.h"
#include "sleep.h"
#include "xil_printf.h"
#include "xiltimer.h"
#include "xparameters.h"
#include <stdio.h>
#include <xiic.h>

// Commands sent to RTL
#define CMD_GET_FQ_INC 0x10000000
#define CMD_SET_PHASE_INC 0x20000000
#define CMD_NO_COMMAND 0x00000000

#define MAX_FQ 8000000          // 8MHz
#define MAX_PHASE_INC 134217728 // 27 bits
#define SAMPLE_FQ 16000000      // 16 MHz

volatile u32 *gpio1_out = (volatile u32 *)XPAR_XGPIO_0_BASEADDR;
volatile u32 *gpio2_in = (volatile u32 *)(XPAR_XGPIO_0_BASEADDR + 8);

s8 get_fq_increment() {
  *gpio1_out = CMD_GET_FQ_INC;
  usleep(10);
  *gpio1_out = CMD_NO_COMMAND;
  return *gpio2_in;
}

u32 fq_to_phase_inc(u32 fq) {
  u64 t = (u64)fq * MAX_PHASE_INC;
  t /= SAMPLE_FQ;
  return (u32)t;
}

void set_phase_inc(u32 phase_inc) {
  *gpio1_out = CMD_SET_PHASE_INC | (phase_inc & 0x07ffffff);
  usleep(10);
  *gpio1_out = CMD_NO_COMMAND;
}

#define ATOI_BUFSIZE 12
char *itoa(int n, int size, u8 zero_fill) {
  static char buffer[ATOI_BUFSIZE];
  buffer[ATOI_BUFSIZE - 1] = 0;
  int start = ATOI_BUFSIZE - 2;
  int p = start;
  int stop = ATOI_BUFSIZE - 2 - size;
  for (; p > stop; n /= 10) {
    int digit = n % 10;
    if (digit == 0 && !zero_fill && p != start) {
      buffer[p--] = ' ';
    } else {
      buffer[p--] = '0' + digit;
    }
  }
  return buffer + p + 1;
}

void print_fq(LCD *lcd, u32 fq) {
    lcd_print_string(lcd, itoa(fq / 1000000, 3, 0));
    lcd_print_char(lcd, '.');
    lcd_print_string(lcd, itoa((fq % 1000000) / 1000, 3, 1));
    lcd_print_char(lcd, ' ');
    lcd_print_string(lcd, itoa(fq % 1000, 3, 1));
    lcd_print_string(lcd, "MHz"); 
}

int main() {
  init_platform();
  xil_printf("Platform init was successful1\n\r");
  u32 fq = 3000000; // TODO: Probably should store this somewhere non-volatile

  // Let everything start up settle before we kick off the local oscillator
  // usleep(1000);
  set_phase_inc(fq_to_phase_inc(fq));

  LCD lcd;
  lcd_init(&lcd, get_iic(), 0x27, 4, 1);
  lcd_blink_on(&lcd);

  int i = 0;
  for (;;) {
    lcd_home(&lcd);
    lcd_print_string(&lcd, "Hello world! ");
    lcd_set_cursor(&lcd, 0, 2);
    print_fq(&lcd, i + 1001000);

    //  xil_printf("%s\n\r", itoa(i, 1));
    usleep(100000);
    ++i;
  }

  /*
  if(XIic_SelfTest(lcd.iic) != XST_SUCCESS) {
      xil_printf("IIC self test failed\n\r");
      return XST_FAILURE;
  } */

  /*


  for(;;) {
      //xil_printf("Sending character\n\r");
      int status = LCD_send_single(&lcd, 0xaa);
      XIicStats stats;
      XIic_GetStats(lcd.iic,  &stats);

      xil_printf("arb lost=%d, txerr:%d, sentbytes: %d, bus busy: %d\n\r",
stats.ArbitrationLost, stats.TxErrors, stats.SendBytes, stats.BusBusy);
//        usleep(100000);
//      	while (XIic_IsIicBusy(lcd.iic)){}
      LCD_send_single(&lcd, 0x55);
      // xil_printf("Character sent\n\r");
//      usleep(100000);
      // XIic_Reset(lcd.iic);
//      while (XIic_IsIicBusy(lcd.iic)){}
    }  */
  for (;;) {
    s8 fq_inc = get_fq_increment();
    if (fq > 0 && fq < MAX_FQ) {
      fq += fq_inc * 1000;
    }
    if (fq_inc != 0) {
      u32 phase_inc = fq_to_phase_inc(fq);
      set_phase_inc(phase_inc);
      xil_printf("Fq: %d, pi: %d\n\r", fq, phase_inc);
    }
  }

  cleanup_platform();
  return 0;
}
