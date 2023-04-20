`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/16 20:03:21
// Design Name: 
// Module Name: UART_RX
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


module UART_RX(
input CLK_50M,
input rst_n,
input RX,
input [2:0] bps_sel,
input check_sel,
output reg [7:0] dout,
output reg error
    );

//波特率选择
localparam bps600   = 17'd8_3333;
localparam bps1200  = 17'd4_1667;
localparam bps2400  = 17'd2_0833;
localparam bps4800  = 17'd1_0417;
localparam bps9600  = 17'd5208;
localparam bps19200 = 17'd2604;
localparam bps38400 = 17'd1302;

//状态机参数
localparam WAIT_START = 1,RX_VLD_DATA = 2,RX_CHECK = 3,RX_STOP = 4;

reg RX_flag;
wire dec_RX;
reg[3:0] bit_cnt;//指示当前波特周期在接收第几位数据(跳过起始位，0-9)
reg[7:0]dout_reg;
wire e_check;
wire o_check;
wire check;
reg [2:0] cs,ns;
reg RX_d1,RX_d2,RX_d3; //d1,d2为消除亚稳态，d3为下降沿检测

//波特率计数器
reg [16:0] bps_mode;
reg [16:0] bps_cnt; //最慢的bps600模式需要17位计数器


//消除亚稳态+亚稳态
always@(posedge CLK_50M or negedge rst_n)begin
    if(!rst_n)begin
        RX_d1 <= 1'b0;
        RX_d2 <= 1'b0;
        RX_d3 <= 1'b0;
    end
    else begin
        RX_d1 <= RX;  
        RX_d2 <= RX_d1;
        RX_d3 <= RX_d2;
    end
end

//下降沿检测
assign dec_RX = RX_d3 && ~RX_d2;

//RX_flag control
always@(posedge CLK_50M,posedge rst_n)begin
    if(!rst_n)begin
        RX_flag <= 0;
    end
    else if(bit_cnt=='d9&&bps_cnt==bps_mode-1)begin
        RX_flag <= 0;
    end
    else if(dec_RX)begin
        RX_flag <= 1;
    end
end

//bit_cnt控制
always@(posedge CLK_50M,negedge rst_n)begin
    if(!rst_n)
        bit_cnt <= 'd0;
    else if(RX_flag) begin
        if(bps_cnt == bps_mode-1)
            bit_cnt <= bit_cnt + 1;
    end
    else 
        bit_cnt <='d0;
end

//波特率计数
always@(posedge CLK_50M or negedge rst_n)begin
  if(!rst_n)
    bps_cnt <= 'd0;
  else if(bps_cnt == bps_mode-1) 
    bps_cnt <= 'd0;
  else if(RX_flag)	//与发送端波特率同步
    bps_cnt <= bps_cnt + 1'b1;
  else
    bps_cnt <= 'd0;
end


//接收状态机
always@(*)begin
    case(cs)
        WAIT_START:ns = (RX_flag)?RX_VLD_DATA:WAIT_START;
        RX_VLD_DATA:ns = (bit_cnt==7&&bps_cnt==bps_mode-1)?RX_CHECK:RX_VLD_DATA;
        RX_CHECK:ns = (bit_cnt==8&&bps_cnt==bps_mode-1)?RX_STOP:RX_CHECK;
        RX_STOP:ns = (bit_cnt==9&&bps_cnt==bps_mode-1)?WAIT_START:RX_STOP;
        default:ns = WAIT_START;
    endcase
end

always@(posedge CLK_50M,negedge rst_n)begin
    if(!rst_n)begin
        cs <= WAIT_START;
    end
    else begin
        cs <= ns;
    end
end

//接收输出数据和数据缓存
always@(posedge CLK_50M,negedge rst_n)begin
    if(!rst_n)begin
        dout_reg <= 'd0;
    end
    else if(bit_cnt=='d9&&bps_cnt==bps_mode-1) begin
        dout_reg <= 'd0;
    end
    else if(bit_cnt >= 'd0 && bit_cnt <= 'd7 && bps_cnt == bps_mode-1)begin//当将有效数据全部存入后则停止
        dout_reg <= {RX_d2,dout_reg[7:1]};//移位寄存器
    end
end

//输出
always@(posedge CLK_50M or negedge rst_n)
  if(~rst_n)
    dout <= 'd0;            
  else if(bit_cnt == 'd9)//当前准备对停止位进行采样,但数据线上还是校验位，要等到bps_mode-1
    dout <= dout_reg;

//校验结果
always@(posedge CLK_50M or negedge rst_n)
  if(~rst_n)
    error <= 1'b0;  
  else if(!RX_flag)
    error <= 1'b0;  
  else if(bit_cnt == 'd9)begin//根据当前数据线的校验位进行对比
    if(check != RX_d2)
      error <= 1'b1; 
    end

//奇偶校验
assign e_check = ^dout_reg; //偶校验
assign o_check = ~e_check; //奇校验

assign check =(check_sel)? o_check : e_check;//奇偶校验选择
endmodule
