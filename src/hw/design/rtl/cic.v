// `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/27/2024 07:17:08 AM
// Design Name: 
// Module Name: cic
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


module cic(
    input wire aclk,
    input wire reset,
    input wire signed [15:0] in,
    input wire in_valid,
    input wire signed [15:0] dec_ratio,
    output reg signed [15:0] out,
    output reg out_valid
    );

    wire signed [39:0] in_extended;
    assign in_extended = $signed(in);

    // Combs
    reg signed [39:0] comb_in, comb_in_d;
    reg signed [39:0] comb1, comb1_d;
    reg signed [39:0] comb2, comb2_d;
    reg signed [39:0] comb3, comb3_d;
    reg signed [39:0] comb4;
    reg signed [39:0] comb_out;
    reg comb_valid;

    // Integrators
    reg signed [39:0] int1;
    reg signed [39:0] int2;
    reg signed [39:0] int3;
    reg signed [39:0] int4;

    // Compensation FIR
    reg signed [41:0] fir_delay[0:7]; // Two times four delay line
    reg signed [41:0] fir_scaled;
    reg signed [41:0] fir_scaled_d;
    reg signed [41:0] fir_out; 
    reg fir_valid;

    reg out_valid_soon;
    reg int_valid;

    // Decimation rate counter
    reg [15:0] decimation_cnt;

    integer i;

    // Filter topology is integrator -> decimaton -> comb 
    // as per https://www.dsprelated.com/showarticle/1337.php figure 10
    //
    // Integrator stage 
    always @(posedge aclk) 
    begin
        if(reset) 
        begin
            int1 <= 0;
            int2 <= 0;
            int3 <= 0;
            int4 <= 0;

            comb_in <= 0;
            comb1 <= 0;
            comb2 <= 0;
            comb3 <= 0;
            comb4 <= 0;
            comb_out <= 0;
            
            for(i = 0; i < 8; i = i + 1)
            begin
                fir_delay[i] <= 0;
            end
            fir_scaled <= 0;
            fir_scaled_d <= 0;

            fir_out <= 0;

            comb_in_d <= 0;
            comb1_d <= 0;
            comb2_d <= 0;
            comb3_d <= 0;
            comb_out <= 0;
            comb_valid <= 0;

            decimation_cnt <= 0;
            out_valid_soon <= 0;
            int_valid <= 0;
        end else begin
            if(in_valid)
            begin
                int1 <= int1 + in_extended;
                int2 <= int2 + int1;
                int3 <= int3 + int2;
                int4 <= int4 + int3;
                decimation_cnt <= decimation_cnt + 1;
                if(decimation_cnt ==  dec_ratio - 1)
                begin
                    int_valid <= 1;
                    comb_in <= int4;
                    decimation_cnt <= 0;
                    out_valid_soon <= 1;
                end else begin
                    // Generate out valid pulses with a 50% duty cycle so we can use it as a sample clock
                    if(decimation_cnt == dec_ratio >> 1) 
                    begin
                        out_valid_soon = 0;
                    end
                    int_valid <= 0;
                end
            end 
        end
    end


    // Compensation FIR
    always @(posedge aclk)
    begin
        if(comb_valid)
        begin
            fir_scaled <= comb_out >>> 2;
            fir_scaled_d <= fir_scaled;
            fir_out <= comb_out + fir_scaled + fir_scaled_d;
            out_valid <= 1;
        end else begin
            out_valid <= 0;
        end
    end
    
    // Comb stage
    always @(posedge aclk)
    begin
        out_valid <= out_valid_soon;
        if(int_valid)
        begin
            // Stage 1
            comb_in_d <= comb_in;
            comb1 <= comb_in - comb_in_d;
            comb1_d <= int1;

            // Stage 2
            comb2 <= comb1 - comb1_d;
            comb2_d <= comb2;

            // Stage 3
            comb3 <= comb2 - comb2_d;
            comb3_d <= comb3;

            // Stage 4
            comb4 <= comb3 - comb3_d;
            comb_out <= comb4; // out <= comb4[37:21];
            comb_valid <= 1;
        end else begin
            comb_valid <= 0;
        end   
     end

    // Compensation stage. Simple FIR as proposed by Dolecek here: 
    // https://www.sciencedirect.com/science/article/abs/pii/S1051200409000177
    /*
    integer i;
    always @(posedge aclk)
    begin
        if(comb_valid) 
        begin
            fir_delay[0] <= comb_out;
            for(i = 1; i < 8; i = i + 1)
            begin
                fir_delay[i] <= fir_delay[i - 1];
            end
            fir_out <= comb_out - (fir_delay[3] * 6) + fir_delay[7];
            out <= fir_out[41:26]; 
            out_valid <= 1;
        end else begin
            out_valid = 0;
        end
    end */


endmodule
