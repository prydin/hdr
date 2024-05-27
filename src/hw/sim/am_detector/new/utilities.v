`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2024 06:41:12 PM
// Design Name: 
// Module Name: dff
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


module dff #(parameter NUMBITS = 14) (
        input clk,
        input clear,
        input [NUMBITS-1:0] d,
        output [NUMBITS-1:0] q
    );
    
    reg [NUMBITS-1:0] q;
    wire [NUMBITS-1:0] d;
    wire clear;
    wire clk;
    
    always @(posedge clk or posedge clear)
    begin
        if(clear == 1) 
        begin
            q <= 0;
        end 
        else 
        begin
            q <= d;
        end    
    end
endmodule

module clk_domain_bridge #(parameter NUMBITS = 14) (
    input clk_a,
    input clk_b,
    input reset,
    input [NUMBITS-1:0] d,
    output [NUMBITS-1:0] q
    );
    
    wire clk_a;
    wire clk_b;
    wire reset;
    wire [NUMBITS-1:0] d;
    reg [NUMBITS-1:0] q;
    
    reg [NUMBITS-1:0] q1;
    reg [NUMBITS-1:0] q2;
    
    dff dff_a1(clk_a, reset, d, q1);
    dff dff_b1(clk_b, reset, q1, q2);
    dff dff_b2(clk_b, reset, q2, q);
endmodule    

