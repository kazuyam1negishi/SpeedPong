/*
Speed Pong
Based on: Pong (Original (C) 1972-2024 Atari)
By: Cristian Rodriguez Millan and Jimmy Soto Agustin
Created for UNLV Spring 2024 College of Engineering Junior Design Competition

This VHDL code is no longer modified for its release on GitHub.
*/

// The game module serves as a structural
// module for all the modules in our project.
module speedPong(input  logic clk, sysReset, gameReset, speedEnable,      // clock for system
                 input  logic p1up, p1down, 	// buttons
                 input  logic p2up, p2down,
                 output logic [6:0] seg0,	// scores
                 output logic [6:0] seg7,
		 		 output logic [6:0] seg4,
		 		 output logic [6:0] seg5,
                 output logic vgaClock,		// clock for video
                 output logic hsync, vsync,	// vga sync signals
                 output logic syncB, blankB,	// blanking signals
                 output logic [7:0] red, green, blue); // rgb values
    // Internal logic
    logic padClk;
    logic scrClk;
    logic pad1upEn, pad1downEn;
    logic pad2upEn, pad2downEn;
    logic [2:0] direction;
    logic [3:0] p1score;
    logic [3:0] p2score;
    logic [9:0] paddle1y1, paddle1y2;
    logic [9:0] paddle2y1, paddle2y2;
    logic [9:0] ballx1, ballx2;
    logic [9:0] bally1, bally2;
    
    // Module instantiations
	// VGA game screen
    vgaGame gameScreen(clk, sysReset, paddle1y1, paddle1y2, paddle2y1, paddle2y2,
		ballx1, ballx2, bally1, bally2, vgaClock, hsync, vsync, syncB, blankB,
		red, green, blue);
	// Clocks (DO NOT TOUCH)
    paddleClk paddleClk(clk, sysReset, padClk);
    scoreClk scoreClk(clk, sysReset, scrClk);
	// Paddle FSMs for handling movement
    paddleFSM p1FSM(clk, gameReset, p1up, p1down, pad1upEn, pad1downEn);
    paddleFSM p2FSM(clk, gameReset, p2up, p2down, pad2upEn, pad2downEn);
	// Paddle modules for positions
    paddle paddle1(padClk, paddle1y1, paddle1y2, pad1upEn, pad1downEn, gameReset, speedEnable, ballx1, ballx2, bally1, bally2);
    paddle paddle2(padClk, paddle2y1, paddle2y2, pad2upEn, pad2downEn, gameReset, speedEnable, ballx1, ballx2, bally1, bally2);
	// Ball module for handling movement
	// Remember to add vars for ball FSM and new vars for ball
	// to allow movement in y direction!
    ball ball(padClk, gameReset, direction, ballx1, ballx2, bally1, bally2);
	// Ball FSM for handling collisions and new direction
    ballCollisions ballCollisions(padClk, gameReset, ballx1, bally1, ballx2, bally2, paddle1y1, paddle1y2, paddle2y1, paddle2y2, direction);
	// Score keeper and display
    scoreDisplay playerScoreDisp(clk, gameReset, p1score, p2score, seg0, seg7);
    scoreKeeper playerScoreUpdate(scrClk, gameReset, ballx1, ballx2, p1score, p2score);
	// Show game mode
	gameModeDisplay gameShow(clk, speedEnable, seg5, seg4);
endmodule

// COMPLETED
// We needed a reduced clock in order to
// move the paddles slowly, since the original clock
// would otherwise make them go off the screen.
module paddleClk(input  logic clk, reset,
                 output logic clk200Hz);
    // m of 215 = 10.001Hz
    // m of 430 = 20.003Hz 
    // m of 2150 = 100.117Hz
    // m of 4300 = 200.234Hz
	// Final clk = 200.234Hz
    logic [29:0] cnt;
    always_ff@(posedge clk, posedge reset)
        if (reset)      cnt <= 1'b0;
        else            cnt <= cnt + 30'd4300;
    assign clk200Hz = cnt[29];
endmodule

