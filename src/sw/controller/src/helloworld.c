/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"

#define CMD_GET_FQ_INC 0x00000001;
#define CMD_NO_COMMAND 0x00000001;

volatile u32* gpio1_out = (volatile u32*) XPAR_XGPIO_0_BASEADDR; 
volatile u32* gpio2_in = (volatile u32*) (XPAR_XGPIO_0_BASEADDR + 8);


s8 get_fq_increment() {
    *gpio1_out = CMD_GET_FQ_INC;
    usleep(10);
    return *gpio2_in;
}


int main()
{
    init_platform();

    for(;;) {
        s8 fq_inc = get_fq_increment();
        xil_printf("FQ Inc: %02x\n\r", fq_inc);
    }

  
    cleanup_platform();
    return 0;
}
