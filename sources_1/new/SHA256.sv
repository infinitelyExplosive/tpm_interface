`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2023 01:22:37 PM
// Design Name: 
// Module Name: SHA256
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


const bit [31:0] K [64] = '{
    32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5, 32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
    32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3, 32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
    32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc, 32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
    32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7, 32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
    32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13, 32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
    32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3, 32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
    32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5, 32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
    32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208, 32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
};

function automatic logic [31:0]
ch(logic [31:0] x, logic [31:0] y, logic [31:0] z);
    return (x & y) ^ (~x & z);
endfunction

function automatic logic [31:0]
maj(logic [31:0] x, logic [31:0] y, logic [31:0] z);
    return (x & y) ^ (x & z) ^ (y & z);
endfunction

function automatic logic [31:0]
rotr(logic [31:0] x, logic [7:0] amount);
    return (x >> amount) | (x << (32 - amount));
endfunction

function automatic logic [31:0]
bsig0(logic [31:0] x);
    return rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
endfunction

function automatic logic [31:0]
bsig1(logic [31:0] x);
    return rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
endfunction

function automatic logic [31:0]
ssig0(logic [31:0] x);
    return rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3);
endfunction

function automatic logic [31:0]
ssig1(logic [31:0] x);
    return rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10);
endfunction

module SHA256(
        input logic clk,
        input logic [31:0] inData,
        input logic [7:0] inLen,
        input logic write,
        input logic start,
        output logic [255:0] digest,
        output logic ready,
        input logic reset
    );

    logic [31:0] h0 = 32'h6a09e667;
    logic [31:0] h1 = 32'hbb67ae85;
    logic [31:0] h2 = 32'h3c6ef372;
    logic [31:0] h3 = 32'ha54ff53a;
    logic [31:0] h4 = 32'h510e527f;
    logic [31:0] h5 = 32'h9b05688c;
    logic [31:0] h6 = 32'h1f83d9ab;
    logic [31:0] h7 = 32'h5be0cd19;

    assign digest = {h0, h1, h2, h3, h4, h5, h6, h7};

    logic [63:0] size;
    logic [31:0] lastWritten, inDataManual, modifiedLast;
    logic weaManual;

    logic [10:0] mem_addr, final_addr;
    logic [31:0] mem_din;
    logic [31:0] mem_dout;

    sha256_mem mem (
        .clka(clk),
        .ena(1),
        .wea(mem_wea),
        .addra(mem_addr),
        .dina(mem_din),
        .douta(mem_dout)
    );

    typedef enum {LOADING, PROCESSING, APPENDING, PADDING, SIZING_HIGH, SIZING_LOW,
                  CALC_PREPARING, CALC_WAITING, CALC_MAIN, CALC_ADDING, DONE} stateEnum;

    assign mem_wea = (state == LOADING ? write : weaManual);
    assign mem_din = (state == LOADING ? inData : inDataManual);

    stateEnum state = LOADING;

    logic [7:0] lastBlockSize, wordIndex, lastWordSize;
    assign lastBlockSize = size % 512;
    assign wordIndex = lastBlockSize / 16;
    assign lastWordSize = lastBlockSize % 32;
    logic needsPadding;
    assign needsPadding = (mem_addr % 16 != 12);
    logic [32:0] mask;

    assign ready = (state == DONE);

    always_comb begin
        if (lastWordSize > 0) begin
            mask = (33'b1 << lastWordSize) - 1;
            modifiedLast = 0;
            modifiedLast = modifiedLast | (lastWritten & mask);
            modifiedLast = modifiedLast | 1 << (lastWordSize + 7);
        end else begin
            modifiedLast = lastWritten;
        end
    end

    logic [31:0] a = 0, b = 0, c = 0, d = 0, e = 0, f = 0, g = 0, h = 0;
    logic [63:0] blockNum = 0;
    logic [7:0] t = 0;
    logic [31:0] s0 = 0, s1 = 0;

    logic [15:0][31:0] w;
    logic [31:0] currentW;
    
    always_comb begin
        if (t < 16) begin
            currentW = {mem_dout[7:0], mem_dout[15:8], mem_dout[23:16], mem_dout[31:24]};
        end else begin
            currentW = w[0] + ssig0(w[1]) + w[9] + ssig1(w[14]);
        end
    end

    logic [31:0] temp1, temp2;
    logic [31:0] test_ch, test_k;
    always_comb begin
        s0 = bsig0(a);
        s1 = bsig1(e);
        test_ch = ch(e, f, g);
        test_k = K[t];
        temp1 = h + bsig1(e) + ch(e, f, g) + K[t] + currentW;
        temp2 = bsig0(a) + maj(a, b, c);
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
            h0 <= 32'h6a09e667;
            h1 <= 32'hbb67ae85;
            h2 <= 32'h3c6ef372;
            h3 <= 32'ha54ff53a;
            h4 <= 32'h510e527f;
            h5 <= 32'h9b05688c;
            h6 <= 32'h1f83d9ab;
            h7 <= 32'h5be0cd19;
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
                    end else if ((mem_addr % 16) - 2 != 12) begin
                        state <= PADDING;
                    end else begin
                        state <= SIZING_HIGH;
                    end
                end
                APPENDING: begin
                    mem_addr <= mem_addr + 1;
                    inDataManual <= 32'h80;
                    weaManual <= 1;
                    if (needsPadding == 1'b1) begin
                        state <= PADDING;
                    end else begin
                        state <= SIZING_HIGH;
                    end
                end
                PADDING: begin
                    mem_addr <= mem_addr + 1;
                    inDataManual <= 32'h0;
                    weaManual <= 1;
                    if (needsPadding == 1'b1) begin
                        state <= PADDING;
                    end else begin
                        state <= SIZING_HIGH;
                    end
                end
                SIZING_HIGH: begin
                    mem_addr <= mem_addr + 1;
                    inDataManual <= {size[39:32], size[47:40], size[55:48], size[63:56]};
                    weaManual <= 1;
                    state <= SIZING_LOW;
                end
                SIZING_LOW: begin
                    mem_addr <= mem_addr + 1;
                    final_addr <= mem_addr + 1;
                    inDataManual <= {size[7:0], size[15:8], size[23:16], size[31:24]};
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
                    f <= h5;
                    g <= h6;
                    h <= h7;

                    state <= CALC_WAITING;
                end
                CALC_WAITING: begin
                    mem_addr <= mem_addr + 1;
                    state <= CALC_MAIN;
                end
                CALC_MAIN: begin
                    if (t < 16) begin
                        mem_addr <= mem_addr + 1;
                    end

                    h <= g;
                    g <= f;
                    f <= e;
                    e <= d + temp1;
                    d <= c;
                    c <= b;
                    b <= a;
                    a <= temp1 + temp2;

                    for (int i = 0; i < 15; i++) begin
                        w[i] <= w[i+1];
                    end
                    w[15] <= currentW;

                    if (t < 63) begin
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
                    h5 <= h5 + f;
                    h6 <= h6 + g;
                    h7 <= h7 + h;

                    a <= h0 + a;
                    b <= h1 + b;
                    c <= h2 + c;
                    d <= h3 + d;
                    e <= h4 + e;
                    f <= h5 + f;
                    g <= h6 + g;
                    h <= h7 + h;

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
