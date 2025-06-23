`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/07/2023 04:38:13 PM
// Design Name: 
// Module Name: testbench_UART
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


module testbench_UART(
    );

    logic clk, reset, rxd, txd, dataValid;
    logic [7:0] rxData, txData;
    logic txSend, txReady;

    parameter CLK_PERIOD = 10;
    initial begin
        clk <= 0;
        forever begin
            #(CLK_PERIOD/2) clk <= ~clk;
        end
    end

    UART #(.DEBUG(1)) dut (.*);

    localparam CYCLES = 5;

    initial begin
        @(posedge clk); reset <= 1; rxd <= 1; txData <= 0; txSend <= 0;
        @(posedge clk); reset <= 0;
        @(posedge clk);
        @(posedge clk); rxd <= 0;
        repeat(CYCLES) @(posedge clk); rxd <= 0;
        repeat(CYCLES) @(posedge clk); rxd <= 0;
        repeat(CYCLES) @(posedge clk); rxd <= 0;
        repeat(CYCLES) @(posedge clk); rxd <= 0;
        repeat(CYCLES) @(posedge clk); rxd <= 0;
        repeat(CYCLES) @(posedge clk); rxd <= 0;
        repeat(CYCLES) @(posedge clk); rxd <= 0;
        repeat(CYCLES) @(posedge clk); rxd <= 0;
        repeat(CYCLES) @(posedge clk); rxd <= 0;
        repeat(CYCLES) @(posedge clk); rxd <= 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); txData <= 8'd00; txSend <= 1;
        @(posedge clk); txSend <= 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
    end
endmodule
