`timescale 1ns / 1ps

// Debounce an input by requiring the set ratio of samples to be equal to the new state
// within a specified number of clock ticks.
module debounce 
    #(
    parameter CYCLES = 16_000,
    parameter GOOD_RATIO_LOG2 = 4 // Need 15/16 good samples
    ) 
    (
    input wire aclk,    // System clock
    input wire reset,   // Master reset
    input wire in,      // Signal to be debounced
    output reg out      // Debounced signal
    );
    
    reg prev = 0;
    reg wanted = 0;
    localparam NEEDED_CYCLES = CYCLES - (CYCLES >>> GOOD_RATIO_LOG2); // "Good" cycles needed for transition
    reg [0:$clog2(CYCLES + 1) - 1] good_cycles = 0;
    reg [0:$clog2(CYCLES + 1) - 1] total_cycles = CYCLES;
    reg edge_found = 0;
    
    always @(posedge aclk or posedge reset) 
    begin
        if(reset) 
        begin
            out <= 0;
            prev <= 0;
            edge_found <= 0;
            good_cycles <= 0;
            total_cycles <= CYCLES;
            wanted <= 0;
        end else begin
            // Are we at the first edge of a transistion?
            if(!edge_found && in != prev) 
            begin
                wanted <= in;
                edge_found <= 1;
            end else if(edge_found) 
            begin
                // Count "good" cycles, i.e. when the input is the wanted value
                if(in == wanted) 
                begin
                    good_cycles <= good_cycles + 1;
                end
                
                // Did we finish the entire sampling window? 
                if(total_cycles == 0)
                begin
                    // If we got enough good samples, we deem the transition valid
                    if(good_cycles >= NEEDED_CYCLES)
                    begin
                        out <= wanted;
                    end
                    
                    // Reset everything for the next transition
                    edge_found <= 0;
                    total_cycles <= CYCLES;
                    good_cycles <= 0;
                end
                total_cycles <= total_cycles - 1;
            end
            prev <= in;
        end
   end
endmodule
