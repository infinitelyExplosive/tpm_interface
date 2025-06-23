`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/30/2024 12:07:48 AM
// Design Name: 
// Module Name: PeripheralStateMachine
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


module PeripheralStateMachine(
    input logic [15:0] periphAddr,
    output logic [7:0] periphInData,
    input logic periphDidWrite,
    input logic periphDidRead,
    input logic [7:0] periphOutData,

    input logic responseBypass,
    input logic bypassPrFifoWren,
    input logic [7:0] hostOutData,

    input logic uartPrFifoWren,
    input logic [7:0] uartRxData,

    input logic pwFifoRden,
    output logic [7:0] pwFifoDout,
    output logic pwFifoEmpty,

    input logic bypassResponseReady,
    input logic uartResponseReady,
    output logic [23:0] stateFifoDout,
    output logic stateFifoEmpty,
    input logic stateFifoRden,

    output logic finishedCommand,
    input logic clk,
    input logic reset
    );

    logic prFifoReset;
    logic [7:0] prFifoDin, prFifoDout;
    logic prFifoWren, prFifoRden, prAlmostEmpty;
    fifo_generator_1 periphReadDataFifo (
        .clk(clk),
        .srst(prFifoReset),
        .din(prFifoDin),
        .wr_en(prFifoWren),
        .rd_en(prFifoRden),
        .dout(prFifoDout),
        .full(),
        .empty(),
        .almost_empty(prAlmostEmpty));
    assign prFifoDin = responseBypass ? hostOutData : uartRxData;
    assign prFifoWren = bypassPrFifoWren || uartPrFifoWren;

    logic pwFifoReset;
    logic [7:0] pwFifoDin;
    logic pwFifoWren;
    fifo_generator_1 periphWriteDataFifo (
        .clk(clk),
        .srst(pwFifoReset),
        .din(pwFifoDin),
        .wr_en(pwFifoWren),
        .rd_en(pwFifoRden),
        .dout(pwFifoDout),
        .full(),
        .empty(pwFifoEmpty),
        .almost_empty());
    assign pwFifoDin = periphOutData;

    logic stateFifoReset;
    logic [23:0] stateFifoDin;
    logic [15:0] stateFifoDinAddr, stateFifoDoutAddr;
    logic [7:0] stateFifoDinData, stateFifoDoutData;
    logic stateFifoWren;
    stateBufFifo stateFifo (
        .clk(clk),
        .srst(stateFifoReset),
        .din(stateFifoDin),
        .wr_en(stateFifoWren),
        .rd_en(stateFifoRden),
        .dout(stateFifoDout),
        .full(),
        .empty(stateFifoEmpty)
    );
    assign stateFifoDin = {stateFifoDinAddr, stateFifoDinData};

    typedef enum {A_IDLE, A_ACTIVE} accessStateEnum;
    accessStateEnum accessState = A_IDLE;

    typedef enum {S_IDLE, S_READY, S_RECEPTION, S_EXECUTION, S_COMPLETION} statusStateEnum;
    statusStateEnum statusState = S_IDLE;
    
    logic [7:0] accessData, statusData;
    logic finalRead = 0;
    logic [7:0] burstDataLow, burstDataHigh;
    logic [15:0] burstData;
    assign {burstDataHigh, burstDataLow} = burstData;
    
    logic [31:0] bytesReceived = 0;
    logic [31:0] commandSize;
    logic [3:0][7:0] commandSizeBytes  = 0;
    assign commandSize = commandSizeBytes;
    
    always_comb begin
        case (periphAddr)
            16'h0000: begin
                periphInData = accessData;
            end
            16'h0018: begin
                periphInData = statusData;
            end
            16'h0019: begin
                periphInData = burstDataLow;
            end
            16'h001a: begin
                periphInData = burstDataHigh;
            end
            16'h001b: begin
                periphInData = 8'h04;
            end
            16'h0024: begin
                periphInData = prFifoDout;
            end
            default: begin
                periphInData = 8'hx;
            end
        endcase
    end

//  Receive data from motherboard logic
    always_ff @(posedge clk) begin
        if (reset) begin
            prFifoRden <= 0;
            pwFifoWren <= 0;
            accessData <=  8'h0;
            statusData <= 8'h84;
            burstData <= 0;
            bytesReceived <= 0;
            commandSizeBytes <= 0;
            accessState <= A_IDLE;
            statusState <= S_IDLE;
            stateFifoDinAddr <= 0;
            stateFifoDinData <= 0;
            stateFifoWren <= 0;
            finalRead <= 0;
            finishedCommand <= 0;
        end else begin
            // handle read FIFO
            if (periphAddr == 16'h0024 && periphDidRead) begin
                prFifoRden <= 1;
                if (prAlmostEmpty) begin
                    finalRead <= 1;
                end
            end else begin
                prFifoRden <= 0;
            end
            // handle write FIFO
            if (periphAddr == 16'h0024 && periphDidWrite) begin
                pwFifoWren <= 1;
            end else begin
                pwFifoWren <= 0;
            end

            stateFifoWren <= 0;

            case (accessState)
                A_IDLE: begin
                    accessData <= 8'h81;
                    if (periphAddr == 16'h0 && periphDidWrite && periphOutData == 8'h02) begin
                        accessState <= A_ACTIVE;
                    end
                end
                A_ACTIVE: begin
                    accessData <= 8'ha1;
                    if (periphAddr == 16'h0 && periphDidWrite && periphOutData == 8'h20) begin
                        accessState <= A_IDLE;
                    end
                end
            endcase

            case (statusState)
                S_IDLE: begin
                    burstData <= 16'h0040;
                    if (periphAddr == 16'h18 && periphDidWrite && periphOutData == 8'h40) begin
                        statusState <= S_READY;
                        statusData <= 8'hc4;
                        stateFifoDinAddr <= 16'h18;
                        stateFifoDinData <= 8'h40;
                        stateFifoWren <= 1;
                        finalRead <= 0;
                    end
                end
                S_READY: begin
                    burstData <= 16'h0040;
                    if (periphAddr == 16'h24 && periphDidWrite) begin
                        statusState <= S_RECEPTION;
                        bytesReceived <= bytesReceived + 1;
                        statusData <= 8'h8c;
                    end
                end
                S_RECEPTION: begin
                    if (periphAddr == 16'h24 && periphDidWrite) begin
                        bytesReceived <= bytesReceived + 1;
                        if (bytesReceived >= 2 && bytesReceived < 6) begin
                            commandSizeBytes[5 - bytesReceived] <= periphOutData;
                        end
                        if (bytesReceived > 6 && bytesReceived == commandSize - 1) begin
                            statusData <= 8'h84;
                        end
                    end
                    if (periphAddr == 16'h18 && periphDidWrite && periphOutData == 8'h20) begin
                        statusData <= 8'h04;
                        statusState <= S_EXECUTION;
                        stateFifoDinAddr <= 16'h18;
                        stateFifoDinData <= 8'h20;
                        stateFifoWren <= 1;
                    end
                end
                S_EXECUTION: begin
                    if (bypassResponseReady || uartResponseReady) begin
                        statusData <= 8'h94;
                    end
                    if (finalRead) begin
                        statusData <= 8'h84;
                        statusState <= S_COMPLETION;
                    end
                end
                S_COMPLETION: begin
                    if (periphAddr == 16'h18 && periphDidWrite && periphOutData == 8'h40) begin
                        statusState <= S_IDLE;
                        finishedCommand <= 1;
                    end
                end
            endcase
        end
    end
    
endmodule
