`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/02/2025 10:08:12 PM
// Design Name: 
// Module Name: top2
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


module top2(
    inout logic [5:0] ja,
    output logic [3:0] led,
    input logic CLK100MHZ,
    output logic uart_rxd_out,
    input logic uart_txd_in,
    input logic [3:0] sw

    );
    logic clk;
    logic output_clk;
    if (DEBUG) begin
        assign clk = CLK100MHZ;
    end else begin
    clk_wiz_0 clkGen (
        .clk_out1(clk),
        .reset(),
        .locked(),
        .clk_in1(CLK100MHZ)
    );
    end
    
    clk_wiz_1 outputClk (
        .clk_out1(output_clk),
        .reset(),
        .locked(),
        .clk_in1(clk)
    );
    assign ja[4] = output_clk;
endmodule
