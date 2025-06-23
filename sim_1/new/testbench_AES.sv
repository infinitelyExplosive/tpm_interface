`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2023 08:05:21 PM
// Design Name: 
// Module Name: testbench_AES
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


module testbench_AES(

    );

    parameter key_bits = 128;

    logic clk;
    logic [key_bits - 1:0] key, key_reversed;
    logic [127:0] pt, pt_reversed, ct, ct_reversed;
    logic ready, start, reset;

    AES #(key_bits) aes_module (
        .clk(clk),
        .key(key),
        .pt(pt),
        .ct(ct),
        .ready(ready),
        .start(start),
        .reset(reset)
    );

    parameter CLK_PERIOD = 10;
    initial begin
        clk <= 0;
        forever begin
            #(CLK_PERIOD/2) clk <= ~clk;
        end
    end

    initial begin
        key <= 0; pt <= 0; start <= 0; reset <= 1;
        @(posedge clk); reset <= 0;
        @(posedge clk); 
        @(posedge clk); key <= 128'hddccbbaa_88776655_44332211_44332211; 
                        pt <= 128'h01000000_00000000_00000000_00000000; 
                        start <= 1;
        @(posedge clk); start <= 0;
                        @(posedge ready); 
        @(posedge clk); assert (ct == 128'h737fb6ba48949409cd8484facc28682f);
        @(posedge clk);
        
    end
endmodule
