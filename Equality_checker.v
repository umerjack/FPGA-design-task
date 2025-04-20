`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2025 09:55:09 PM
// Design Name: 
// Module Name: Equality_checker
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


module Equality_checker (
    input wire [2:0] a,
    input wire [2:0] b,
    output wire eq
);
    assign eq = (a == b);
endmodule
