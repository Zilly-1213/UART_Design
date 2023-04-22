`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/16 20:03:21
// Design Name: 
// Module Name: UART_TX
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
//`include "UART.vh"


module UART_TX#(
    parameter BAUD_RATE = 115200,
    parameter CLK_FREQ = 10_000_000,
    parameter VLD_DATA_WIDTH = 8,
    parameter CHECK_SEL = 1)
    (
    //input
    input CLK,
    input rst_n,
    input [VLD_DATA_WIDTH-1:0] din,
    input req,//发送请求
    //output
    output reg TX,
    output wire TX_busy
    );


//状态参数
localparam IDLE = 0,TX_START = 1,TX_VLD_DATA = 2,TX_CHECK = 3,TX_STOP = 4;
localparam CLKS_PER_BIT =   CLK_FREQ / BAUD_RATE;

reg TX_flag;//表示当前有数据可发

reg[31:0] CLKS_CNT;
reg[3:0] bit_cnt;//指示当前波特周期在传输数据包第几位数据(1-11)
reg[2:0] cs,ns;
reg[7:0] din_reg;//需要发送的数据缓存
wire e_check;
wire o_check;
wire check;

//TX_flag control
always@(posedge CLK,negedge rst_n)begin
    if(!rst_n)begin
        TX_flag <= 0;
    end
    else if(bit_cnt==VLD_DATA_WIDTH+3 &&CLKS_CNT==CLKS_PER_BIT-1) begin
        TX_flag <= 0;
    end
    else if(req)begin
        TX_flag <= 1;
    end
end

//时钟计数控制
always@(posedge CLK,negedge rst_n)begin
    if(!rst_n)begin
        CLKS_CNT <= 0;
    end
    else if(CLKS_CNT == CLKS_PER_BIT-1) begin
        CLKS_CNT <= 0;
    end
    else begin
        CLKS_CNT <= CLKS_CNT + 1;
    end
end

//TX_busy控制
assign TX_busy = (TX_flag)?1:0;

//状态机逻辑
always@(*)begin
    case(cs)
        IDLE:
            ns = (TX_flag&&CLKS_CNT==CLKS_PER_BIT-1)?TX_START:IDLE;
        TX_START:
            ns = (bit_cnt==1&&CLKS_CNT==CLKS_PER_BIT-1)?TX_VLD_DATA:TX_START;
        TX_VLD_DATA:
            ns = (bit_cnt==9&&CLKS_CNT==CLKS_PER_BIT-1)?TX_CHECK:TX_VLD_DATA;
        TX_CHECK:
            ns = (bit_cnt==10&&CLKS_CNT==CLKS_PER_BIT-1)?TX_STOP:TX_CHECK;
        TX_STOP:
            ns = (bit_cnt==11&&CLKS_CNT==CLKS_PER_BIT-1)?IDLE:TX_STOP;
        default:
            ns = IDLE;
    endcase
end

always@(posedge CLK,negedge rst_n)begin
    if(!rst_n)begin
        cs <= IDLE;
    end
    else begin
        cs <= ns;
    end
end

//输入数据缓存
always@(posedge CLK)begin	
  if(req)
    din_reg <= din;
  else if(!TX_flag)
    din_reg <= 'd0;
end

//bit_cnt逻辑
always@(posedge CLK,negedge rst_n)begin
    if(!rst_n)
        bit_cnt <= 'd0;
    else if(TX_flag) begin
        if(CLKS_CNT == CLKS_PER_BIT-1)
            bit_cnt <= bit_cnt + 1;
        else 
            bit_cnt <= bit_cnt;
    end
    else
        bit_cnt <= 'd0;
end

//发送数据逻辑
always@(*)begin
    if(TX_flag)begin
        case(cs)
            IDLE:TX = 1'b1;//还没到完整时钟周期
            TX_START:TX = 1'b0;
            TX_VLD_DATA:begin
                case(bit_cnt)
                    2:TX = din_reg[0];
                    3:TX = din_reg[1];
                    4:TX = din_reg[2];
                    5:TX = din_reg[3];
                    6:TX = din_reg[4];
                    7:TX = din_reg[5];
                    8:TX = din_reg[6];
                    9:TX = din_reg[7];
                endcase
            end
            TX_CHECK:TX = check;
            TX_STOP:TX = 1'b1;
            default:TX = 1'b1;
        endcase 
    end
    else 
        TX = 1'b1;
end

//奇偶校验
assign e_check = ^din_reg;
assign o_check = ~e_check;
assign check = (CHECK_SEL)?o_check:e_check;
endmodule
