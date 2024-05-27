//`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/09/2024 01:53:15 PM
// Design Name: 
// Module Name: root
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module root(
    input wire clk,
    input wire pio20,           // ADC Bit 13 
    input wire pio19,           // ADC Bit 12
    input wire pio18,           // ADC Bit 11
    input wire pio17,           // ADC Bit 10
    input wire pio16,           // ADC Bit 9
    input wire pio9,            // ADC Bit 8
    input wire pio8,            // ADC Bit 7
    input wire pio7,            // ADC Bit 6
    input wire pio6,            // ADC Bit 5
    input wire pio5,            // ADC Bit 4
    input wire pio4,            // ADC Bit 3
    input wire pio3,            // ADC Bit 2
    input wire pio2,            // ADC Bit 1
    input wire pio1,            // ADC Bit 0
    output wire pio26,          // 3.3V for fq dial
    input wire pio27,           // Fq dial ck
    input wire pio28,           // Fq dial dt 
    input wire [1:0] btn,       // Button for test
    output wire [0:3] led,      // LEDs for test 
    output wire pio21,          // ADC clock 
    output wire pio48,          // DAC delta/sigma out
    input wire usb_uart_rxd,    // UART in
    output wire usb_uart_txd    // UART out
    );
    
    // Clock speeds
    localparam SAMPLE_CLK_FQ = 16_000_000;
    localparam FAST_CLK_FQ = 128_000_000;
    
    // Drive fq dial 3.3V pin
    assign pio26 = 1;
    
    // Generate clocks
    wire sample_clk;
    wire fast_clk;
    wire clk_locked;
    clocks clocks
       (
        .clk_128mhz(fast_clk),      // Fast clock
        .clk_16mhz(sample_clk),     // Sample clock        
        .reset(1'b0),               // input reset
        .locked(clk_locked),        // output locked
        .clk_in1(clk)               // input clk_in1
    );
    
    // Reset logic: Delay 2 cycles before asserting reset, then hold for 16 cycles
    reg reset = 0;
    reg [0:1] reset_delay = 2; 
    reg [0:3] reset_hold = 15;
    always @(posedge sample_clk) 
    begin
        if(reset_delay != 0) 
        begin
            reset_delay <= reset_delay - 1;
        end else begin
            if(reset_hold != 0)
            begin
                reset <= 1;
                reset_hold <= reset_hold - 1;
            end else begin
                reset <= 0;
            end
        end
    end
    
    //   Controls
    localparam FQ_POLL_FQ = 100; // Poll once every 0.01s
    localparam FQ_POLL_TICKS = SAMPLE_CLK_FQ / FQ_POLL_FQ;
    wire [7:0] fq_inc;
    assign led[0:2] = { fq_inc[7], fq_inc[1], fq_inc[0] };
    wire fq_valid; 
    
    fq_dial #(
        .FQ_POLL_TICKS(FQ_POLL_TICKS)
    ) fq_dial (
        .aclk(sample_clk),
        .reset(reset),
        .ck(pio27),
        .dt(pio28),
        .fq_inc(fq_inc),
        .out_valid(fq_valid)); 
       
    wire signed [13:0] in;
    assign in = { pio1, pio2, pio3, pio4, pio5, pio6, pio7, pio8, pio9, pio16, pio17, pio18, pio19, pio20 };
    wire signed [15:0] baseband;
    wire output_valid;
    
    // Controller and UI
    controller controller (
        .aclk(fast_clk),
        .clk_locked(clk_locked), 
        .reset(reset),
        .fq_change(fq_inc),
        .fq_change_valid(fq_valid),
        .phase_inc(),
        .phase_inc_valid(),
        .uart_rx(usb_uart_rxd),
        .uart_tx(usb_uart_txd)
    );
    
    // ADC sampling
    assign pio21 = sample_clk;    // Connect clock to physical pin
    reg signed [13:0] adc_sample = 0;
    reg data_valid = 0;
    
    // Capture samples on negative edge of sample clock, This gives the
    // ADC plenty of time to settle.
    always @(negedge sample_clk) 
    begin
        adc_sample <= in;
        data_valid <= 1;
    end
    
    am_detector am_1 (
        .aclk(sample_clk),
        .phase_inc(27'd8_388_608), // 1MHz
        .phase_valid(data_valid), // TODO: Should be separate signal triggered by fq change.
        .rf(adc_sample),
        .baseband(baseband),
        .reset(reset),
        .i_valid(data_valid),
        .o_valid(output_valid)
     );
    
     dac my_dac (
        .clk(sample_clk),
        .din(baseband << 1),  // TODO: Check scaling
        .rst_n(~reset),
        .dout(pio48)
     );

endmodule
