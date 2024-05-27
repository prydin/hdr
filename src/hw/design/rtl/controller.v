`timescale 1ns / 1ps

module monostable_ff
    #(CYCLES = 1        // Number of cycles to keep output high after positive flank on d
    ) (
    input wire aclk,    // System clock
    input wire reset,   // Master reset
    input wire d,       // Data in
    output reg q);      // Data out
    
    reg [$clog2(CYCLES + 1) - 1: 0] counter = CYCLES;
    reg prev = 0;
    
    always @(posedge aclk) 
    begin
        if(reset)
        begin
            counter <= CYCLES;
            prev <= d;
            q <= 0;
        end else begin
            // Positive flank?
            if(prev == 0 && d == 1)
            begin
                // Set output high and start counting down time to reset
                q <= 1;
                counter <= CYCLES;
            end else begin
                if(q == 1) 
                begin
                    counter <= counter - 1;
                    if(counter == 0) 
                    begin
                        // Reset time reached
                        q <= 0;
                    end
                end
            end
            prev <= d;
        end
    end
endmodule

module controller #(parameter PHASE_INC_WIDTH = 27) (
        input wire aclk,
        input wire clk_locked,
        input wire reset,
        input wire fq_ck,
        input wire fq_dt,
        output wire [PHASE_INC_WIDTH - 1:0] phase_inc,
        output wire phase_inc_valid,
        input wire uart_rx,
        output wire uart_tx
    );
    
    wire [31:0] phase_inc_comp;
    assign phase_inc = phase_inc_comp[PHASE_INC_WIDTH - 1:1];
    assign phase_inc_valid = phase_inc_comp[0];
    reg fq_read_enable = 0;
   
    
    // Frequency dial
    wire fq_valid;
    wire signed [7:0] fq_change; 
    rotary_enc fq_dial (
        .aclk(aclk),
        .reset(reset),
        .ck(fq_ck),
        .dt(fq_dt),
        .read_enable(fq_read_enable),
        .out(fq_change),
        .out_valid(fq_valid)
    );

    // Handle phase increment output
    wire [31:0] phase_inc_comp;
    assign phase_inc = phase_inc_comp[PHASE_INC_WIDTH - 1:1];
    assign phase_inc_valid = phase_inc_comp[0];
    monostable_ff phase_inc_ff (
        .aclk(aclk),
        .reset(reset),
        .d(phase_inc_comp[0]),
        .q(phase_inc_valid));
       
   // Commands from MCU to FPGA
   localparam GET_FQ_INC = 4'h1;                // Get latest frequency increment
   localparam NO_COMMAND = 4'h0;                // No command -> Get ready for next
   
    reg [31:0] to_mcu = 32'h0;
    wire [31:0] from_mcu;
    wire [3:0] command_from_mcu = from_mcu[31:28];
    wire [27:0] data_from_mcu = from_mcu[27:0];
    reg ready = 1;
        
    mcu mcu (
        .aclk(aclk),
        .to_mcu_tri_i(to_mcu),
        .from_mcu_tri_o(from_mcu),
        .locked(clk_locked),
        .usb_uart_rxd(uart_rx),
        .usb_uart_txd(uart_tx));
        
    // Command dispatcher state machine
    localparam IDLE         = 4'h0;     // Awaiting command
    localparam READ         = 4'h1;     // Read value
    localparam LIMBO        = 4'h2;     // Stalled until NO_COMMAND received 
    reg [3:0] state = IDLE;
    always @(posedge aclk or posedge reset)
    begin
        if(reset) 
        begin
            ready <= 1;
            to_mcu <= 0;
        end else begin 
            case(command_from_mcu)
            GET_FQ_INC:
                case(state)
                IDLE:
                    begin
                        fq_read_enable <= 1;
                        state <= READ; 
                    end
                READ:
                    begin
                        if(fq_valid) 
                        begin
                            to_mcu <= {{24{fq_change[7]}}, fq_change };
                            fq_read_enable <= 0;
                            state <= LIMBO;
                        end
                    end
                endcase
            NO_COMMAND:
                begin
                    state <= IDLE;
                end
            endcase
        end
     end
endmodule
