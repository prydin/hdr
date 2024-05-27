`timescale 1ns / 1ps

module monostable_ff
    #(CYCLES = 1        // Number of cycles to keep output high after positive flank on d
    ) (
    input wire aclk,    // System clock
    input wire reset,   // Master reset
    input wire d,       // Data in
    output reg q);      // Data out
    
    reg [$clog2(CYCLES + 1) - 1: 0] counter = CYCLES;
    reg prev = 0;
    
    always @(posedge aclk) 
    begin
        if(reset)
        begin
            counter <= CYCLES;
            prev <= d;
            q <= 0;
        end else begin
            // Positive flank?
            if(prev == 0 && d == 1)
            begin
                // Set output high and start counting down time to reset
                q <= 1;
                counter <= CYCLES;
            end else begin
                if(q == 1) 
                begin
                    counter <= counter - 1;
                    if(counter == 0) 
                    begin
                        // Reset time reached
                        q <= 0;
                    end
                end
            end
            prev <= d;
        end
    end
endmodule

module controller #(parameter PHASE_INC_WIDTH = 27) (
        input wire aclk,
        input wire clk_locked,
        input wire reset,
        input wire signed [7:0] fq_change,
        output wire fq_change_valid,
        output wire [PHASE_INC_WIDTH - 1:0] phase_inc,
        output wire phase_inc_valid,
        input wire uart_rx,
        output wire uart_tx
    );
    
    // MCU message types 
    localparam FQ_CHANGE = 3'h0;    // Update frequency
   
    wire [3:0] irqs;                 // NSC interrupt pins
   
    // Generate interrupt pulse from fq_change_valid input
    monostable_ff fq_irq_ff (
        .aclk(aclk),
        .reset(reset),
        .d(fq_change_valid),
        .q(irqs[0]));
        
    // Handle phase increment output
    wire [31:0] phase_inc_comp;
    assign phase_inc = phase_inc_comp[PHASE_INC_WIDTH - 1:1];
    assign phase_inc_valid = phase_inc_comp[0];
    monostable_ff phase_inc_ff (
        .aclk(aclk),
        .reset(reset),
        .d(phase_inc_comp[0]),
        .q(phase_inc_valid));
    /*
    microblaze_mcs_0 cpu (
      .Clk(aclk),                               // input wire Clk
      .Reset(reset),                            // input wire Reset
      .INTC_IRQ(),                              // output wire INTC_IRQ
      .INTC_Interrupt(irqs),                    // input wire [3 : 0] INTC_Interrupt
      .UART_rxd(uart_rx),                       // input wire UART_rxd
      .UART_txd(uart_tx),                       // output wire UART_txd
      .GPIO1_tri_i({{24{1'b0}}, fq_change}),    // Frequency change
      .GPIO1_tri_o(phase_inc_comp),             // DDS phase increment output, including strobe bit
      .GPIO2_tri_i(0),                          // input wire [31 : 0] GPIO2_tri_i
      .GPIO2_tri_o(),                           // output wire [31 : 0] GPIO2_tri_o
      .GPIO3_tri_i(0),                          // input wire [31 : 0] GPIO3_tri_i
      .GPIO3_tri_o(),                           // output wire [31 : 0] GPIO3_tri_o
      .GPIO4_tri_i(0),                          // input wire [31 : 0] GPIO4_tri_i
      .GPIO4_tri_o()                            // output wire [31 : 0] GPIO4_tri_o
        ); */
       
   // Commands from MCU to FPGA
   localparam GET_FQ_INC = 4'h1;                // Get latest frequency increment
   localparam NO_COMMAND = 4'h0;                // No command -> Get ready for next
   
    reg [31:0] to_mcu = 32'h42424242; // TODO: Change to 0
    wire [31:0] from_mcu;
    wire [3:0] command_from_mcu = from_mcu[31:28];
    wire [27:0] data_from_mcu = from_mcu[27:0];
    reg ready = 1; 
        
    //`default_nettype wire
    mcu mcu (
        .aclk(aclk),
        .to_mcu_tri_i(to_mcu),
        .from_mcu_tri_o(from_mcu),
        .locked(clk_locked),
        .usb_uart_rxd(uart_rx),
        .usb_uart_txd(uart_tx));
    //`default_nettype none
        
    // Command dispatcher
    always @(posedge aclk or posedge reset)
    begin
        if(reset) 
        begin
            ready <= 1;
            to_mcu <= 0;
        end else begin 
            to_mcu <= to_mcu + 1;
            case(command_from_mcu)
            GET_FQ_INC:
                if(ready)
                begin
                    // TODO: Do stuff
                    to_mcu <= to_mcu + 1;
                    ready <= 0;
                end
            NO_COMMAND:
                begin
                    ready <= 1;
                end
            endcase
        end   
    end
endmodule
