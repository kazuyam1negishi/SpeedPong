// SpeedPong Wrapper
// for the DE2-115 FPGA Board.

module speedPongWrapper(input  logic       CLOCK_50,
                        input  logic [1:0] SW,
                        input  logic [3:0] KEY,
                        output logic [6:0] HEX0,
                        output logic [6:0] HEX7,
                        output logic       VGA_CLK, 
                        output logic       VGA_HS,
                        output logic       VGA_VS,
                        output logic       VGA_SYNC_N,
                        output logic       VGA_BLANK_N,
                        output logic [7:0] VGA_R,
                        output logic [7:0] VGA_G,
                        output logic [7:0] VGA_B);
    speedPong speedPongGame(CLOCK_50, SW[0], SW[1], KEY[3], KEY[2],
        KEY[1], KEY[0], HEX0,
        HEX7, VGA_CLK,
        VGA_HS, VGA_VS, VGA_SYNC_N, VGA_BLANK_N, VGA_R,
        VGA_G, VGA_B);
endmodule