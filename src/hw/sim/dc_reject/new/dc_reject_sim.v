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


module dc_reject_sim();
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
    
    wire signed [15:0] signal;
    wire signed [15:0] out;
    wire out_valid;
    wire signal_valid;
      
     local_osc baseband_osc (
          .aclk(clk),                            
          .s_axis_phase_tdata(8389 * 1),
          .s_axis_phase_tvalid(valid),
          .m_axis_data_tvalid(signal_valid), 
          .m_axis_data_tdata(signal)
        );
        
        
    reg [0:3] divider = 0;
    reg sample_clk = 0;
    always @(posedge clk) 
    begin
        divider <= divider + 1;
        if(divider == 0)
        begin
            sample_clk <= ~sample_clk;
        end
    end
    dc_reject uut (
        .aclk(sample_clk),
        .alpha(2**23 - 1000),
        .reset(reset),
        //.in(10000),
        .in((signal >>> 2) + 16000),
        .in_valid(signal_valid),
        .out(out),
        .out_valid(out_valid));
    
endmodule
