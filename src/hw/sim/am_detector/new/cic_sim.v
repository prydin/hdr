`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/27/2024 09:10:52 AM
// Design Name: 
// Module Name: cic_sim
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


module cic_sim();
    reg reset = 1;
    reg valid = 0;
    reg clk = 0;
    always #31 // Approx 16MHz
    begin
        clk = ~clk;
        if(reset) 
        begin
            valid <= 1;
            reset <= 0;
        end
    end 
    
    reg signed [16:0] signal;
    wire signed [15:0] carrier;
    wire signed [15:0] baseband;

    wire signed [15:0] out;
    wire signed out_valid;
    wire signal_valid;
    wire baseband_valid;
    wire carrier_valid;
      
     local_osc baseband_osc (
          .aclk(clk),                            
          .s_axis_phase_tdata(8_389 * 1),
          .s_axis_phase_tvalid(valid),
          .m_axis_data_tvalid(baseband_valid), 
          .m_axis_data_tdata(baseband)
        );
        
     local_osc carrier_osc (
      .aclk(clk),                            
      .s_axis_phase_tdata(8_389000 * 1),
      .s_axis_phase_tvalid(valid),
      .m_axis_data_tvalid(signal_valid), 
      .m_axis_data_tdata(carrier)
    );
    
    always @(*) 
    begin
        signal = baseband + carrier;
    end

    filter_chain filters (
        .aclk(clk),
        .reset(reset),
        .in(signal >>> 1),
        .in_valid(valid),
        .out(out),
        .out_valid(out_valid)
    );
    
endmodule
