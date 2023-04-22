`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/22 09:22:57
// Design Name: 
// Module Name: uart_rx_tb
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


module uart_rx_tb(
    );
parameter BAUD_RATE =        115200;         // bit rate in bit/s
parameter CLK_FREQ =        10_000_000;     // clock frequency in Hz
parameter VLD_DATA_WIDTH =    8;              // number of bits to be transmitted
parameter CHECK_SEL = 1;//奇偶校验的选择

parameter CLK_PERIOD = 100;

integer i;
real BAUD_PERIOD = 1_000_000_000 * 1 / BAUD_RATE;    // bit rate period in nanoseconds

reg CLK;
reg rst_n;
reg i_serial_data;

wire [VLD_DATA_WIDTH-1:0] o_dout;
wire o_error;
wire o_dout_vld;

//10M时钟
always #(CLK_PERIOD/2) CLK = ~CLK;

initial begin
    CLK = 1;
    rst_n = 0;
    #200 rst_n = 1;
    i_serial_data = 1'b1;
    
    #200;
    send_8_bits(8'b0001_0110);  // 8'h16
    send_8_bits(8'b0011_0010);  // 8'h32
    send_8_bits(8'b1010_1111);  // 8'haf
    $finish;
end

task send_8_bits;
    input [VLD_DATA_WIDTH:0] data;
    begin
        i_serial_data = 1'b0;
        for (i=0; i<8; i=i+1) begin
            #BAUD_PERIOD i_serial_data = data[i];
        end
        #BAUD_PERIOD i_serial_data = (^data)?0:1;
        #BAUD_PERIOD i_serial_data = 1'b1;
        #(2*BAUD_PERIOD);
    end
endtask

UART_RX#(
    .BAUD_RATE(BAUD_RATE),
    .CLK_FREQ(CLK_FREQ),
    .VLD_DATA_WIDTH(VLD_DATA_WIDTH),
    .CHECK_SEL(CHECK_SEL)
)i_uart_rx
(
    .CLK(CLK),
    .rst_n(rst_n),
    .RX(i_serial_data),
    .dout(o_dout),
    .error(o_error),
    .RX_dout_vld(o_dout_vld)
);
endmodule
