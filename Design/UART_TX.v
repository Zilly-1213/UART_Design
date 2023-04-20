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
`include "UART.vh"

module UART_TX(
    //input
    input CLK,
    input rst_n,
    input [2:0] bps_sel,
    input check_sel,
    input [`VLD_DATA_WIDTH-1:0] din,
    input req,//发送请求
    //output
    output reg Tx
    );

//波特率参数
localparam bps600   = 17'd8_3333;//乘积都为50M，波特率为600时，一个波特的时钟实际上由多少个小时钟组成
localparam bps1200  = 17'd4_1667;
localparam bps2400  = 17'd2_0833;
localparam bps4800  = 17'd1_0417;
localparam bps9600  = 17'd5208;
localparam bps19200 = 17'd2604;
localparam bps38400 = 17'd1302;
//状态参数
localparam IDLE = 0,TX_START = 1,TX_VLD_DATA = 2,TX_CHECK = 3,TX_STOP = 4;

reg[16:0] bps_mode;
reg[16:0] bps_cnt;
reg[3:0] bit_cnt;//指示当前波特周期在传输数据包第几位数据(1-11)
reg[2:0] cs,ns;
reg TX_flag;//表示当前有数据可发
reg[7:0] din_reg;//需要发送的数据缓存
wire e_check;
wire o_check;
wire check;

//TX_flag control
always@(posedge CLK,negedge rst_n)begin
    if(!rst_n)begin
        TX_flag <= 0;
    end
    else if(bit_cnt==11&&bps_cnt==bps_mode-1) begin
        TX_flag <= 0;
    end
    else if(req)begin
        TX_flag <= 1;
    end
end

//波特率选择
always@(*)begin
  case(bps_sel)
    0: bps_mode = bps600;   
    1: bps_mode = bps1200;  
    2: bps_mode = bps2400; 
    3: bps_mode = bps4800;  
    4: bps_mode = bps9600;  
    5: bps_mode = bps19200; 
    6: bps_mode = bps38400; 
    default : bps_mode = bps600; 
  endcase
end 

//波特率计数控制
always@(posedge CLK,negedge rst_n)begin
    if(!rst_n)begin
        bps_cnt <= 0;
    end
    else if(bps_cnt == bps_mode-1) begin
        bps_cnt <= 0;
    end
    else begin
        bps_cnt <= bps_cnt + 1;
    end
end

//状态机逻辑
always@(*)begin
    case(cs)
        IDLE:
            ns = (TX_flag&&bps_cnt==bps_mode-1)?TX_START:IDLE;
        TX_START:
            ns = (bit_cnt==1&&bps_cnt==bps_mode-1)?TX_VLD_DATA:TX_START;
        TX_VLD_DATA:
            ns = (bit_cnt==9&&bps_cnt==bps_mode-1)?TX_CHECK:TX_VLD_DATA;
        TX_CHECK:
            ns = (bit_cnt==10&&bps_cnt==bps_mode-1)?TX_STOP:TX_CHECK;
        TX_STOP:
            ns = (bit_cnt==11&&bps_cnt==bps_mode-1)?IDLE:TX_STOP;
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
    if(!rst_n)begin
        bit_cnt <= 'd0;
    end
    else if(TX_flag) begin
        if(bps_cnt == bps_mode-1)begin
            bit_cnt <= bit_cnt + 1;
        end
        else begin
            bit_cnt <= bit_cnt;
        end
    end
    else begin
        bit_cnt <= 'd0;
    end
end

//发送数据逻辑
always@(*)begin
    if(TX_flag)begin
        case(cs)
            IDLE:Tx = 1'b1;
            TX_START:Tx = 1'b0;
            TX_VLD_DATA:begin
                case(bit_cnt)
                    2:Tx = din_reg[0];
                    3:Tx = din_reg[1];
                    4:Tx = din_reg[2];
                    5:Tx = din_reg[3];
                    6:Tx = din_reg[4];
                    7:Tx = din_reg[5];
                    8:Tx = din_reg[6];
                    9:Tx = din_reg[7];
                endcase
            end
            TX_CHECK:Tx = check;
            TX_STOP:Tx = 1'b1;
            default:Tx = 1'b1;
        endcase 
    end
    else 
        Tx = 1'b1;
end

//奇偶校验
assign e_check = ^din_reg;
assign o_check = ~e_check;
assign check = (check_sel)?o_check:e_check;
endmodule
