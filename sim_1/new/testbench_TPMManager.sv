`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/14/2024 10:01:01 PM
// Design Name: 
// Module Name: testbench_TPMManager
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


module testbench_TPMManager(

    );

    logic clk;
    logic reset = 1;
    logic [15:0] periphAddr = 0;
    logic [7:0] periphInData;
    logic [7:0] periphOutData = 0;
    logic periphDidWrite = 0;
    logic periphDidRead = 0;
    logic [15:0] hostAddr;
    logic [7:0] hostInData;
    logic [7:0] hostOutData = 0;
    logic hostIsWrite;
    logic hostIsReady = 0;
    logic hostStart;
    logic hostGotResponse = 0;
    logic uartDataValid = 0;
    logic [7:0] uartRxData = 0;
    logic [7:0] uartTxData;
    logic uartTxSend;
    logic uartTxReady = 0;

    logic debugDone;
    logic [7:0] result = 0;
    logic [7:0] garbage = 0;
    

    localparam CLK_PERIOD = 10;
    initial begin
        clk <= 0;
        forever begin
            #(CLK_PERIOD/2) clk <= ~clk;
        end
    end

    TPMManager dut (.*);

    task send_command(input [15:0] addr, input [7:0] data, input isWrite, output [7:0] commandResponse);
        @(posedge clk);
        periphAddr <= addr;
        repeat(2) @(posedge clk);
        periphOutData <= data;
        @(posedge clk);
        if (isWrite) begin
            periphDidWrite <= 1;
        end else begin
            periphDidRead <= 1;
        end
        @(posedge clk);
        if (!isWrite) begin
            commandResponse <= periphInData;
        end else begin
            commandResponse <= 0;
        end
        periphDidRead <= 0;
        periphDidWrite <= 0;
        repeat(4) @(posedge clk);
        
    endtask

    task send_uart(input [7:0] data);
        @(posedge  clk);
        uartRxData <= data;
        uartDataValid <= 1;
        @(posedge clk);
        uartDataValid <= 0;
        @(posedge clk);
    endtask

    task send_uartdata(input [7:0] header, input [7:0] data);
        send_uart(header);
        repeat(3) @(posedge clk);
        send_uart(data);
        repeat(2) @(posedge clk);
    endtask

    task send_commandbytes(input [7:0] data []);
        logic [7:0] garbage;
        for(int i = 0; i < data.size(); i++) begin
            send_command(16'h24, data[i], 1, .commandResponse(garbage));
        end
    endtask

    task send_uartcommand(input [7:0] data []);
        for(int i = 0; i < data.size(); i++) begin
            send_uartdata(8'h1, data[i]);
        end
    endtask

    task send_uartresponse(input [7:0] data []);
        for(int i = 0; i < data.size(); i++) begin
            send_uartdata(8'h2, data[i]);
        end
    endtask

    task run_command(input [7:0] requestData [], input [7:0] responseData []);
        response.delete();
        responseReceived = new [responseData.size()];

        for(int i = 0; i < responseData.size(); i++) begin
            response.push_back(responseData[i]);
        end

        send_command(16'h0, 8'h02, 1, .commandResponse(garbage));
        repeat(3) @(posedge clk);
        send_command(16'h18, 8'h40, 1, .commandResponse(garbage));
        repeat(3) @(posedge clk);
        send_commandbytes(requestData);
        repeat(3) @(posedge clk);
        send_command(16'h24, 8'h08, 1, .commandResponse(garbage));
        repeat(3) @(posedge clk);
        send_command(16'h18, 8'h20, 1, .commandResponse(garbage));

        $display("executing");
        repeat(30) @(posedge clk);

        while (result != 8'h94) begin
            send_command(16'h18, 0, 0, result);
        end


        for(int i = 0; i < responseData.size(); i++) begin
            send_command(16'h24, 0, 0, result);
            $display("host read %h", result);
            responseReceived[i] = result;
        end

        assert (responseData == responseReceived);

        send_command(16'h18, 8'h40, 1, .commandResponse(garbage));
        send_command(16'h0, 8'h20, 1, .commandResponse(garbage));
    endtask


    int uartHeader = 0;
    logic [7:0] commandQueue [$:2000];
    logic [31:0] commandSize;
    logic [3:0][7:0] commandSizeBytes;
    logic uartSendCommand;

    logic isBypass;

    assign commandSize = commandSizeBytes;
    logic [7:0] responseQueue [$:2000];
    logic [31:0] responseSize;
    logic [3:0][7:0] responseSizeBytes;
    assign responseSize = responseSizeBytes;
    logic uartSendResponse;

    logic [31:0] uartDelayCount;

    // uart tx handling
    always_ff @(posedge clk) begin
        if (uartTxReady == 0) begin
            uartTxReady <= 1;
        end else if (uartTxSend) begin
            if (uartHeader == 0) begin
                uartHeader <= uartTxData;
            end else begin
                uartTxReady <= 0;
                uartHeader <= 0;
                if (uartHeader == 1) begin
                    $display("uart as periph %h", uartTxData);
                    if (commandQueue.size() >= 2 && commandQueue.size() < 6) begin
                        commandSizeBytes[5 - commandQueue.size()] <= uartTxData;
                    end else if (commandQueue.size() >= 6 && commandQueue.size() == commandSize - 1) begin
                        uartSendCommand <= 1;
                        isBypass <= 1;
                    end
                    commandQueue.push_back(uartTxData);
                end else begin
                    $display("uart as host %h", uartTxData);
                    if (responseQueue.size() >= 2 && responseQueue.size() < 6) begin
                        responseSizeBytes[5 - responseQueue.size()] <= uartTxData;
                    end else if (responseQueue.size() >= 6 && responseQueue.size() == responseSize - 1) begin
                        uartSendResponse <= 1;
                    end
                    responseQueue.push_back(uartTxData);
                end
            end
        end
    end

    localparam UART_DELAY = 50;
    // uart rx handling
    always @(posedge clk) begin
        if (uartDelayCount > 0) begin
            uartDelayCount <= uartDelayCount - 1;
        end else begin
            if (uartSendCommand) begin
                send_uart('h01);
                #(CLK_PERIOD * UART_DELAY);
                send_uart(commandQueue.pop_front());
                #(CLK_PERIOD * UART_DELAY);
                if (commandQueue.size() == 0) begin
                    uartSendCommand <= 0;
                    if (isBypass) begin
                        send_uart('h10);
                    end else begin
                        send_uart('h20);
                    end
                    #(CLK_PERIOD * UART_DELAY);
                    send_uart('h04);
                    #(CLK_PERIOD * UART_DELAY);
                    send_uart('h08);
                    #(CLK_PERIOD * UART_DELAY);
                end
            end else if (uartSendResponse && !isBypass) begin
                send_uart('h02);
                #(CLK_PERIOD * UART_DELAY);
                send_uart(responseQueue.pop_front());
                #(CLK_PERIOD * UART_DELAY);
                if (responseQueue.size() == 0) begin
                    uartSendResponse <= 0;
                    send_uart('h40);
                    #(CLK_PERIOD * UART_DELAY);
                end
            end
        end
    end




    logic [31:0] hostIdleCount = 0;
    logic [31:0] executionCount = 0;
    logic [7:0] nextResponse = 0;
    logic nextResponseReady = 0;
    logic [31:0] tpmBytesReceived = 0;
    logic [31:0] tpmCommandLength;
    logic [3:0] [7:0] tpmCommandLengthBytes = 0;
    assign tpmCommandLength = tpmCommandLengthBytes;
    logic [31:0] tpmBytesRead = 0;
    logic [7:0] response[$:2000];
    logic [7:0] responseReceived [];
    logic [31:0] responseLen = 20;

    typedef enum {SIM_IDLE, SIM_RECEPTION, SIM_EXECUTION, SIM_COMPLETION} simStateEnum;
    simStateEnum simState = SIM_IDLE;

    always_ff @(posedge clk) begin
        hostGotResponse <= 0;
        if (!hostIsReady) begin
            if (nextResponseReady) begin
                hostOutData <= nextResponse;
                nextResponseReady <= 0;
                hostGotResponse <= 1;
            end
            if (hostIdleCount == 0) begin
                hostIsReady <= 1;
            end else begin
                hostIdleCount <= hostIdleCount - 1;
            end
        end else if (hostStart) begin
            hostIsReady <= 0;
            hostIdleCount <= 5;
            case (simState)
                SIM_IDLE: begin
                    if (hostAddr == 16'h24 && hostIsWrite) begin
                        simState <= SIM_RECEPTION;
                        tpmBytesReceived <= tpmBytesReceived + 1;
                    end else if (hostAddr == 16'h0 && !hostIsWrite) begin
                        nextResponse <= 8'ha1;
                        nextResponseReady <= 1;
                    end else if (hostAddr == 16'h18 && !hostIsWrite) begin
                        nextResponse <= 8'hc4;
                        nextResponseReady <= 1;
                    end
                end
                SIM_RECEPTION: begin
                    if (hostAddr == 16'h24 && hostIsWrite) begin
                        tpmBytesReceived <= tpmBytesReceived + 1;
                        if (tpmBytesReceived >= 2 && tpmBytesReceived < 6) begin
                            tpmCommandLengthBytes[5 - tpmBytesReceived] <= hostInData;
                        end
                        if (tpmBytesReceived > 6 && tpmBytesReceived == tpmCommandLength - 1) begin
                            simState <= SIM_EXECUTION;
                        end
                    end
                end
                SIM_EXECUTION: begin
                    if (hostAddr == 16'h0 && !hostIsWrite) begin
                        nextResponse <= 8'ha1;
                        nextResponseReady <= 1;
                    end else if (hostAddr == 16'h18 && !hostIsWrite) begin
                        nextResponse <= 8'h04;
                        nextResponseReady <= 1;
                    end
                    if (executionCount < 30) begin
                        executionCount <= executionCount + 1;
                    end else begin
                        simState <= SIM_COMPLETION;
                    end
                end
                SIM_COMPLETION: begin
                    if (hostAddr == 16'h24 && !hostIsWrite) begin
                        // nextResponse <= response[tpmBytesRead];
                        nextResponse <= response.pop_front();
                        nextResponseReady <= 1;
                        tpmBytesRead <= tpmBytesRead + 1;
                        if (tpmBytesRead == responseLen) begin
                            simState <= SIM_IDLE;
                        end
                    end else if (hostAddr == 16'h0 && !hostIsWrite) begin
                        nextResponse <= 8'ha1;
                        nextResponseReady <= 1;
                    end else if (hostAddr == 16'h18 && !hostIsWrite) begin
                        nextResponse <= 8'h94;
                        nextResponseReady <= 1;
                    end
                end
            endcase
        end
    end

    logic [7:0] request1 [] = '{'h80, 'h01, 'h00, 'h00, 'h00, 'h0c, 'h00, 'h00, 'h01, 'h7b, 'h00};
    logic [7:0] response1 [] = '{'h80, 'h01, 'h00, 'h00, 'h00, 'h14, 'h00, 'h00, 'h00, 'h00, 'h00, 'h08, 'h06, 'h3c, 'h31, 'hf1, 'h2a, 'h64, 'he6, 'he8};

    initial begin
        reset <= 1;
        @(posedge clk); reset <= 0;
        @(posedge clk); periphAddr <= 0;
        repeat(5) @(posedge clk);
        run_command(request1, response1);
        repeat(50) @(posedge clk);
        run_command(request1, response1);

    end

endmodule
