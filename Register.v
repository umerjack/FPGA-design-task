`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2025 09:15:15 PM
// Design Name: 
// Module Name: Register
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


module Register (
    input wire clk,
    input wire rst,
    input wire en,
    input wire [7:0] d_in,
    output reg [7:0] d_out
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            d_out <= 8'd0;
        else if (en)
            d_out <= d_in;
    end
endmodule

