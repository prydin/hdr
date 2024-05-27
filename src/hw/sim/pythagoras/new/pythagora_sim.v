`timescale 1us / 1ns
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


module pythagora_sim();
    reg clk;
    reg reset;
    reg sample_clk;
    wire pio48;
    
    initial clk = 1'b0;
    initial reset = 1;
    
    localparam CLOCK_PERIOD = 12;
    
    reg [4:0] sample_clk_counter = 0;
    always #(CLOCK_PERIOD / 2) 
    begin
        clk = ~clk;
        if(reset) 
        begin
            reset <= 0;
        end
    end
        
    wire signed [31:0] carrier;
    wire signed [15:0] i = carrier[31:16];
    wire signed [15:0] q = carrier[15:0];
    wire carrier_valid;
    
    osc_455kHz carrier1 (
        .aclk(clk),                              // input wire aclk
        .m_axis_data_tvalid(carrier_valid),      // output wire m_axis_data_tvalid
        .m_axis_data_tdata(carrier));            // output wire [15 : 0] m_axis_data_tdata
            
    wire  h_valid;    
    wire signed [15:0] h;
    pythagoras uut (
        .aclk(clk),
        .i(i),
        .q(q),
        .i_valid(carrier_valid),
        .h(h),
        .o_valid(h_valid)
    );
endmodule
    

