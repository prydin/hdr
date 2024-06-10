#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
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

int main()
{
    init_platform();
    xil_printf("Platform init was successful\n\r");
    u32 fq = 3000000; // TODO: Probably should store this somewhere non-volatile

    // Let everything start up settle before we kick off the local oscillator
    //usleep(1000);
    set_phase_inc(fq_to_phase_inc(fq));

    LCD lcd;
    LCD_init(&lcd, get_iic(), 0x27);
/*    if(XIic_SelfTest(lcd.iic) != XST_SUCCESS) {
        xil_printf("IIC self test failed\n\r");
        return XST_FAILURE;
    } */

    /*
    for(;;) {
        int status = LCD_send_single(&lcd, 0xff);
        usleep(100000);
       	while (XIic_IsIicBusy(lcd.iic)){}
        LCD_send_single(&lcd, 0x00);
        usleep(100000);
        while (XIic_IsIicBusy(lcd.iic)){}
      } */
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
