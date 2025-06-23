`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2023 12:16:44 AM
// Design Name: 
// Module Name: RSA
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


module BigIntMult(
    input logic clk,
    input logic [5:0] aAddr,
    input logic [63:0] aData,
    input logic [5:0] bAddr,
    input logic [63:0] bData,
    input logic start,
    output logic [5:0] rAddr,
    output logic [63:0] rData,
    output logic rWen,
    output logic [63:0] result,
    input logic reset
);

endmodule

module RSA(
    input logic clk,
    input logic reset
    );

    // module bigIntMult
endmodule