// COMPLETED
// We also needed a different clock for the
// scoring so that we can increase the score by 1
// and send the ball back before awarding too many points.
module scoreClk(input  logic clk, reset,
		output logic clk1Hz);
	logic [31:0] cnt;
	always_ff@(posedge clk, posedge reset)
	 	if (reset)	cnt <= 1'b0;
		else		cnt <= cnt + 32'd1575;
	assign clk1Hz = cnt[31];
endmodule

// COMPLETED
// This module controls the paddle
// by controlling its (x,y) coordinates.
// Only the y coordinates are modified,
// as modifying the x coords would make
// the paddle change shape or be able
// to move left and right.
// This also allows us to control both
// paddles with a single module.
// With paddleClk, the paddle will move
// about 200 pixels per second when
// running the original Pong game.
module paddle(input  logic clk,
              output logic [9:0] y1, y2,
              input  logic up, down,
              input  logic reset, speedEn,
	      	  input  logic [9:0] ballx1, ballx2,
	      	  input  logic [9:0] bally1, bally2);
    always_ff@(posedge clk, posedge reset)
        if (reset) begin
            // reset control
            y1 <= 10'd180;
            y2 <= 10'd300;
        end
	// Check if the paddles are
	// going past the game area.
	else if (y1 <= 15) begin
	    y1 <= 10'd20;
	    y2 <= 10'd145;
	end
	else if (y2 >= 465) begin
	    y1 <= 10'd340;
	    y2 <= 10'd460;
	end
	// Also, check if SpeedPong is in play.
	// If so, upon button press, teleport
	// the paddle relative to the center
	// of the ball.
	else if (down && speedEn) begin
	    if(ballx1 >= 10'd75 && ballx2 <= 10'd565) begin
		y1 <= bally1 - 10'd45;
		y2 <= bally2 + 10'd45;
	    end
	end
	// In order to avoid any movement with
	// the up button, if it's pressed, the
	// the coordinates will stay the same.
	else if (up && speedEn) begin
	    if(ballx1 >= 10'd75 && ballx2 <= 10'd565) begin
		y1 <= y1;
		y2 <= y2;
	    end
	end
	// If Pong is in play, allow movement.
	else if (up) begin
		y1 <= y1 - 1'd1;
		y2 <= y2 - 1'd1;
	end
	else if (down) begin
		y1 <= y1 + 1'd1;
		y2 <= y2 + 1'd1;
	end
	else begin
		y1 <= y1;
		y2 <= y2;
	end
endmodule

// COMPLETED
// This module controls the movement
// of each paddle by only enabling
// movement when a button is pressed and held.
module paddleFSM(input  logic clk, reset,
		 		 input  logic padup, paddown,
		 		 output logic upEn, downEn);
	// only two states needed
	typedef enum logic {S0, S1} stateType;
	logic currState1, nextState1;
	logic currState2, nextState2;
	always_ff@(posedge clk, posedge reset)
		if (reset) 	currState1 <= S0;
		else		currState1 <= nextState1;
	always_comb
	case(currState1)
		S0: begin
			if (~padup) 	nextState1 = S1;
			else		nextState1 = S0;
		end
		S1: begin
			if (~padup)	nextState1 = S1;
			else		nextState1 = S0;
		end
	endcase
	assign upEn = (currState1 == S1);

	always_ff@(posedge clk, posedge reset)
		if (reset) 	currState2 <= S0;
		else		currState2 <= nextState2;
	always_comb
	case(currState2)
		S0: begin
			if (~paddown) 	nextState2 = S1;
			else		nextState2 = S0;
		end
		S1: begin
			if (~paddown)	nextState2 = S1;
			else		nextState2 = S0;
		end
	endcase
	assign downEn = (currState2 == S1);
endmodule

