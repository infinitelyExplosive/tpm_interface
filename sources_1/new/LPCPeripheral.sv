`timescale 1ns / 100ps

/* LPC Peripheral, receives TPM read/write requests

inAd: LAD measurement read by host
outAd: LAD values written if `enable` is high
frame: LFRAME#
addr: address specified in request
inData: data to be returned in read request
outData: data recieved from write request, valid once `isReady`
didWrite: asserted for 1 cycle when write finishes
didRead: asserted for 1 cycle when read finishes
*/
module LPCPeripheral(
    input logic [3:0] inAd,
    output logic [3:0] outAd,
    output logic enable,
    input logic clk,
    input logic frame,
    output logic [15:0] addr,
    input logic [7:0] inData,
    output logic [7:0] outData,
    output logic didWrite,
    output logic didRead,
    input logic reset
    );
    typedef enum {IDLE, DIRECTION, ADDR, DATA, TAR1, SYNC, TAR2} stateEnum;

    logic [3:0][3:0] addrNibbles;
    assign addr = addrNibbles;
    logic [1:0][3:0] inDataNibbles;
    assign inDataNibbles = inData;
    logic [1:0][3:0] outDataNibbles;
    assign outData = outDataNibbles;

    stateEnum state = IDLE;
    stateEnum nextState = IDLE;
    logic [2:0] cyclesLeft = 0;
    logic [2:0] nextCycles = 0;

    logic isWrite;

    always_comb begin
        nextCycles = 3'd0;
        case (state)
            IDLE: begin
                if (~frame) begin
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
                    nextCycles = 3'd1;
                end else begin
                    nextState = TAR1;
                end
            end
            DATA: begin
                if (isWrite == 1'b1) begin
                    nextState = TAR1; //timing hack to send response 1 cycle early
                end else begin
                    nextState = TAR2;
                    nextCycles = 3'd1;
                end
            end
            TAR1: begin
                nextState = SYNC;
                // nextCycles = 3'd1; // THIS IS NOT SAME AS ACTUAL PROTOCOL
                //                     // ADDS 1 DELAY SO RESPONSE DATA HAS CAN BE READ
                //                     // IN CORRECTLY NAMED STATE 
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
            outData <= 0;
            addr <= 0;
            didWrite <= 0;
            didRead <= 0;
            cyclesLeft <= 0;
            isWrite <= 0;
        end else begin
            if (cyclesLeft > 0) begin
                cyclesLeft <= cyclesLeft - 1;
            end else begin
                state <= nextState;
                cyclesLeft <= nextCycles;
            end

            case (state)
                IDLE: begin
                    didWrite <= 1'b0;
                    didRead <= 1'b0;
                end
                DIRECTION: begin
                    isWrite <= inAd[1];
                end
                ADDR: begin
                    addrNibbles[cyclesLeft] <= inAd;
                end
                DATA: begin
                    if (isWrite == 1'b1) begin
                        outDataNibbles[1 - cyclesLeft] <= inAd;
                    end else begin
                        outAd <= inDataNibbles[1 - cyclesLeft];
                    end
                end
                TAR1: begin
                end
                SYNC: begin
                    outAd <= 4'd0;
                    enable <= 1'b1;
                end
                TAR2: begin
                    outAd <= 4'b1111;
                    if (cyclesLeft == 1'b0) begin
                        enable <= 1'b0;
                        if (isWrite == 1) begin
                            didWrite <= 1'b1;
                        end else begin
                            didRead <= 1'b1;
                        end
                    end
                end
            endcase
        end
    end

endmodule
