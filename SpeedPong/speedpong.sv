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
    logic [3:0] p1score;
    logic [3:0] p2score;
    // assign p1score = 4'b0000;
    // assign p2score = 4'b0000;
    logic [9:0] paddle1y1, paddle1y2;
    logic [9:0] paddle2y1, paddle2y2;
    logic [9:0] ballx1, ballx2;
    // assign paddle1y1 = 10'd180;
    // assign paddle1y2 = 10'd300;
    // assign paddle2y1 = 10'd180;
    // assign paddle2y2 = 10'd300;
    
    // Module instantiations
    vgaGame gameScreen(clk, sysReset, paddle1y1, paddle1y2,
             paddle2y1, paddle2y2, ballx1, ballx2, vgaClock, hsync, vsync, syncB, blankB,
			 red, green, blue);
    paddleClk paddleClk(clk, sysReset, padClk);
    scoreClk scoreClk(clk, sysReset, scrClk);
    paddleFSM p1FSM(clk, gameReset, p1up, p1down, pad1upEn, pad1downEn);
    paddleFSM p2FSM(clk, gameReset, p2up, p2down, pad2upEn, pad2downEn);
    paddle paddle1(padClk, paddle1y1, paddle1y2, pad1upEn, pad1downEn, gameReset);
    paddle paddle2(padClk, paddle2y1, paddle2y2, pad2upEn, pad2downEn, gameReset);
    ball ball(padClk, gameReset, ballx1, ballx2);
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
    // final clk TBD
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
// about 10 pixels per second when
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
module ball(input  logic clk, reset,
	    output logic [9:0] ballx1, ballx2);
	always_ff@(posedge clk, posedge reset)
		if (reset) begin
			ballx1 <= 10'd215;
			ballx2 <= 10'd265;
		end
		else if (ballx2 >= 630)	begin
			ballx1 <= 10'd215;
			ballx2 <= 10'd265;
		end
		// Testing scoring!
		else begin
			ballx1 <= ballx1 + 10'd1;
			ballx2 <= ballx2 + 10'd1;
		end
endmodule

// This constantly checks if the ball's coordinates
// are going to overlap with a paddles's coordinates.
module ballCollision();

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