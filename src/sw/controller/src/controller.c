#include <stdio.h>
#include <xiic.h>
#include "xiltimer.h"
#include "platform.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xparameters.h"
#include "lcd.h"

// Commands sent to RTL
#define CMD_GET_FQ_INC      0x10000000
#define CMD_SET_PHASE_INC   0x20000000
#define CMD_NO_COMMAND      0x00000000

#define MAX_FQ          8000000     // 8MHz
#define MAX_PHASE_INC   134217728   // 27 bits
#define SAMPLE_FQ       16000000    // 16 MHz

volatile u32* gpio1_out = (volatile u32*) XPAR_XGPIO_0_BASEADDR; 
volatile u32* gpio2_in = (volatile u32*) (XPAR_XGPIO_0_BASEADDR + 8);


s8 get_fq_increment() {
    *gpio1_out = CMD_GET_FQ_INC;
    usleep(10);
    *gpio1_out = CMD_NO_COMMAND;
    return *gpio2_in;
}

u32 fq_to_phase_inc(u32 fq) {
    u64 t = (u64) fq * MAX_PHASE_INC;
    t /= SAMPLE_FQ;
    return (u32) t;
}

void set_phase_inc(u32 phase_inc) {
    *gpio1_out = CMD_SET_PHASE_INC | (phase_inc & 0x07ffffff);
    usleep(10);
    *gpio1_out = CMD_NO_COMMAND;
    
}

#define ATOI_BUFSIZE 12
char *itoa(int i) {
    static char buffer[ATOI_BUFSIZE];
    if(i == 0) {
        return "0";
    }
    buffer[ATOI_BUFSIZE - 1] = 0;
    int p = ATOI_BUFSIZE - 2;
    for(; i && p >= 0; i /= 10) {
        buffer[p--] = '0' + i % 10;
    }  
    return buffer + p + 1;
}

int main()
{
    init_platform();
    xil_printf("Platform init was successful1\n\r");
    u32 fq = 3000000; // TODO: Probably should store this somewhere non-volatile

    // Let everything start up settle before we kick off the local oscillator
    //usleep(1000);
    xil_printf("%s\n\r", itoa(42));
    set_phase_inc(fq_to_phase_inc(fq));

    LCD lcd;
    lcd_init(&lcd, get_iic(), 0x27, 1);
    lcd_blink_on(&lcd);

    int i = 0;
    for(;;) {
        lcd_home(&lcd);
        lcd_print_string(&lcd, "Hello world! ");
        lcd_print_string(&lcd, itoa(i));
         xil_printf("%s\n\r", itoa(i));
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

        xil_printf("arb lost=%d, txerr:%d, sentbytes: %d, bus busy: %d\n\r", stats.ArbitrationLost, stats.TxErrors, stats.SendBytes, stats.BusBusy);
//        usleep(100000);
 //      	while (XIic_IsIicBusy(lcd.iic)){}
        LCD_send_single(&lcd, 0x55);
        // xil_printf("Character sent\n\r");
  //      usleep(100000);
        // XIic_Reset(lcd.iic);
  //      while (XIic_IsIicBusy(lcd.iic)){}
      }  */
    for(;;) {
        s8 fq_inc = get_fq_increment();
        if(fq > 0 && fq < MAX_FQ) {
            fq += fq_inc * 1000;
        }
        if(fq_inc != 0) {
            u32 phase_inc = fq_to_phase_inc(fq);
            set_phase_inc(phase_inc);
            xil_printf("Fq: %d, pi: %d\n\r", fq, phase_inc);
        }
    } 

  
    cleanup_platform();
    return 0;
}
