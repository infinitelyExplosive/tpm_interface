`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2023 09:57:45 PM
// Design Name: 
// Module Name: UART
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


module UART #(
    parameter BAUD=460800,
    parameter WIDTH=8,
    parameter DEBUG=0
)(
    input logic clk,
    input logic reset,
    input logic rxd,
    output logic txd,
    output logic dataValid,
    output logic [7:0] rxData,
    input logic [7:0] txData,
    input logic txSend,
    output logic txReady
    );
    
    localparam CLK_FREQ = 25_000_000;
    localparam CYCLES_PER_BIT = (DEBUG == 1) ? 5 : CLK_FREQ/BAUD;
    
    logic [WIDTH-1:0] txDataInternal;
    logic [31:0] txCounter = 0;
    logic [31:0] rxCounter = 0;
    logic [31:0] rxAccumulator = 0;
    logic [3:0] txIndex = 0;
    logic [3:0] rxIndex = 0;
    
    typedef enum {IDLE, START, DATA, PARITY, STOP} state_enum;
    
    state_enum txState = IDLE;
    state_enum rxState = IDLE;

    assign txReady = (txState == IDLE);
    
    always_ff @(posedge clk) begin
        // tx logic
        if (reset) begin
            txDataInternal <= 8'b0;
            txCounter <= 8'b0;
            txIndex <= 4'b0;
            txd <= 1'b1;
            txState <= IDLE;
        end else case (txState)
            IDLE: begin
                if (txSend == 1) begin
                    txDataInternal <= txData;
                    txCounter <= 8'b0;
                    txIndex <= 4'b0;
                    txState <= START;
                end
            end
            START: begin
                txd <= 1'b0;
                if (txCounter < CYCLES_PER_BIT - 1) begin
                    txCounter <= txCounter + 1;
                end else begin
                    txCounter <= 0;
                    txState <= DATA;
                end
            end
            DATA: begin
                txd <= txDataInternal[txIndex];
                if (txCounter < CYCLES_PER_BIT - 1) begin
                    txCounter <= txCounter + 1;
                end else begin
                    txCounter <= 0;
                    if (txIndex < WIDTH - 1) begin
                        txIndex <= txIndex + 1;
                    end else begin
                        txState <= PARITY;
                    end 
                end
            end
            PARITY: begin
                txd <= txDataInternal[0]
                       ^ txDataInternal[1]
                       ^ txDataInternal[2]
                       ^ txDataInternal[3]
                       ^ txDataInternal[4]
                       ^ txDataInternal[5]
                       ^ txDataInternal[6]
                       ^ txDataInternal[7];
                if (txCounter < CYCLES_PER_BIT - 1) begin
                    txCounter <= txCounter + 1;
                end else begin
                    txCounter <= 0;
                    txState <= STOP;
                end
            end
            STOP: begin
                txd <= 1'b1;
                if (txCounter < CYCLES_PER_BIT - 1) begin
                    txCounter <= txCounter + 1;
                end else begin
                    txCounter <= 0;
                    txState <= IDLE;
                end
            end 
        endcase

        // rx logic
        if (reset) begin
            rxCounter <= 0;
            rxAccumulator <= 0;
            rxData <= 0;
            rxIndex <= 0;
            rxState <= IDLE;
            dataValid <= 0;
        end else case (rxState)
            IDLE: begin
                dataValid <= 0;
                if (rxd == 0) begin
                    rxCounter <= 0;
                    rxIndex <= 0;
                    rxState <= START;
                end
            end
            START: begin
                if (rxCounter < CYCLES_PER_BIT - 1) begin
                    if (rxd == 1) begin
                        rxAccumulator <= rxAccumulator + 1;
                    end
                    rxCounter <= rxCounter + 1;
                end else begin
                    rxCounter <= 0;
                    rxAccumulator <= 0;
                    if (rxAccumulator < CYCLES_PER_BIT / 2) begin
                        rxState <= DATA;
                    end else begin
                        rxState <= IDLE;
                    end
                end
            end
            DATA: begin
                if (rxCounter < CYCLES_PER_BIT - 1) begin
                    if (rxd == 1) begin
                        rxAccumulator <= rxAccumulator + 1;
                    end
                    rxCounter <= rxCounter + 1;
                end else begin
                    rxCounter <= 0;
                    rxAccumulator <= 0;
                    rxData[rxIndex] <= rxAccumulator > CYCLES_PER_BIT / 2;
                    if (rxIndex < WIDTH - 1) begin
                        rxIndex <= rxIndex + 1;
                    end else begin
                        rxState <= PARITY;
                    end 
                end
            end
            PARITY: begin
                if (rxCounter < CYCLES_PER_BIT - 1) begin
                    if (rxd == 1) begin
                        rxAccumulator <= rxAccumulator + 1;
                    end
                    rxCounter <= rxCounter + 1;
                end else begin
                    rxCounter <= 0;
                    rxAccumulator <= 0;
                    if (rxData[0]
                        ^ rxData[1]
                        ^ rxData[2]
                        ^ rxData[3]
                        ^ rxData[4]
                        ^ rxData[5]
                        ^ rxData[6] 
                        ^ rxData[7]
                        ^ ((rxAccumulator > CYCLES_PER_BIT / 2) ? 1'b1 : 1'b0) == 1'b0) begin
                        rxState <= STOP;
                    end else begin
                        rxState <= IDLE;
                    end
                end
            end
            STOP: begin
                if (rxCounter < CYCLES_PER_BIT - 1) begin
                    if (rxd == 1) begin
                        rxAccumulator <= rxAccumulator + 1;
                    end
                    rxCounter <= rxCounter + 1;
                end else begin
                    dataValid <= 1;
//                    if (rxAccumulator > CYCLES_PER_BIT / 2) begin
//                    end
                    rxAccumulator <= 0;
                    rxCounter <= 0;
                    rxState <= IDLE;
                end
            end 
        endcase
    end
endmodule
