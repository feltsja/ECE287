module simon_says (clk, rst, start, initialize, userGuess, submit, startRound, roundNumb, gameDisplay, difficulty, done, segmentDisp, vga_R, vga_G, vga_B, 
vga_sync, vga_clk, vga_blank, hsync, vsync);
input clk, rst; // SW17
input start; // SW16
input initialize; //SW13
input [2:0] userGuess;  // 001 - Red, 010 - Blue, 011 - Yellow, 100 - Green //SW2-0
input submit;  // Keybutton 0
input startRound;  //Keybutton 3
output reg [3:0] roundNumb;  // 1 -> 10
output reg [2:0] gameDisplay;  // 001 - Red, 010 - Blue, 011 - Yellow, 100 - Green
input [1:0] difficulty;   // 00 = Easy, 01 = Medium, 10 = Hard, 11 = Insane  //SW15-14
output reg done;  // LED to show finished
output [6:0] segmentDisp;
// VGA Outputs
output reg [7:0] vga_R, vga_G, vga_B;
output reg hsync, vsync;
output reg vga_sync;
output reg vga_blank;
output reg vga_clk;

reg [2:0] winLosePlaying; // 00 = Playing, 01 = Win, 10 = Lose

wire [19:0] randomNumber;

random_number_generator rand(clk, rst, 16'h7A3D, ~start, initialize, randomNumber);

seven_segment segmentDisplay(roundNumb, segmentDisp);

reg [3:0] count;
reg [3:0] count2;
reg pass;
reg [27:0] timer;
reg [27:0] difficulty_time;
reg [1:0] round1Display;
reg [1:0] round2Display;
reg [1:0] round3Display;
reg [1:0] round4Display;
reg [1:0] round5Display;
reg [1:0] round6Display;
reg [1:0] round7Display;
reg [1:0] round8Display;
reg [1:0] round9Display;
reg [1:0] round10Display;

reg [9:0] pixel_x;
reg [9:0] pixel_y;
reg vga_HS, vga_VS;

reg [3:0]S;
reg [3:0]NS;

// Setting up a 25 MHz clock  as clk25
always @(posedge clk)
	if(vga_clk)
		vga_clk <= 1'b0;
	else
		vga_clk <= 1'b1;
		
// Initializing the VGA

wire CounterXmax = (pixel_x == 10'd799);
wire CounterYmax = (pixel_y == 10'd525);
reg active_pixels;

parameter HA_END = 10'd639;           // end of active pixels
parameter HS_STA = HA_END + 16;   // sync starts after front porch
parameter HS_END = HS_STA + 96;   // sync ends
parameter WIDTH   = 10'd799;           // last pixel on line (after back porch)

// vertical timings
parameter VA_END = 10'd479;           // end of active pixels
parameter VS_STA = VA_END + 10;   // sync starts after front porch
parameter VS_END = VS_STA + 2;    // sync ends
parameter HEIGHT = 10'd524;           // last line on screen (after back porch)

always @(posedge vga_clk)
	if(CounterXmax && ~CounterYmax)
	begin
		pixel_x <= 10'd0;
		pixel_y <= pixel_y + 10'd1;
	end
	else if(~CounterXmax)
		pixel_x <= pixel_x + 10'd1;
	else if(CounterXmax && CounterYmax)
	begin
		pixel_x <= 10'd0;
		pixel_y <= 10'd0;
	end
always @(*)
begin
	hsync = ~((pixel_x >= HS_STA) && (pixel_x < HS_END));
	vsync = ~((pixel_y >= VS_STA) && (pixel_y < VS_END));
	active_pixels = (pixel_x <= HA_END && pixel_y <= VA_END);
	vga_blank = active_pixels;
	vga_sync = 1'b1;
end
	

// Setting up constraints for the colors

localparam button_spacing = 0;
localparam button_size_x = 320;
localparam button_size_y = 240;
localparam RED_X_L = 0;
localparam RED_X_R = RED_X_L + button_size_x;
localparam RED_Y_T = 0;
localparam RED_Y_B = RED_Y_T + button_size_y;
localparam BLUE_X_L = RED_X_R + button_spacing;
localparam BLUE_X_R = BLUE_X_L + button_size_x;
localparam BLUE_Y_T = 0;
localparam BLUE_Y_B = BLUE_Y_T + button_size_y;
localparam YELL_X_L = 0;
localparam YELL_X_R = YELL_X_L + button_size_x;
localparam YELL_Y_T = RED_Y_B + button_spacing;
localparam YELL_Y_B = YELL_Y_T + button_size_y;
localparam GRN_X_L = YELL_X_R + button_spacing;
localparam GRN_X_R = GRN_X_L + button_size_x;
localparam GRN_Y_T = BLUE_Y_B + button_spacing;
localparam GRN_Y_B = GRN_Y_T + button_size_y;

wire redOn, blueOn, yellOn, grnOn;

assign redOn = ((RED_X_L <= pixel_x) && (pixel_x <= RED_X_R) && (RED_Y_T <= pixel_y) && (pixel_y <= RED_Y_B));
assign blueOn = ((BLUE_X_L <= pixel_x) && (pixel_x <= BLUE_X_R) && (BLUE_Y_T <= pixel_y) && (pixel_y <= BLUE_Y_B));
assign yellOn = ((YELL_X_L <= pixel_x) && (pixel_x <= YELL_X_R) && (YELL_Y_T <= pixel_y) && (pixel_y <= YELL_Y_B));
assign grnOn = ((GRN_X_L <= pixel_x) && (pixel_x <= GRN_X_R) && (GRN_Y_T <= pixel_y) && (pixel_y <= GRN_Y_B));

// Creation of the FSM

parameter START = 4'd0,
	INIT = 4'd1,
	FOR_COND_ROUNDS = 4'd2,
	ROUND_BEGIN = 4'd3,
	FOR_COND_COUNT = 4'd4,
	DISPLAY = 4'd5,
	DELAY = 4'd6,
	DISPLAY_OFF = 4'd7,
	DELAY_OFF = 4'd8,
	GUESSING = 4'd9,
	FOR_COND_GUESS = 4'd10,
	MAKE_GUESS = 4'd11,
	GUESS_CHECK = 4'd12,
	COUNT_2_INCR = 4'd13,
	ROUND_INCR = 4'd14,
	RESET = 4'd15;


always @(*)
begin
	case (S)
		START: if (start == 1'b1)
					NS = INIT;
				else
					NS = START;
		INIT: if (initialize == 1'b1)
					NS = FOR_COND_ROUNDS;
				else
					NS = INIT;
		FOR_COND_ROUNDS: if (roundNumb <= 4'd10 && startRound == 1'b0)
									NS = ROUND_BEGIN;
							else if (roundNumb <= 4'd10 && startRound == 1'b1)
									NS = FOR_COND_ROUNDS;
							else
									NS = RESET;
		ROUND_BEGIN: if (startRound == 1'b0)
							NS = FOR_COND_COUNT;
						else
							NS = ROUND_BEGIN;
		FOR_COND_COUNT: if (count > roundNumb)
									NS = GUESSING;
							else
									NS = DISPLAY;
		DISPLAY: NS = DELAY;
		DELAY: if (timer >= difficulty_time)
					NS = DISPLAY_OFF;
				else
					NS = DELAY;
		DISPLAY_OFF: NS = DELAY_OFF;
		DELAY_OFF: if (timer >= difficulty_time)
					NS = FOR_COND_COUNT;
				else
					NS = DELAY_OFF;
		GUESSING: NS = FOR_COND_GUESS;
		FOR_COND_GUESS: if (pass == 1'b0)
								NS = RESET;
							else if (count2 <= roundNumb)
								NS = MAKE_GUESS;
							else
								NS = ROUND_INCR;
		MAKE_GUESS: if (submit == 1'b1)
							NS = MAKE_GUESS;
						else
							NS = GUESS_CHECK;
		GUESS_CHECK: if (submit == 1'b1)
							NS = COUNT_2_INCR;
						else
							NS = GUESS_CHECK;
		COUNT_2_INCR: NS = FOR_COND_GUESS;
		ROUND_INCR: NS = FOR_COND_ROUNDS;
		RESET: if (start == 1'b0 && initialize == 1'b0)
					NS = START;
				else
					NS = RESET;
	endcase
end

always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
		roundNumb <= 4'd0;
		count <= 4'd0;
		gameDisplay <= 3'd0;
		done <= 1'b0;
		round1Display <= 2'd0;
		round2Display <= 2'd0;
		round3Display <= 2'd0;
		round4Display <= 2'd0;
		round5Display <= 2'd0;
		round6Display <= 2'd0;
		round7Display <= 2'd0;
		round8Display <= 2'd0;
		round9Display <= 2'd0;
		round10Display <= 2'd0;
	end
	else
		case (S)
			START: 
			begin
				done <= 1'b0;
				pass <= 1'b0;
				roundNumb <= 4'd0;
				winLosePlaying <= 2'd0;
			end
			INIT:
			begin
				roundNumb <= 4'd1;
				if (difficulty == 2'b00)
					difficulty_time <= 27'd50000000;  // 1 sec
				else if (difficulty == 2'b01)
					difficulty_time <= 27'd25000000;  // 0.5 sec
				else if (difficulty == 2'b10)
					difficulty_time <= 27'd12500000;  // 0.25 sec
				else
					difficulty_time <= 27'd5000000;   // 0.1 sec
			end
			FOR_COND_ROUNDS: 
			begin
				count <= 4'd1;
				round1Display <= randomNumber[1:0];
				round2Display <= randomNumber[3:2];
				round3Display <= randomNumber[5:4];
				round4Display <= randomNumber[7:6];
				round5Display <= randomNumber[9:8];
				round6Display <= randomNumber[11:10];
				round7Display <= randomNumber[13:12];
				round8Display <= randomNumber[15:14];
				round9Display <= randomNumber[17:16];
				round10Display <= randomNumber[19:18];
				
				if (roundNumb > 4'd10)
					winLosePlaying <= 2'd1;
					
			end
			DISPLAY: 
			begin
				if (count == 4'd1)
					gameDisplay <= {1'b0, round1Display} + 3'd1;
				else if (count == 4'd2)
					gameDisplay <= {1'b0, round2Display} + 3'd1;
				else if (count == 4'd3)
					gameDisplay <= {1'b0, round3Display} + 3'd1;
				else if (count == 4'd4)
					gameDisplay <= {1'b0, round4Display} + 3'd1;
				else if (count == 4'd5)
					gameDisplay <= {1'b0, round5Display} + 3'd1;
				else if (count == 4'd6)
					gameDisplay <= {1'b0, round6Display} + 3'd1;
				else if (count == 4'd7)
					gameDisplay <= {1'b0, round7Display} + 3'd1;
				else if (count == 4'd8)
					gameDisplay <= {1'b0, round8Display} + 3'd1;
				else if (count == 4'd9)
					gameDisplay <= {1'b0, round9Display} + 3'd1;
				else if (count == 4'd10)
					gameDisplay <= {1'b0, round10Display} + 3'd1;
				
				timer <= 27'd0;
			end
			DELAY: timer <= timer + 27'd1;
			DISPLAY_OFF: 
			begin
				gameDisplay <= 3'd0;
				count <= count + 4'd1;
				timer <= 27'd0;
			end
			DELAY_OFF: timer <= timer + 27'd1;
			GUESSING: 
			begin
				pass <= 1'b1;
				count2 <= 4'd1;
			end
			GUESS_CHECK:
			begin
				if (count2 == 4'd1)
				begin
					if (userGuess !== {1'b0, round1Display} + 3'd1)
						pass <= 1'b0;
				end
				else if (count2 == 4'd2)
				begin
					if (userGuess !== {1'b0, round2Display} + 3'd1)
						pass <= 1'b0;
				end
				else if (count2 == 4'd3)
				begin	
					if (userGuess !== {1'b0, round3Display} + 3'd1)
						pass <= 1'b0;
				end
				else if (count2 == 4'd4)
				begin	
					if (userGuess !== {1'b0, round4Display} + 3'd1)
						pass <= 1'b0;
				end
				else if (count2 == 4'd5)
				begin	
					if (userGuess !== {1'b0, round5Display} + 3'd1)
						pass <= 1'b0;
				end
				else if (count2 == 4'd6)
				begin	
					if (userGuess !== {1'b0, round6Display} + 3'd1)
						pass <= 1'b0;
				end
				else if (count2 == 4'd7)
				begin	
					if (userGuess !== {1'b0, round7Display} + 3'd1)
						pass <= 1'b0;
				end
				else if (count2 == 4'd8)
				begin	
					if (userGuess !== {1'b0, round8Display} + 3'd1)
						pass <= 1'b0;
				end
				else if (count2 == 4'd9)
				begin	
					if (userGuess !== {1'b0, round9Display} + 3'd1)
						pass <= 1'b0;
				end
				else if (count2 == 4'd10)
				begin	
					if (userGuess !== {1'b0, round10Display} + 3'd1)
						pass <= 1'b0;
				end
				
				if (pass == 1'b0)
					winLosePlaying <= 2'd2;
			end
			COUNT_2_INCR: count2 <= count2 + 4'd1;
			ROUND_INCR: roundNumb <= roundNumb + 4'd1;
			RESET: done <= 1'b1;

		endcase
end

/* FSM init and NS always */
always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
		S <= START;
	end
	else
	begin
		S <= NS;
	end
end

always @(*)
begin
	if(redOn && (gameDisplay == 3'b001))
	begin
		vga_R = 8'hFF;
		vga_B = 8'h00;
		vga_G = 8'h00;
	end
	else if(blueOn && (gameDisplay == 3'b010))
	begin
		vga_R = 8'h00;
		vga_B = 8'hFF;
		vga_G = 8'h00;
	end
	else if(yellOn && (gameDisplay == 3'b011))
	begin
		vga_R = 8'hFF;
		vga_B = 8'h00;
		vga_G = 8'hFF;
	end
	else if(grnOn && (gameDisplay == 3'b100))
	begin
		vga_R = 8'h00;
		vga_B = 8'h00;
		vga_G = 8'hFF;
	end
	else if(winLosePlaying == 2'd0)
	begin
		vga_R = 8'hFF;
		vga_B = 8'hFF;
		vga_G = 8'hFF;
	end
	else if(winLosePlaying == 2'd1)
	begin
		vga_R = 8'h00;
		vga_B = 8'h7F;
		vga_G = 8'hFF;
	end
		else if(winLosePlaying == 2'd2)
	begin
		vga_R = 8'h00;
		vga_B = 8'h00;
		vga_G = 8'h00;
	end
end

endmodule
