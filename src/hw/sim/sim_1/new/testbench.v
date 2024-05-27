`timescale 10ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/10/2024 04:26:18 PM
// Design Name: 
// Module Name: testbench
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


module testbench();
    reg clk;
    wire pio48;
    
    initial clk = 1'b0;

    root uut (.clk(clk), .pio48(pio48));
    
    localparam CLOCK_PERIOD = 10;
    
    always #(CLOCK_PERIOD / 2) 
    begin
        clk <= ~clk;
    end
endmodule
