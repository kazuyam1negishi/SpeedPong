// remember
// this is active low, not active high
// and the output should be from g:a, not a:g

module sevenseg(input logic [3:0] data,
		output logic [6:0] segments);
	always_comb
		begin
	case (data)
	0: segments = 7'b100_0000;
	1: segments = 7'b111_1001;
	2: segments = 7'b010_0100;
	3: segments = 7'b011_0000;
	4: segments = 7'b001_1001;
	5: segments = 7'b001_0010;
	6: segments = 7'b000_0010;
	7: segments = 7'b111_1000;
	8: segments = 7'b000_0000;
	9: segments = 7'b001_1000;
	10: segments = 7'b111_1111;
	default: segments = 7'b111_1111;
	endcase
	end
endmodule

module scoreDisplay(input  logic clk, reset,
					 input  logic [3:0] p1score,
					 input  logic [3:0] p2score,
					 output logic [6:0] p,
					 output logic [6:0] n);
	sevenseg score1(p1score, n);
	sevenseg score2(p2score, p);
endmodule