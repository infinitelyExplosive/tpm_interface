`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2023 10:30:47 PM
// Design Name: 
// Module Name: SHA1
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

function automatic logic [31:0]
f0_19(logic [31:0] b, logic [31:0] c, logic [31:0] d);
    return (b & c) | (~b & d);
endfunction

function automatic logic [31:0]
f20_39(logic [31:0] b, logic [31:0] c, logic [31:0] d);
    return b ^ c ^ d;
endfunction

function automatic logic [31:0]
f40_59(logic [31:0] b, logic [31:0] c, logic [31:0] d);
    return (b & c) | (b & d) | (c & d);
endfunction

function automatic logic [31:0]
f60_79(logic [31:0] b, logic [31:0] c, logic [31:0] d);
    return b ^ c ^ d;
endfunction

function automatic logic [31:0]
s(logic[31:0] x, logic[7:0] amount);
    return (x << amount) | x >> (32 - amount);
endfunction

module SHA1(
    input logic clk,
    input logic [63:0] inData,
    input logic [7:0] inLen,
    input logic write,
    input logic start,
    output logic [159:0] digest,
    output logic ready,
    input logic reset
    );

    logic [31:0] h0 = 32'h67452301;
    logic [31:0] h1 = 32'hefcdab89;
    logic [31:0] h2 = 32'h98badcfe;
    logic [31:0] h3 = 32'h10325476;
    logic [31:0] h4 = 32'hc3d2e1f0;

    assign digest = {h0, h1, h2, h3, h4};

    logic [63:0] size;
    logic [63:0] lastWritten, inDataManual, modifiedLast;
    logic weaManual;

    logic mem_wea;
    logic [9:0] mem_addr, final_addr;
    logic [63:0] mem_din;
    logic [63:0] mem_dout;

    sha1_mem mem (
        .clka(clk),
        .ena(1),
        .wea(mem_wea),
        .addra(mem_addr),
        .dina(mem_din),
        .douta(mem_dout)
    );

    typedef enum {LOADING, PROCESSING, APPENDING, PADDING, SIZING,
                  CALC_PREPARING, CALC_WAITING, CALC_MAIN, CALC_ADDING, DONE} stateEnum;

    assign mem_wea = (state == LOADING ? write : weaManual);
    assign mem_din = (state == LOADING ? inData : inDataManual);

    stateEnum state = LOADING;

    logic [8:0] lastBlockSize, wordIndex, lastWordSize;
    assign lastBlockSize = size % 512;
    assign wordIndex = lastBlockSize / 8;
    assign lastWordSize = lastBlockSize % 64;
    logic needsPadding;
    assign needsPadding = (mem_addr % 8 != 5);
    logic [64:0] mask;

    assign ready = state == DONE;

    always_comb begin
        if (lastWordSize > 0) begin
            mask = (65'b1 << lastWordSize) - 1;
            modifiedLast = 0;
            modifiedLast = modifiedLast | (lastWritten & mask);
            modifiedLast = modifiedLast | 1 << (lastWordSize + 7);
        end else begin
            modifiedLast = lastWritten;
        end
    end

    logic [31:0] a = 0, b = 0, c = 0, d = 0, e = 0;
    logic [63:0] blockNum = 0;
    logic [7:0] t = 0;
    logic [31:0] k, f;
    always_comb begin
        if (t < 20) begin
            k = 32'h5a827999;
            f = f0_19(b, c, d);
        end else if (t < 40) begin
            k = 32'h6ed9eba1;
            f = f20_39(b, c, d);
        end else if (t < 60) begin
            k = 32'h8f1bbcdc;
            f = f40_59(b, c, d);
        end else begin
            k = 32'hca62c1d6;
            f = f60_79(b, c, d);
        end
    end

    logic [15:0][31:0] w;
    logic [31:0] currentW;
    logic test, test2;
    always_comb begin
        test2 = (t % 2 == 0);
        if ((t < 16) && (t % 2 == 0)) begin
            currentW = {mem_dout[7:0], mem_dout[15:8], mem_dout[23:16], mem_dout[31:24]};
            test = 0;
        end else if ((t < 16) && (t % 2 == 1)) begin
            currentW = {mem_dout[39:32], mem_dout[47:40], mem_dout[55:48], mem_dout[63:56]};
            test = 1;
        end else begin
            currentW = s((w[13] ^ w[8] ^ w[2] ^ w[0]), 1);
        end
    end

    always_ff @( posedge clk ) begin
        if (reset == 1'b1) begin
            size <= 0;
            state <= LOADING;
            mem_addr <= 0;
            final_addr <= 0;
            lastWritten <= 0;
            weaManual <= 0;
            inDataManual <= 0;
            t <= 0;
            h0 <= 32'h67452301;
            h1 <= 32'hefcdab89;
            h2 <= 32'h98badcfe;
            h3 <= 32'h10325476;
            h4 <= 32'hc3d2e1f0;
        end else begin
            case (state)
                LOADING: begin
                    if (write == 1'b1) begin
                        mem_addr <= mem_addr + 1;
                        size <= size + inLen;
                        lastWritten <= inData;
                    end
                    if (start == 1'b1) begin
                        state <= PROCESSING;
                    end
                end
                PROCESSING: begin
                    mem_addr <= mem_addr > 0 ? mem_addr - 1 : 0;
                    inDataManual <= modifiedLast;
                    weaManual <= 1'b1;
                    if (lastWordSize == 0) begin
                        state <= APPENDING;
                    end else if ((mem_addr % 8) - 2 != 5) begin
                        state <= PADDING;
                    end else begin
                        state <= SIZING;
                    end
                end
                APPENDING: begin
                    mem_addr <= mem_addr + 1;
                    inDataManual <= 64'h80;
                    weaManual <= 1;
                    if (needsPadding == 1'b1) begin
                        state <= PADDING;
                    end else begin
                        state <= SIZING;
                    end
                end
                PADDING: begin
                    mem_addr <= mem_addr + 1;
                    inDataManual <= 64'h0;
                    weaManual <= 1;
                    if (needsPadding == 1'b1) begin
                        state <= PADDING;
                    end else begin
                        state <= SIZING;
                    end
                end
                SIZING: begin
                    mem_addr <= mem_addr + 1;
                    final_addr <= mem_addr + 1;
                    inDataManual <= {size[7:0], size[15:8], size[23:16], size[31:24], size[39:32], size[47:40], size[55:48], size[63:56]};
                    weaManual <= 1;
                    t <= 0;
                    state <= CALC_PREPARING;
                end
                CALC_PREPARING: begin
                    mem_addr <= 0;
                    weaManual <= 0;
                    t <= 0;
                    a <= h0;
                    b <= h1;
                    c <= h2;
                    d <= h3;
                    e <= h4;
                    state <= CALC_WAITING;
                end
                CALC_WAITING: begin
                    state <= CALC_MAIN;
                end
                CALC_MAIN: begin
                    if (t < 16 && t % 2 == 0) begin
                        mem_addr <= mem_addr + 1;
                    end

                    e <= d;
                    d <= c;
                    c <= s(b, 30);
                    b <= a;
                    a <= s(a, 5) + f + e + k + currentW;
                    for (int i = 0; i < 15; i++) begin
                        w[i] <= w[i+1];
                    end
                    w[15] <= currentW;

                    if (t < 79) begin
                        t <= t + 1;
                    end else begin
                        state <= CALC_ADDING;
                    end
                end
                CALC_ADDING: begin
                    h0 <= h0 + a;
                    h1 <= h1 + b;
                    h2 <= h2 + c;
                    h3 <= h3 + d;
                    h4 <= h4 + e;

                    a <= h0 + a;
                    b <= h1 + b;
                    c <= h2 + c;
                    d <= h3 + d;
                    e <= h4 + e;

                    t <= 0;
                    if (mem_addr > final_addr) begin
                        state <= DONE;
                    end else begin
                        state <= CALC_MAIN;
                    end
                end
                DONE: begin
                    state <= DONE;
                end
            endcase
        end   
    end
endmodule
