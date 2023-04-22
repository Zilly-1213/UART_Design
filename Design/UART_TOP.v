`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/16 20:03:21
// Design Name: 
// Module Name: UART_TOP
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


module UART_TOP#(parameter 
CLK_FREQ = 10_000_000,TX_baud_rate = 9600,RX_baud_rate = 115200,
TX_clks_per_bit = CLK_FREQ/TX_baud_rate,RX_clks_per_bit = CLK_FREQ/RX_baud_rate,
check_sel = 1)(
input CLK,
input rst_n,
input [7:0] din,
input req,
input TX,
output RX,
output req_ack,
output [7:0] dout,
output error,
output TX_finish,
output TX_IDLE_flag,
output RX_dout_vld
    );

UART_TX i_UART_TX(
.CLK(CLK_FREQ),
.rst_n(rst_n),
.baud_rate(TX_baud_rate),
.CLK_FREQ(CLK_FREQ),
.CLKS_PER_BIT(TX_clks_per_bit),
.check_sel(check_sel),
.din(din),
.req(req),
.TX(TX),
.req_ack(req_ack),
.TX_finish(TX_finish),
.TX_IDLE_flag(TX_IDLE_flag)
);

UART_RX i_UART_RX (
.CLK(CLK),
.rst_n(rst_n),
.RX(RX),
.baud_rate(RX_baud_rate),
.CLK_FREQ(CLK_FREQ),
.CLKS_PER_BIT(RX_clks_per_bit),
.check_sel(check_sel),
.dout(dout),
.error(error),
.RX_dout_vld(RX_dout_vld)
);

endmodule
