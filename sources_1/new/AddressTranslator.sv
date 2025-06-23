`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2023 04:42:14 PM
// Design Name: 
// Module Name: AddressTranslator
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


module AddressTranslator(
    input [3:0] inAd,
    output [3:0] outAd,
    output enable,
    input clk,
    input frame,
    output [15:0] addr,
    input [7:0] inData,
    output [7:0] outData,
    output didWrite,
    output didRead
    );
endmodule
