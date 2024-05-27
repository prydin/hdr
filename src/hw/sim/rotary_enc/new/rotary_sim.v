`timescale 1ns / 1ps

module rotary_sim();
    reg clk = 0;
    reg reset = 0;
    
    reg ck = 0;
    reg dt = 0;
    reg read_enable = 0;
    wire signed [7:0] out;
    integer i;
    
    initial 
    begin
        reset = 0;
        #2
        reset = 1;
        #16
        reset = 0;
                
        // Move forward
        ck <= 1;
        dt <= 1;
        #3000 
        
        // Read 
        #100
        read_enable <= 1;
        #100
        read_enable <= 0;
        #100
        
        // Move backwards
        ck <= 0;
        dt <= 1;
        #3000 
        
        // Read 
        #100
        read_enable <= 1;
        #100
        read_enable <= 0;
        
        // Do nothing (should get back 0)
        #100
        read_enable <= 1;
        #100
        read_enable <= 0;   
        
        // Move forward twice
        ck <= 1;
        dt <= 1;
        #3000
        
        ck <= 0;
        dt <= 0;
        #3000 

        // Read 
        #100
        read_enable <= 1;
        #100
        read_enable <= 0;
    end
    
    always #1
    begin
        clk<= ~clk;
    end
    
    rotary_enc #(
        .CYCLES(1000)
    ) rot (
        .aclk(clk), 
        .reset(reset),
        .ck(ck), 
        .dt(dt),
        .read_enable(read_enable),
        .out(out));
endmodule
