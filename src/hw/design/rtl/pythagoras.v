`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/31/2024 04:39:38 PM
// Design Name: 
// Module Name: pythagoras
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


module pythagoras(
        input wire aclk,
        input wire signed [15:0] i,
        input wire signed [15:0] q,
        input wire i_valid,
        output wire signed [15:0] h,
        output wire o_valid
    );
    
   
    reg [31:0] squared_i = 0;
    reg [31:0] squared_q = 0;
    reg [32:0] sum_squared = 0;
    reg sum_squared_valid = 0;
    wire [23:0] raw_out;
    assign h = { ~raw_out[15], raw_out[14:0] }; // TODO: Revisit scaling
    
    always @(posedge aclk) 
    begin 
        if(i_valid) 
        begin
            squared_i <= i * i;
            squared_q <= q * q;                   
            sum_squared <= squared_i + squared_q;
            sum_squared_valid <= 1;
        end
        else 
        begin
            sum_squared_valid <= 0;
        end 
    end
        
   sqrt sqrt1 (
      .aclk(aclk),                                          // input wire aclk
      .s_axis_cartesian_tvalid(sum_squared_valid),          // input wire s_axis_cartesian_tvalid
      .s_axis_cartesian_tdata(sum_squared[32:1]),           // input wire [31 : 0] s_axis_cartesian_tdata
      .m_axis_dout_tvalid(o_valid),                         // output wire m_axis_dout_tvalid
      .m_axis_dout_tdata(raw_out)                           // output wire [23 : 0] m_axis_dout_tdata
    );     
endmodule
