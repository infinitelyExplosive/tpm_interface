`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/08/2023 06:50:37 PM
// Design Name: 
// Module Name: TPMManager
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

module TPMManager(
    input logic clk,
    input logic reset,
    input logic [15:0] periphAddr,
    output logic [7:0] periphInData,
    input logic [7:0] periphOutData,
    input logic periphDidWrite,
    input logic periphDidRead,
    output logic [15:0] hostAddr,
    output logic [7:0] hostInData,
    input logic [7:0] hostOutData,
    output logic hostIsWrite,
    input logic hostIsReady,
    output logic hostStart,
    input logic hostGotResponse,
    input logic uartDataValid,
    input logic [7:0] uartRxData,
    output logic [7:0] uartTxData,
    output logic uartTxSend,
    input logic uartTxReady,
    output logic debugDone
    );

    logic finishedCommand;
    logic internalReset;
    logic internalResetSignal;
    assign internalResetSignal = reset | internalReset;

    logic [7:0] accessData;
    logic [7:0] pwFifoDout, hrFifoDout;
    logic pwFifoRden, hrFifoRden;
    logic pwFifoEmpty, hrFifoEmpty;

    logic [23:0] stateFifoDout;
    logic stateFifoEmpty, stateFifoRden;
    
    logic hostShouldSend;
    logic hostShouldGo;

    logic hwFifoWren;

    logic bypassPrFifoWren;
    logic bypassResponseReady;
    
    typedef enum {TX_IDLE, PERIPH_HEADER, PERIPH_BYTE, HOST_HEADER, HOST_BYTE} uartTxStateEnum;
    uartTxStateEnum uartTxState = TX_IDLE;
    logic uartPrFifoWren = 0;
    logic uartResponseReady = 0;
    logic responseBypass = 0;

    HostStateMachine hostStateMachine (
        .hostAddr(hostAddr),
        .hostInData(hostInData),
        .hostOutData(hostOutData),
        .hostGotResponse(hostGotResponse),
        .hostIsWrite(hostIsWrite),
        .hostStart(hostStart),
        .hostIsReady(hostIsReady),
        .responseBypass(responseBypass),
        .bypassPrFifoWren(bypassPrFifoWren),
        .bypassResponseReady(bypassResponseReady),
        .uartRxData(uartRxData),
        .stateFifoDout(stateFifoDout),
        .stateFifoEmpty(stateFifoEmpty),
        .stateFifoRden(stateFifoRden),
        .hrFifoRden(hrFifoRden),
        .hrFifoDout(hrFifoDout),
        .hrFifoEmpty(hrFifoEmpty),
        .hwFifoWren(hwFifoWren),
        .hostShouldSend(hostShouldSend),
        .hostShouldGo(hostShouldGo),
        .clk(clk),
        .reset(internalResetSignal),
        .debugDone(debugDone)
    );

    PeripheralStateMachine peripheralStateMachine (
        .periphAddr(periphAddr),
        .periphInData(periphInData),
        .periphDidWrite(periphDidWrite),
        .periphDidRead(periphDidRead),
        .periphOutData(periphOutData),
        .responseBypass(responseBypass),
        .bypassPrFifoWren(bypassPrFifoWren),
        .hostOutData(hostOutData),
        .uartPrFifoWren(uartPrFifoWren),
        .uartRxData(uartRxData),
        .pwFifoRden(pwFifoRden),
        .pwFifoDout(pwFifoDout),
        .pwFifoEmpty(pwFifoEmpty),
        .bypassResponseReady(bypassResponseReady),
        .uartResponseReady(uartResponseReady),
        .stateFifoDout(stateFifoDout),
        .stateFifoEmpty(stateFifoEmpty),
        .stateFifoRden(stateFifoRden),
        .finishedCommand(finishedCommand),
        .clk(clk),
        .reset(internalResetSignal)
    );

    always_ff @(posedge clk) begin
        if (reset) begin
            internalReset <= 0;
        end else begin
            if (finishedCommand) begin
                internalReset <= 1;
            end
            if (internalReset) begin
                internalReset <= 0;
            end
        end
    end



//  ************************
//  * UART MANAGEMENT *

    logic [7:0] delay;

    always_ff @(posedge clk) begin
        if (internalResetSignal) begin
            uartTxState <= TX_IDLE;
            pwFifoRden <= 0;
            hrFifoRden <= 0;
            uartTxData <= 0;
            uartTxSend <= 0;
            delay <= 0;
        end else if (delay > 0) begin
            uartTxSend <= 0;
            delay <= delay - 1;
        end else begin
            uartTxSend <= 0;
            case (uartTxState)
                TX_IDLE: begin
                    pwFifoRden <= 0;
                    hrFifoRden <= 0;
                    if (!pwFifoEmpty) begin
                        uartTxState <= PERIPH_HEADER;
                    end else if (!hrFifoEmpty && !responseBypass) begin
                        uartTxState <= HOST_HEADER;
                    end
                end
                PERIPH_HEADER: begin
                    if (uartTxReady) begin
                        uartTxData <= 8'h01;
                        uartTxSend <= 1;
                        delay <= 3;
                        uartTxState <= PERIPH_BYTE;
                    end
                end
                PERIPH_BYTE: begin
                    if (uartTxReady) begin
                        uartTxData <= pwFifoDout;
                        uartTxSend <= 1;
                        delay <= 3;
                        pwFifoRden <= 1;
                        uartTxState <= TX_IDLE;
                    end
                end
                HOST_HEADER: begin
                    if (uartTxReady) begin
                        uartTxData <= 8'h02;
                        uartTxSend <= 1;
                        delay <= 3;
                        uartTxState <= HOST_BYTE;
                    end
                end
                HOST_BYTE: begin
                    if (uartTxReady) begin
                        uartTxData <= hrFifoDout;
                        uartTxSend <= 1;
                        delay <= 3;
                        hrFifoRden <= 1;
                        uartTxState <= TX_IDLE;
                    end
                end
            endcase
        end
    end

    typedef enum {RX_IDLE, RX_HOSTWRITE, RX_PERIPHREAD} uartRxStateEnum;
    uartRxStateEnum uartRxState = RX_IDLE;


    always_ff @(posedge clk) begin
        if (internalResetSignal) begin 
            uartRxState <= RX_IDLE;
            uartPrFifoWren <= 0;
            hwFifoWren <= 0;
            hostShouldSend <= 0;
            hostShouldGo <= 0;
            responseBypass <= 0;
            uartResponseReady <= 0;
        end else begin
            uartPrFifoWren <= 0;
            hwFifoWren <= 0;

            case (uartRxState)
                RX_IDLE: begin
                    if (uartDataValid) begin
                        if (uartRxData == 8'h01) begin
                            uartRxState <= RX_HOSTWRITE;
                        end else if (uartRxData == 8'h02) begin
                            uartRxState <= RX_PERIPHREAD;
                        end else if (uartRxData == 8'h04) begin
                            hostShouldSend <= 1;
                        end else if (uartRxData == 8'h08) begin
                            hostShouldGo <= 1;
                        end else if (uartRxData == 8'h10) begin
                            responseBypass <= 1;
                        end else if (uartRxData == 8'h20) begin
                            responseBypass <= 0;
                        end else if (uartRxData == 8'h40) begin
                            uartResponseReady <= 1;
                        end
                    end
                end
                RX_HOSTWRITE: begin
                    if (uartDataValid) begin
                        hwFifoWren <= 1;
                        uartRxState <= RX_IDLE;
                    end
                end
                RX_PERIPHREAD: begin
                    if (uartDataValid && !responseBypass) begin
                        uartPrFifoWren <= 1;
                        uartRxState <= RX_IDLE;
                    end
                end
            endcase
        end
    end

    
endmodule
