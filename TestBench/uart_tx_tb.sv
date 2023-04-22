`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/22 09:22:57
// Design Name: 
// Module Name: uart_tx_tb
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


module uart_tx_tb(
    );
parameter BAUD_RATE =        115200;         // bit rate in bit/s
parameter CLK_FREQ =        10_000_000;     // clock frequency in Hz
parameter VLD_DATA_WIDTH =    8;              // number of bits to be transmitted
parameter CHECK_SEL = 1;//奇偶校验的选择

parameter CLK_PERIOD = 100;

real BAUD_PERIOD = 1_000_000_000 * 1 / BAUD_RATE;   //传输1比特时钟周期对应的ns
real WAIT_TIME = BAUD_PERIOD * (4 + VLD_DATA_WIDTH);

reg CLK;
reg rst_n;
reg [VLD_DATA_WIDTH-1:0] i_din;//输入数据总线
reg i_req;

wire o_TX;
wire o_TX_busy;

UART_TX#(
    .BAUD_RATE(BAUD_RATE),
    .CLK_FREQ(CLK_FREQ),
    .VLD_DATA_WIDTH(VLD_DATA_WIDTH),
    .CHECK_SEL(CHECK_SEL)
) i_uart_tx
(
    .CLK(CLK),
    .rst_n(rst_n),
    .din(i_din),
    .req(i_req),//发送请求
    //output
    .TX(o_TX),
    .TX_busy(o_TX_busy)
);

//10M时钟
always #(CLK_PERIOD/2) CLK = ~CLK;

initial begin
    CLK = 1;
    rst_n = 0;
    i_req = 0;
    #200 rst_n = 1;
    send_data(8'b0111_0101);
    send_data(8'b0101_1001);
    send_data(8'b0101_1000);
    $finish;
end

//发送数据
task send_data;
    input [7:0] data;
    begin
        i_din = data;
        #100;
        if(!o_TX_busy)
            i_req = 1;
        else 
            i_req = 0;
        #100 i_req = 0;
        #(WAIT_TIME);
    end
endtask


endmodule
