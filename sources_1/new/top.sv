`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2023 11:00:57 PM
// Design Name: 
// Module Name: top
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


module top #(DEBUG=0)
(
    inout logic [5:0] ja,
    output logic [3:0] led,
    input logic CLK100MHZ,
    output logic uart_rxd_out,
    input logic uart_txd_in,
    input logic [3:0] sw
    );
    
    logic clk;
    logic output_clk;
    if (DEBUG) begin
        assign clk = CLK100MHZ;
    end else begin
    clk_wiz_0 clkGen (
        .clk_out1(clk),
        .reset(),
        .locked(),
        .clk_in1(CLK100MHZ)
    );
    end
    
    clk_wiz_1 outputClk (
        .clk_out1(output_clk),
        .reset(),
        .locked(),
        .clk_in1(clk)
    );

    logic reset;
    logic [3:0] sw_buffered;
    always_ff @(posedge clk) begin
        sw_buffered <= sw;
    end
    assign reset = sw_buffered[3];

    (* MARK_DEBUG = "TRUE" *) logic dataValid;
    logic txSend, txReady;
    (* MARK_DEBUG = "TRUE" *) logic [7:0] txData, rxData;

    UART #(.DEBUG(DEBUG)) uartTransmitter (
        .clk(clk),
        .reset(reset),
        .rxd(uart_txd_in),
        .txd(uart_rxd_out),
        .dataValid(dataValid),
        .rxData(rxData),
        .txData(txData),
        .txSend(txSend),
        .txReady(txReady)
    );

    // logic [63:0] counter;
    // always_ff @(posedge CLK100MHZ) begin
    //     if (counter < 50_000_000)
    //     // if (counter < 400)
    //         counter <= counter + 1;
    //     else
    //         counter <= 0;
        
    //     if (counter == 30000) begin
    //         txSend <= 1;
    //     end else begin
    //         txSend <= 0;
    //     end
    // end
    
    // assign txSend = counter == 30000;
    // assign txData = 8'h31;
    // assign led[0] = counter < 25_000_000;
    // assign txSend = counter == 399;
    // assign txData = 8'h31;
    // assign led[0] = counter < 200;
    
    
    // LPC assert
    
    logic [3:0] hostInAd;
    (* MARK_DEBUG = "TRUE" *) logic [3:0] hostOutAd;
    logic hostEnable;
    logic [15:0] controlHostAddr;
    logic [7:0] controlHostInData, hostOutData;
    logic controlHostIsWrite, hostIsReady, controlHostStart, hostGotResponse;
    logic frame;
    
    assign ja[4] = output_clk;
    assign ja[5] = frame;
    
    
//    assign {ja[4], ja[3], ja[2], ja[5]} = hostEnable ? hostOutAd : 4'bzzzz;

//    assign hostInAd = {ja[4], ja[3], ja[2], ja[5]};
    IOBUF buf1(.O(hostInAd[3]), .I(hostOutAd[3]), .IO(ja[3]), .T(~hostEnable));
    IOBUF buf2(.O(hostInAd[2]), .I(hostOutAd[2]), .IO(ja[2]), .T(~hostEnable));
    IOBUF buf3(.O(hostInAd[1]), .I(hostOutAd[1]), .IO(ja[1]), .T(~hostEnable));
    IOBUF buf4(.O(hostInAd[0]), .I(hostOutAd[0]), .IO(ja[0]), .T(~hostEnable));
    
//    assign led[0] = hostIsWrite;
//    assign led[1] = hostAddr == 0;
//    assign led[2] = hostAddr == 16'h18;
//    assign led[3] = hostAddr == 16'h24;
    
    (* MARK_DEBUG = "TRUE" *) logic [15:0] hostAddr;
    (* MARK_DEBUG = "TRUE" *) logic [7:0] hostInData;
    (* MARK_DEBUG = "TRUE" *) logic hostIsWrite;
    (* MARK_DEBUG = "TRUE" *) logic hostStart;
    LPCHost lpcHost (
        .inAd(hostInAd),
        .outAd(hostOutAd),
        .enable(hostEnable),
        .clk(clk),
        .frame(frame),
        .addr(hostAddr),
        .inData(hostInData),
        .outData(hostOutData),
        .isWrite(hostIsWrite),
        .isReady(hostIsReady),
        .start(hostStart),
        .gotResponse(hostGotResponse),
        .reset(reset)
    );

    (* MARK_DEBUG = "TRUE" *) logic is_command;
    assign is_command = (uartState == COMMAND_SEND) ||
                        (uartState == COMMAND_EXECUTE) ||
                        (uartState == COMMAND_FINISH);

    assign hostAddr = is_command ? smHostAddr : controlHostAddr;
    assign hostInData = is_command ? smHostInData : controlHostInData;
    assign hostIsWrite = is_command ? smHostIsWrite : controlHostIsWrite;
    assign hostStart = is_command ? smHostStart : controlHostStart;


    // TPM Command Sending Section

    logic [15:0] smHostAddr;
    logic [7:0] smHostInData;
    logic smHostIsWrite, smHostStart;
    logic hrFifoRden, hrFifoEmpty;
    logic [7:0] hrFifoDout;
    logic hwFifoWren;
    (* MARK_DEBUG = "TRUE" *) logic hostShouldSend, hostShouldGo;
    logic requestSent, commandDone;
    CommandOnlyHostSM commandOnlyHostSM (
        .hostAddr(smHostAddr),
        .hostInData(smHostInData),
        .hostOutData(hostOutData),
        .hostGotResponse(hostGotResponse),
        .hostIsWrite(smHostIsWrite),
        .hostStart(smHostStart),
        .hostIsReady(hostIsReady),

        .uartRxData(rxData),

        .hrFifoRden(hrFifoRden),
        .hrFifoDout(hrFifoDout),
        .hrFifoEmpty(hrFifoEmpty),
        .hwFifoWren(hwFifoWren),
        .hostShouldSend(hostShouldSend),
        .hostShouldGo(hostShouldGo),
        .requestSent(requestSent),
        .commandDone(commandDone),
        .clk(clk),
        .reset(reset)
        
        ,.debugSignal(led[3])
    );
    
    // END TPM Command Sending Section


    // logic [3:0] periphInAd, periphOutAd;
    // logic periphEnable;
    // logic [15:0] periphAddr;
    // logic [7:0] periphInData, periphOutData;
    // logic periphDidWrite, periphDidRead;

    // LPCPeripheral lpcPeripheral (
    //     .inAd(periphInAd),
    //     .outAd(periphOutAd),
    //     .enable(periphEnable),
    //     .clk(clk),
    //     .frame(), //<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    //     .addr(periphAddr),
    //     .inData(periphInData),
    //     .outData(periphOutData),
    //     .didWrite(periphDidWrite),
    //     .didRead(periphDidRead),
    //     .reset(reset)
    // );
    
    
    typedef enum {IDLE, DATA, EXECUTE, COMMAND_SEND, COMMAND_EXECUTE, COMMAND_FINISH} uartStateEnum;
    (* MARK_DEBUG = "TRUE" *) uartStateEnum uartState = IDLE;
    
    assign led[0] = uartState == COMMAND_SEND;
    assign led[1] = uartState == COMMAND_EXECUTE;
    assign led[2] = requestSent;

    always_ff @(posedge clk) begin
        if (reset) begin
            uartState <= IDLE;
            controlHostAddr <= 0;
            controlHostInData <= 0;
            controlHostIsWrite <= 0;
            controlHostStart <= 0;
            hostShouldSend <= 0;
            hostShouldGo <= 0;
        end else begin
            hwFifoWren <= 0;
            case (uartState) 
            IDLE: begin
                controlHostStart <= 0;
                if (dataValid) begin
                    if (rxData[5]) begin
                        hostShouldSend <= 1;
                        uartState <= COMMAND_SEND;
                    end else begin
                        if (rxData[7]) begin
                            controlHostIsWrite <= 1;
                            uartState <= DATA;
                        end else begin
                            controlHostIsWrite <= 0;
                            uartState <= EXECUTE;
                        end
                        
                        if (rxData[0]) begin
                            controlHostAddr <= 16'h0;
                        end else if (rxData[1]) begin
                            controlHostAddr <= 16'h18;
                        end else if (rxData[2]) begin
                            controlHostAddr <= 16'h24;
                        end
                    end
                end
            end
            DATA: begin
                if (dataValid) begin
                    if (controlHostAddr == 16'h24) begin
                        hwFifoWren <= 1;
                        uartState <= IDLE;
                    end else begin
                        controlHostInData <= rxData;
                        uartState <= EXECUTE;
                    end
                end
            end
            EXECUTE: begin
                if (hostIsReady && !sw_buffered[0]) begin
                    controlHostStart <= 1;
                    uartState <= IDLE;
                end
            end
            COMMAND_SEND: begin
                if (rxData[6]) begin
                    hostShouldGo <= 1;
                end
                if (requestSent && hostShouldGo) begin
                    hostShouldSend <= 0;
                    uartState <= COMMAND_EXECUTE;
                end
            end
            COMMAND_EXECUTE: begin
                if (commandDone) begin
                    hostShouldGo <= 0;
                    uartState <= COMMAND_FINISH;
                end
            end
            COMMAND_FINISH: begin
                if (hrFifoEmpty) begin
                    uartState <= IDLE;
                end
            end
            endcase
        end
    end

    always_ff @(posedge clk ) begin
        if (hostGotResponse && txReady && uartState == IDLE) begin
            txData <= hostOutData;
            txSend <= 1;
        end else if (txReady && !hrFifoEmpty && 
                    (uartState == COMMAND_EXECUTE || uartState == COMMAND_FINISH)) begin
            txData <= hrFifoDout;
            hrFifoRden <= 1;
            txSend <= 1;
        end else begin
            txSend <= 0;
            hrFifoRden <= 0;
        end
    end
    
    
    
endmodule
