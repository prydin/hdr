`timescale 1ns / 1ps

module debounce_sim();
    reg clk = 0;
    reg reset = 0;
    reg in = 0;
    wire out;
    integer i;
    
    initial 
    begin
        reset = 0;
        #2
        reset = 1;
        #16
        reset = 0;
        
        // Begin test
        in = 0;
        #100

        // Transistion to 1        
        // Bounce for a while
        for(i = 0; i < 50; i = i + 1) 
        begin
            #2
            in = 1;
            #2
            in = 0;
        end 
        
        // Settle on a 1 for a while 
        in = 1;
        #2000
        
        // Transistion to 0        
        // Bounce for 1000 cycles
        for(i = 0; i < 50; i = i + 1) 
        begin
            #2
            in <= 0;
            #2
            in = 1;
        end 
        
        // Settle on a 1 for 16000 cycles 
        in = 0;
        #2000
        
        // Just bounce and never settle        
        for(i = 0; i < 2000; i = i + 1) 
        begin
            #2
            in = 0;
            #2
            in = 1;
        end         
    end
    
    always #1
    begin
        clk<= ~clk;
    end
    
    debounce #(
    .CYCLES(800)
    ) deb (
        .aclk(clk), 
        .reset(reset),
        .in(in), 
        .out(out));
endmodule
