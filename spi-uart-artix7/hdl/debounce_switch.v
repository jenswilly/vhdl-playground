/*

Copyright (c) 2014-2018 Alex Forencich
Modified by Jens Willy, 2026-05

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog-2001

`resetall
`timescale 1 ns / 1 ps
`default_nettype none

/*
 * Synchronizes switch and button inputs with a slow sampled shift register
 */
module debounce_switch  #(
    parameter N=3, // length of shift register
    parameter RATE=125000 // clock division factor
)(
    input wire i_clk,
    input wire i_rst,
    input wire i_raw,
    output wire o_debounced
);

reg [23:0] cnt_reg = 24'd0;

reg [N-1:0] debounce_reg;

reg state;

/*
 * The synchronized output is the state register
 */
assign o_debounced = state;

integer k;

always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        cnt_reg <= 0;
        state <= 0;
        debounce_reg <= 0;
    end else begin
        if (cnt_reg < RATE) begin
            cnt_reg <= cnt_reg + 24'd1;
        end else begin
            cnt_reg <= 24'd0;
        end
        
        if (cnt_reg == 24'd0) begin
            debounce_reg <= {debounce_reg[N-2:0], i_raw};
        end
        
        if (|debounce_reg == 0) begin
            state <= 0;
        end else if (&debounce_reg == 1) begin
            state <= 1;
        end else begin
            state <= state;
        end
    end
end

endmodule

`resetall
