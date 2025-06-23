`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2024 06:01:39 PM
// Design Name: 
// Module Name: TristateTest
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


module TristateTest(
    input logic CLK100MHZ,
    inout logic [3:0] ja,
    input logic [3:0] sw,
    output logic [3:0] led
    );

    logic [3:0] sw_buffer;

    logic [3:0] ja_in;
    logic [3:0] ja_out;
    logic enable;

    assign ja = enable ? ja_out: 4'bZZZZ;
    assign ja_in = ja;

    always_ff @(posedge CLK100MHZ) begin
        sw_buffer <= sw;
        enable <= sw_buffer[3];
    end

    assign led = ja_in;

    always_ff @(posedge CLK100MHZ) begin
        case (sw_buffer[2:0])
            3'b000: ja_out <= 4'b0000;
            3'b001: ja_out <= 4'b1111;
            3'b010: ja_out <= 4'b1100;
            3'b011: ja_out <= 4'b0011;
            3'b100: ja_out <= 4'b0001;
            3'b101: ja_out <= 4'b0010;
            3'b110: ja_out <= 4'b0100;
            3'b111: ja_out <= 4'b1000;
        endcase
    end
endmodule
