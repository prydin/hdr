`timescale 1ns / 1ps

module edge_detect(
    input wire aclk,
    input wire reset,
    input wire signal,
    output reg pos,
    output reg neg
    );
    
    reg [1:0] shift = 2'b00;
    always @(posedge aclk or posedge reset) 
    begin
        if(reset) 
        begin
            shift <= { signal, signal };
        end else begin 
            shift <= { shift, signal };
            if(shift == 2'b01) 
            begin
                pos <= 1'b1;
                neg <= 1'b0;
            end else if(shift == 2'b10) 
            begin
                pos <= 1'b0;
                neg <= 1'b1;
            end else begin
                pos <= 1'b0;
                neg <= 1'b0;
            end
        end
    end
endmodule
            

// Debounce an input by requiring the set ratio of samples to be equal to the new state
// within a specified number of clock ticks.
module debounce 
    #(
    parameter CYCLES = 160_000    // 10ms
    ) 
    (
    input wire aclk,    // System clock
    input wire reset,   // Master reset
    input wire in,      // Signal to be debounced
    output reg out      // Debounced signal
    );
    
    wire pos;
    wire neg;
    edge_detect edge_detect(
        .aclk(aclk),
        .reset(reset),
        .signal(in),
        .pos(pos),
        .neg(neg)); 
    
    reg [0:$clog2(CYCLES + 1) - 1] counter = 0;
      
    // Look for a state that lasts for at least CYCLES cycles. 
    always @(posedge aclk or posedge reset) 
    begin
        if(reset) 
        begin
            out <= in;
            counter <= CYCLES;
        end else begin
            // Switch changed, reset counter
            if(pos | neg)
            begin
                counter <= CYCLES;
            end else begin
                counter <= counter - 1;
                if(counter == 0) 
                begin
                    // We found a stable state
                    out <= in;
                    counter <= CYCLES;
                end
            end
    end
   end
endmodule
