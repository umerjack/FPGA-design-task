`timescale 1ns/1ps

module tb_top_axi_dpe_wrapper;

  // Clock and Reset
  logic clk;
  logic rst;
  logic rstn;

  // BRAM preload interface
  logic [3:0]   x_wr_addr;
  logic [31:0]  x_wr_data;
  logic [127:0]  x_wr_en;

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
reg [255:0] m_axi_rdata_sequence [0:127];

initial begin
    m_axi_rdata_sequence[0]   = {32'h7,   32'h6,   32'h5,   32'h4,   32'h3,   32'h2,   32'h1,   32'h0};//sum in float =28.0 it skiping it 
    m_axi_rdata_sequence[1]   = {32'hF,   32'hE,   32'hD,   32'hC,   32'hB,   32'hA,   32'h9,   32'h8};//sum in float =92.0
    m_axi_rdata_sequence[2]   = {32'h17,  32'h16,  32'h15,  32'h14,  32'h13,  32'h12,  32'h11,  32'h10};//sum in float =156.0
    m_axi_rdata_sequence[3]   = {32'h1F,  32'h1E,  32'h1D,  32'h1C,  32'h1B,  32'h1A,  32'h19,  32'h18};//sum in float =220.0
    m_axi_rdata_sequence[4]   = {32'h27,  32'h26,  32'h25,  32'h24,  32'h23,  32'h22,  32'h21,  32'h20};//sum in float =284.0
    m_axi_rdata_sequence[5]   = {32'h2F,  32'h2E,  32'h2D,  32'h2C,  32'h2B,  32'h2A,  32'h29,  32'h28};//sum in float =348.0
    m_axi_rdata_sequence[6]   = {32'h37,  32'h36,  32'h35,  32'h34,  32'h33,  32'h32,  32'h31,  32'h30};//sum in float =412.0
    m_axi_rdata_sequence[7]   = {32'h3F,  32'h3E,  32'h3D,  32'h3C,  32'h3B,  32'h3A,  32'h39,  32'h38};//sum in float =476.0
    m_axi_rdata_sequence[8]   = {32'h47,  32'h46,  32'h45,  32'h44,  32'h43,  32'h42,  32'h41,  32'h40};//sum in float =540.0
    m_axi_rdata_sequence[9]   = {32'h4F,  32'h4E,  32'h4D,  32'h4C,  32'h4B,  32'h4A,  32'h49,  32'h48};//sum in float =604.0
    m_axi_rdata_sequence[10]  = {32'h57,  32'h56,  32'h55,  32'h54,  32'h53,  32'h52,  32'h51,  32'h50};//sum in float =668.0
    m_axi_rdata_sequence[11]  = {32'h5F,  32'h5E,  32'h5D,  32'h5C,  32'h5B,  32'h5A,  32'h59,  32'h58};//sum in float =732.0
    m_axi_rdata_sequence[12]  = {32'h67,  32'h66,  32'h65,  32'h64,  32'h63,  32'h62,  32'h61,  32'h60};//sum in float =796.0
    m_axi_rdata_sequence[13]  = {32'h6F,  32'h6E,  32'h6D,  32'h6C,  32'h6B,  32'h6A,  32'h69,  32'h68};//sum in float =860.0
    m_axi_rdata_sequence[14]  = {32'h77,  32'h76,  32'h75,  32'h74,  32'h73,  32'h72,  32'h71,  32'h70};//sum in float =924.0
    m_axi_rdata_sequence[15]  = {32'h7F,  32'h7E,  32'h7D,  32'h7C,  32'h7B,  32'h7A,  32'h79,  32'h78};//sum in float =998.0
    m_axi_rdata_sequence[16]  = {32'h87,  32'h86,  32'h85,  32'h84,  32'h83,  32'h82,  32'h81,  32'h80};//sum in float =-996.0
    m_axi_rdata_sequence[17]  = {32'h8F,  32'h8E,  32'h8D,  32'h8C,  32'h8B,  32'h8A,  32'h89,  32'h88};//sum in float =-932.0
    m_axi_rdata_sequence[18]  = {32'h97,  32'h96,  32'h95,  32'h94,  32'h93,  32'h92,  32'h91,  32'h90};//sum in float =-868.0
    m_axi_rdata_sequence[19]  = {32'h9F,  32'h9E,  32'h9D,  32'h9C,  32'h9B,  32'h9A,  32'h99,  32'h98};//sum in float =-804.0
    m_axi_rdata_sequence[20]  = {32'hA7,  32'hA6,  32'hA5,  32'hA4,  32'hA3,  32'hA2,  32'hA1,  32'hA0};//sum in float =-740.0
    m_axi_rdata_sequence[21]  = {32'hAF,  32'hAE,  32'hAD,  32'hAC,  32'hAB,  32'hAA,  32'hA9,  32'hA8};//sum in float =-676.0
    m_axi_rdata_sequence[22]  = {32'hB7,  32'hB6,  32'hB5,  32'hB4,  32'hB3,  32'hB2,  32'hB1,  32'hB0};//sum in float =-612.0
    m_axi_rdata_sequence[23]  = {32'hBF,  32'hBE,  32'hBD,  32'hBC,  32'hBB,  32'hBA,  32'hB9,  32'hB8};//sum in float =-548.0
    m_axi_rdata_sequence[24]  = {32'hC7,  32'hC6,  32'hC5,  32'hC4,  32'hC3,  32'hC2,  32'hC1,  32'hC0};//sum in float =-484.0
    m_axi_rdata_sequence[25]  = {32'hCF,  32'hCE,  32'hCD,  32'hCC,  32'hCB,  32'hCA,  32'hC9,  32'hC8};
    m_axi_rdata_sequence[26]  = {32'hD7,  32'hD6,  32'hD5,  32'hD4,  32'hD3,  32'hD2,  32'hD1,  32'hD0};
    m_axi_rdata_sequence[27]  = {32'hDF,  32'hDE,  32'hDD,  32'hDC,  32'hDB,  32'hDA,  32'hD9,  32'hD8};
    m_axi_rdata_sequence[28]  = {32'hE7,  32'hE6,  32'hE5,  32'hE4,  32'hE3,  32'hE2,  32'hE1,  32'hE0};
    m_axi_rdata_sequence[29]  = {32'hEF,  32'hEE,  32'hED,  32'hEC,  32'hEB,  32'hEA,  32'hE9,  32'hE8};
    m_axi_rdata_sequence[30]  = {32'hF7,  32'hF6,  32'hF5,  32'hF4,  32'hF3,  32'hF2,  32'hF1,  32'hF0};
    m_axi_rdata_sequence[31]  = {32'hFF,  32'hFE,  32'hFD,  32'hFC,  32'hFB,  32'hFA,  32'hF9,  32'hF8};
    m_axi_rdata_sequence[32]  = {32'h107, 32'h106, 32'h105, 32'h104, 32'h103, 32'h102, 32'h101, 32'h100};
    m_axi_rdata_sequence[33]  = {32'h10F, 32'h10E, 32'h10D, 32'h10C, 32'h10B, 32'h10A, 32'h109, 32'h108};
    m_axi_rdata_sequence[34]  = {32'h117, 32'h116, 32'h115, 32'h114, 32'h113, 32'h112, 32'h111, 32'h110};
    m_axi_rdata_sequence[35]  = {32'h11F, 32'h11E, 32'h11D, 32'h11C, 32'h11B, 32'h11A, 32'h119, 32'h118};
    m_axi_rdata_sequence[36]  = {32'h127, 32'h126, 32'h125, 32'h124, 32'h123, 32'h122, 32'h121, 32'h120};
    m_axi_rdata_sequence[37]  = {32'h12F, 32'h12E, 32'h12D, 32'h12C, 32'h12B, 32'h12A, 32'h129, 32'h128};
    m_axi_rdata_sequence[38]  = {32'h137, 32'h136, 32'h135, 32'h134, 32'h133, 32'h132, 32'h131, 32'h130};
    m_axi_rdata_sequence[39]  = {32'h13F, 32'h13E, 32'h13D, 32'h13C, 32'h13B, 32'h13A, 32'h139, 32'h138};
    m_axi_rdata_sequence[40]  = {32'h147, 32'h146, 32'h145, 32'h144, 32'h143, 32'h142, 32'h141, 32'h140};
    m_axi_rdata_sequence[41]  = {32'h14F, 32'h14E, 32'h14D, 32'h14C, 32'h14B, 32'h14A, 32'h149, 32'h148};
    m_axi_rdata_sequence[42]  = {32'h157, 32'h156, 32'h155, 32'h154, 32'h153, 32'h152, 32'h151, 32'h150};
    m_axi_rdata_sequence[43]  = {32'h15F, 32'h15E, 32'h15D, 32'h15C, 32'h15B, 32'h15A, 32'h159, 32'h158};
    m_axi_rdata_sequence[44]  = {32'h167, 32'h166, 32'h165, 32'h164, 32'h163, 32'h162, 32'h161, 32'h160};
    m_axi_rdata_sequence[45]  = {32'h16F, 32'h16E, 32'h16D, 32'h16C, 32'h16B, 32'h16A, 32'h169, 32'h168};
    m_axi_rdata_sequence[46]  = {32'h177, 32'h176, 32'h175, 32'h174, 32'h173, 32'h172, 32'h171, 32'h170};
    m_axi_rdata_sequence[47]  = {32'h17F, 32'h17E, 32'h17D, 32'h17C, 32'h17B, 32'h17A, 32'h179, 32'h178};
    m_axi_rdata_sequence[48]  = {32'h187, 32'h186, 32'h185, 32'h184, 32'h183, 32'h182, 32'h181, 32'h180};
    m_axi_rdata_sequence[49]  = {32'h18F, 32'h18E, 32'h18D, 32'h18C, 32'h18B, 32'h18A, 32'h189, 32'h188};
    m_axi_rdata_sequence[50]  = {32'h197, 32'h196, 32'h195, 32'h194, 32'h193, 32'h192, 32'h191, 32'h190};
    m_axi_rdata_sequence[51]  = {32'h19F, 32'h19E, 32'h19D, 32'h19C, 32'h19B, 32'h19A, 32'h199, 32'h198};
    m_axi_rdata_sequence[52]  = {32'h1A7, 32'h1A6, 32'h1A5, 32'h1A4, 32'h1A3, 32'h1A2, 32'h1A1, 32'h1A0};
    m_axi_rdata_sequence[53]  = {32'h1AF, 32'h1AE, 32'h1AD, 32'h1AC, 32'h1AB, 32'h1AA, 32'h1A9, 32'h1A8};
    m_axi_rdata_sequence[54]  = {32'h1B7, 32'h1B6, 32'h1B5, 32'h1B4, 32'h1B3, 32'h1B2, 32'h1B1, 32'h1B0};
    m_axi_rdata_sequence[55]  = {32'h1BF, 32'h1BE, 32'h1BD, 32'h1BC, 32'h1BB, 32'h1BA, 32'h1B9, 32'h1B8};
    m_axi_rdata_sequence[56]  = {32'h1C7, 32'h1C6, 32'h1C5, 32'h1C4, 32'h1C3, 32'h1C2, 32'h1C1, 32'h1C0};
    m_axi_rdata_sequence[57]  = {32'h1CF, 32'h1CE, 32'h1CD, 32'h1CC, 32'h1CB, 32'h1CA, 32'h1C9, 32'h1C8};
    m_axi_rdata_sequence[58]  = {32'h1D7, 32'h1D6, 32'h1D5, 32'h1D4, 32'h1D3, 32'h1D2, 32'h1D1, 32'h1D0};
    m_axi_rdata_sequence[59]  = {32'h1DF, 32'h1DE, 32'h1DD, 32'h1DC, 32'h1DB, 32'h1DA, 32'h1D9, 32'h1D8};
    m_axi_rdata_sequence[60]  = {32'h1E7, 32'h1E6, 32'h1E5, 32'h1E4, 32'h1E3, 32'h1E2, 32'h1E1, 32'h1E0};
    m_axi_rdata_sequence[61]  = {32'h1EF, 32'h1EE, 32'h1ED, 32'h1EC, 32'h1EB, 32'h1EA, 32'h1E9, 32'h1E8};
    m_axi_rdata_sequence[62]  = {32'h1F7, 32'h1F6, 32'h1F5, 32'h1F4, 32'h1F3, 32'h1F2, 32'h1F1, 32'h1F0};
    m_axi_rdata_sequence[63]  = {32'h1FF, 32'h1FE, 32'h1FD, 32'h1FC, 32'h1FB, 32'h1FA, 32'h1F9, 32'h1F8};
    m_axi_rdata_sequence[64]  = {32'h207, 32'h206, 32'h205, 32'h204, 32'h203, 32'h202, 32'h201, 32'h200};
    m_axi_rdata_sequence[65]  = {32'h20F, 32'h20E, 32'h20D, 32'h20C, 32'h20B, 32'h20A, 32'h209, 32'h208};
    m_axi_rdata_sequence[66]  = {32'h217, 32'h216, 32'h215, 32'h214, 32'h213, 32'h212, 32'h211, 32'h210};
    m_axi_rdata_sequence[67]  = {32'h21F, 32'h21E, 32'h21D, 32'h21C, 32'h21B, 32'h21A, 32'h219, 32'h218};
    m_axi_rdata_sequence[68]  = {32'h227, 32'h226, 32'h225, 32'h224, 32'h223, 32'h222, 32'h221, 32'h220};
    m_axi_rdata_sequence[69]  = {32'h22F, 32'h22E, 32'h22D, 32'h22C, 32'h22B, 32'h22A, 32'h229, 32'h228};
    m_axi_rdata_sequence[70]  = {32'h237, 32'h236, 32'h235, 32'h234, 32'h233, 32'h232, 32'h231, 32'h230};
    m_axi_rdata_sequence[71]  = {32'h23F, 32'h23E, 32'h23D, 32'h23C, 32'h23B, 32'h23A, 32'h239, 32'h238};
    m_axi_rdata_sequence[72]  = {32'h247, 32'h246, 32'h245, 32'h244, 32'h243, 32'h242, 32'h241, 32'h240};
    m_axi_rdata_sequence[73]  = {32'h24F, 32'h24E, 32'h24D, 32'h24C, 32'h24B, 32'h24A, 32'h249, 32'h248};
    m_axi_rdata_sequence[74]  = {32'h257, 32'h256, 32'h255, 32'h254, 32'h253, 32'h252, 32'h251, 32'h250};
    m_axi_rdata_sequence[75]  = {32'h25F, 32'h25E, 32'h25D, 32'h25C, 32'h25B, 32'h25A, 32'h259, 32'h258};
    m_axi_rdata_sequence[76]  = {32'h267, 32'h266, 32'h265, 32'h264, 32'h263, 32'h262, 32'h261, 32'h260};
    m_axi_rdata_sequence[77]  = {32'h26F, 32'h26E, 32'h26D, 32'h26C, 32'h26B, 32'h26A, 32'h269, 32'h268};
    m_axi_rdata_sequence[78]  = {32'h277, 32'h276, 32'h275, 32'h274, 32'h273, 32'h272, 32'h271, 32'h270};
    m_axi_rdata_sequence[79]  = {32'h27F, 32'h27E, 32'h27D, 32'h27C, 32'h27B, 32'h27A, 32'h279, 32'h278};
    m_axi_rdata_sequence[80]  = {32'h287, 32'h286, 32'h285, 32'h284, 32'h283, 32'h282, 32'h281, 32'h280};
    m_axi_rdata_sequence[81]  = {32'h28F, 32'h28E, 32'h28D, 32'h28C, 32'h28B, 32'h28A, 32'h289, 32'h288};
    m_axi_rdata_sequence[82]  = {32'h297, 32'h296, 32'h295, 32'h294, 32'h293, 32'h292, 32'h291, 32'h290};
    m_axi_rdata_sequence[83]  = {32'h29F, 32'h29E, 32'h29D, 32'h29C, 32'h29B, 32'h29A, 32'h299, 32'h298};
    m_axi_rdata_sequence[84]  = {32'h2A7, 32'h2A6, 32'h2A5, 32'h2A4, 32'h2A3, 32'h2A2, 32'h2A1, 32'h2A0};
    m_axi_rdata_sequence[85]  = {32'h2AF, 32'h2AE, 32'h2AD, 32'h2AC, 32'h2AB, 32'h2AA, 32'h2A9, 32'h2A8};
    m_axi_rdata_sequence[86]  = {32'h2B7, 32'h2B6, 32'h2B5, 32'h2B4, 32'h2B3, 32'h2B2, 32'h2B1, 32'h2B0};
    m_axi_rdata_sequence[87]  = {32'h2BF, 32'h2BE, 32'h2BD, 32'h2BC, 32'h2BB, 32'h2BA, 32'h2B9, 32'h2B8};
    m_axi_rdata_sequence[88]  = {32'h2C7, 32'h2C6, 32'h2C5, 32'h2C4, 32'h2C3, 32'h2C2, 32'h2C1, 32'h2C0};
    m_axi_rdata_sequence[89]  = {32'h2CF, 32'h2CE, 32'h2CD, 32'h2CC, 32'h2CB, 32'h2CA, 32'h2C9, 32'h2C8};
    m_axi_rdata_sequence[90]  = {32'h2D7, 32'h2D6, 32'h2D5, 32'h2D4, 32'h2D3, 32'h2D2, 32'h2D1, 32'h2D0};//sum in float =-340.0
    m_axi_rdata_sequence[91]  = {32'h2DF, 32'h2DE, 32'h2DD, 32'h2DC, 32'h2DB, 32'h2DA, 32'h2D9, 32'h2D8};//sum in float =-276.0
    m_axi_rdata_sequence[92]  = {32'h2E7, 32'h2E6, 32'h2E5, 32'h2E4, 32'h2E3, 32'h2E2, 32'h2E1, 32'h2E0};//sum in float =-212.0
    m_axi_rdata_sequence[93]  = {32'h2EF, 32'h2EE, 32'h2ED, 32'h2EC, 32'h2EB, 32'h2EA, 32'h2E9, 32'h2E8};//sum in float =-148.0
    m_axi_rdata_sequence[94]  = {32'h2F7, 32'h2F6, 32'h2F5, 32'h2F4, 32'h2F3, 32'h2F2, 32'h2F1, 32'h2F0};//sum in float =-84.0
    m_axi_rdata_sequence[95]  = {32'h2FF, 32'h2FE, 32'h2FD, 32'h2FC, 32'h2FB, 32'h2FA, 32'h2F9, 32'h2F8};//sum in float =-20.0
    m_axi_rdata_sequence[96]  = {32'h307, 32'h306, 32'h305, 32'h304, 32'h303, 32'h302, 32'h301, 32'h300};//sum in float =52.0
    m_axi_rdata_sequence[97]  = {32'h30F, 32'h30E, 32'h30D, 32'h30C, 32'h30B, 32'h30A, 32'h309, 32'h308};//sum in float =116.0
    m_axi_rdata_sequence[98]  = {32'h317, 32'h316, 32'h315, 32'h314, 32'h313, 32'h312, 32'h311, 32'h310};//sum in float =180.0
    m_axi_rdata_sequence[99]  = {32'h31F, 32'h31E, 32'h31D, 32'h31C, 32'h31B, 32'h31A, 32'h319, 32'h318};//sum in float =244.0
    m_axi_rdata_sequence[100] = {32'h327, 32'h326, 32'h325, 32'h324, 32'h323, 32'h322, 32'h321, 32'h320};//sum in float =308.0
    m_axi_rdata_sequence[101] = {32'h32F, 32'h32E, 32'h32D, 32'h32C, 32'h32B, 32'h32A, 32'h329, 32'h328};//sum in float =372.0
    m_axi_rdata_sequence[102] = {32'h337, 32'h336, 32'h335, 32'h334, 32'h333, 32'h332, 32'h331, 32'h330};//sum in float =4360
    m_axi_rdata_sequence[103] = {32'h33F, 32'h33E, 32'h33D, 32'h33C, 32'h33B, 32'h33A, 32'h339, 32'h338};//sum in float =500.0
    m_axi_rdata_sequence[104] = {32'h347, 32'h346, 32'h345, 32'h344, 32'h343, 32'h342, 32'h341, 32'h340};//sum in float =564.0
    m_axi_rdata_sequence[105] = {32'h34F, 32'h34E, 32'h34D, 32'h34C, 32'h34B, 32'h34A, 32'h349, 32'h348};//sum in float =628.0
    m_axi_rdata_sequence[106] = {32'h357, 32'h356, 32'h355, 32'h354, 32'h353, 32'h352, 32'h351, 32'h350};//sum in float =692.0
    m_axi_rdata_sequence[107] = {32'h35F, 32'h35E, 32'h35D, 32'h35C, 32'h35B, 32'h35A, 32'h359, 32'h358};//sum in float =756.0
    m_axi_rdata_sequence[108] = {32'h367, 32'h366, 32'h365, 32'h364, 32'h363, 32'h362, 32'h361, 32'h360};//sum in float =820.0
    m_axi_rdata_sequence[109] = {32'h36F, 32'h36E, 32'h36D, 32'h36C, 32'h36B, 32'h36A, 32'h369, 32'h368};//sum in float =884.0
    m_axi_rdata_sequence[110] = {32'h377, 32'h376, 32'h375, 32'h374, 32'h373, 32'h372, 32'h371, 32'h370};//sum in float =948.0
    m_axi_rdata_sequence[111] = {32'h37F, 32'h37E, 32'h37D, 32'h37C, 32'h37B, 32'h37A, 32'h379, 32'h378};//sum in float =1012
    m_axi_rdata_sequence[112] = {32'h387, 32'h386, 32'h385, 32'h384, 32'h383, 32'h382, 32'h381, 32'h380};//sum in float =-972.0
    m_axi_rdata_sequence[113] = {32'h38F, 32'h38E, 32'h38D, 32'h38C, 32'h38B, 32'h38A, 32'h389, 32'h388};//sum in float =-908.0
    m_axi_rdata_sequence[114] = {32'h397, 32'h396, 32'h395, 32'h394, 32'h393, 32'h392, 32'h391, 32'h390};//sum in float =-844.0
    m_axi_rdata_sequence[115] = {32'h39F, 32'h39E, 32'h39D, 32'h39C, 32'h39B, 32'h39A, 32'h399, 32'h398};//sum in float =-780.0
    m_axi_rdata_sequence[116] = {32'h3A7, 32'h3A6, 32'h3A5, 32'h3A4, 32'h3A3, 32'h3A2, 32'h3A1, 32'h3A0};//sum in float =-716.0
    m_axi_rdata_sequence[117] = {32'h3AF, 32'h3AE, 32'h3AD, 32'h3AC, 32'h3AB, 32'h3AA, 32'h3A9, 32'h3A8};//sum in float =-652.0
    m_axi_rdata_sequence[118] = {32'h3B7, 32'h3B6, 32'h3B5, 32'h3B4, 32'h3B3, 32'h3B2, 32'h3B1, 32'h3B0};//sum in float =-588.0
    m_axi_rdata_sequence[119] = {32'h3BF, 32'h3BE, 32'h3BD, 32'h3BC, 32'h3BB, 32'h3BA, 32'h3B9, 32'h3B8};//sum in float =-524.0
    m_axi_rdata_sequence[120] = {32'h3C7, 32'h3C6, 32'h3C5, 32'h3C4, 32'h3C3, 32'h3C2, 32'h3C1, 32'h3C0};//sum in float =-460.0
    m_axi_rdata_sequence[121] = {32'h3CF, 32'h3CE, 32'h3CD, 32'h3CC, 32'h3CB, 32'h3CA, 32'h3C9, 32'h3C8};//sum in float =-396.0
    m_axi_rdata_sequence[122] = {32'h3D7, 32'h3D6, 32'h3D5, 32'h3D4, 32'h3D3, 32'h3D2, 32'h3D1, 32'h3D0};//sum in float =-332.0
    m_axi_rdata_sequence[123] = {32'h3DF, 32'h3DE, 32'h3DD, 32'h3DC, 32'h3DB, 32'h3DA, 32'h3D9, 32'h3D8};//sum in float =-268.0
    m_axi_rdata_sequence[124] = {32'h3E7, 32'h3E6, 32'h3E5, 32'h3E4, 32'h3E3, 32'h3E2, 32'h3E1, 32'h3E0};//sum in float =-204.0
    m_axi_rdata_sequence[125] = {32'h3EF, 32'h3EE, 32'h3ED, 32'h3EC, 32'h3EB, 32'h3EA, 32'h3E9, 32'h3E8};//sum in float =-140.0
    m_axi_rdata_sequence[126] = {32'h3F7, 32'h3F6, 32'h3F5, 32'h3F4, 32'h3F3, 32'h3F2, 32'h3F1, 32'h3F0};//sum in float =-76.0
    m_axi_rdata_sequence[127] = {32'h3FF, 32'h3FE, 32'h3FD, 32'h3FC, 32'h3FB, 32'h3FA, 32'h3F9, 32'h3F8};//sum in float =-12.0
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
    for (int i = 0; i < 64; i++) begin
      @(posedge clk);
      x_wr_en   = 64'b1 << i;
      x_wr_data = 32'h3F800000; // FP32: 1.0
      x_wr_addr = 4'd0;
    end
    x_wr_en = 64'd0;

    #20;
    
    // Setup AXI-Lite registers
    assign dpe_data_type = 2; // REG_DPE_DATA_TYPE (int8)
    
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
    // Write to REG_CONTROL (0x0C) — start DMA
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
