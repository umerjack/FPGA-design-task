`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2025 01:08:43 AM
// Design Name: 
// Module Name: FSM
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

module FSM (
    input wire clk, rst, s,
    input wire zi, zj, AgtB,  // signal from datapath
    output reg Li, Lj, Ei, Ej,
    output reg EA, EB, WR, Csel, Bout,
    output reg done
);

    // === State Definitions ===
    parameter S0 = 3'd0,
              S1 = 3'd1,
              S2 = 3'd2,
              S3 = 3'd3,
              S4 = 3'd4,
              S5 = 3'd5,
              S6 = 3'd6,
              S7 = 3'd7;

    reg [2:0] current_state, next_state;

   //current state logic
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= S0;
        else
            current_state <= next_state;
    end

    // === Next State Logic ===
    always @(*) begin
        case (current_state)
            S0: next_state = (s) ? S1 : S0;

            S1: next_state = S2;

            S2: next_state = S3;

            S3: begin
                if (AgtB)
                    next_state = S4;
                else if (~zj)
                    next_state = S2;
                else
                    next_state = (zi) ? S7 : S1;
            end

            S4: next_state = S5;

            S5: next_state = S6;

            S6: begin
                if (~zj)
                    next_state = S2;
                else
                    next_state = (zi) ? S7 : S1;
            end

            S7: next_state = (s) ? S7 : S0;

            default: next_state = S0;
        endcase
    end

    // === Output Logic ===
    always @(*) begin
        // Default all control signals to 0
        Li = 0; Lj = 0; Ei = 0; Ej = 0;
        EA = 0; EB = 0; WR = 0; Csel = 0;
        Bout = 0; done = 0;

        case (current_state)
            S0: begin
                Li = 1;
                Ei = 1;
            end

            S1: begin
                EA = 1;
                Csel = 0;
                Lj = 1;
                Ej = 1;
            end

            S2: begin
                EB = 1;
                Csel = 1;
            end

            S3: begin
                if (~AgtB && ~zj)
                    Ej = 1;
                else if (~zi)
                    Ei = 1;
        
            end

            S4: begin
                WR = 1;
                Csel = 0;
                Bout = 1;
            end

            S5: begin
                WR = 1;
                Csel = 1;
                Bout = 0;
            end

            S6: begin
                EA = 1;
                Csel = 0;
                if (~zj)
                    Ej = 1;
                else if (~zi)
                    Ei = 1;
           
            end

            S7: begin
                done = 1;
            end
        endcase
    end

endmodule
