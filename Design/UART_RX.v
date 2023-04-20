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

//������ѡ��
localparam bps600   = 17'd8_3333;
localparam bps1200  = 17'd4_1667;
localparam bps2400  = 17'd2_0833;
localparam bps4800  = 17'd1_0417;
localparam bps9600  = 17'd5208;
localparam bps19200 = 17'd2604;
localparam bps38400 = 17'd1302;

//״̬������
localparam WAIT_START = 1,RX_VLD_DATA = 2,RX_CHECK = 3,RX_STOP = 4;

reg RX_flag;
wire dec_RX;
reg[3:0] bit_cnt;//ָʾ��ǰ���������ڽ��յڼ�λ����(������ʼλ��0-9)
reg[7:0]dout_reg;
wire e_check;
wire o_check;
wire check;
reg [2:0] cs,ns;
reg RX_d1,RX_d2,RX_d3; //d1,d2Ϊ��������̬��d3Ϊ�½��ؼ��

//�����ʼ�����
reg [16:0] bps_mode;
reg [16:0] bps_cnt; //������bps600ģʽ��Ҫ17λ������


//��������̬+����̬
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

//�½��ؼ��
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

//bit_cnt����
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

//�����ʼ���
always@(posedge CLK_50M or negedge rst_n)begin
  if(!rst_n)
    bps_cnt <= 'd0;
  else if(bps_cnt == bps_mode-1) 
    bps_cnt <= 'd0;
  else if(RX_flag)	//�뷢�Ͷ˲�����ͬ��
    bps_cnt <= bps_cnt + 1'b1;
  else
    bps_cnt <= 'd0;
end


//����״̬��
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

//����������ݺ����ݻ���
always@(posedge CLK_50M,negedge rst_n)begin
    if(!rst_n)begin
        dout_reg <= 'd0;
    end
    else if(bit_cnt=='d9&&bps_cnt==bps_mode-1) begin
        dout_reg <= 'd0;
    end
    else if(bit_cnt >= 'd0 && bit_cnt <= 'd7 && bps_cnt == bps_mode-1)begin//������Ч����ȫ���������ֹͣ
        dout_reg <= {RX_d2,dout_reg[7:1]};//��λ�Ĵ���
    end
end

//���
always@(posedge CLK_50M or negedge rst_n)
  if(~rst_n)
    dout <= 'd0;            
  else if(bit_cnt == 'd9)//��ǰ׼����ֹͣλ���в���,���������ϻ���У��λ��Ҫ�ȵ�bps_mode-1
    dout <= dout_reg;

//У����
always@(posedge CLK_50M or negedge rst_n)
  if(~rst_n)
    error <= 1'b0;  
  else if(!RX_flag)
    error <= 1'b0;  
  else if(bit_cnt == 'd9)begin//���ݵ�ǰ�����ߵ�У��λ���жԱ�
    if(check != RX_d2)
      error <= 1'b1; 
    end

//��żУ��
assign e_check = ^dout_reg; //żУ��
assign o_check = ~e_check; //��У��

assign check =(check_sel)? o_check : e_check;//��żУ��ѡ��
endmodule
