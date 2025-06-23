`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2023 05:22:12 PM
// Design Name: 
// Module Name: testbench_LPCPeripheral
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


module testbench_LPCPeripheral(

    );
    logic [3:0] ad;
    logic [3:0] inAd;
    logic [3:0] outAd;
    logic enable;
    logic clk;
    logic frame;
    logic [15:0] addr;
    logic [7:0] inData;
    logic [7:0] outData;
    logic didWrite;
    logic didRead;
    logic reset;
    
    assign ad = enable ? outAd : inAd;

    LPCPeripheral dut (
        .inAd(inAd),
        .outAd(outAd),
        .enable(enable),
        .clk(clk),
        .frame(frame),
        .addr(addr),
        .inData(inData),
        .outData(outData),
        .didWrite(didWrite),
        .didRead(didRead),
        .reset(reset)
    );

    always_comb begin
        case (addr)
            16'h1234: begin
                inData = 8'hab;
            end
            16'h5678: begin
                inData = 8'hcd;
            end
            default: begin
                inData = 8'hee;
            end
        endcase
    end
    

    parameter CLK_PERIOD = 10;
    initial begin
        clk <= 0;
        for (int i = 0; i < 150; i++) begin
            #(CLK_PERIOD/2) clk <= ~clk;
        end
    end

    initial begin
        inAd <= 4'hf; frame <= 1; reset <= 0;
        @(posedge clk); reset <= 1;
        @(posedge clk);
        @(posedge clk); reset <= 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); inAd <= 4'b0101; frame <= 0;
        @(posedge clk); inAd <= 4'b0010; frame <= 1;
        @(posedge clk); inAd <= 4'h2;
        @(posedge clk); inAd <= 4'h4;
        @(posedge clk); inAd <= 4'h6;
        @(posedge clk); inAd <= 4'h8;
        @(posedge clk); inAd <= 4'he;
        @(posedge clk); inAd <= 4'h9;
        @(posedge clk); inAd <= 4'b1111;
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
        @(posedge clk); inAd <= 4'b0101; frame <= 0;
        @(posedge clk); inAd <= 4'b0000; frame <= 1;
        @(posedge clk); inAd <= 4'h1;
        @(posedge clk); inAd <= 4'h2;
        @(posedge clk); inAd <= 4'h3;
        @(posedge clk); inAd <= 4'h4;
        @(posedge clk); inAd <= 4'b1111;
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
        @(posedge clk); inAd <= 4'b0101; frame <= 0;
        @(posedge clk); inAd <= 4'b0000; frame <= 1;
        @(posedge clk); inAd <= 4'h5;
        @(posedge clk); inAd <= 4'h6;
        @(posedge clk); inAd <= 4'h7;
        @(posedge clk); inAd <= 4'h8;
        @(posedge clk); inAd <= 4'b1111;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
    end


endmodule
