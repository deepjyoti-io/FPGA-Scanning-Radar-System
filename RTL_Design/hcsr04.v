`timescale 1ns / 1ps

module hcsr04 (
    input clk,           // 100MHz
    input tick_1us,      // 1 microsecond tick from top module
    input echo,          // HC-SR04 Echo pin
    output reg trigger,  // HC-SR04 Trigger pin
    output reg [7:0] distance_cm, // Calculated distance (max 255cm)
    output reg dist_ready // Pulses high when distance is calculated
);

    reg [1:0] state = 0;
    reg [15:0] timer = 0;
    reg [19:0] calc_dist = 0; 
    
    always @(posedge clk) begin
        dist_ready <= 0; // Default to 0
        
        if (tick_1us) begin
            case (state)
                0: begin // Send 10us Trigger
                    trigger <= 1'b1;
                    if (timer >= 10) begin
                        trigger <= 1'b0;
                        timer <= 0;
                        state <= 1;
                    end else timer <= timer + 1;
                end
                
                1: begin // Wait for Echo to go HIGH
                    if (echo == 1'b1) begin
                        timer <= 0;
                        state <= 2;
                    end else if (timer > 50000) begin // Timeout if no obstacle
                        timer <= 0;
                        state <= 0;
                    end else timer <= timer + 1;
                end
                
                2: begin // Measure Echo width
                    if (echo == 1'b0) begin
                        // Optimized division: timer / 58 is roughly (timer * 141) >> 13
                        calc_dist = (timer * 141) >> 13;
                        
                        if (calc_dist > 255) distance_cm <= 255; 
                        else distance_cm <= calc_dist[7:0];
                        
                        dist_ready <= 1'b1; 
                        timer <= 0;
                        state <= 3;
                    end else timer <= timer + 1;
                end
                
                3: begin // Delay before next trigger (~50ms)
                    if (timer >= 50000) begin
                        timer <= 0;
                        state <= 0;
                    end else timer <= timer + 1;
                end
            endcase
        end
    end
endmodule