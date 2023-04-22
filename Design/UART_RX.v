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

module UART_RX#(
    parameter BAUD_RATE = 115200,
    parameter CLK_FREQ = 10_000_000,
    parameter VLD_DATA_WIDTH = 8,
    parameter CHECK_SEL = 1)
    (
    input CLK,
    input rst_n,
    input RX,
    output reg [VLD_DATA_WIDTH-1:0] dout,
    output reg error,
    output reg RX_dout_vld
    );

//状态机参数
localparam IDLE = 0,RECV_START = 1,RX_VLD_DATA = 2,RX_CHECK = 3,RX_STOP = 4;
localparam CLKS_PER_BIT =   CLK_FREQ / BAUD_RATE;

reg RX_flag;
wire dec_RX;
reg data_bit_mid,stop_bit_mid;
reg return_idle;

reg[7:0]dout_reg;
wire e_check;
wire o_check;
wire check;
reg [2:0] cs,ns;
reg RX_d1,RX_d2,RX_d3; //d1,d2为消除亚稳态，d3为下降沿检测

//时钟计数器
reg [31:0] CLK_cnt; //最慢的bps600模式需要17位计数器
reg[3:0] bit_cnt;//指示当前波特周期在接收第几位数据(跳过起始位，1-11)

//TAG 消除亚稳态+亚稳态
always@(posedge CLK or negedge rst_n)begin
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
always@(posedge CLK,posedge rst_n)begin
    if(!rst_n)
        RX_flag <= 0;
    else if(cs==RECV_START&&return_idle)
        RX_flag <= 0;
    else if(cs==RX_STOP&&CLK_cnt==CLKS_PER_BIT-1)
        RX_flag <= 0;
    else if(dec_RX)
        RX_flag <= 1;
end

//bit_cnt控制
always@(posedge CLK,negedge rst_n)begin
    if(!rst_n)
        bit_cnt <= 'd0;
    else if(RX_flag) begin
        if(cs!=RECV_START)begin
           if(CLK_cnt == CLKS_PER_BIT-1)
            bit_cnt <= bit_cnt + 1; 
        end
        else begin
            if(!return_idle)
                bit_cnt <= 'd2;
            else
                bit_cnt <= 'd0;
        end
    end
    else 
        bit_cnt <='d0;
end

//时钟计数
always@(posedge CLK or negedge rst_n)begin
  if(!rst_n)
    CLK_cnt <= 'd0;
  else if(CLK_cnt == (0.5*CLKS_PER_BIT)+1&&cs==RECV_START)begin//当采样完中间信号时计数器重置
    CLK_cnt <= 'd0;
  end
  else if(CLK_cnt == CLKS_PER_BIT-1) 
    CLK_cnt <= 'd0;
  else if(RX_flag)	//与发送端波特率同步
    CLK_cnt <= CLK_cnt + 1'b1;
  else
    CLK_cnt <= 'd0;
end

//data_bit_mid,stop_bit_mid，return _IDLE信号控制信号控制
always@(posedge CLK,negedge rst_n) begin
    if(!rst_n)begin
        data_bit_mid <= 0;
        stop_bit_mid <= 0;
        return_idle <= 0;
    end
    else begin
        if(cs==RECV_START&&CLK_cnt==(0.5*CLKS_PER_BIT))//在接收到下降沿后的半个周期的尾端进行采样
            if(RX_d2 == 0)
                return_idle <= 0;
            else
                return_idle <= 1;
        else
            return_idle <= 0;

        if(cs==RX_VLD_DATA&&CLK_cnt==CLKS_PER_BIT-1)
            data_bit_mid <= 1;
        else
            data_bit_mid <= 0;

        if(cs==RX_STOP&&CLK_cnt==CLKS_PER_BIT-1)
            stop_bit_mid <= 1;
        else
            stop_bit_mid <= 0;
    end
end



//接收状态控制
always@(*)begin
    case(cs)
        IDLE:ns = (RX_flag)?RECV_START:IDLE;
        RECV_START:ns = (CLK_cnt<(0.5*CLKS_PER_BIT+1))?RECV_START:((CLK_cnt==(0.5*CLKS_PER_BIT+1)&&return_idle)?IDLE:RX_VLD_DATA);
        RX_VLD_DATA:ns = (bit_cnt==VLD_DATA_WIDTH+1&&CLK_cnt==CLKS_PER_BIT-1)?RX_CHECK:RX_VLD_DATA;
        RX_CHECK:ns = (bit_cnt==VLD_DATA_WIDTH+2&&CLK_cnt==CLKS_PER_BIT-1)?RX_STOP:RX_CHECK;
        RX_STOP:ns = (bit_cnt==VLD_DATA_WIDTH+3&&CLK_cnt==CLKS_PER_BIT-1)?IDLE:RX_STOP;
        default:ns = IDLE;
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

//接收数据和缓存
always@(posedge CLK,negedge rst_n)begin
    if(!rst_n)begin
        dout_reg <= 'd0;
    end
    else if(bit_cnt=='d11&&CLK_cnt==CLKS_PER_BIT-1) begin
        dout_reg <= 'd0;
    end
    else if(bit_cnt >= 'd2 && bit_cnt <= 'd9 && CLK_cnt == CLKS_PER_BIT-1)begin//TAG 每当到达CLKS_PER_BITS时，处于有效数据的中间时刻
        dout_reg <= {RX_d2,dout_reg[7:1]};//移位寄存器
    end
end

//缓存输出
always@(posedge CLK or negedge rst_n)
  if(~rst_n)
    dout <= 'd0;            
  else if(cs==RX_CHECK)//当前准备对校验位进行采样，此时输出已缓存的所有有效数据
    dout <= dout_reg;

//校验结果
always@(posedge CLK or negedge rst_n)
  if(!rst_n)
    error <= 1'b0;  
  else if(!RX_flag)
    error <= 1'b0;  
  else if(cs==RX_CHECK&&CLK_cnt==CLKS_PER_BIT-1)begin//根据当前数据线的校验位的中间时刻进行对比
    if(check != RX_d2)
      error <= 1'b1; 
    end

//RX_dout_vld逻辑
always @(posedge CLK,negedge rst_n) begin
    if(!rst_n)
        RX_dout_vld <= 0;
    else if(cs==RX_CHECK&&CLK_cnt==0)
        RX_dout_vld <= 1;
    else
        RX_dout_vld <= 0;
end

//奇偶校验
assign e_check = ^dout_reg; //偶校验
assign o_check = ~e_check; //奇校验
assign check =(CHECK_SEL)? o_check : e_check;//奇偶校验选择
endmodule
