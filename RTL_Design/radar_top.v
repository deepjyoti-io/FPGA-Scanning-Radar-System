`timescale 1ns / 1ps

module radar_top (
    input clk,          // 100MHz onboard clock
    input echo,         // PMOD input from HC-SR04
    output trigger,     // PMOD output to HC-SR04
    output servo_pwm,   // PMOD output to SG90
    output uart_tx      // UART output to PC
);

    // --- 1 Microsecond Tick Generator ---
    reg [6:0] timer_1us = 0;
    reg tick_1us = 0;
    always @(posedge clk) begin
        if (timer_1us == 99) begin // 100MHz / 100 = 1MHz
            timer_1us <= 0;
            tick_1us <= 1'b1;
        end else begin
            timer_1us <= timer_1us + 1;
            tick_1us <= 1'b0;
        end
    end

    // --- Interconnect Wires ---
    wire [7:0] angle_wire;
    wire [7:0] distance_wire;
    wire dist_ready_wire;
    wire tx_busy;
    
    reg [7:0] uart_data;
    reg uart_send;

    // --- Module Instantiations ---
    servo_sg90 servo_inst (
        .clk(clk),
        .tick_1us(tick_1us),
        .servo_pwm(servo_pwm),
        .current_angle(angle_wire)
    );

    hcsr04 sonar_inst (
        .clk(clk),
        .tick_1us(tick_1us),
        .echo(echo),
        .trigger(trigger),
        .distance_cm(distance_wire),
        .dist_ready(dist_ready_wire)
    );

    uart_tx uart_inst (
        .clk(clk),
        .data_in(uart_data),
        .send_en(uart_send),
        .tx(uart_tx),
        .tx_busy(tx_busy)
    );

    // --- UART Transmission State Machine ---
    reg [2:0] tx_state = 0;
    
    always @(posedge clk) begin
        uart_send <= 1'b0; // Default off
        
        case (tx_state)
            0: begin
                // Wait until the sonar module finishes a measurement
                if (dist_ready_wire && !tx_busy) begin 
                    uart_data <= 8'hFF; // Byte 1: Sync Byte (255)
                    uart_send <= 1'b1;
                    tx_state <= 1;
                end
            end
            1: if (!tx_busy && !uart_send) tx_state <= 2; // Wait for TX to finish
            2: begin
                uart_data <= angle_wire; // Byte 2: Current Angle
                uart_send <= 1'b1;
                tx_state <= 3;
            end
            3: if (!tx_busy && !uart_send) tx_state <= 4;
            4: begin
                uart_data <= distance_wire; // Byte 3: Distance in cm
                uart_send <= 1'b1;
                tx_state <= 5;
            end
            5: if (!tx_busy && !uart_send) tx_state <= 0; // Done, wait for next measurement
        endcase
    end

endmodule