`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2025 09:05:10 PM
// Design Name: 
// Module Name: RAM
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


module RAM (
    input wire clk,
    input wire we,
    input wire [2:0] addr,
    input wire [7:0] din, //data width
    output wire [7:0] dout
);
    reg [7:0] mem [0:7];

    assign dout = mem[addr]; 

    always @(posedge clk) begin
        if (we)
            mem[addr] <= din;
    end
endmodule

