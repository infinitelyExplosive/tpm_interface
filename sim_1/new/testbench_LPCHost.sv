`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2023 11:47:52 AM
// Design Name: 
// Module Name: testbench_LPCHost
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


module testbench_LPCHost(

    );
    logic [3:0] ad;
    logic [3:0] inAd, outAd;
    logic enable, clk, frame;
    logic [15:0] addr;
    logic [7:0] inData, outData;
    logic isWrite, isReady, start, reset;

    assign ad = enable ? outAd : inAd;

    LPCHost dut (
        .inAd(inAd),
        .outAd(outAd),
        .enable(enable),
        .clk(clk),
        .frame(frame),
        .addr(addr),
        .inData(inData),
        .outData(outData),
        .isWrite(isWrite),
        .isReady(isReady),
        .start(start),
        .reset(reset)
    );

    parameter CLK_PERIOD = 10;
    initial begin
        clk <= 0;
        for (int i = 0; i < 100; i++) begin
            #(CLK_PERIOD/2) clk <= ~clk;
        end
    end

    initial begin
        inAd <= 'hf; addr <= 'hffff; inData <= 'hff; isWrite <= 1; start <= 0; reset <= 0;
        @(posedge clk); reset <= 1;
        @(posedge clk); 
        @(posedge clk); 
        @(posedge clk); reset <= 0;
                        @(posedge isReady);
        @(posedge clk); addr <= 'h1234; inData <= 'hab; isWrite <= 1; start <= 1;
        @(posedge clk); start <= 0;
        @(posedge clk); 
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); inAd <= 0;
        @(posedge clk); inAd <= 'hf;
                        @(posedge isReady);
        @(posedge clk); addr <= 'h8765; isWrite <= 0; start <= 1;
        @(posedge clk); start <= 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); inAd <= 0;
        @(posedge clk); inAd <= 'he;
        @(posedge clk); inAd <= 'hd;
        @(posedge clk); inAd <= 'hf;
        @(posedge clk); inAd <= 'hf;
    end
endmodule
