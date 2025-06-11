-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
-- Date        : Sun Jun  1 22:53:48 2025
-- Host        : hp running 64-bit Ubuntu 20.04.6 LTS
-- Command     : write_vhdl -force -mode synth_stub -rename_top floating_point_3 -prefix
--               floating_point_3_ floating_point_3_stub.vhdl
-- Design      : floating_point_3
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcku5p-ffvb676-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity floating_point_3 is
  Port ( 
    aclk : in STD_LOGIC;
    aresetn : in STD_LOGIC;
    s_axis_a_tvalid : in STD_LOGIC;
    s_axis_a_tready : out STD_LOGIC;
    s_axis_a_tdata : in STD_LOGIC_VECTOR ( 15 downto 0 );
    m_axis_result_tvalid : out STD_LOGIC;
    m_axis_result_tready : in STD_LOGIC;
    m_axis_result_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );

  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of floating_point_3 : entity is "floating_point_3,floating_point_v7_1_19,{}";
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of floating_point_3 : entity is "floating_point_3,floating_point_v7_1_19,{x_ipProduct=Vivado 2024.2,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=floating_point,x_ipVersion=7.1,x_ipCoreRevision=19,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_XDEVICEFAMILY=kintexuplus,C_PART=xcku5p-ffvb676-2-i,C_HAS_ADD=0,C_HAS_SUBTRACT=0,C_HAS_MULTIPLY=0,C_HAS_DIVIDE=0,C_HAS_SQRT=0,C_HAS_COMPARE=0,C_HAS_FIX_TO_FLT=1,C_HAS_FLT_TO_FIX=0,C_HAS_FLT_TO_FLT=0,C_HAS_RECIP=0,C_HAS_RECIP_SQRT=0,C_HAS_ABSOLUTE=0,C_HAS_LOGARITHM=0,C_HAS_EXPONENTIAL=0,C_HAS_FMA=0,C_HAS_FMS=0,C_HAS_UNFUSED_MULTIPLY_ADD=0,C_HAS_UNFUSED_MULTIPLY_SUB=0,C_HAS_UNFUSED_MULTIPLY_ACCUMULATOR_A=0,C_HAS_UNFUSED_MULTIPLY_ACCUMULATOR_S=0,C_HAS_ACCUMULATOR_A=0,C_HAS_ACCUMULATOR_S=0,C_HAS_ACCUMULATOR_PRIMITIVE_A=0,C_HAS_ACCUMULATOR_PRIMITIVE_S=0,C_A_WIDTH=16,C_A_FRACTION_WIDTH=0,C_B_WIDTH=16,C_B_FRACTION_WIDTH=0,C_C_WIDTH=16,C_C_FRACTION_WIDTH=0,C_RESULT_WIDTH=32,C_RESULT_FRACTION_WIDTH=24,C_COMPARE_OPERATION=8,C_LATENCY=1,C_OPTIMIZATION=1,C_MULT_USAGE=0,C_BRAM_USAGE=0,C_RATE=1,C_ACCUM_INPUT_MSB=32,C_ACCUM_MSB=32,C_ACCUM_LSB=-31,C_HAS_UNDERFLOW=0,C_HAS_OVERFLOW=0,C_HAS_INVALID_OP=0,C_HAS_DIVIDE_BY_ZERO=0,C_HAS_ACCUM_OVERFLOW=0,C_HAS_ACCUM_INPUT_OVERFLOW=0,C_HAS_ACLKEN=0,C_HAS_ARESETN=1,C_THROTTLE_SCHEME=1,C_HAS_A_TUSER=0,C_HAS_A_TLAST=0,C_HAS_B=0,C_HAS_B_TUSER=0,C_HAS_B_TLAST=0,C_HAS_C=0,C_HAS_C_TUSER=0,C_HAS_C_TLAST=0,C_HAS_OPERATION=0,C_HAS_OPERATION_TUSER=0,C_HAS_OPERATION_TLAST=0,C_HAS_RESULT_TUSER=0,C_HAS_RESULT_TLAST=0,C_TLAST_RESOLUTION=0,C_A_TDATA_WIDTH=16,C_A_TUSER_WIDTH=1,C_B_TDATA_WIDTH=16,C_B_TUSER_WIDTH=1,C_C_TDATA_WIDTH=16,C_C_TUSER_WIDTH=1,C_OPERATION_TDATA_WIDTH=8,C_OPERATION_TUSER_WIDTH=1,C_RESULT_TDATA_WIDTH=32,C_RESULT_TUSER_WIDTH=1,C_FIXED_DATA_UNSIGNED=0}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of floating_point_3 : entity is "yes";
end floating_point_3;

architecture stub of floating_point_3 is
  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "aclk,aresetn,s_axis_a_tvalid,s_axis_a_tready,s_axis_a_tdata[15:0],m_axis_result_tvalid,m_axis_result_tready,m_axis_result_tdata[31:0]";
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_INFO of aclk : signal is "xilinx.com:signal:clock:1.0 aclk_intf CLK";
  attribute X_INTERFACE_MODE : string;
  attribute X_INTERFACE_MODE of aclk : signal is "slave";
  attribute X_INTERFACE_PARAMETER : string;
  attribute X_INTERFACE_PARAMETER of aclk : signal is "XIL_INTERFACENAME aclk_intf, ASSOCIATED_BUSIF S_AXIS_OPERATION:M_AXIS_RESULT:S_AXIS_C:S_AXIS_B:S_AXIS_A, ASSOCIATED_RESET aresetn, ASSOCIATED_CLKEN aclken, FREQ_HZ 10000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of aresetn : signal is "xilinx.com:signal:reset:1.0 aresetn_intf RST";
  attribute X_INTERFACE_MODE of aresetn : signal is "slave";
  attribute X_INTERFACE_PARAMETER of aresetn : signal is "XIL_INTERFACENAME aresetn_intf, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of s_axis_a_tvalid : signal is "xilinx.com:interface:axis:1.0 S_AXIS_A TVALID";
  attribute X_INTERFACE_MODE of s_axis_a_tvalid : signal is "slave";
  attribute X_INTERFACE_PARAMETER of s_axis_a_tvalid : signal is "XIL_INTERFACENAME S_AXIS_A, TDATA_NUM_BYTES 2, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of s_axis_a_tready : signal is "xilinx.com:interface:axis:1.0 S_AXIS_A TREADY";
  attribute X_INTERFACE_INFO of s_axis_a_tdata : signal is "xilinx.com:interface:axis:1.0 S_AXIS_A TDATA";
  attribute X_INTERFACE_INFO of m_axis_result_tvalid : signal is "xilinx.com:interface:axis:1.0 M_AXIS_RESULT TVALID";
  attribute X_INTERFACE_MODE of m_axis_result_tvalid : signal is "master";
  attribute X_INTERFACE_PARAMETER of m_axis_result_tvalid : signal is "XIL_INTERFACENAME M_AXIS_RESULT, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of m_axis_result_tready : signal is "xilinx.com:interface:axis:1.0 M_AXIS_RESULT TREADY";
  attribute X_INTERFACE_INFO of m_axis_result_tdata : signal is "xilinx.com:interface:axis:1.0 M_AXIS_RESULT TDATA";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of stub : architecture is "floating_point_v7_1_19,Vivado 2024.2";
begin
end;
