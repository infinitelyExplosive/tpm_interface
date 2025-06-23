`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/25/2023 03:12:52 PM
// Design Name: 
// Module Name: testbench_SHA1
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


module testbench_SHA1(
    );

    logic clk;
    logic [63:0] inData;
    logic [7:0] inLen;
    logic write, start;
    logic [159:0] digest;
    logic ready, reset;

    SHA1 dut (
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
        @(posedge clk); inData <= 64'h0123_1357_6789_abcd; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'h6666_7777_8888_9999; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'h6420_8642_a864_ca86; inLen <= 64; write <= 1;
        @(posedge clk); write <= 0;
        @(posedge clk); start <= 1;
        @(posedge clk); start <= 0;
        @(posedge clk);
                        @(posedge ready);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); reset <= 1;
        @(posedge clk); reset <= 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); 
        @(posedge clk); inData <= 64'h0123_1357_6789_abcd; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'h6666_7777_8888_9999; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'ha864_ca86; inLen <= 32; write <= 1;
        @(posedge clk); write <= 0; start <= 1;
        @(posedge clk); start <= 0;
        @(posedge clk);
                        @(posedge ready);
        @(posedge clk);
        @(posedge clk); reset <= 1;
        @(posedge clk); reset <= 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); //5
        @(posedge clk); inData <= 64'h0123_1357_6789_abcd; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'h5555_5555_8888_9999; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'h1234_2345_3456_4567; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'h1122_2233_3344_4455; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'habcd_abcd_abcd_abcd; inLen <= 64; write <= 1;
        @(posedge clk); write <= 0; start <= 1;
        @(posedge clk); start <= 0;
        @(posedge clk);
        @(posedge clk);
                        @(posedge ready);
        @(posedge clk);
        @(posedge clk); reset <= 1;
        @(posedge clk); reset <= 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); //6
        @(posedge clk); inData <= 64'h0123_1357_6789_abcd; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'h6666_6666_8888_9999; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'h1234_2345_3456_4567; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'h1122_2233_3344_4455; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'habcd_abcd_abcd_abcd; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'hefef_fefe_eeee_ffff; inLen <= 64; write <= 1;
        @(posedge clk); write <= 0; start <= 1;
        @(posedge clk); start <= 0;
        @(posedge clk);
                        @(posedge ready);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); reset <= 1;
        @(posedge clk); reset <= 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); //7
        @(posedge clk); inData <= 64'h8001_0180_4444_0011; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'h7777_7777_8888_9999; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'h1234_2345_3456_4567; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'h1122_2233_3344_4455; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'habcd_abcd_abcd_abcd; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'hefef_fefe_eeee_ffff; inLen <= 64; write <= 1;
        @(posedge clk); inData <= 64'h1248_37f3_9a9a_8421; inLen <= 64; write <= 1;
        @(posedge clk); write <= 0; start <= 1;
        @(posedge clk); start <= 0;
        @(posedge clk);
                        @(posedge ready);
    end
endmodule