// COMPLETED
// This module behaves the same as
// the paddle module.
// This modules now handles collisions
// as well as the movement of the ball.
module ball(input  logic       clk, reset,
	    	input  logic [2:0] direction,
	    	output logic [9:0] ballx1, ballx2,
	    	output logic [9:0] bally1, bally2);
	always_ff@(posedge clk, posedge reset)
		// Reset if game reset high.
		if (reset) begin
			ballx1 <= 10'd305; bally1 = 10'd305;
			ballx2 <= 10'd335; bally2 = 10'd335;
		end
		// These two conditions reset the ball
		// if a goal is reached.
		else if (ballx1 <= 10)	begin
			ballx1 <= 10'd305; bally1 = 10'd305;
			ballx2 <= 10'd335; bally2 = 10'd335;
		end
		else if (ballx2 >= 630)	begin
			ballx1 <= 10'd305; bally1 = 10'd305;
			ballx2 <= 10'd335; bally2 = 10'd335;
		end
		// Encoding ball movement!
		// This took so damn long and i'm so f*cking happy
		// that this finally works, thank God
		// Left Up
		else if (direction == 3'b010) begin
			ballx1 <= ballx1 - 10'd1; bally1 <= bally1 - 10'd1;
			ballx2 <= ballx2 - 10'd1; bally2 <= bally2 - 10'd1;
		end
		// Left Straight (LM)
		else if (direction == 3'b011) begin
			ballx1 <= ballx1 - 10'd2; bally1 <= bally1;
			ballx2 <= ballx2 - 10'd2; bally2 <= bally2;
		end
		// Left Down
		else if (direction == 3'b001) begin
			ballx1 <= ballx1 - 10'd1; bally1 <= bally1 + 10'd1;
			ballx2 <= ballx2 - 10'd1; bally2 <= bally2 + 10'd1;
		end
		// Right Up
		else if (direction == 3'b110) begin
			ballx1 <= ballx1 + 10'd1; bally1 <= bally1 - 10'd1;
			ballx2 <= ballx2 + 10'd1; bally2 <= bally2 - 10'd1;
		end
		// Right Straight (RM)
		else if (direction == 3'b111) begin
			ballx1 <= ballx1 + 10'd2; bally1 <= bally1;
			ballx2 <= ballx2 + 10'd2; bally2 <= bally2;
		end
		// Right Down
		else if (direction == 3'b101) begin
			ballx1 <= ballx1 + 10'd1; bally1 <= bally1 + 10'd1;
			ballx2 <= ballx2 + 10'd1; bally2 <= bally2 + 10'd1;
		end
		// This case should never be met.
		else begin
			ballx1 <= ballx1 + 10'd1;
			ballx2 <= ballx2 + 10'd1;
		end
endmodule 

// COMPLETED
// Ball collisions module
// This module handles the collisions
// based on the current position of the ball
// relative to the paddles/barriers.
module ballCollisions(input  logic       clk, reset,
					  input  logic [9:0] ballx1, bally1, ballx2, bally2,
					  input  logic [9:0] paddle1y1, paddle1y2,
					  input  logic [9:0] paddle2y1, paddle2y2,
					  output logic [2:0] direction);
	/*
	Key
	L - left, R - right
	U - up, M - middle, D - down

	Direction outputs
	LU - 010
	LM - 011
	LD - 001
	RU - 110
	RM - 111
	RD - 101
	Unused - 000, 100
	*/
	// state types
	typedef enum logic [2:0] {LU, LM, LD, RU, RM, RD} stateDir;
	stateDir currDir, nextDir;
	// state register
	always_ff@(posedge clk, posedge reset)
		if (reset)		currDir <= LU;
		else			currDir <= nextDir;
	// next state logic
	always_comb
		case(currDir)
			LU: begin
				// Barrier collision
				if(bally1 <= 10'd10) 									nextDir <= LD;
				// Paddle collisions
				else if(ballx1 <= 10'd75 && ballx1 >= 10'd50 && (bally1 + 10'd15) >= paddle1y1) begin
					if((bally1 + 10'd15) <= (paddle1y1 + 40))			nextDir = RU;
					else if((bally1 + 10'd15) <= (paddle1y1 + 80))		nextDir = RM;
					else if((bally1 + 10'd15) <= paddle1y2)				nextDir = RD;
					else 												nextDir = LU;
				end
				// No collision
				else 													nextDir = LU;
			end
			LM: begin
				// Paddle collisions
				if(ballx1 <= 10'd75 && ballx1 >= 10'd50 && (bally1 + 10'd15) >= paddle1y1) begin
					if((bally1 + 10'd15) <= (paddle1y1 + 40)) nextDir = RU;
					else if((bally1 + 10'd15) <= (paddle1y1 + 80)) nextDir = RM;
					else if((bally1 + 10'd15) <= paddle1y2) nextDir = RD;
					else nextDir = LM;
				end
				// No collision
				else nextDir = LM;

			end
			LD: begin
				// Barrier collision
				if(bally2 >= 10'd470) nextDir <= LU;
				// Paddle collisions
				else if(ballx1 <= 10'd75 && ballx1 >= 10'd50 && (bally1 + 10'd15) >= paddle1y1) begin
					if((bally1 + 10'd15) <= (paddle1y1 + 40)) nextDir = RU;
					else if((bally1 + 10'd15) <= (paddle1y1 + 80)) nextDir = RM;
					else if((bally1 + 10'd15) <= paddle1y2) nextDir = RD;
					else nextDir = LD;
				end
				// No collision
				else nextDir = LD;
			end
			RU: begin
				// Barrier collision
				if(bally1 <= 10'd10) nextDir <= RD;
				// Paddle collisions
				else if(ballx1 >= 10'd535 && ballx1 <= 10'd560 && (bally1 + 10'd15) >= paddle2y1) begin
					if((bally1 + 10'd15) <= (paddle2y1 + 40)) nextDir = LU;
					else if((bally1 + 10'd15) <= (paddle2y1 + 80)) nextDir = LM;
					else if((bally1 + 10'd15) <= paddle2y2) nextDir = LD;
					else nextDir = RU;
				end
				// No collision
				else nextDir = RU;
			end
			RM: begin
				// Paddle collisions
				if(ballx1 >= 10'd535 && ballx1 <= 10'd560 && (bally1 + 10'd15) >= paddle2y1) begin
					if((bally1 + 10'd15) <= (paddle2y1 + 40)) nextDir = LU;
					else if((bally1 + 10'd15) <= (paddle2y1 + 80))nextDir = LM;
					else if((bally1 + 10'd15) <= paddle2y2) nextDir = LD;
					else nextDir = RM;
				end
				// No collision
				else nextDir = RM;
			end
			RD: begin
				// Barrier collision
				if(bally2 >= 10'd470) nextDir <= RU;
				// Paddle collisions
				else if(ballx1 >= 10'd535 && ballx1 <= 10'd560 && (bally1 + 10'd15) >= paddle2y1) begin
					if((bally1 + 10'd15) <= (paddle2y1 + 40)) nextDir = LU;
					else if((bally1 + 10'd15) <= (paddle2y1 + 80)) nextDir = LM;
					else if((bally1 + 10'd15) <= paddle2y2) nextDir = LD;
					else nextDir = RD;
				end
				// No collision
				else nextDir = RD;
			end
			default: nextDir = LU;
		endcase
	// next state logic
	assign direction[2] = (currDir == RU) || (currDir == RM) || (currDir == RD);
	assign direction[1] = (currDir == LU) || (currDir == RU) || (currDir == LM) || (currDir == RM);
	assign direction[0] = (currDir == LD) || (currDir == RD) || (currDir == LM) || (currDir == RM);
endmodule

// COMPLETED
// This module checks whenever the ball is past a
// player's paddle and increases the score accordingly.
module scoreKeeper(input  logic clk, reset,
		   input  logic [9:0] ballx1, ballx2,
		   output logic [3:0] score1, score2);
	always_ff@(posedge clk, posedge reset)
		// if the game is reset, reset the scores
		if (reset) begin
			score1 <= 4'b0;
			score2 <= 4'b0;
		end
		// If ball is outside of play area, give points.
		else if (ballx2 >= 620)		score1 <= score1 + 1'b1;
		else if (ballx1 <= 20) 		score2 <= score2 + 1'b1;
		// if score is >= 10, reset score
		else if (score1 >= 10)		score1 <= 4'b0;
		else if (score2 >= 10) 		score2 <= 4'b0;
		// if nothing eventful happens, keep the score.
		else begin
			score1 <= score1;
			score2 <= score2;
		end
endmodule

// COMPLETED
// Display which game mode is in play.
module gameModeDisplay(input  logic clk, speedEn,
		       		   output logic [6:0] S,
					   output logic [6:0] P);
	always_ff@(posedge clk)
		if (speedEn) begin
			S <= 7'b001_0010;
			P <= 7'b000_1100;
		end
		else begin
			S <= 7'b111_1111;
			P <= 7'b000_1100;
		end
endmodule