import serial 
import pygame 
import math 
import sys 
# ========================================== 
# 1. Configuration 
# ========================================== 
SERIAL_PORT = 'COM3'  # <--- CHANGE THIS TO YOUR ARTY S7 COM PORT 
BAUD_RATE = 115200 
MAX_DISTANCE_CM = 100     # Radar scale (cm) 
OBSTACLE_THRESHOLD = 40   # Distance (cm) to trigger the RED figures 
# UI Settings 
WIDTH, HEIGHT = 800, 400 
CENTER = (WIDTH // 2, HEIGHT) 
# ========================================== 
# 2. Setup Serial Connection 
# ========================================== 
print(f"Connecting to {SERIAL_PORT} at {BAUD_RATE} baud...") 
try: 
ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1) 
print("Connection successful! Starting radar...") 
except Exception as e: 
print(f"Error opening serial port: {e}") 
sys.exit() 
# ========================================== 
# 3. Setup Pygame Window 
# ========================================== 
pygame.init() 
screen = pygame.display.set_mode((WIDTH, HEIGHT)) 
pygame.display.set_caption("FPGA HC-SR04 Radar Interface") 
font = pygame.font.SysFont("Consolas", 18) 
# Array to store the last recorded distance for each of the 180 degrees 
distances = [0] * 181  
current_angle = 0 
# ========================================== 
# 4. Main Loop 
# ========================================== 
running = True 
while running: 
# Handle window close 
for event in pygame.event.get(): 
if event.type == pygame.QUIT: 
running = False 
# Read UART data from FPGA 
# We look for our 3-byte packet: [0xFF, Angle, Distance] 
while ser.in_waiting >= 3: 
sync_byte = ser.read()[0] 
if sync_byte == 255:  # 0xFF in decimal 
            angle = ser.read()[0] 
            distance = ser.read()[0] 
             
            if 0 <= angle <= 180: 
                current_angle = angle 
                # Cap the distance to our max scale to prevent drawing off-screen 
                distances[angle] = min(distance, MAX_DISTANCE_CM) 
 
    # --- DRAWING THE RADAR --- 
    screen.fill((0, 20, 0)) # Dark green background 
     
    # 1. Draw Radar Grid 
    pygame.draw.circle(screen, (0, 100, 0), CENTER, WIDTH // 2, 1) 
    pygame.draw.circle(screen, (0, 100, 0), CENTER, int(WIDTH // 2 * 0.66), 1) 
    pygame.draw.circle(screen, (0, 100, 0), CENTER, int(WIDTH // 2 * 0.33), 1) 
     
    # Draw angle lines (30, 60, 90, 120, 150 degrees) 
    for angle in range(0, 181, 30): 
        rad = math.radians(angle) 
        x = CENTER[0] + math.cos(rad) * (WIDTH // 2) 
        y = CENTER[1] - math.sin(rad) * (HEIGHT) 
        pygame.draw.line(screen, (0, 100, 0), CENTER, (x, y), 1) 
 
    # 2. Draw Recorded Points (Obstacles) 
    for a in range(181): 
        dist = distances[a] 
        if dist > 0 and dist < 255: # Valid reading 
            rad = math.radians(a) 
             
            # Map distance (cm) to pixels 
            pixel_dist = (dist / MAX_DISTANCE_CM) * (WIDTH // 2) 
             
            x = int(CENTER[0] + pixel_dist * math.cos(rad)) 
            y = int(CENTER[1] - pixel_dist * math.sin(rad)) 
             
            # If obstacle is dangerously close, draw RED figure 
            if dist < OBSTACLE_THRESHOLD: 
                pygame.draw.circle(screen, (255, 0, 0), (x, y), 6) # Red Blip 
            else: 
                pygame.draw.circle(screen, (0, 255, 0), (x, y), 3) # Green Blip 
 
    # 3. Draw the Sweeping Radar Arm 
    rad_current = math.radians(current_angle) 
    arm_x = CENTER[0] + math.cos(rad_current) * (WIDTH // 2) 
    arm_y = CENTER[1] - math.sin(rad_current) * (HEIGHT) 
    pygame.draw.line(screen, (0, 255, 0), CENTER, (arm_x, arm_y), 3) 
 
    # 4. Add Text Information 
    info_text = font.render(f"Angle: {current_angle}° | Dist: {distances[current_angle]} cm", True, (0, 255, 0)) 
    screen.blit(info_text, (10, 10)) 
     
    warn_text = font.render(f"RED Alert Threshold: < {OBSTACLE_THRESHOLD} cm", True, (255, 50, 50)) 
    screen.blit(warn_text, (10, 30)) 
 
    # Update the display 
    pygame.display.flip() 
 
# Clean exit 
ser.close() 
pygame.quit() 