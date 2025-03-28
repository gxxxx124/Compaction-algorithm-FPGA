`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/10 18:45:17
// Design Name: 
// Module Name: LZW_Decode
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


module LZW_Decode(
    input               i_clk           ,
    input               i_rst           ,
    
    input  [15:0]       i_axis_data     ,
    input               i_axis_valid    ,
    input               i_axis_last     ,
    output              o_axis_ready    ,

    output [7 :0]       o_decode_data   ,
    output              o_decode_valid  
);

reg  [15 :0]            ri_data                 ;
reg                     ri_valid                ;
reg  [7  :0]            r_C                     ;
reg                     r_C_valid               ;
reg                     r_C_valid_1d            ;
reg  [127:0]            r_CS                    ;
reg  [7  :0]            r_CS_num                ;
reg  [127:0]            r_P                     ;
reg  [7  :0]            r_P_num                 ;
reg  [7  :0]            r_Dict_raddr            ;
reg  [7  :0]            r_Dict_waddr            ;
reg  [127:0]            r_Dict_Ram[0:9][0:7]    ;
reg  [7  :0]            r_Dict_Ram_num[0:9][0:7];
reg  [7  :0]            r_Dict_len              ;
reg                     ro_axis_ready           ;
reg  [7  :0]            ro_decode_data          ;
reg                     ro_decode_valid         ;
reg                     ro_decode_valid_1d      ;
reg  [7  :0]            r_out_num               ;
reg  [7  :0]            r_exist_addr            ;
reg                     r_exist                 ;
reg                     r_exist_valid           ;
reg                     r_exist_valid_1d        ;
reg                     r_exist_valid_2d        ;
reg                     r_exist_valid_3d        ;
reg  [7  :0]            r_Dict_num              ;

wire                    w_encode                ;
wire                    w_axis_active           ;
wire                    w_Dict_valid            ;
wire                    w_C_qurrey_end          ;


assign o_axis_ready   = ro_axis_ready           ;
assign o_decode_data  = ro_decode_data          ;
assign o_decode_valid = ro_decode_valid_1d      ;
assign w_axis_active  = i_axis_valid & o_axis_ready;
assign w_encode       = !ri_data[7 :0] && ri_data[15:8];
assign w_Dict_valid   = (r_exist_valid_1d && r_exist && r_P_num > 0) || (r_exist_valid && !r_exist);
assign w_C_qurrey_end = r_C_valid && r_Dict_raddr == r_Dict_len;

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        ri_data  <= 'd0;
        ri_valid <= 'd0;
    end else if(w_axis_active) begin
        ri_data  <= i_axis_data;
        ri_valid <= 'd1;
    end else begin
        ri_data  <= ri_data;
        ri_valid <= 'd0;
    end
end

//读入C
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        r_C <= 'd0;
    else if(w_encode)
        r_C <= ri_data[15:8];
    else
        r_C <= ri_data[7 :0];
end

//读入C有效，valid为高时查询ram,
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_C_valid <= 'd0;
    else if(r_C_valid)
        r_C_valid <= 'd0;
    else if(ri_valid)
        r_C_valid <= 'd1;
    else 
        r_C_valid <= r_C_valid;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_C_valid_1d <= 'd0;
    else 
        r_C_valid_1d <= r_C_valid;
end

//判断Dict中是否存在字符
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        r_exist <= 'd0;
    else if(r_exist_valid_2d)
        r_exist <= 'd0;
    else if(r_C_valid && !w_encode)
        r_exist <= 'd1;
    else if(r_C_valid && r_C <= (r_Dict_waddr << 3) + r_Dict_num) 
        r_exist <= 'd1;
    else            
        r_exist <= r_exist;
end

//对应Dict的地址
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_exist_addr <= 'd0;
    else if(w_encode)
        r_exist_addr <= ri_data[15:8];
    else 
        r_exist_addr <= 'd0;
end

//Dict查询完成信号
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        r_exist_valid <= 'd0;
    else 
        r_exist_valid <= r_C_valid & !r_C_valid_1d;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        r_exist_valid_1d <= 'd0;
        r_exist_valid_2d <= 'd0;
        r_exist_valid_3d <= 'd0;
    end else begin 
        r_exist_valid_1d <= r_exist_valid;
        r_exist_valid_2d <= r_exist_valid_1d;
        r_exist_valid_3d <= r_exist_valid_2d;
    end
end

//CS字符串
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_CS <= 'd0;
    else if(r_exist_valid && !r_exist)  
        case(r_P_num)
            1           :r_CS <= {r_P[119:0],r_P[15 :  8]};
            2           :r_CS <= {r_P[119:0],r_P[23 : 16]};
            3           :r_CS <= {r_P[119:0],r_P[31 : 24]};
            4           :r_CS <= {r_P[119:0],r_P[39 : 32]};
            5           :r_CS <= {r_P[119:0],r_P[47 : 40]};
            6           :r_CS <= {r_P[119:0],r_P[55 : 48]};
            7           :r_CS <= {r_P[119:0],r_P[63 : 56]};
            8           :r_CS <= {r_P[119:0],r_P[71 : 64]};
            9           :r_CS <= {r_P[119:0],r_P[79 : 72]};
            10          :r_CS <= {r_P[119:0],r_P[87 : 80]};
            11          :r_CS <= {r_P[119:0],r_P[95 : 88]};
            12          :r_CS <= {r_P[119:0],r_P[103: 96]};
            13          :r_CS <= {r_P[119:0],r_P[111:104]};
            14          :r_CS <= {r_P[119:0],r_P[119:112]};
            15          :r_CS <= {r_P[119:0],r_P[127:120]};
            16          :r_CS <= {r_P[119:0],r_P[7  :0]};
        endcase     
    else if(r_exist_valid && r_exist && !w_encode)
        r_CS <= r_C;
    else if(r_exist_valid && r_exist && w_encode)
        case(r_C >> 3)
            0       :r_CS <= r_Dict_Ram[r_C -  1][r_C >> 3];
            1       :r_CS <= r_Dict_Ram[r_C -  9][r_C >> 3];
            2       :r_CS <= r_Dict_Ram[r_C - 17][r_C >> 3];
            3       :r_CS <= r_Dict_Ram[r_C - 25][r_C >> 3];
            4       :r_CS <= r_Dict_Ram[r_C - 33][r_C >> 3];
            5       :r_CS <= r_Dict_Ram[r_C - 41][r_C >> 3];
            6       :r_CS <= r_Dict_Ram[r_C - 49][r_C >> 3];
            7       :r_CS <= r_Dict_Ram[r_C - 57][r_C >> 3];
            default :r_CS <= r_Dict_Ram[r_C -  1][r_C >> 3];
        endcase
    else 
        r_CS <= r_CS;
end

//记录CS的字符个数，从1开始
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_CS_num <= 'd0;
    else if(r_exist_valid && !r_exist)
        r_CS_num <= r_P_num + 1;
    else if(r_exist_valid && r_exist && !w_encode)
        r_CS_num <= 'd1;
    else if(r_exist_valid && r_exist && w_encode)
        case(r_C >> 3)
            0       :r_CS_num <= r_Dict_Ram_num[r_C -  1][r_C >> 3];
            1       :r_CS_num <= r_Dict_Ram_num[r_C -  9][r_C >> 3];
            2       :r_CS_num <= r_Dict_Ram_num[r_C - 17][r_C >> 3];
            3       :r_CS_num <= r_Dict_Ram_num[r_C - 25][r_C >> 3];
            4       :r_CS_num <= r_Dict_Ram_num[r_C - 33][r_C >> 3];
            5       :r_CS_num <= r_Dict_Ram_num[r_C - 41][r_C >> 3];
            6       :r_CS_num <= r_Dict_Ram_num[r_C - 49][r_C >> 3];
            7       :r_CS_num <= r_Dict_Ram_num[r_C - 57][r_C >> 3];
            default :r_CS_num <= r_Dict_Ram_num[r_C -  1][r_C >> 3];
        endcase
    else 
        r_CS_num <= r_CS_num;
end

//P字符串长度
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_P_num <= 'd0;
    else if(r_exist_valid_2d)
        r_P_num <= r_CS_num;
    else if(r_exist_valid_1d && r_exist && r_P_num > 0)   
        r_P_num <= r_P_num + 1;
    else if(r_exist_valid_1d && r_exist && r_P_num == 0)
        r_P_num <= r_CS_num;
    else 
        r_P_num <= r_P_num;
end

//P字符串
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_P <= 128'd0;
    else if(r_exist_valid_2d)
        r_P <= r_CS;
    else if(r_exist_valid_1d && r_exist && r_P_num > 0)
        r_P <= {r_P[119:0],r_CS[7 :0]};
    else if(r_exist_valid_1d && r_exist && r_P_num == 0)
        r_P <= r_CS;
    else 
        r_P <= r_P;
end

//查询地址，valid有高期间遍历ram;
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_Dict_raddr <= 'd0;
    else if(r_C_valid && r_Dict_raddr == r_Dict_len)
        r_Dict_raddr <= 'd0;
    else if(r_C_valid)
        r_Dict_raddr <= r_Dict_raddr + 1;
    else 
        r_Dict_raddr <= r_Dict_raddr;
end

//记录当前RAM中元素深度
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_Dict_len <= 'd0;
    else if(w_Dict_valid && r_Dict_num == 7)
        r_Dict_len <= r_Dict_len + 1;
    else 
        r_Dict_len <= r_Dict_len;
end

//Dict写地址
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_Dict_waddr <= 'd0;
    else if(w_Dict_valid && r_Dict_num == 7)
        r_Dict_waddr <= r_Dict_waddr + 1;
    else 
        r_Dict_waddr <= r_Dict_waddr;
end

//Dict写指定并行RAM
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_Dict_num <= 'd0;
    else if(w_Dict_valid && r_Dict_num == 7)
        r_Dict_num <= 'd0;
    else if(w_Dict_valid)   
        r_Dict_num <= r_Dict_num + 1;
    else 
        r_Dict_num <= r_Dict_num;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        r_out_num <= 'd0;
    else if(r_exist_valid_2d)
        r_out_num <= r_CS_num;
    else if(ro_decode_valid)
        r_out_num <= r_out_num - 1;
    else 
        r_out_num <= r_out_num;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        ro_decode_data <= 'd0;
    else case(r_out_num)
        1           :ro_decode_data <= r_P[7  :  0];
        2           :ro_decode_data <= r_P[15 :  8];
        3           :ro_decode_data <= r_P[23 : 16];
        4           :ro_decode_data <= r_P[31 : 24];
        5           :ro_decode_data <= r_P[39 : 32];
        6           :ro_decode_data <= r_P[47 : 40];
        7           :ro_decode_data <= r_P[55 : 48];
        8           :ro_decode_data <= r_P[63 : 56];
        9           :ro_decode_data <= r_P[71 : 64];
        10          :ro_decode_data <= r_P[79 : 72];
        11          :ro_decode_data <= r_P[87 : 80];
        12          :ro_decode_data <= r_P[95 : 88];
        13          :ro_decode_data <= r_P[103: 96];
        14          :ro_decode_data <= r_P[111:104];
        15          :ro_decode_data <= r_P[119:112];
        16          :ro_decode_data <= r_P[127:120];
        default     :ro_decode_data <= 'd0;
    endcase
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        ro_decode_valid <= 'd0;
    else if(ro_decode_valid && r_out_num == 1)
        ro_decode_valid <= 'd0;
    else if(r_exist_valid_3d)
        ro_decode_valid <= 'd1;
    else 
        ro_decode_valid <= ro_decode_valid;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        ro_decode_valid_1d <= 'd0;
    else 
        ro_decode_valid_1d <= ro_decode_valid;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) 
        ro_axis_ready <= 'd1;
    else if(w_axis_active)
        ro_axis_ready <= 'd0;
    else if(ro_decode_valid && r_out_num == 1)
        ro_axis_ready <= 'd1;
    else 
        ro_axis_ready <= ro_axis_ready;
end

genvar i;
generate 
    for(i = 0 ; i < 10 ; i = i + 1)
    begin

        //写Dict
        always@(posedge i_clk,posedge i_rst)
        begin
            if(i_rst) 
                r_Dict_Ram[i][r_Dict_waddr] <= 'd0;
            else if((r_exist_valid && !r_exist) && i == r_Dict_num)
                r_Dict_Ram[i][r_Dict_waddr] <= {r_P[119:0],r_P[7  :0]};
            else if((r_exist_valid_1d && r_exist && r_P_num > 0) && i == r_Dict_num)
                r_Dict_Ram[i][r_Dict_waddr] <= {r_P[119:0],r_CS[7 :0]};
            else 
                r_Dict_Ram[i][r_Dict_waddr] <= r_Dict_Ram[i][r_Dict_waddr];
        end

        //写Dict中字符串的长度
        always@(posedge i_clk,posedge i_rst)
        begin
            if(i_rst) 
                r_Dict_Ram_num[i][r_Dict_waddr] <= 'd1;
            else if((r_exist_valid && !r_exist) && i == r_Dict_num)
                r_Dict_Ram_num[i][r_Dict_waddr] <= r_P_num + 1;
            else if((r_exist_valid_1d && r_exist && r_P_num > 0) && i == r_Dict_num)
                r_Dict_Ram_num[i][r_Dict_waddr] <= r_P_num + 1;
            else    
                r_Dict_Ram_num[i][r_Dict_waddr] <= r_Dict_Ram_num[i][r_Dict_waddr];
        end
end
endgenerate

endmodule
