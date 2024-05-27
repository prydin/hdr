`default_nettype none

// Delta/sigma-bsed DC reject filter.
// y(n) = x(n) - x(n - 1) + y(n - 1) * alpha
// Samples are fed through a differentiator and then into an integrator with a 
// weakened feedback causing fast changes to be favored over stable signals.
// 
// Setting alpha to 2**(alpha_width - 1)*0.9999 results in a very sharp filter
// with a cutoff very close to DC. 
module dc_reject #(
    parameter SIGNAL_WIDTH = 16,
    parameter ALPHA_WIDTH = 24  
    ) ( 
    input wire aclk, 
    input wire reset,
    
    input wire signed [0:-ALPHA_WIDTH + 1] alpha,  
    input wire signed [0:-SIGNAL_WIDTH + 1] in,     
    input wire in_valid,
    
    output reg signed [0:-SIGNAL_WIDTH + 1] out,
    output reg out_valid = 0
    );
        
    reg signed [0:-ALPHA_WIDTH + 1] diff = 0;    // Accumulator for differential
    reg signed [0:-ALPHA_WIDTH + 1] integ = 0;   // Accumulator for integral
    reg signed [0:-ALPHA_WIDTH + 1] integ_d = 0; // z^-1 time shifted integral
    reg signed [0:-ALPHA_WIDTH + 1] in_d = 0;    // z^-1 time shifted input
    reg signed [0:-ALPHA_WIDTH * 2 + 1] integ_times_alpha = 0; // Scaled feedback pre-reduction
    reg signed [0:-ALPHA_WIDTH + 1] feedback = 0;// Redduced scaled feedback
    
    wire signed [0:-ALPHA_WIDTH + 1] in_extended;
    assign in_extended = in << (ALPHA_WIDTH - SIGNAL_WIDTH);
    
    always @(*) 
    begin
        integ_times_alpha = integ_d * alpha; 
        feedback = integ_times_alpha >>> (ALPHA_WIDTH - 1); // -1 because alpha is signed and effectively one bit shorter
        integ = diff + feedback;
    end    
    
    always @(posedge aclk or posedge reset) 
    begin
        if(reset) 
        begin
            diff <= 0;
            out <= 0;
            out_valid <= 0;
        end else begin
            if(in_valid)
            begin
                diff <= in_extended - in_d;
                in_d <= in_extended;              
                integ_d <= integ;
                out <= integ >>> (ALPHA_WIDTH-SIGNAL_WIDTH);
                out_valid <= 1;
            end else begin
                out_valid <= 0;
            end
        end
    end
endmodule