`timescale 1ns / 1ps
//`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2024 07:35:27 AM
// Design Name: 
// Module Name: detector_sim
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


module detector_sim();
    reg clk;
    wire pio48;

    initial clk = 1'b0;
    reg signal_valid = 0;
    
    wire signed [15:0] baseband;
    wire baseband_valid;
    wire signed [31:0] carrier_iq;
    wire carrier_valid;
    wire sample_clk;
    wire clk_fast;

    
    reg signed [13:0] signal;    
    reg reset = 1;
    reg valid = 0;
    reg signed [31:0] prod;
    wire signed [15:0] carrier_i;
    wire signed [15:0] interference;
    wire interference_valid;

    assign carrier_i = carrier_iq[15:0];
    
    always @(posedge clk) 
    begin
        if(baseband_valid && carrier_valid && valid) 
        begin
            // prod <= ((baseband >>> 2) + (interference >>> 2) + 16384) * carrier_i;
            prod <= ((baseband >>> 1) + 16384) * carrier_i;
            signal <= prod >>> 17;
            signal_valid <= 1;
        end else begin 
            prod <= 0;
            signal <= 0;
            signal_valid <= 0;
        end
    end
    
    localparam CLOCK_PERIOD = 83; // Approx 12MHz
        
    initial begin
        #10;
    end 
    
    always #(CLOCK_PERIOD / 2) 
    begin
        clk = 1'b1;
        #(CLOCK_PERIOD/2) clk = 1'b0;
        #(CLOCK_PERIOD/2);
        if(reset) 
        begin
            valid <= 1;
            reset <= 0;
        end
    end 
    
     clocks clocks
       (
        .clk_128mhz(clk_fast),      // Fast clock
        .clk_16mhz(sample_clk),     // Sample clock        
        .reset(reset),              // input reset
        .locked(),                  // output locked
        .clk_in1(clk)               // input clk_in1
    );
    
    wire pio1, pio2, pio3, pio4, pio5, pio6, pio7, pio8, pio9, pio16, pio17, pio18, pio19, pio20, pio21, pio29, pio30;
    
   assign { pio1, pio2, pio3, pio4, pio5, pio6, pio7, pio8, pio9, pio16, pio17, pio18, pio19, pio20 } = signal;
   
   reg pio27, pio28;
   
   root root1(
    .clk(clk),
    .pio20(pio20),
    .pio19(pio19),
    .pio18(pio18),
    .pio17(pio17),
    .pio16(pio16),
    .pio9(pio9),
    .pio8(pio8),
    .pio7(pio7),
    .pio6(pio6),
    .pio5(pio5),
    .pio4(pio4),
    .pio3(pio3),
    .pio2(pio2),
    .pio1(pio1),
    .pio21(pio21), // ADC clock
    .pio27(pio27), // Fq ck
    .pio28(pio28), // Fq dt 
    .pio29(pio29), // SCL
    .pio30(pio30), // SDA
    .pio48(pio48)  // DAC delta/sigma out
    );
   
    // Generate 1kHz modulated on top of 1MHz
    local_osc carrier_gen (
        .aclk(sample_clk),                                 // input wire aclk
        // .s_axis_phase_tdata(8_380_166),             // 1,000,100Hz
        .s_axis_phase_tdata(8_388_608),
        .s_axis_phase_tvalid(valid),
        .m_axis_data_tvalid(carrier_valid),         // output wire m_axis_data_tvalid
        .m_axis_data_tdata(carrier_iq));            // output wire [15 : 0] m_axis_data_tdata
        
        
    local_osc baseband_osc (
          .aclk(sample_clk),                              // input wire aclk
          .s_axis_phase_tdata(8_389),
          .s_axis_phase_tvalid(valid),
          .m_axis_data_tvalid(baseband_valid),  // output wire m_axis_data_tvalid
          .m_axis_data_tdata(baseband)    // output wire [15 : 0] m_axis_data_tdata
        );
        
    local_osc interference_osc (
          .aclk(sample_clk),                              // input wire aclk
          .s_axis_phase_tdata(83890),
          .s_axis_phase_tvalid(valid),
          .m_axis_data_tvalid(interference_valid),  // output wire m_axis_data_tvalid
          .m_axis_data_tdata(interference)    // output wire [15 : 0] m_axis_data_tdata
        );
        
        
    // Simulate a user fiddling with the frequency knob
    initial 
    begin
        #1000
        pio27 <= 0;
        pio27 <= 0;
        
        #3000
        pio27 <= 1;
        pio27 <= 1;
        
        #3000
        pio27 <= 0;
        pio27 <= 0;
        
        #3000
        pio27 <= 1;
        pio27 <= 1;
    end
        
                
endmodule
    

