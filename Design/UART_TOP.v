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
rx_bps = 3'd4,rx_check = 1'b1,
tx_bps = 3'd4,tx_check = 1'b1)(
input CLK,
input rst_n,
input [7:0] din,
input req,
input TX,
output RX,
output [7:0] dout,
output error
    );

UART_TX i_UART_TX(
. CLK  (CLK ),
. rst_n    (rst_n   ),
. din      (din     ),
. req      (req     ),
. TX       (TX      ),
. bps_sel  (tx_bps),
. check_sel(tx_check)
);

UART_RX i_UART_RX (
. CLK  (CLK),
. rst_n    (rst_n  ),
. RX       (RX    ),
. dout     (dout   ),
. error    (error  ),
. bps_sel  (rx_bps),
. check_sel(rx_check)
);

endmodule
