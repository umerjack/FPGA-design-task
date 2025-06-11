module bram_8kx32_sp (
    input  wire        clk,      // clock for read/write
    input  wire        en,       // enable
    input  wire        we,       // write enable (1 = write, 0 = read)
    input  wire [12:0] addr,     // 13-bit address (up to 8K)
    input  wire [31:0] din,      // data in (for write)
    output reg  [31:0] dout      // data out (for read)
);

    // Memory array
    (* ram_style = "block" *) reg [31:0] mem [0:8191];  // 8K entries of 32-bit width
    
    always @(posedge clk) begin
        if (en) begin
            if (we)
                mem[addr] <= din;
            else
                dout <= mem[addr];
        end
    end
endmodule
