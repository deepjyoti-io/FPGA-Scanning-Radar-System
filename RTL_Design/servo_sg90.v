`timescale 1ns / 1ps

module servo_sg90 (
    input clk,            // 100MHz
    input tick_1us,       // 1 microsecond tick
    output servo_pwm,     // PWM output to SG90
    output reg [7:0] current_angle // 0 to 180 degrees
);

    reg [15:0] pwm_counter = 0;
    reg [15:0] high_time = 1500; // default 90 deg
    
    reg sweep_dir = 1; 
    reg [4:0] speed_div = 0; 
    
    initial current_angle = 90;

    always @(posedge clk) begin
        if (tick_1us) begin
            if (pwm_counter >= 19999) begin // 20ms period (50Hz)
                pwm_counter <= 0;
                
                if (speed_div >= 2) begin 
                    speed_div <= 0;
                    if (sweep_dir == 1) begin
                        if (current_angle >= 180) sweep_dir <= 0;
                        else current_angle <= current_angle + 1;
                    end else begin
                        if (current_angle == 0) sweep_dir <= 1;
                        else current_angle <= current_angle - 1;
                    end
                    // Optimized division: (angle * 1000) / 180 is roughly (angle * 1422) >> 8
                    high_time <= 1000 + ((current_angle * 1422) >> 8);
                end else begin
                    speed_div <= speed_div + 1;
                end
            end else begin
                pwm_counter <= pwm_counter + 1;
            end
        end
    end
    
    assign servo_pwm = (pwm_counter < high_time) ? 1'b1 : 1'b0;

endmodule