`timescale 1ns / 1ps

module tb_top_dot_product_engine;

  logic clk = 0;
  logic rst = 1;
  logic rstn = 0;

  logic en = 1;
  logic start;
  logic [15:0] weight_element;
  logic [2:0]  data_type;
  logic [3:0]  x_wr_addr;
  logic [31:0] x_wr_data;
  logic [63:0] x_wr_en;

  logic [31:0] y_out;
  logic        done;

  // Clock generation (200 MHz)
  always #2.5 clk = ~clk;

  top_dot_product_engine dut (
    .clk           (clk),
    .rst           (rst),
    .rstn          (rstn),
    .en            (en),
    .start         (start),
    .weight_element(weight_element),
    .data_type     (data_type),
    .x_wr_addr     (x_wr_addr),
    .x_wr_data     (x_wr_data),
    .x_wr_en       (x_wr_en),
    .y_out         (y_out),
    .done          (done)
  );

  int i,j;
  logic [31:0] results [0:0];

  // Function to interpret 32-bit logic as real
  function real fp32_to_real(input logic [31:0] val);
    int unsigned temp;
    begin
      temp = val;
      fp32_to_real = $bitstoshortreal(temp);
    end
  endfunction

  // Task to preload x_vector[i] = 1.0 (FP32)
  task preload_bram;
    for (i = 0; i < 32; i++) begin
      @(posedge clk);
      x_wr_en   = 64'b1 << i;
      x_wr_data = 32'h3F800000; // 1.0 in FP32
      x_wr_addr = 4'd0;
    end
    @(posedge clk);
    x_wr_en = 64'd0;
  endtask

  initial begin
    start = 0;
    weight_element = 0;
//    data_type = 3'd1; // INT4
    data_type = 3'd2; // INT8
    x_wr_en = 0;
    x_wr_data = 0;
    x_wr_addr = 0;

    #20;
    rst = 0;
    rstn = 1;

    preload_bram();

    // Feed 32 INT8 values
//    for (i = 0; i < 32; i++) begin
//      @(posedge clk);
//      weight_element = i[7:0]; // 8-bit INT values
//    end

//    @(posedge clk);
//    start = 1;
//    repeat (5) @(posedge clk); // Give time for conversion and propagation
//    start = 0;
    
    for (j = 0; j < 128; j++) begin
//        weight_element = j; // unique row per dot product
        weight_element = j[7:0]; // unique row per dot product
        @(posedge clk);
        
        if (j >= 30) begin
            start = 1;
        end
    end  
 
    results[0] = y_out;
    $display("Dot product result = %h (%f)", y_out, fp32_to_real(y_out));

    #20;
    $finish;
  end

endmodule
