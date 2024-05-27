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

// Commands sent to RTL
#define CMD_GET_FQ_INC  0x10000000
#define CMD_NO_COMMAND  0x00000000

#define MAX_FQ          8000000 // 8MHz

volatile u32* gpio1_out = (volatile u32*) XPAR_XGPIO_0_BASEADDR; 
volatile u32* gpio2_in = (volatile u32*) (XPAR_XGPIO_0_BASEADDR + 8);


s8 get_fq_increment() {
    *gpio1_out = CMD_GET_FQ_INC;
    usleep(10);
    *gpio1_out = CMD_NO_COMMAND;
    return *gpio2_in;
}

int main()
{
    init_platform();

    u32 fq = 3000000; // TODO: Probably should store this somewhere non-volatile
    for(;;) {
        s8 fq_inc = get_fq_increment();
        if(fq > 0 && fq < MAX_FQ) {
            fq += fq_inc;
        }
        if(fq_inc != 0) {
            xil_printf("Fq: %d", fq);
        }
    }

  
    cleanup_platform();
    return 0;
}
