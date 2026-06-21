# FPGA-Based Hardware Scanning Radar

## 📌 Project Overview
This project implements a complete hardware-in-the-loop scanning radar system utilizing custom Register-Transfer Level (RTL) digital logic. Operating on a Xilinx Spartan-7 FPGA, the system manages a sweeping micro-servo and an ultrasonic rangefinder to detect obstacles. The FPGA streams synchronized telemetry data over a custom UART transmitter to a Python-based host application, which renders the radar sweep in real-time.

## 🛠️ Core Technologies & Tech Stack
* **Hardware:** Arty S7 (Xilinx Spartan-7 FPGA), HC-SR04 Ultrasonic Sensor, SG90 Micro Servo
* **HDL / RTL:** Verilog (Custom State Machines, Clock Dividers)
* **EDA Tools:** Xilinx Vivado (Synthesis, Implementation, Bitstream Generation)
* **Host Software:** Python 3 (PySerial for UART, Pygame for UI rendering)

## 🚀 Key Engineering Features

### 1. Custom RTL UART Transmitter
Rather than relying on soft-core processors or IP blocks, this project features a custom-written UART TX module. It operates at a 115200 baud rate, utilizing precise clock division (`100MHz / 115200 ≈ 868 clocks/bit`) to shift out data frames via an FSM, ensuring reliable asynchronous serial communication with the host PC.

### 2. Hardware Pulse-Width Modulation (PWM) Controller
The `servo_sg90` Verilog module generates a precise 50Hz (20ms) control signal. It uses an internal state machine to continuously calculate and adjust the duty cycle, sweeping the radar head smoothly from 0° to 180° without tying up CPU cycles.

### 3. Microsecond Timing & Echo Processing
The `hcsr04` module acts as an independent hardware peripheral. It features a microsecond-resolution timer driven by the 100MHz system clock to generate 10µs trigger pulses. It then measures the echo response width and uses an optimized bit-shift division algorithm (`(timer * 141) >> 13`) to calculate the physical distance in centimeters natively on the FPGA fabric.

### 4. Synchronized Data Pipelining
The top-level module acts as a traffic controller, waiting for a valid distance calculation before assembling a 3-byte telemetry packet (`[0xFF Sync Byte, Angle, Distance]`). This packet is queued and fired off to the UART transmitter, ensuring the Python UI receives perfectly synchronized spatial data.

## 🔌 Hardware Pinout Configuration (Arty S7 PMOD JA)
| FPGA Pin | Interface | Component Connection |
| :--- | :--- | :--- |
| **R2** | System Clock | 100MHz Onboard Oscillator |
| **L17** | `servo_pwm` | SG90 Servo PWM Signal |
| **L18** | `trigger` | HC-SR04 Trigger Pin |
| **M14** | `echo` | HC-SR04 Echo Pin |
| **R12** | `uart_tx` | USB-UART (Host PC) |

## ⚙️ Setup and Installation
### FPGA Setup
1. Create a new Vivado project targeting your specific Spartan-7 board.
2. Import all Verilog files from the `RTL_Design` directory.
3. Apply the provided `.xdc` constraints file to map the I/O ports.
4. Generate the bitstream and program the device.

### Host PC Setup
1. Ensure Python 3.x is installed along with `pyserial` and `pygame`.
2. Connect the Arty S7 board via USB.
3. Update the `SERIAL_PORT` variable in the Python script to match your system's COM port.
4. Run the visualization script: `python radar_ui.py`.
