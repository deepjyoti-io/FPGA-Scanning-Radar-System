`timescale 1ns / 1ps

module uart_tx (
    input clk,            // 100MHz system clock
    input [7:0] data_in,  // Byte to transmit
    input send_en,        // Pulse high to start transmission
    output reg tx,        // UART TX pin
    output reg tx_busy    // High when transmitting
);

    parameter CLKS_PER_BIT = 868; // 100MHz / 115200 baud = ~868

    reg [3:0] state = 0;
    reg [15:0] clock_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] saved_data = 0;

    initial begin
        tx = 1'b1;
        tx_busy = 1'b0;
    end

    always @(posedge clk) begin
        case (state)
            0: begin // Idle
                tx <= 1'b1;
                clock_count <= 0;
                bit_index <= 0;
                if (send_en) begin
                    saved_data <= data_in;
                    tx_busy <= 1'b1;
                    state <= 1;
                end else begin
                    tx_busy <= 1'b0;
                end
            end
            
            1: begin // Start Bit (Drive TX low)
                tx <= 1'b0;
                if (clock_count < CLKS_PER_BIT - 1) begin
                    clock_count <= clock_count + 1;
                end else begin
                    clock_count <= 0;
                    state <= 2;
                end
            end
            
            2: begin // Data Bits
                tx <= saved_data[bit_index];
                if (clock_count < CLKS_PER_BIT - 1) begin
                    clock_count <= clock_count + 1;
                end else begin
                    clock_count <= 0;
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        state <= 3;
                    end
                end
            end
            
            3: begin // Stop Bit (Drive TX high)
                tx <= 1'b1;
                if (clock_count < CLKS_PER_BIT - 1) begin
                    clock_count <= clock_count + 1;
                end else begin
                    clock_count <= 0;
                    state <= 0; // Return to idle
                end
            end
            
            default: state <= 0;
        endcase
    end
endmodule