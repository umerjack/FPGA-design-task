# Define input clock period (in nanoseconds)
# 200 MHz = 5 ns period
# 250 MHz = 4 ns period
# 300 MHz = 3.33 ns period

create_clock -name clk -period 3.33 [get_ports clk]


