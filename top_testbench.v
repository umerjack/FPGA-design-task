`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2025 11:28:01 AM
// Design Name: 
// Module Name: top_testbench
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


`timescale 1ns / 1ps

module top_testbench;

    // Parameters
    parameter N = 8;
    parameter L = 3;

    // Inputs to top_module
    reg clk, rst, s;
    reg Rd, Wrinit;
    reg [N-1:0] Datain;
    reg [L-1:0] Radd;

    // Outputs
    wire [N-1:0] DataOut;
    wire done;

    // Instantiate DUT
    top_module #(N, L) dut (
        .clk(clk),
        .rst(rst),
        .s(s),
        .done(done),
        .Rd(Rd),
        .Wrinit(Wrinit),
        .Datain(Datain),
        .Radd(Radd),
        .DataOut(DataOut)
    );

    // Clock generation: 50 MHz => 20ns period
    initial clk = 0;
    always #10 clk = ~clk;

    integer i;
    reg [N-1:0] expected [0:7]; // Expected sorted result
    reg [N-1:0] predefined_values [0:7]; // Input data read from file
    reg pass;

    initial begin
        // === Define Predefined Values ===
           predefined_values[0] = 8'd16;
           predefined_values[1] = 8'd14;
           predefined_values[2] = 8'd12;
           predefined_values[3] = 8'd10;
           predefined_values[4] = 8'd8;
           predefined_values[5] = 8'd6;
           predefined_values[6] = 8'd4;
           predefined_values[7] = 8'd2;
   
           // === Expected Sorted Result ==
           expected[0] = 8'd10;
           expected[1] = 8'd15;
           expected[2] = 8'd25;
           expected[3] = 8'd30;
           expected[4] = 8'd45;
           expected[5] = 8'd60;
           expected[6] = 8'd75;
           expected[7] = 8'd90;
        
        

        // Initial values
        rst = 1;
        s = 0;
        Wrinit = 0;
        Rd = 0;
        Datain = 0;
        Radd = 0;

        // Hold reset for 2 clock cycles
        #40;
        rst = 0;

        // === Write initial data to memory in reverse ===
        for (i = 0; i < 8; i = i + 1) begin
            Datain = predefined_values[i];
            Radd = i;
            Wrinit = 1;
            #20;
        end
        Wrinit = 0;

        // === Start Sorting ===
        s = 1;
        #20;

        // Wait for done signal
        wait (done == 1);
        #20;

        // === Read and Compare Sorted Result ===
        s=0;
        pass = 0;
        Rd = 1;
        for (i = 0; i < 8; i = i + 1) begin
            Radd = i;
            #20;
            if (DataOut !== expected[i]) begin
                $display("FAIL: M[%0d] = %0d, expected %0d", i, DataOut, expected[i]);
                pass = 0;
            end else begin
                $display("PASS: M[%0d] = %0d", i, DataOut);
                 pass = 1;
            end
        end
        Rd = 0;

        if (pass)
            $display("\n?  Test PASSED.");
        else
            $display("\n?  Test FAILED.");

        $stop;
    end
endmodule

