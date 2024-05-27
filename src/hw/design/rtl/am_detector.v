`default_nettype none

module am_detector (
    input wire aclk,
    input wire signed [13:0] rf,
    input wire [26:0] phase_inc,
    input wire phase_valid,
    output wire signed [15:0] baseband,
    input wire reset,
    input wire i_valid,
    output wire o_valid
    );
        
    wire signed [15:0] scaled_in;
    assign scaled_in = rf << 2;
    wire signed [15:0] pre_dc_block;
    wire pre_dc_block_valid;
    wire signed [31:0] dds_config;
    assign dds_config = { 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, phase_inc };
    
    // ************* IF carrier generation *************
    wire carrier_valid;
    wire [31:0] raw_carrier_iq; 
    local_osc local_osc_1 (
        .aclk(aclk),                                // input wire aclk
        .m_axis_data_tvalid(carrier_valid),         // output wire m_axis_data_tvalid
        .m_axis_data_tdata(raw_carrier_iq),         // output wire [15 : 0] m_axis_data_tdata
        .s_axis_phase_tdata(dds_config),
        .s_axis_phase_tvalid(phase_valid));                  
    
    // ************** MIXER SECTION *************
    wire signed [15:0] carrier_i;
    wire signed [15:0] carrier_q;
    reg signed [31:0] prod_i;
    reg signed [31:0] prod_q;
    wire signed [15:0] mixed_i;
    wire signed [15:0] mixed_q;
    wire signed [15:0] filtered_i;
    wire filtered_i_valid;
    wire signed [15:0] filtered_q;
    wire filtered_q_valid;

    reg prod_valid = 1'b0;
    
    assign mixed_i = prod_i[31:16];
    assign mixed_q = prod_q[31:16];
        
    // Extract I and Q from carrier generator stream
    assign carrier_i = raw_carrier_iq[31:16];
    assign carrier_q = raw_carrier_iq[15:0];
  
    // Mix signal and I/Q of local oscillator
    always @(posedge aclk) 
    begin
        if(carrier_valid && i_valid)
        begin
            prod_i <= carrier_i * scaled_in;
            prod_q <= carrier_q * scaled_in;
            prod_valid <= 1;
        end
        else
        begin
            prod_i <= 0;
            prod_q <= 0;
            prod_valid <= 0;
        end
    end
    
    
    filter_chain filters_i (
        .aclk(aclk),
        .reset(reset),
        .in(mixed_i),
        .in_valid(prod_valid),
        .out(filtered_i),
        .out_valid(filtered_i_valid)
    );
    
    filter_chain filters_q (
        .aclk(aclk),
        .reset(reset),
        .in(mixed_q),
        .in_valid(prod_valid),
        .out(filtered_q),
        .out_valid(filtered_q_valid)
    );

    // Recombine I and Q signal
    pythagoras pyt_1 (
        .aclk(aclk),
        .i(filtered_i),
        .q(filtered_q),
        .i_valid(filtered_q_valid && filtered_i_valid),
        .h(pre_dc_block),
        .o_valid(pre_dc_block_valid)
    );
    
    // Remove any DC remnants
    localparam alpha = 24'd8387608 - 24'd1000;
    dc_reject dc_reject  (
        .aclk(aclk),
        .reset(reset),
        .alpha(alpha),
        .in(pre_dc_block),
        .in_valid(pre_dc_block_valid),
        .out(baseband),
        .out_valid(o_valid)
       );
endmodule
