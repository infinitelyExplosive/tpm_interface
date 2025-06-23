`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2023 04:28:32 PM
// Design Name: 
// Module Name: testbench_SHA256
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


module testbench_SHA256(
    );

    logic clk;
    logic [31:0] inData;
    logic [7:0] inLen;
    logic write, start;
    logic [255:0] digest;
    logic ready, reset;

    SHA256 dut (
        .clk(clk),
        .inData(inData),
        .inLen(inLen),
        .write(write),
        .start(start),
        .digest(digest),
        .ready(ready),
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
        inData <= 0; inLen <= 0; write <= 0; start <= 0; reset <= 1;
        @(posedge clk); reset <= 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); inData <= 32'h1a3c583a; inLen <= 32; write <= 1;
        @(posedge clk); inData <= 32'h912f92ec; inLen <= 32; write <= 1;
        @(posedge clk); inData <= 32'hd3060eb0; inLen <= 32; write <= 1;
        @(posedge clk); inData <= 32'hbae7ee81; inLen <= 32; write <= 1;
        @(posedge clk); inData <= 32'h3ac7c94c; inLen <= 32; write <= 1;
        @(posedge clk); inData <= 32'h61b05b03; inLen <= 32; write <= 1;
        @(posedge clk); inData <= 32'h509f01c1; inLen <= 32; write <= 1;
        @(posedge clk); inData <= 32'hfa2894f2; inLen <= 32; write <= 1;
        @(posedge clk); inData <= 32'ha4c52376; inLen <= 32; write <= 1;
        @(posedge clk); inData <= 32'h2c2e2681; inLen <= 32; write <= 1;
        @(posedge clk); inData <= 32'hf4fa1aac; inLen <= 32; write <= 1;
        @(posedge clk); inData <= 32'hf2e37e18; inLen <= 32; write <= 1;
        @(posedge clk); inData <= 32'hdd3cae83; inLen <= 32; write <= 1;
        @(posedge clk); inData <= 32'h000211d3; inLen <= 24; write <= 1;
        @(posedge clk); write <= 0;
        @(posedge clk); start <= 1;
        @(posedge clk); start <= 0;
                        @(posedge ready); assert (digest == 256'h339ae409e8eb6260917c6ba2e6938feecbb7597b0409ea714a6f6ae439dd2689);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); reset <= 1;
        @(posedge clk); reset <= 0;
        
    end

    
endmodule
