`timescale 1ns / 1ps


// Frequency dial handler. Wrapper around a rotary envoder handler
module fq_dial #(
        FQ_POLL_TICKS = 16_000_000 / 10,
        DEBOUNCE_CYCLES = 16_000_000 / 100
    ) (
        input wire aclk,            // System clock
        input wire reset,           // Master reset
        input wire ck,              // Rotary clock
        input wire dt,              // Rotary data
        output wire [7:0] fq_inc,   // Frequency increment output
        output reg out_valid        // Output valid
    );
    
    reg read_fq = 0;
    rotary_enc #(
        .CYCLES(DEBOUNCE_CYCLES)
    ) fq_dial (
        .aclk(aclk),
        .reset(reset),
        .ck(ck),
        .dt(dt),
        .read_enable(read_fq),
        .out(fq_inc)
    );
    
    reg [$clog2(FQ_POLL_TICKS + 1) - 1:0] fq_poll_counter = FQ_POLL_TICKS -1;
    always @(posedge aclk) 
    begin
        if(reset)
        begin
            fq_poll_counter <=  FQ_POLL_TICKS -1;
            out_valid <= 0;
        end
        fq_poll_counter <= fq_poll_counter - 1;
        if(fq_poll_counter == 0)
        begin
            // Time to poll. Set read_enable high and make the output invalid while
            // we're reading. 
            read_fq <= 1;
            out_valid <= 0;
            fq_poll_counter <= FQ_POLL_TICKS;
        end else begin
            if(read_fq)
            begin
                // Done reading. Output is valid again.
                read_fq <= 0;
                out_valid <= 1;
            end
        end
    end
endmodule
