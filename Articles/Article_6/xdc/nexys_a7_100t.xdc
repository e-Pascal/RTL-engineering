# Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk_i }]; #IO_L12P_T1_MRCC_35 Sch=clk100mhz
create_clock -add -name sys_clk_pin -period 2.00 -waveform {0 1} [get_ports {clk_i}];
set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { resetn }]; #IO_L3P_T0_DQS_AD1P_15 Sch=cpu_resetn
