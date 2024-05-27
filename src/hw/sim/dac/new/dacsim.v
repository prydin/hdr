`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2024 02:17:46 PM
// Design Name: 
// Module Name: dacsim
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


module dacsim();
    reg clk;
    wire pio48;

    initial clk = 1'b0;
    
    reg signed [15:0] signal = 0;
    
    reg reset = 1;
    
    localparam CLOCK_PERIOD = 2;
    
    dac uut(
        .clk(clk),
        .rst_n(~reset),
        .din(signal),
        .dout(pio48));
    
    always #(CLOCK_PERIOD / 2) 
    begin
        clk <= ~clk;
        signal <= signal + 16;
        if(reset == 1) reset <= 0;
    end
endmodule
    
