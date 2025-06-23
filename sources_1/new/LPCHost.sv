`timescale 1ns / 100ps

/* LPC Host, sends TPM read/write requests

inAd: LAD measurement read by host
outAd: LAD values written if `enable` is high
frame: LFRAME#
addr: address to be used in request
inData: data to be written in write request
outData: data read from read request, valid once `isReady`
isWrite: direction of request
*/
module LPCHost(
    input logic [3:0] inAd,
    output logic [3:0] outAd,
    output logic enable,
    input logic clk,
    output logic frame,
    input logic [15:0] addr,
    input logic [7:0] inData,
    output logic [7:0] outData,
    input logic isWrite,
    output logic isReady,
    input logic start,
    output logic gotResponse,
    input logic reset
);
    typedef enum {IDLE, DIRECTION, ADDR, DATA, TAR1, SYNC, TAR2} stateEnum;
    
    logic [3:0][3:0] addrNibbles;
    assign addrNibbles = addr;
    logic [1:0][3:0] inDataNibbles;
    assign inDataNibbles = inData;
    logic [1:0][3:0] outDataNibbles;
    assign outData = outDataNibbles;

    stateEnum state = IDLE;
    stateEnum nextState = IDLE;
    logic [2:0] cyclesLeft = 0;
    logic [2:0] nextCycles = 0;

    assign isReady = ~reset & state == IDLE;

    always_comb begin
        nextCycles = 3'd0;
        nextState = IDLE;
        case (state)
            IDLE: begin
                if (start) begin
                    nextState = DIRECTION;
                end else begin
                    nextState = IDLE;
                end
            end
            DIRECTION: begin
                nextState = ADDR;
                nextCycles = 3'd3;
            end
            ADDR: begin
                if (isWrite == 1'b1) begin
                    nextState = DATA;
                end else begin
                    nextState = TAR1;
                end
                nextCycles = 3'd1;
            end
            DATA: begin
                if (isWrite == 1'b1) begin
                    nextState = TAR1;
                end else begin
                    nextState = TAR2;
                end
                nextCycles = 3'd1;
            end
            TAR1: begin
                nextState = SYNC;
                nextCycles = 3'd1; // THIS IS NOT SAME AS ACTUAL PROTOCOL
                                    // ADDS 1 DELAY SO RESPONSE DATA HAS CAN BE READ
                                    // IN CORRECTLY NAMED STATE 
            end
            SYNC: begin
                if (isWrite == 1'b1) begin
                    nextState = TAR2;
                end else begin
                    nextState = DATA;
                end
                nextCycles = 3'd1;
            end
            TAR2: begin
                nextState = IDLE;
            end
        endcase
    end

    always_ff @( posedge clk ) begin : main_loop
        if (reset) begin
            state <= IDLE;
            outAd <= 0;
            enable <= 0;
            frame <= 1;
            outDataNibbles <= 0;
            cyclesLeft <= 0;
            gotResponse <= 0;
        end else begin
            if (cyclesLeft > 0) begin
                cyclesLeft <= cyclesLeft - 1;
            end else begin
                state <= nextState;
                cyclesLeft <= nextCycles;
            end

            case (state)
                IDLE: begin
                    gotResponse <= 0;
                    if (start) begin
                        outAd <= 4'b0101;
                        enable <= 1'b1;
                        frame <= 1'b0;
                    end
                end
                DIRECTION: begin
                    if (isWrite == 1'b1) begin
                        outAd <= 4'b0010;
                    end else begin
                        outAd <= 4'd0;
                    end
                    frame <= 1'b1;
                end
                ADDR: begin
                    outAd <= addrNibbles[cyclesLeft];
                end
                DATA: begin
                    if (isWrite == 1'b1) begin
                        outAd <= inDataNibbles[1 - cyclesLeft];
                    end else begin
                        outDataNibbles[1 - cyclesLeft] <= inAd;
                    end
                end
                TAR1: begin
                    outAd <= 4'b1111;
                    if (cyclesLeft == 1'd0) begin
                        enable <= 1'b0;
                    end
                end
                SYNC: begin
                end
                TAR2: begin
                    if (!isWrite) begin
                        gotResponse <= 1;
                    end
                end
            endcase
        end
    end

endmodule

