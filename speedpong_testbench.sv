// Basic testbench for the SpeedPong game.

module speedPongPaddleTestbench();
	// Internal logic, enough to test.
	logic clk, reset;
	logic up, down;
	logic [9:0] y1, y2;
	// Device under test (dut)
	paddle dut(clk, y1, y2, up, down, reset);
	// Clock declaration;
	always
		begin
			clk = 1'b1; #5; clk = 1'b0; #5;
		end
	// Testing up/down controls
	// to make sure y coordinates change.
	initial
		begin	
			reset = 1'b1; #50;
			reset = 1'b0; #50;
			up = 1'b1; #200;
			up = 1'b0; #100;
			down = 1'b1; #300;
			down = 1'b0; #100;
			reset = 1'b1; #50;
			reset = 1'b0; #50;
		end
endmodule