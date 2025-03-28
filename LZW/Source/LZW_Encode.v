`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 

// Design Name: 
// Module Name: LZW_Encode
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


module LZW_Encode(
    input           i_clk           ,
    input           i_rst           ,

    input  [7 :0]   i_axis_data     ,
    input           i_axis_valid    ,
    input           i_axis_last     ,
    output          o_axis_ready    ,

    output [15:0]   o_axis_encode   ,
    output          o_axis_envalid  ,
    input           i_axis_enready  
);

reg                 ro_axis_ready       ;
reg  [15 :0]        ro_axis_encode      ;
reg                 ro_axis_envalid     ;
reg  [127:0]        r_PC                ;
reg  [127:0]        r_PC_d              ;
reg  [10 :0]        r_PC_valid          ;
reg  [7  :0]        r_C                 ;
reg                 r_C_valid           ;
reg  [7  :0]        r_PC_num            ;
reg  [7  :0]        r_out_num           ;
reg  [9  :0]        r_PC_exist          ;
reg                 r_Dict_exist        ;
reg                 r_Dict_exist_1d     ;
reg  [7  :0]        r_log_addr          ;
reg  [7  :0]        r_log_ram           ; 
reg                 r_querry_cmp        ;
reg                 r_querry_cmp_1d     ;
reg                 r_axis_last         ;
reg                 r_string_last       ;
reg  [7  :0]        r_Dict_len          ;
reg  [7  :0]        r_Dict_addr         ;
reg  [7  :0]        r_Dict_addr_1d      ;
reg  [7  :0]        r_Dict_addr_2d      ;
reg  [7  :0]        r_Dict_write_addr   ;
reg  [7  :0]        r_Dict_num          ;
reg  [127:0]        r_Dict_Ram[0:9][0:7];
reg  [7  :0]        r_Dict_Ram_num[0:9][0:7];


wire                w_axis_active       ;

assign o_axis_ready   = ro_axis_ready   ;
assign o_axis_encode  = ro_axis_encode  ;
assign o_axis_envalid = ro_axis_envalid ;
assign w_axis_active  = i_axis_valid & o_axis_ready;

//ready控制
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_axis_ready <= 'd1;
    else if(w_axis_active)
        ro_axis_ready <= 'd0;
    else if(r_querry_cmp)
        ro_axis_ready <= 'd1;
    else 
        ro_axis_ready <= ro_axis_ready;
end

//last信号，表示最后一个数据
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_axis_last <= 'd0;
    else if(w_axis_active)
        r_axis_last <= i_axis_last;
    else 
        r_axis_last <= 'd0;
end

//字符串结束信号
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_string_last <= 'd0;
    else if(r_string_last && r_out_num > 0 && r_Dict_exist_1d)
        r_string_last <= 'd0;
    else if(ro_axis_envalid && r_string_last && !r_Dict_exist_1d)
        r_string_last <= 'd0;
    else if(r_axis_last)
        r_string_last <= 'd1;
    else 
        r_string_last <= r_string_last;
end

//输出字符个数
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        r_out_num <= 'd0;
    else if(r_querry_cmp_1d && !r_Dict_exist_1d)
        r_out_num <= 'd0;
    else if(r_string_last && r_querry_cmp && r_Dict_exist)
        r_out_num <= r_PC_num;
    else if(r_querry_cmp && !r_Dict_exist)
        r_out_num <= r_PC_num;
    else 
        r_out_num <= r_out_num;
end

//串行输出编码数据
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)   
        ro_axis_encode <= 'd0;
    else if(r_string_last && r_out_num > 0 && r_Dict_exist_1d)
        ro_axis_encode <= {r_log_addr + 8'd1,8'd0};
    else if(r_out_num > 1)
        ro_axis_encode <= {r_log_addr + 8'd1,8'd0};
    else case(r_out_num)
         0          :ro_axis_encode <= {8'd0,r_PC_d[7  :  0]};
         1          :ro_axis_encode <= {8'd0,r_PC_d[15 :  8]};
         2          :ro_axis_encode <= {8'd0,r_PC_d[23 : 16]};
         3          :ro_axis_encode <= {8'd0,r_PC_d[31 : 24]};
         4          :ro_axis_encode <= {8'd0,r_PC_d[39 : 32]};
         5          :ro_axis_encode <= {8'd0,r_PC_d[47 : 40]};
         6          :ro_axis_encode <= {8'd0,r_PC_d[55 : 48]};
         7          :ro_axis_encode <= {8'd0,r_PC_d[63 : 56]};
         8          :ro_axis_encode <= {8'd0,r_PC_d[71 : 64]};
         9          :ro_axis_encode <= {8'd0,r_PC_d[79 : 72]};
        10          :ro_axis_encode <= {8'd0,r_PC_d[87 : 80]};
        11          :ro_axis_encode <= {8'd0,r_PC_d[95 : 88]};
        12          :ro_axis_encode <= {8'd0,r_PC_d[103: 96]};
        13          :ro_axis_encode <= {8'd0,r_PC_d[111:104]};
        14          :ro_axis_encode <= {8'd0,r_PC_d[119:112]};
        15          :ro_axis_encode <= {8'd0,r_PC_d[127:120]};
        default     :ro_axis_encode <= 'd0;        
    endcase
end

//输出编码有效信号
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_axis_envalid <= 'd0;
    else if(ro_axis_envalid && r_string_last && !r_Dict_exist_1d)
        ro_axis_envalid <= 'd1;
    else if(ro_axis_envalid)
        ro_axis_envalid <= 'd0;
    else if(r_string_last && r_out_num > 0 && r_Dict_exist_1d)
        ro_axis_envalid <= 'd1;
    else if(r_querry_cmp_1d && !r_Dict_exist_1d)
        ro_axis_envalid <= 'd1;
    else 
        ro_axis_envalid <= ro_axis_envalid;
end

//输入新的字符C
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        r_C       <= 'd0;
        r_C_valid <= 'd0;
    end else if(w_axis_active) begin
        r_C       <= i_axis_data;
        r_C_valid <= 'd1;
    end else begin
        r_C       <= r_C;
        r_C_valid <= 'd0;
    end 
end

//字符串判断窗口P+C
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_PC <= 128'd0;
    else if(r_querry_cmp && !r_Dict_exist)
        r_PC <= {120'd0,r_PC[7:0]};
    else if(r_C_valid)
        r_PC <= {r_PC[119:0],r_C};
    else 
        r_PC <= r_PC;
end

//记录不存在的P+C串，用于编码数据输出
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_PC_d <= 'd0;
    else if(r_querry_cmp && !r_Dict_exist)
        r_PC_d <= r_PC;
    else 
        r_PC_d <= r_PC_d;
end     

//P+C开始判断信号
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_PC_valid[0] <= 'd0;
    else 
        r_PC_valid[0] <= r_C_valid;
end

//开始判断信号打拍
genvar j;
generate 
    for(j = 1 ; j < 11 ; j = j + 1)
    begin
        always@(posedge i_clk)
            if(r_C_valid | r_querry_cmp)
                r_PC_valid[j] <= 0;
            else 
                r_PC_valid[j] <= r_PC_valid[j - 1];
    end
endgenerate

//P+C串的长度
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_PC_num <= 'd0;
    else if(r_querry_cmp && !r_Dict_exist)
        r_PC_num <= 'd1;
    else if(r_querry_cmp && r_Dict_exist)
        r_PC_num <= r_PC_num + 1;
    else 
        r_PC_num <= r_PC_num;
end

//字典存入深度
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_Dict_len <= 'd0;
    else if(r_querry_cmp && !r_Dict_exist && r_Dict_num == 7)
        r_Dict_len <= r_Dict_len + 1;
    else 
        r_Dict_len <= r_Dict_len;
end

//字典并行寻址
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_Dict_addr <= 'd0;
    else if(r_querry_cmp)
        r_Dict_addr <= 'd0;
    else if(r_Dict_addr < r_Dict_len && (|r_PC_exist == 0) && r_PC_valid)
        r_Dict_addr <= r_Dict_addr + 1;
    else 
        r_Dict_addr <= r_Dict_addr;
end

//地址打拍
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        r_Dict_addr_1d <= 'd0;
        r_Dict_addr_2d <= 'd0;
    end else begin
        r_Dict_addr_1d <= r_Dict_addr;
        r_Dict_addr_2d <= r_Dict_addr_1d;
    end
end

//字典数据对比完成
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_querry_cmp <= 'd0;
    else if(r_querry_cmp)
        r_querry_cmp <= 'd0;
    else if(r_PC_valid && (|r_PC_exist == 1))
        r_querry_cmp <= 'd1;
    else if(r_Dict_addr == r_Dict_len && r_PC_valid[r_Dict_addr + 1])
        r_querry_cmp <= 'd1;
    else    
        r_querry_cmp <= 'd0;
end

//打拍
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_querry_cmp_1d <= 'd0;
    else    
        r_querry_cmp_1d <= r_querry_cmp;
end

//字典中是否存在P+C标志
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_Dict_exist <= 'd0;
    else if(r_PC_valid && (|r_PC_exist == 1))
        r_Dict_exist <= 'd1;
    else if(r_Dict_addr == r_Dict_len && r_PC_valid[r_Dict_addr + 1])
        r_Dict_exist <= 'd0;
    else 
        r_Dict_exist <= r_Dict_exist;
end

//记录存在P+C串的ram编号
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_log_ram <= 'd0;
    else if(r_PC_exist[0])
        r_log_ram <= 'd0;
    else if(r_PC_exist[1])
        r_log_ram <= 'd1;
    else if(r_PC_exist[2])
        r_log_ram <= 'd2;
    else if(r_PC_exist[3])
        r_log_ram <= 'd3;
    else if(r_PC_exist[4])
        r_log_ram <= 'd4;
    else if(r_PC_exist[5])
        r_log_ram <= 'd5;
    else if(r_PC_exist[6])
        r_log_ram <= 'd6;
    else if(r_PC_exist[7])
        r_log_ram <= 'd7;
    else if(r_PC_exist[8])
        r_log_ram <= 'd8;
    else if(r_PC_exist[9])
        r_log_ram <= 'd9;
    else 
        r_log_ram <= r_log_ram;
end

//记录编码数据的字典标号
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_log_addr <= 'd0;
    else if(r_querry_cmp && r_Dict_exist)
        r_log_addr <= (r_Dict_addr_2d << 3) + r_log_ram;
    else 
        r_log_addr <= r_log_addr;
end

//打拍
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_Dict_exist_1d <= 'd0;
    else if(r_querry_cmp)
        r_Dict_exist_1d <= r_Dict_exist;
    else 
        r_Dict_exist_1d <= r_Dict_exist_1d;
end

//字典并行RAM控制
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_Dict_num <= 'd0;
    else if(r_querry_cmp && !r_Dict_exist && r_Dict_num == 7)
        r_Dict_num <= 'd0;
    else if(r_querry_cmp && !r_Dict_exist)
        r_Dict_num <= r_Dict_num + 1;
    else 
        r_Dict_num <= r_Dict_num;
end

//字典并行RAM地址控制
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_Dict_write_addr <= 'd0;
    else if(r_querry_cmp && !r_Dict_exist && r_Dict_num == 7)
        r_Dict_write_addr <= r_Dict_write_addr + 1;
    else 
        r_Dict_write_addr <= r_Dict_write_addr;
end

genvar i;
generate 
    for(i = 0 ; i < 10 ; i = i + 1)
    begin
        
        //P+C字符串查询
        always@(posedge i_clk,posedge i_rst)
        begin
                if(i_rst)   
                    r_PC_exist[i] <= 'd0;
                else if(r_PC_valid && r_PC_num == r_Dict_Ram_num[i][r_Dict_addr]) 
                    if(r_PC_num == 0)
                        r_PC_exist[i] = 1;
                    else if(r_PC == r_Dict_Ram[i][r_Dict_addr])
                        r_PC_exist[i] = 1;
                    else 
                        r_PC_exist[i] = 0;
                else        
                    r_PC_exist[i] <= 'd0;
        end

        //P+C字符串存入字典
        always@(posedge i_clk,posedge i_rst)
        begin
            if(i_rst) 
                r_Dict_Ram[i][r_Dict_write_addr] <= 'd0;
            else if(r_querry_cmp && !r_Dict_exist && i == r_Dict_num)
                r_Dict_Ram[i][r_Dict_write_addr] <= r_PC;
            else 
                r_Dict_Ram[i][r_Dict_write_addr] <= r_Dict_Ram[i][r_Dict_write_addr];
        end

        //记录存入P+C字符串字典中的字符串长度
        always@(posedge i_clk,posedge i_rst)
        begin
            if(i_rst) 
                r_Dict_Ram_num[i][r_Dict_write_addr] <= 'd0;
            else if(r_querry_cmp && !r_Dict_exist && i == r_Dict_num)
                r_Dict_Ram_num[i][r_Dict_write_addr] <= r_PC_num;
            else 
                r_Dict_Ram_num[i][r_Dict_write_addr] <= r_Dict_Ram_num[i][r_Dict_write_addr];
        end
end
endgenerate

endmodule
