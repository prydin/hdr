`timescale 1ns / 1ps

// Quadrature rotary encoder handler. Accumulates the number of detents moved
// in a register. 1 is a clockwise step and -1 is counter-clockwise.
module rotary_enc #(
    parameter CYCLES = 160000        // Debounce cycles
    ) (
    input wire aclk,                // Clock
    input wire reset,               // Master reset
    input wire ck,                  // Clock pulse
    input wire dt,                  // Data pules
    input wire read_enable,         // Triggers readout and reset of movement register
    output reg out_valid,           /// Output is valid
    output reg signed [7:0] out     // Number of moves accululated since last readout
    );

    reg ck_prev = 0;
    reg signed [7:0] move = 0;

    wire ck_debounced;
    wire dt_debounced;
        
    // Debounce rotary contacts
    debounce #(
        .CYCLES(CYCLES)
    ) debounce_ck (
        .aclk(aclk),
        .reset(reset),
        .in(ck),
        .out(ck_debounced));       
    debounce  #(
        .CYCLES(CYCLES)
    ) debounce_dt(
        .aclk(aclk),
        .reset(reset),
        .in(dt),
        .out(dt_debounced));

    always @(posedge aclk)
    begin   
        if(reset) 
        begin
            // Use raw values since the debouncer won't have settled
            ck_prev <= ck; 
            move <= 0;
        end else if(read_enable && !out_valid)
        begin 
            // Positive flank of read_enable. Copy number of steps moved 
            // since last read to out.
            out <= move;
            out_valid <= 1;
        end else if(!read_enable && out_valid) 
        begin
            // Negative flank of read_enabled encountered
            out_valid <= 0;
            move <= 0;
        end else if(ck_debounced != ck_prev)
        begin
            if(ck_debounced == dt_debounced) 
            begin
                // Clockwise
                move <= move + 1;
            end else begin
                // Counter-clockwise
                move <= move - 1;
           end
           ck_prev <= ck_debounced;
        end
    end
endmodule
