`default_nettype none
// Filter chain:
// [Pre decimation fir} -> [Decimate 16:1] -> [DC reject] -> [4k LPF FIR] -> [Image reject FIR] -> [DC reject]  
module filter_chain(
        input wire aclk,
        input wire reset,
        input wire signed [15:0] in,
        input wire in_valid,
        output reg signed [15:0] out,
        output reg out_valid
    );

    wire signed [31:0] dec_1mhz;
    wire dec_1mhz_valid;
    wire signed [31:0] dec_62khz;
    wire signed [15:0] dec_62khz_in;
    wire dec_62khz_valid;

    wire signed [15:0] pre_dc_reject;
    wire signed [15:0] stage1_in;
    wire signed stage1_in_valid;
    wire signed [31:0] stage1_out;
    wire stage1_valid;
    wire signed [31:0] stage2_out;
    wire stage2_valid;
    wire signed [15:0] dc_filtered_out;
    wire dc_filtered_valid;
        
    // Downsample to 1Mhz
    decimate16to1 decimator_1mhz (
        .aclk(aclk),                    
        .s_axis_data_tvalid(in_valid),  
        .s_axis_data_tready(),  
        .s_axis_data_tdata(in),    
        .m_axis_data_tvalid(dec_1mhz_valid),  
        .m_axis_data_tdata(dec_1mhz) 
        );
        
   // Downsample to 62.5kHz
    assign dec_62khz_in = dec_1mhz[29:14];
    decimate16to1_low decimator_62hkz (
        .aclk(aclk),                    
        .s_axis_data_tvalid(dec_1mhz_valid),  
        .s_axis_data_tready(),  
        .s_axis_data_tdata(dec_62khz_in),    
        .m_axis_data_tvalid(dec_62khz_valid),  
        .m_axis_data_tdata(dec_62khz) 
        );
        
    assign stage1_in = dec_62khz[30:15]; 
    
    // 4kHz bandwidth-limiting LPF
    fir_4khz bw_limiter_fir (
        .aclk(aclk),
        .s_axis_data_tdata(stage1_in),
        .s_axis_data_tvalid(dec_62khz_valid),
        .s_axis_data_tready(),
        .m_axis_data_tvalid(stage1_valid),  
        .m_axis_data_tdata(stage1_out) 
    );
    
    
    // TODO: Upsample
    assign stage2_out = stage1_out;
    assign stage2_valid = stage1_valid;
       
    // Transfer to outputs
    always @(posedge aclk) 
    begin
        if(stage2_valid)
        begin
            out <= stage2_out >>> 15;
            out_valid <= 1;
        end else begin 
            out_valid <= 0;
        end
    end
endmodule