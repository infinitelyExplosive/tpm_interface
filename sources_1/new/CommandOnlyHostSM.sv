`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/30/2024 12:07:48 AM
// Design Name: 
// Module Name: CommandOnlyHostSM
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


module CommandOnlyHostSM(
    output logic [15:0] hostAddr,
    output logic [7:0] hostInData,
    input logic [7:0] hostOutData,
    input logic hostGotResponse,
    output logic hostIsWrite,
    output logic hostStart,
    input logic hostIsReady,

    input logic [7:0] uartRxData,

    input logic hrFifoRden,
    output logic [7:0] hrFifoDout,
    (* MARK_DEBUG = "TRUE" *) output logic hrFifoEmpty,
    input logic hwFifoWren,
    input logic hostShouldSend,
    input logic hostShouldGo,
    output logic requestSent,
    output logic commandDone,
    input logic clk,
    input logic reset
    
    ,output logic debugSignal
    );

    assign debugSignal = hwFifoEmpty;
    
    logic [7:0] hrFifoDin;
    logic hrFifoWren;
    fifo_generator_1 hostReadDataFifo (
        .clk(clk),
        .srst(reset),
        .din(hrFifoDin),
        .wr_en(hrFifoWren),
        .rd_en(hrFifoRden),
        .dout(hrFifoDout),
        .full(),
        .empty(hrFifoEmpty),
        .almost_empty());
    assign hrFifoDin = hostOutData;

    logic [7:0] hwFifoDin, hwFifoDout;
    (* MARK_DEBUG = "TRUE" *) logic hwFifoRden;
    (* MARK_DEBUG = "TRUE" *) logic hwFifoEmpty;
    fifo_generator_1 hostWriteDataFifo (
        .clk(clk),
        .srst(reset),
        .din(hwFifoDin),
        .wr_en(hwFifoWren),
        .rd_en(hwFifoRden),
        .dout(hwFifoDout),
        .full(),
        .empty(hwFifoEmpty),
        .almost_empty());
    assign hwFifoDin = uartRxData;

    typedef enum {H_IDLE, H_SENDING, H_EXECUTION, H_AWAITING, H_READING, H_RECEIVED, H_RELINQUISH, H_DONE} hostStateEnum;
    (* MARK_DEBUG = "TRUE" *) hostStateEnum hostState = H_IDLE;
    assign requestSent = hostStart == H_SENDING && hwFifoEmpty;
    assign commandDone = hostState == H_DONE;

    (* MARK_DEBUG = "TRUE" *) logic [7:0] idleCount = 0;
    (* MARK_DEBUG = "TRUE" *) logic [31:0] bytesRead = 0;
    (* MARK_DEBUG = "TRUE" *) logic [31:0] responseSize;
    (* MARK_DEBUG = "TRUE" *) logic [3:0][7:0] responseSizeBytes = 0;
    assign responseSize = responseSizeBytes;


    always_ff @(posedge clk) begin
        if (hostGotResponse && hostAddr == 16'h24) begin
            hrFifoWren <= 1;
        end else begin
            hrFifoWren <= 0;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            hostState <= H_IDLE;
            idleCount <= 0;
            hostIsWrite <= 0;
            hostStart <= 0;
            hwFifoRden <= 0;
            hostAddr <= 0;
            hostInData <= 0;
            bytesRead <= 0;
            responseSizeBytes <= 0;
        end else begin
            hostStart <= 0;
            hwFifoRden <= 0;
            if (hostIsReady) begin
                if (idleCount > 0) begin
                    idleCount <= idleCount - 1;
                end else begin
                    idleCount <= 2;
                    case (hostState)
                        H_IDLE: begin
                            bytesRead <= 0;
                            idleCount <= 0;
                            responseSizeBytes <= 0;
                            if (hostShouldSend) begin
                                hostState <= H_SENDING;
                            end
                        end
                        H_SENDING: begin
                            if (!hwFifoEmpty) begin
                                hostAddr <= 16'h24;
                                hostInData <= hwFifoDout;
                                idleCount <= 2;
                                hostIsWrite <= 1;
                                hostStart <= 1;
                                hwFifoRden <= 1;
                            end else if (hwFifoEmpty && hostShouldGo) begin
                                hostState <= H_EXECUTION;
                            end
                        end
                        H_EXECUTION: begin
                            hostAddr <= 16'h18;
                            hostInData <= 8'h20;
                            hostIsWrite <= 1;
                            hostStart <= 1;
                            hostState <= H_AWAITING;
                        end
                        H_AWAITING: begin
                            hostAddr <= 16'h18;
                            hostIsWrite <= 0;
                            hostStart <= 1;
                            idleCount <= 500;
                        end
                        H_READING: begin
                            hostAddr <= 16'h24;
                            hostIsWrite <= 0;
                            hostStart <= 1;
                            idleCount <= 10;
                        end
                        H_RECEIVED: begin
                            hostAddr <= 16'h18;
                            hostInData <= 8'h40;
                            hostIsWrite <= 1;
                            hostStart <= 1;
                            hostState <= H_RELINQUISH;
                        end
                        H_RELINQUISH: begin
                            hostAddr <= 16'h0;
                            hostInData <= 8'h20;
                            hostIsWrite <= 1;
                            hostStart <= 1;
                            hostState <= H_DONE;
                        end
                        H_DONE: begin
                            hostState <= H_IDLE;
                        end
                    endcase
                end
            end else begin 
                // host not ready (may return read data)
                if (hostState == H_AWAITING && hostGotResponse && hostAddr == 16'h18 && hostOutData == 8'h94) begin
                    hostState <= H_READING;
                end else if (hostState == H_READING && hostGotResponse && hostAddr == 16'h24) begin
                    bytesRead <= bytesRead + 1;
                    if (bytesRead >= 2 && bytesRead < 6) begin
                        responseSizeBytes[5 - bytesRead] <= hostOutData;
                    end
                    if (bytesRead > 6 && bytesRead >= responseSize - 1) begin
                        hostState <= H_RECEIVED;
                    end
                end
            end
        end
    end
endmodule
