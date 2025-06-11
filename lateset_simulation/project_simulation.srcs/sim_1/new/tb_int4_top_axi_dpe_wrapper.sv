`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2025 01:59:18 PM
// Design Name: 
// Module Name: tb_int4_top_axi_dpe_wrapper
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


module tb_int4_top_axi_dpe_wrapper;

  // Clock and Reset
  logic clk;
  logic rst;
  logic rstn;

  // BRAM preload interface
  logic [3:0]   x_wr_addr;
  logic [31:0]  x_wr_data;
  logic [63:0]  x_wr_en;

  parameter S_AXI_ADDR_WIDTH = 32;
  
  // AXI-Lite
  logic         s_axi_awvalid = 0;
  logic         s_axi_awready;
  logic [S_AXI_ADDR_WIDTH-1:0]   s_axi_awaddr = 0;
  logic [2:0]   s_axi_awprot = 0;
  logic         s_axi_wvalid = 0;
  logic         s_axi_wready;
  logic [31:0]  s_axi_wdata = 0;
  logic [3:0]   s_axi_wstrb = 0;
  logic         s_axi_bvalid;
  logic         s_axi_bready = 0;
  logic [1:0]   s_axi_bresp;
  logic         s_axi_arvalid = 0;
  logic         s_axi_arready;
  logic [S_AXI_ADDR_WIDTH-1:0]   s_axi_araddr;
  logic [2:0]   s_axi_arprot;
  logic         s_axi_rvalid;
  logic         s_axi_rready;
  logic [31:0]  s_axi_rdata;
  logic [1:0]   s_axi_rresp;

  // AXI Master
  logic         m_axi_arvalid;
  logic         m_axi_arready = 0;
  logic [31:0]  m_axi_araddr;
  logic [7:0]   m_axi_arlen;
  logic [2:0]   m_axi_arsize;
  logic [1:0]   m_axi_arburst;
  logic [2:0]   m_axi_arprot;
  logic [3:0]   m_axi_arcache;
  logic         m_axi_rvalid = 0;
  logic         m_axi_rready;
  logic [255:0] m_axi_rdata;
  logic [1:0]   m_axi_rresp;
  logic         m_axi_rlast;
  logic         m_axi_awvalid;
  logic         m_axi_awready = 0;
  logic [31:0]  m_axi_awaddr;
  logic [7:0]   m_axi_awlen;
  logic [2:0]   m_axi_awsize;
  logic [1:0]   m_axi_awburst;
  logic [2:0]   m_axi_awprot;
  logic [3:0]   m_axi_awcache;
  logic         m_axi_wvalid;
  logic         m_axi_wready = 0;
  logic [255:0] m_axi_wdata;
  logic [31:0]  m_axi_wstrb;
  logic         m_axi_wlast;
  logic         m_axi_bvalid = 0;
  logic         m_axi_bready;
  logic [1:0]   m_axi_bresp;
  logic [31:0]  dpe_out;
  logic         dpe_done;  
  logic [2:0]   dpe_data_type;
  logic write_valid_o;

  // Parameters
  parameter NUM_WORDS = 128;


  // Clock generator
  initial clk = 0;
  always #5 clk = ~clk;

  // DUT instance
  top_axi_dpe_wrapper  #(.S_AXI_ADDR_WIDTH (S_AXI_ADDR_WIDTH)) 
  dut (
    .clk(clk),
    .rst(rst),
    .rstn(rstn),
    .x_wr_addr(x_wr_addr),
    .x_wr_data(x_wr_data),
    .x_wr_en(x_wr_en),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awprot(s_axi_awprot),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arprot(s_axi_arprot),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arlen(m_axi_arlen),
    .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst),
    .m_axi_arprot(m_axi_arprot),
    .m_axi_arcache(m_axi_arcache),
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready(m_axi_rready),
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp),
    .m_axi_rlast(m_axi_rlast),
    .m_axi_awvalid(m_axi_awvalid),
    .m_axi_awready(m_axi_awready),
    .m_axi_awaddr(m_axi_awaddr),
    .m_axi_awlen(m_axi_awlen),
    .m_axi_awsize(m_axi_awsize),
    .m_axi_awburst(m_axi_awburst),
    .m_axi_awprot(m_axi_awprot),
    .m_axi_awcache(m_axi_awcache),
    .m_axi_wvalid(m_axi_wvalid),
    .m_axi_wready(m_axi_wready),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wstrb(m_axi_wstrb),
    .m_axi_wlast(m_axi_wlast),
    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_bready(m_axi_bready),
    .m_axi_bresp(m_axi_bresp),  
    .dpe_data_type(dpe_data_type),
    .dpe_out(dpe_out),
    .dpe_done(dpe_done),
    .write_valid_o(write_valid_o)
  );

    // Pre-computed m_axi_rdata values with zero-padded left shifts of {0x00, ..., 0x1F}
    logic [255:0] m_axi_rdata_sequence [0:127];
   
 initial begin

    m_axi_rdata_sequence [0] = 256'h0F0E0D0C0B0A09080706050403020100FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    m_axi_rdata_sequence [1] = 256'h0102030405060708090A0B0C0D0E0F00F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00;
    m_axi_rdata_sequence [2] = 256'h1112131415161718191A1B1C1D1E1F20EFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF;
    m_axi_rdata_sequence [3] = 256'h7F7E7D7C7B7A7978777675747372717080808080808080808080808080808080;
    m_axi_rdata_sequence [4] = 256'h8889888988898889888988898889888988898889888988898889888988898889;
    m_axi_rdata_sequence [5] = 256'h000100020003000400050006000700080009000A000B000C000D000E000F0010;
    m_axi_rdata_sequence [6] = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    m_axi_rdata_sequence [7] = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    m_axi_rdata_sequence [8] = 256'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;
    m_axi_rdata_sequence [9] = 256'hF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF;
    m_axi_rdata_sequence [10] = 256'h13579BDF2468ACE013579BDF2468ACE013579BDF2468ACE013579BDF2468ACE0;
    m_axi_rdata_sequence [11] = 256'h89ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF01234567;
    m_axi_rdata_sequence [12] = 256'hFFEEDDCCBBAA99887766554433221100FFEEDDCCBBAA99887766554433221100;
    m_axi_rdata_sequence [13] = 256'h0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F;
    m_axi_rdata_sequence [14] = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    m_axi_rdata_sequence [15] = 256'h5555555555555555555555555555555555555555555555555555555555555555;
    m_axi_rdata_sequence [16] = 256'hABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789;
    m_axi_rdata_sequence [17] = 256'h13579BDF13579BDF13579BDF13579BDF13579BDF13579BDF13579BDF13579BDF;
    m_axi_rdata_sequence [18] = 256'hFEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210;
    m_axi_rdata_sequence [19] = 256'hC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DE;
    m_axi_rdata_sequence [20] = 256'hF1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00;
    m_axi_rdata_sequence [21] = 256'h00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF;
    m_axi_rdata_sequence [22] = 256'h7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F;
    m_axi_rdata_sequence [23] = 256'h0001000100010001000100010001000100010001000100010001000100010001;
    m_axi_rdata_sequence [24] = 256'h0808080808080808080808080808080808080808080808080808080808080808;
    m_axi_rdata_sequence [25] = 256'h8181818181818181818181818181818181818181818181818181818181818181;
    m_axi_rdata_sequence [26] = 256'h102030405060708090A0B0C0D0E0F000102030405060708090A0B0C0D0E0F000;
    m_axi_rdata_sequence [27] = 256'hFFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF;
    m_axi_rdata_sequence [28] = 256'hABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCA;
    m_axi_rdata_sequence [29] = 256'h1234123412341234123412341234123412341234123412341234123412341234;
    m_axi_rdata_sequence [30] = 256'h89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB;
    m_axi_rdata_sequence [31] = 256'hFEDC1234FEDC1234FEDC1234FEDC1234FEDC1234FEDC1234FEDC1234FEDC1234;
    m_axi_rdata_sequence [32] = 256'h0F0E0D0C0B0A09080706050403020100FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    m_axi_rdata_sequence [33] = 256'h0102030405060708090A0B0C0D0E0F00F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00;
    m_axi_rdata_sequence [34] = 256'h1112131415161718191A1B1C1D1E1F20EFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF;
    m_axi_rdata_sequence [35] = 256'h7F7E7D7C7B7A7978777675747372717080808080808080808080808080808080;
    m_axi_rdata_sequence [36] = 256'h8889888988898889888988898889888988898889888988898889888988898889;
    m_axi_rdata_sequence [37] = 256'h000100020003000400050006000700080009000A000B000C000D000E000F0010;
    m_axi_rdata_sequence [38] = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    m_axi_rdata_sequence [39] = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    m_axi_rdata_sequence [40] = 256'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;
    m_axi_rdata_sequence [41] = 256'hF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF;
    m_axi_rdata_sequence [42] = 256'h13579BDF2468ACE013579BDF2468ACE013579BDF2468ACE013579BDF2468ACE0;
    m_axi_rdata_sequence [43] = 256'h89ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF01234567;
    m_axi_rdata_sequence [44] = 256'hFFEEDDCCBBAA99887766554433221100FFEEDDCCBBAA99887766554433221100;
    m_axi_rdata_sequence [45] = 256'h0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F;
    m_axi_rdata_sequence [46] = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    m_axi_rdata_sequence [47] = 256'h5555555555555555555555555555555555555555555555555555555555555555;
    m_axi_rdata_sequence [48] = 256'hABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789;
    m_axi_rdata_sequence [49] = 256'h13579BDF13579BDF13579BDF13579BDF13579BDF13579BDF13579BDF13579BDF;
    m_axi_rdata_sequence [50] = 256'hFEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210;
    m_axi_rdata_sequence [51] = 256'hC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DE;
    m_axi_rdata_sequence [52] = 256'hF1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00;
    m_axi_rdata_sequence [53] = 256'h00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF;
    m_axi_rdata_sequence [54] = 256'h7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F;
    m_axi_rdata_sequence [55] = 256'h0001000100010001000100010001000100010001000100010001000100010001;
    m_axi_rdata_sequence [56] = 256'h0808080808080808080808080808080808080808080808080808080808080808;
    m_axi_rdata_sequence [57] = 256'h8181818181818181818181818181818181818181818181818181818181818181;
    m_axi_rdata_sequence [58] = 256'h102030405060708090A0B0C0D0E0F000102030405060708090A0B0C0D0E0F000;
    m_axi_rdata_sequence [59] = 256'hFFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF;
    m_axi_rdata_sequence [60] = 256'hABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCA;
    m_axi_rdata_sequence [61] = 256'h1234123412341234123412341234123412341234123412341234123412341234;
    m_axi_rdata_sequence [62] = 256'h89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB;
    m_axi_rdata_sequence [63] = 256'hFEDC1234FEDC1234FEDC1234FEDC1234FEDC1234FEDC1234FEDC1234FEDC1234;
    m_axi_rdata_sequence [64] = 256'h0F0E0D0C0B0A09080706050403020100FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    m_axi_rdata_sequence [65] = 256'h0102030405060708090A0B0C0D0E0F00F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00;
    m_axi_rdata_sequence [66] = 256'h1112131415161718191A1B1C1D1E1F20EFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF;
    m_axi_rdata_sequence [67] = 256'h7F7E7D7C7B7A7978777675747372717080808080808080808080808080808080;
    m_axi_rdata_sequence [68] = 256'h8889888988898889888988898889888988898889888988898889888988898889;
    m_axi_rdata_sequence [69] = 256'h000100020003000400050006000700080009000A000B000C000D000E000F0010;
    m_axi_rdata_sequence [70] = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    m_axi_rdata_sequence [71] = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    m_axi_rdata_sequence [72] = 256'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;
    m_axi_rdata_sequence [73] = 256'hF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF;
    m_axi_rdata_sequence [74] = 256'h13579BDF2468ACE013579BDF2468ACE013579BDF2468ACE013579BDF2468ACE0;
    m_axi_rdata_sequence [75] = 256'h89ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF01234567;
    m_axi_rdata_sequence [76] = 256'hFFEEDDCCBBAA99887766554433221100FFEEDDCCBBAA99887766554433221100;
    m_axi_rdata_sequence [77] = 256'h0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F;
    m_axi_rdata_sequence [78] = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    m_axi_rdata_sequence [79] = 256'h5555555555555555555555555555555555555555555555555555555555555555;
    m_axi_rdata_sequence [80] = 256'hABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789;
    m_axi_rdata_sequence [81] = 256'h13579BDF13579BDF13579BDF13579BDF13579BDF13579BDF13579BDF13579BDF;
    m_axi_rdata_sequence [82] = 256'hFEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210;
    m_axi_rdata_sequence [83] = 256'hC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DE;
    m_axi_rdata_sequence [84] = 256'hF1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00;
    m_axi_rdata_sequence [85] = 256'h00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF;
    m_axi_rdata_sequence [86] = 256'h7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F;
    m_axi_rdata_sequence [87] = 256'h0001000100010001000100010001000100010001000100010001000100010001;
    m_axi_rdata_sequence [88] = 256'h0808080808080808080808080808080808080808080808080808080808080808;
    m_axi_rdata_sequence [89] = 256'h8181818181818181818181818181818181818181818181818181818181818181;
    m_axi_rdata_sequence [90] = 256'h102030405060708090A0B0C0D0E0F000102030405060708090A0B0C0D0E0F000;
    m_axi_rdata_sequence [91] = 256'hFFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF;
    m_axi_rdata_sequence [92] = 256'hABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCA;
    m_axi_rdata_sequence [93] = 256'h1234123412341234123412341234123412341234123412341234123412341234;
    m_axi_rdata_sequence [94] = 256'h89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB;
    m_axi_rdata_sequence [95] = 256'hFEDC1234FEDC1234FEDC1234FEDC1234FEDC1234FEDC1234FEDC1234FEDC1234;
    m_axi_rdata_sequence [96] = 256'h0F0E0D0C0B0A09080706050403020100FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    m_axi_rdata_sequence [97] = 256'h0102030405060708090A0B0C0D0E0F00F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00;
    m_axi_rdata_sequence [98] = 256'h1112131415161718191A1B1C1D1E1F20EFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF;
    m_axi_rdata_sequence [99] = 256'h7F7E7D7C7B7A7978777675747372717080808080808080808080808080808080;
    m_axi_rdata_sequence [100] = 256'h8889888988898889888988898889888988898889888988898889888988898889;
    m_axi_rdata_sequence [101] = 256'h000100020003000400050006000700080009000A000B000C000D000E000F0010;
    m_axi_rdata_sequence [102] = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    m_axi_rdata_sequence [103] = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    m_axi_rdata_sequence [104] = 256'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;
    m_axi_rdata_sequence [105] = 256'hF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF;
    m_axi_rdata_sequence [106] = 256'h13579BDF2468ACE013579BDF2468ACE013579BDF2468ACE013579BDF2468ACE0;
    m_axi_rdata_sequence [107] = 256'h89ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF01234567;
    m_axi_rdata_sequence [108] = 256'hFFEEDDCCBBAA99887766554433221100FFEEDDCCBBAA99887766554433221100;
    m_axi_rdata_sequence [109] = 256'h0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F;
    m_axi_rdata_sequence [110] = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    m_axi_rdata_sequence [111] = 256'h5555555555555555555555555555555555555555555555555555555555555555;
    m_axi_rdata_sequence [112] = 256'hABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789;
    m_axi_rdata_sequence [113] = 256'h13579BDF13579BDF13579BDF13579BDF13579BDF13579BDF13579BDF13579BDF;
    m_axi_rdata_sequence [114] = 256'hFEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210;
    m_axi_rdata_sequence [115] = 256'hC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DE;
    m_axi_rdata_sequence [116] = 256'hF1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00;
    m_axi_rdata_sequence [117] = 256'h00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF;
    m_axi_rdata_sequence [118] = 256'h7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F;
    m_axi_rdata_sequence [119] = 256'h0001000100010001000100010001000100010001000100010001000100010001;
    m_axi_rdata_sequence [120] = 256'h0808080808080808080808080808080808080808080808080808080808080808;
    m_axi_rdata_sequence [121] = 256'h8181818181818181818181818181818181818181818181818181818181818181;
    m_axi_rdata_sequence [122] = 256'h102030405060708090A0B0C0D0E0F000102030405060708090A0B0C0D0E0F000;
    m_axi_rdata_sequence [123] = 256'hFFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF;
    m_axi_rdata_sequence [124] = 256'hABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCABCA;
    m_axi_rdata_sequence [125] = 256'h1234123412341234123412341234123412341234123412341234123412341234;
    m_axi_rdata_sequence [126] = 256'h89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB89AB;
    m_axi_rdata_sequence [127] = 256'hFEDC1234FEDC1234FEDC1234FEDC1234FEDC1234FEDC1234FEDC1234FEDC1234;
end
  // Reset sequence
  initial begin
    rst  = 1;
    rstn = 0;
    #20;
    rst  = 0;
    rstn = 1;
  end

  logic [6:0] j = 0;

  // Stimulus process
  initial begin
    // Preload x_vector with 1.0 FP32
    for (int i = 0; i < 33; i++) begin
      @(posedge clk);
      x_wr_en   = 64'b1 << i;
      x_wr_data = 32'h3F800000; // FP32: 1.0
      x_wr_addr = 4'd0;
    end
    x_wr_en = 64'd0;

    #20;
    
    // Setup AXI-Lite registers
    assign dpe_data_type = 1; // REG_DPE_DATA_TYPE (int8)
    
    #100;
    
    // =============================
    // Write to REG_SOURCE_ADDR (0x00)
    // =============================
    s_axi_awaddr  = 32'h3EC;
    s_axi_wdata   = 32'h00001000;
    s_axi_wstrb   = 4'hF;
    s_axi_awvalid = 1;
    s_axi_wvalid  = 1;
    s_axi_bready  = 1;

    wait (s_axi_awready && s_axi_wready);
    @(posedge clk);
    @(posedge clk);
    s_axi_awvalid = 0;
    s_axi_wvalid  = 0;

    wait (s_axi_bvalid);
    @(posedge clk);
    s_axi_bready = 0;

    // =============================
    // Write to REG_TARGET_ADDR (0x04)
    // =============================
    @(posedge clk);
    s_axi_awaddr  = 32'h3F0;
    s_axi_wdata   = 32'h00002000;
    s_axi_wstrb   = 4'hF;
    s_axi_awvalid = 1;
    s_axi_wvalid  = 1;
    s_axi_bready  = 1;

    wait (s_axi_awready && s_axi_wready);
    @(posedge clk);
    @(posedge clk);
    s_axi_awvalid = 0;
    s_axi_wvalid  = 0;

    wait (s_axi_bvalid);
    @(posedge clk);
    s_axi_bready = 0;

    // =============================
    // Write to REG_LENGTH (0x08)
    // =============================
    @(posedge clk);
    s_axi_awaddr  = 32'h3F4;
    s_axi_wdata   = 32'd64;
    s_axi_wstrb   = 4'hF;
    s_axi_awvalid = 1;
    s_axi_wvalid  = 1;
    s_axi_bready  = 1;

    wait (s_axi_awready && s_axi_wready);
    @(posedge clk);
    @(posedge clk);
    s_axi_awvalid = 0;
    s_axi_wvalid  = 0;

    wait (s_axi_bvalid);
    @(posedge clk);
    s_axi_bready = 0;

    // =========================================
    // Write to REG_CONTROL (0x0C) - start DMA
    // =========================================
    @(posedge clk);
    s_axi_awaddr  = 32'h3F8;
    s_axi_wdata   = 32'd1;
    s_axi_wstrb   = 4'hF;
    s_axi_awvalid = 1;
    s_axi_wvalid  = 1;
    s_axi_bready  = 1;

    wait (s_axi_awready && s_axi_wready);
    @(posedge clk);
    @(posedge clk);
    s_axi_awvalid = 0;
    s_axi_wvalid  = 0;

    wait (s_axi_bvalid);
    @(posedge clk);
    s_axi_bready = 0;

    @(posedge clk);
    @(posedge clk);
    @(negedge clk);
    
    // =========================================
    // Feed AXI read data (m_axi_rdata) from predefined sequence
    for (j = 0; j <= NUM_WORDS; j++) begin    

      m_axi_rvalid = 1;
      m_axi_rdata  = m_axi_rdata_sequence[j];
      m_axi_rlast  = (j == NUM_WORDS-1);
      
      // Wait for slave to accept the data
      wait (m_axi_rready);
      m_axi_arready = 1;
      @(negedge clk);
    end
    
    // Deassert after handshake
    m_axi_rvalid = 0;
    m_axi_rlast  = 0;

    // Wait for DMA completion
    repeat (1000) @(posedge clk);
    $finish;
  end
  
  // Monitor write_valid_o to start AXI write channel
  initial begin
    wait (write_valid_o);
    m_axi_awready = 1;
    m_axi_wready = 1;
    m_axi_bvalid = 1;
  end 

endmodule