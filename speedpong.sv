/*
Speed Pong
Based on: Pong (Original (C) 1972-2024 Atari)
By: Cristian Rodriguez Millan and Jimmy Soto Agustin
Created for UNLV Spring 2024 College of Engineering Junior Design Competition

This VHDL code has been slightly modified for its release on GitHub.
*/

// The game module serves as a structural
// module for all the modules in our project.
module speedPong(input  logic clk, sysReset, gameReset,      // clock for system
                 input  logic p1up, p1down, 	// buttons
                 input  logic p2up, p2down,
                 output logic [6:0] seg0,	// scores
                 output logic [6:0] seg7,
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
    
    // Module instantiations
	// VGA game screen
    vgaGame gameScreen(clk, sysReset, paddle1y1, paddle1y2,
             paddle2y1, paddle2y2, ballx1, ballx2, vgaClock, hsync, vsync, syncB, blankB,
			 red, green, blue);
	// Clocks (DO NOT TOUCH)
    paddleClk paddleClk(clk, sysReset, padClk);
    scoreClk scoreClk(clk, sysReset, scrClk);
	// Paddle FSMs for handling movement
    paddleFSM p1FSM(clk, gameReset, p1up, p1down, pad1upEn, pad1downEn);
    paddleFSM p2FSM(clk, gameReset, p2up, p2down, pad2upEn, pad2downEn);
	// Paddle modules for positions
    paddle paddle1(padClk, paddle1y1, paddle1y2, pad1upEn, pad1downEn, gameReset);
    paddle paddle2(padClk, paddle2y1, paddle2y2, pad2upEn, pad2downEn, gameReset);
	// Ball module for handling movement
	// Remember to add vars for ball FSM and new vars for ball
	// to allow movement in y direction!
    ball ball(padClk, gameReset, ballx1, ballx2);
	// Ball FSM for handling collisions and new direction
	ballCollisions ballColl();
	// Score keeper and display
    scoreDisplay(clk, gameReset, p1score, p2score, seg7, seg0);
    scoreKeeper(scrClk, gameReset, ballx1, ballx2, p1score, p2score);

endmodule

// We needed a reduced clock in order to
// move the paddles slowly, since the clock
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
        else            cnt <= cnt + 4300;
    assign clk200Hz = cnt[29];
endmodule

module scoreClk(input  logic clk, reset,
		output logic clk1Hz);
	logic [31:0] cnt;
	always_ff@(posedge clk, posedge reset)
	 	if (reset)	cnt <= 1'b0;
		else		cnt <= cnt + 1575;
	assign clk1Hz = cnt[31];
endmodule

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
              input  logic reset);
    always_ff@(posedge clk, posedge reset)
        if (reset) begin
            // reset control
            y1 <= 10'd180;
            y2 <= 10'd300;
        end
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

// This module behaves the same as
// the paddle module.
// This modules now handles collisions
// as well as the movement of the ball.
module ball(input  logic       clk, reset,
			input  logic [2:0] direction,
	    output logic [9:0] ballx1, ballx2);
	always_ff@(posedge clk, posedge reset)
		// Reset if game reset high.
		if (reset) begin
			ballx1 <= 10'd305;
			ballx2 <= 10'd335;
		end
		// These two conditions reset the ball
		// if a goal is reached.
		else if (ballx1 <= 10)	begin
			ballx1 <= 10'd305;
			ballx2 <= 10'd335;
		end
		else if (ballx2 >= 630)	begin
			ballx1 <= 10'd305;
			ballx2 <= 10'd335;
		end
		// Originally just for testing.
		// Will be used for RM.
		else begin
			ballx1 <= ballx1 + 10'd1;
			ballx2 <= ballx2 + 10'd1;
		end
endmodule 

