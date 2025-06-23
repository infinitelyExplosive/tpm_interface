`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/29/2023 01:54:04 AM
// Design Name: 
// Module Name: testbench_top
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


module testbench_top(

    );

    wire [5:0] ja;
    logic [3:0] led;
    logic CLK100MHZ;
    logic uart_rxd_out;
    logic uart_txd_in;
    logic [3:0] sw;

    top #(.DEBUG(1)) dut (.*);

    parameter CLK_PERIOD = 10;
    initial begin
        CLK100MHZ <= 0;
        forever begin
            #(CLK_PERIOD/2) CLK100MHZ <= ~CLK100MHZ;
        end
    end

    enum {S_IDLE, S_DIR, S_ADDR0, S_ADDR1, S_ADDR2, S_ADDR3, S_DATA0, S_DATA1, S_TAR1, S_TAR2, S_SYNC, S_DATA2, S_DATA3, S_TAR3, S_TAR4} sim_state;

    logic sim_enable;
    assign sim_enable = (sim_state == S_TAR2 || sim_state == S_SYNC || sim_state == S_DATA2 || sim_state == S_DATA3 || sim_state == S_TAR3);
    logic [3:0] simInAd, simOutAd;
    IOBUF buf1(.O(simInAd[3]), .I(simOutAd[3]), .IO(ja[3]), .T(sim_enable));
    IOBUF buf2(.O(simInAd[2]), .I(simOutAd[2]), .IO(ja[2]), .T(sim_enable));
    IOBUF buf3(.O(simInAd[1]), .I(simOutAd[1]), .IO(ja[1]), .T(sim_enable));
    IOBUF buf4(.O(simInAd[0]), .I(simOutAd[0]), .IO(ja[0]), .T(sim_enable));
    
    logic [7:0] sim_access, sim_status;

    logic sim_is_executing = 0;
    logic sim_is_write = 0;
    logic [15:0] sim_addr;
    logic [7:0] sim_data;
    logic [7:0] sim_outdata [];
    int sim_data_i = 0;
    logic sim_finished_cycle;
    always_ff @(posedge CLK100MHZ) begin
        case (sim_state)
        S_IDLE: begin
            if (simInAd == 4'b0101) begin
                sim_state <= S_DIR;
            end
        end
        S_DIR: begin
            sim_is_write <= simInAd[1] == 1;
            sim_state <= S_ADDR0;
        end
        S_ADDR0: begin
            sim_addr[15:12] <= simInAd;
            sim_state <= S_ADDR1;
        end
        S_ADDR1: begin
            sim_addr[11:8] <= simInAd;
            sim_state <= S_ADDR2;
        end
        S_ADDR2: begin
            sim_addr[7:4] <= simInAd;
            sim_state <= S_ADDR3;
        end
        S_ADDR3: begin
            sim_addr[3:0] <= simInAd;
            if (sim_is_write) begin
                sim_state <= S_DATA0;
            end else begin
                sim_state <= S_TAR1;
            end
        end
        S_DATA0: begin
            sim_data[3:0] <= simInAd;
            sim_state <= S_DATA1;
        end
        S_DATA1: begin
            sim_data[7:4] <= simInAd;
            sim_state <= S_TAR1;
        end
        S_TAR1: begin
            simOutAd <= 4'b1111;
            sim_state <= S_TAR2;
        end
        S_TAR2: begin
            simOutAd <= 4'b0000;
            sim_state <= S_SYNC;
        end
        S_SYNC: begin
            if (!sim_is_write) begin
                if (sim_addr == 16'h0000) begin
                    simOutAd <= sim_access[3:0];
                end else if (sim_addr == 16'h0018) begin
                    simOutAd <= sim_status[3:0];
                end else begin
                    simOutAd <= sim_outdata[sim_data_i][3:0];
                end
                sim_state <= S_DATA2;
            end else begin
                simOutAd <= 4'b1111;
                sim_state <= S_TAR2;
            end
        end
        S_DATA2: begin
            if (sim_addr == 16'h0000) begin
                simOutAd <= sim_access[7:4];
            end else if (sim_addr == 16'h0018) begin
                simOutAd <= sim_status[7:4];
            end else begin
                simOutAd <= sim_outdata[sim_data_i][7:4];
                sim_data_i += 1;
            end
            sim_state <= S_DATA3;
        end
        S_DATA3: begin
            simOutAd <= 4'b1111;
            sim_state <= S_TAR2;
        end
        S_TAR2: begin
            sim_state <= S_IDLE;
        end
        endcase
    end
    assign sim_finished_cycle = sim_state == S_TAR2;

    localparam CYCLES = 5;

    task send_byte(input [7:0] data);
        logic parity;
        parity <= 0;
        @(posedge CLK100MHZ);
        uart_txd_in <= 0;

        for (int i = 0; i < 8; i++) begin
            repeat (CYCLES) @(posedge CLK100MHZ);
            uart_txd_in <= data[i];
            parity <= parity ^ data[i];
            // $display("step %d val %b parity is %b", i, data[i], parity);
        end
        repeat (CYCLES) @(posedge CLK100MHZ);
        // $display("step 8 parity is %b", parity);
        uart_txd_in <= parity;
        repeat (CYCLES) @(posedge CLK100MHZ);
        uart_txd_in <= 1;
        repeat (CYCLES) @(posedge CLK100MHZ);
    endtask
    
    initial begin
        sw <= 4'hf; uart_txd_in <= 1'b1; sim_access <= 8'h0; sim_status <= 8'h0;
        @(posedge CLK100MHZ); 
        @(posedge CLK100MHZ); sw <= 4'h0;
        @(posedge CLK100MHZ); 
        send_byte(8'h84);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h00);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h84);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'hc1);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h84);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h00);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h84);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h00);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h84);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h00);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h84);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h0c);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h84);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h00);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h84);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h00);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h84);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h00);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h84);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h99);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h84);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h00);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h84);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h01);
        repeat(30) @(posedge CLK100MHZ);
        
        repeat(30) @(posedge CLK100MHZ);

        
        send_byte(8'h01);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h02);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h01);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h82);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h40);
        repeat(30) @(posedge CLK100MHZ);
        send_byte(8'h02);
        repeat(30) @(posedge CLK100MHZ);

        repeat(30) @(posedge CLK100MHZ);

        send_byte(8'h20);
        sim_outdata = '{8'h00, 8'hc4, 8'h00, 8'h00, 8'h00, 8'h0a, 8'h00, 8'h00, 8'h00, 8'h1e};
        repeat(30) @(posedge CLK100MHZ);
        
        repeat(120) @(posedge CLK100MHZ);

        send_byte(8'h40);

        repeat(60) @(posedge CLK100MHZ);
        sim_status <= 8'h94;
        
    end
endmodule
