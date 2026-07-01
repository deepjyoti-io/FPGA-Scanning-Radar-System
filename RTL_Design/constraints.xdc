## Clock signal (100MHz) 
set_property -dict {PACKAGE_PIN R2 IOSTANDARD SSTL135} [get_ports clk] 
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk] 
## PMOD Header JA (Sensors and Servo) 
# Connect SG90 Servo Signal wire here 
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { servo_pwm }]; # Sch=ja_p[1] 
# Connect HC-SR04 Trigger wire here 
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { trigger }]; # Sch=ja_n[1] 
# Connect HC-SR04 Echo wire here 
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { echo }]; # Sch=ja_p[2] 
## USB-UART Interface 
# Sends data from the FPGA to the USB cable connected to your laptop 
set_property -dict { PACKAGE_PIN R12   IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]; # 
Sch=uart_rxd_out 
## Configuration options, can be used for all designs 
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design] 
set_property CONFIG_VOLTAGE 3.3 [current_design] 
set_property CFGBVS VCCO [current_design] 
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design] 
set_property CONFIG_MODE SPIx4 [current_design] 
set_property INTERNAL_VREF 0.675 [get_iobanks 34] 
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]