module FSM (
    input wire clk,
    input wire rst,s,
    input wire AgtB,
    input wire zi,
    input wire zj,
    
    output reg Li,
    output reg Lj,
    output reg Ei,
    output reg Ej,
    output reg EA,
    output reg EB,
    output reg WR,
    output reg Csel,
    output reg Bout,
    output reg done
);

    // Define states
    parameter S0 = 3'd0,
              S1 = 3'd1,
              S2 = 3'd2,
              S3 = 3'd3,
              S4 = 3'd4,
              S5 = 3'd5,
              S6 = 3'd6,
              S7 = 3'd7;

    reg [2:0] current_state, next_state;

    // State Register
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= S0;
        else
            current_state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        case (current_state)
            S0: next_state =(s)? S1:S0;

            S1: next_state = S2;

            S2: next_state = S3;

            S3: begin
                if (AgtB)
                    next_state = S4;
                else if (zj==1'b0)
                    next_state = S2;
                else if (zi==1'b1)
                    next_state = S7;
                else
                    next_state = S1;
            end

            S4: next_state = S5;

            S5: next_state = S6;

             S6: begin
    
                if (zj==1'b0)
                    next_state = S2;
                else if (zi==1'b1)
                    next_state = S7;
                else
                    next_state = S1;
            end

            S7: 
                
                    next_state = (s)?S7:S0;  // done state
     
            default: next_state = S0;
        endcase
    end

    // Output Logic
    always @(*) begin
        // Default all outputs to 0
        Li = 0; Lj = 0;
        Ei = 0; Ej = 0;
        EA = 0; EB = 0;
        WR = 0; Csel = 0; Bout = 0;
        done = 0;

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
                // Conditional outputs for retries
                if (!AgtB && !zj)
                    Ej = 1;
                else if (!AgtB && !zi)
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
           if(zj==1'b0) Ej=1;
          else if(zi==1'b0) Ei=1;
            end

            S7: begin
              
                    done = 1;
            end
        endcase
    end

endmodule
