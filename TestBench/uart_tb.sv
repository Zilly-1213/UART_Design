`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/22 15:46:39
// Design Name: 
// Module Name: uart_tb
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


module uart_tb(
    );

parameter BAUD_RATE_1 = 115200;
parameter CLK_FREQ_1 =  10_000_000;     // clock frequency in Hz
parameter CLK_FREQ_2 = 50_000_000;
parameter VLD_DATA_WIDTH_1 = 8;              // number of bits to be transmitted
parameter CHECK_SEL_1 = 1;//奇偶校验的选择

parameter CLK_PERIOD_1 = 100;
parameter CLK_PERIOD_2 = 20;

real WAIT_TIME = 1_000_000_000/BAUD_RATE_1;

reg CLK_1,CLK_2;
reg rst_n_1,rst_n_2;

//PC_1 TX
reg i_req_1;
reg [VLD_DATA_WIDTH_1-1:0] i_din_1;
wire o_TX_1;
wire o_TX_busy_1;

//PC_2 RX
wire [VLD_DATA_WIDTH_1-1:0] o_dout_1;
wire o_error_1;
wire o_dout_vld_1;

always #(CLK_PERIOD_1/2)CLK_1 = ~CLK_1;//10M tx clk
always #(CLK_PERIOD_2/2)CLK_2 = ~CLK_2;//50M rx clk

//TX_1
initial begin
    CLK_1 = 1;
    rst_n_1 = 0;
    #CLK_PERIOD_1 rst_n_1 = 1;

    send_data_1(8'hab);        
    send_data_1(8'hcd);        
    send_data_1(8'hef); 
end

//RX_2
initial begin
    CLK_2 = 1;
    rst_n_2 = 0;
    #CLK_PERIOD_2 rst_n_2 = 1;

    repeat(3)@(posedge o_dout_vld_1);

    #(WAIT_TIME*11);
    $finish;

end



UART_TX#(
    .BAUD_RATE(BAUD_RATE_1),
    .CLK_FREQ(CLK_FREQ_1),
    .VLD_DATA_WIDTH(VLD_DATA_WIDTH_1),
    .CHECK_SEL(CHECK_SEL_1)
)i_uart_tx_1(
    .CLK(CLK_1),
    .rst_n(rst_n_1),
    .din(i_din_1),
    .req(i_req_1),//发送请求
    //output
    .TX(o_TX_1),
    .TX_busy(o_TX_busy_1)
);

UART_RX#(
    .BAUD_RATE(BAUD_RATE_1),
    .CLK_FREQ(CLK_FREQ_2),
    .VLD_DATA_WIDTH(VLD_DATA_WIDTH_1),
    .CHECK_SEL(CHECK_SEL_1)
)i_uart_rx_2
(   
    //input
    .CLK(CLK_2),
    .rst_n(rst_n_2),
    .RX(o_TX_1),
    //output
    .dout(o_dout_1),
    .error(o_error_1),
    .RX_dout_vld(o_dout_vld_1)
);

//发送数据
task send_data_1;
    input [VLD_DATA_WIDTH_1-1:0] data;
    begin
        i_din_1 = data;
        #CLK_PERIOD_1;
        if(!o_TX_busy_1)
            i_req_1 = 1;
        else 
            i_req_1 = 0;
        #CLK_PERIOD_1 i_req_1 = 0;
        @(negedge o_TX_busy_1);
    end
endtask

endmodule