// Ball collisions module
// This module handles the collisions
// based on the current position of the ball
// relative to the paddles/barriers.
module ballCollisions(input  logic       clk, reset,
					  input  logic [9:0] ballx1, bally1, ballx2, bally2,
					  input  logic [9:0] paddle1y1, paddle1y2,
					  input  logic [9:0] paddle2y1, paddle2y2,
					  output logic [2:0] direction);
	// In this first version, 6 states
	// are used for each possible direction
	// of the ball.
	/* Key
	L - left, R - right
	U - up, M - middle, D - down
	*/

	// internal logic for comparisons
	logic [9:0] ballCtr = ballx1 + 15;
	// Define boundaries for new angle
	// Paddle 1
	logic [9:0] padUpLim1 = paddle1y1 + 40;
	logic [9:0] padMidMin1 = paddle1y1 + 41;
	logic [9:0] padMidLim1 = paddle1y1 + 79;
	logic [9:0] padDownMin1 = paddle1y1 + 80;
	// Paddle 2
	logic [9:0] padUpLim2 = paddle2y1 + 40;
	logic [9:0] padMidMin2 = paddle2y1 + 41;
	logic [9:0] padMidLim2 = paddle2y1 + 79;
	logic [9:0] padDownMin2 = paddle2y1 + 80;
	// state types
	typedef enum logic {LU, LM, LD, RU, RM, RD} stateDir;
	stateDir currDir, nextDir;
	// state register
	always_ff@(posedge clk, posedge reset)
		if (reset)		currDir <= LU;
		else			currDir <= nextDir;
	// next state logic
	// REMEMBER YOU'RE MISSING A CHECK
	// TO SEE IF YOUR X FOR THE BALL & PADDLE MATCH!
	always_comb
		case(currDir)
			LU: begin
				// Top barrier collision
				if(ballx1 <= 10)											nextDir <= LD;
				// Paddle collisions
				else if(ballCtr >= paddle1y1 && ballCtr <= padUpLim1)		nextDir <= RU;
				else if(ballCtr >= padMidMin1 && ballCtr <= padMidLim1) 	nextDir <= RM;
				else if(ballCtr >= padDownMin1 && ballCtr <= paddle1y2) 	nextDir <= RD;
				// No collision
				else														nextDir <= LU;
			end
			LM: begin
				// No barrier collisions! Only paddle collisions!
				if(ballCtr >= paddle1y1 && ballCtr <= padUpLim1)			nextDir <= RU;
				else if(ballCtr >= padMidMin1 && ballCtr <= padMidLim1) 	nextDir <= RM;
				else if(ballCtr >= padDownMin1 && ballCtr <= paddle1y2) 	nextDir <= RD;
				// No collision
				else														nextDir <= LM;
			end
			LD: begin
				// Botton barrier collision
				if(ballx1 >= 470)											nextDir <= LU;
				// Paddle collisions
				else if(ballCtr >= paddle1y1 && ballCtr <= padUpLim1)		nextDir <= RU;
				else if(ballCtr >= padMidMin1 && ballCtr <= padMidLim1) 	nextDir <= RM;
				else if(ballCtr >= padDownMin1 && ballCtr <= paddle1y2) 	nextDir <= RD;
				// No collision
				else														nextDir <= LD;
			end 
			RU: begin
				// Top barrier collision
				if(ballx1 <= 10)											nextDir <= RD;
				// Paddle collisions
				else if(ballCtr >= paddle2y1 && ballCtr <= padUpLim2)		nextDir <= LU;
				else if(ballCtr >= padMidMin2 && ballCtr <= padMidLim2) 	nextDir <= LM;
				else if(ballCtr >= padDownMin2 && ballCtr <= paddle2y2) 	nextDir <= LD;
				// No collision
				else														nextDir <= RU;
			end
			RM: begin
				// No barrier collisions! Only paddle collisions!
				if(ballCtr >= paddle2y1 && ballCtr <= padUpLim2)			nextDir <= LU;
				else if(ballCtr >= padMidMin2 && ballCtr <= padMidLim2) 	nextDir <= LM;
				else if(ballCtr >= padDownMin2 && ballCtr <= paddle2y2) 	nextDir <= LD;
				// No collision
				else														nextDir <= RM;
			end
			RD: begin
				// Botton barrier collision
				if(ballx1 >= 470)											nextDir <= RU;
				// Paddle collisions
				else if(ballCtr >= paddle2y1 && ballCtr <= padUpLim2)		nextDir <= LU;
				else if(ballCtr >= padMidMin2 && ballCtr <= padMidLim2) 	nextDir <= LM;
				else if(ballCtr >= padDownMin2 && ballCtr <= paddle2y2) 	nextDir <= LD;
				// No collision
				else														nextDir <= RD;
			end
		endcase
	// output logic 'omitted'
	// already implemented
	// inside next state logic
endmodule

// This module checks whenever the ball is past a
// player's paddle and increases the score accordingly.
module scoreKeeper(input  logic clk, reset,
		   input  logic [9:0] ballx1, ballx2,
		   output logic [3:0] score1, score2);
	always_ff@(posedge clk, posedge reset)
		if (reset) begin
			score1 <= 4'b0;
			score2 <= 4'b0;
		end
		else if (ballx2 >= 620)		score1 <= score1 + 1'b1;
		else if (ballx1 <= 20) 		score2 <= score2 + 1'b1;
		else if (score1 >= 10)		score1 <= 4'b0;
		else if (score2 >= 10) 		score2 <= 4'b0;
		else begin
			score1 <= score1;
			score2 <= score2;
		end
endmodule