#include <stdio.h>
#include <xparameters.h>
#include <xil_printf.h>
#include <xil_io.h>
#include <xgpio.h>
#include <sleep.h>

#include "platform.h"

#define	XGPIO_AXI_BASEADDRESS	XPAR_XGPIO_0_BASEADDR

/* GPIO Channels */
#define INPUT_CHANNEL 2
#define OUTPUT_CHANNEL 1

/* FPGA commands */
#define GET_FQ_INC 0x10000000
#define NO_COMMAND 0x00000000

#define SETTLE_DELAY 10     /* 10 us */
#define POLL_DELAY 100000   /* 100 ms */

XGpio Gpio;

s8 get_fq_inc() {
    /* Issue GET_FQ_INC command  */
    XGpio_DiscreteWrite(&Gpio, OUTPUT_CHANNEL, GET_FQ_INC);

    /* Read back result */
    usleep(SETTLE_DELAY);
    u32 result = XGpio_DiscreteRead(&Gpio, INPUT_CHANNEL);
    xil_printf("Result: %d\r\n", result);

    /* Prepare command dispatcher for next command */
    XGpio_DiscreteWrite(&Gpio, OUTPUT_CHANNEL, NO_COMMAND);
    return (s8) (result & 0x000000ff);
}


void mainloop() {
    for(;;) {
        usleep(POLL_DELAY);
        s8 fq_inc = get_fq_inc();
        xil_printf("Fq ic: %d\r\n", fq_inc);
    }
}

int main(){
    init_platform();

	/* Initialize the GPIO driver */
    int status;
    status = XGpio_Initialize(&Gpio, XPAR_XGPIO_0_BASEADDR);


//    Xil_Out32(XPAR_XGPIO_0_BASEADDR, 0xeeeeeeee);
    int x = 0;
    for(/* int i = 0; i < 100; ++i */;;) {
        volatile u32 in = Xil_In32(XPAR_XGPIO_0_BASEADDR + 8);
        x += in;
    }
    xil_printf("Input sum: %d\r\n", x);

    return 0; 

    
	if (status != XST_SUCCESS) {
		xil_printf("Gpio Initialization Failed\r\n");
		return XST_FAILURE;
	}

    XGpio_SetDataDirection(&Gpio, INPUT_CHANNEL, 0x0fffffff);
    xil_printf("DD IN: %d\n\r", XGpio_GetDataDirection(&Gpio, INPUT_CHANNEL));
    XGpio_SetDataDirection(&Gpio, OUTPUT_CHANNEL, 0x00000000);
    xil_printf("DD OUT: %d\n\r", XGpio_GetDataDirection(&Gpio, OUTPUT_CHANNEL));    

    print("Successfully initialized application\n\r");

    /* Start main UI loop */
    mainloop();

    cleanup_platform();
    return 0;
}
