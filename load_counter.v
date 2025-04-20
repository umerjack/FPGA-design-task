`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2025 09:49:25 PM
// Design Name: 
// Module Name: load_counter
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


module load_counter (
    input wire clk,
    input wire rst,
    input wire ld,
    input wire en,
    input wire [2:0] ld_val,
    output reg [2:0] count
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            count <= 3'd0;
        else if (ld)
            count <= ld_val;
        else if (en)
            count <= count + 1;
    end
endmodule
