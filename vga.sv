/*
VGA Controller for SpeedPong
*/

module vgaGame(input  logic clk, reset,
               input  logic [9:0] p1y1, p1y2,
               input  logic [9:0] p2y1, p2y2,
	       input  logic [9:0] ballx1, ballx2,
               output logic vgaclk,          // 25.175 MHz VGA clock 
               output logic hsync, vsync, 
               output logic sync_b, blank_b, // to monitor & DAC 
               output logic [7:0] r, g, b);  // to video DAC 

  logic [9:0] x, y; 

  // Use a clock divider to create the 25 MHz VGA pixel clock 
  // 25 MHz clk period = 40 ns 
  // Screen is 800 clocks wide by 525 tall, but only 640 x 480 used for display 
  // HSync = 1/(40 ns * 800) = 31.25 kHz 
  // Vsync = 31.25 KHz / 525 = 59.52 Hz (~60 Hz refresh rate) 
  
  // divide 50 MHz input clock by 2 to get 25 MHz clock
  always_ff @(posedge clk, posedge reset)
    if (reset)
	   vgaclk = 1'b0;
    else
	   vgaclk = ~vgaclk;
		
  // generate monitor timing signals 
  vgaController vgaCont(vgaclk, reset, hsync, vsync, sync_b, blank_b, x, y); 

  // user-defined module to determine pixel color
  // now used in unison with speedpong to display,
  // move, and manage the game elements.
  videoGen videoGen(x, y, p1y1, p1y2, p2y1, p2y2, ballx1, ballx2, r, g, b); 
  
endmodule 


module vgaController #(parameter HBP     = 10'd48,   // horizontal back porch
                                 HACTIVE = 10'd640,  // number of pixels per line
                                 HFP     = 10'd16,   // horizontal front porch
                                 HSYN    = 10'd96,   // horizontal sync pulse = 60 to move electron gun back to left
                                 HMAX    = HBP + HACTIVE + HFP + HSYN, //48+640+16+96=800: number of horizontal pixels (i.e., clock cycles)
                                 VBP     = 10'd32,   // vertical back porch
                                 VACTIVE = 10'd480,  // number of lines
                                 VFP     = 10'd11,   // vertical front porch
                                 VSYN    = 10'd2,    // vertical sync pulse = 2 to move electron gun back to top
                                 VMAX    = VBP + VACTIVE + VFP  + VSYN) //32+480+11+2=525: number of vertical pixels (i.e., clock cycles)                      

     (input  logic vgaclk, reset,
      output logic hsync, vsync, sync_b, blank_b, 
      output logic [9:0] hcnt, vcnt); 

      // counters for horizontal and vertical positions 
      always @(posedge vgaclk, posedge reset) begin 
        if (reset) begin
          hcnt <= 0;
          vcnt <= 0;
        end
        else  begin
          hcnt++; 
      	   if (hcnt == HMAX) begin 
            hcnt <= 0; 
  	        vcnt++; 
  	        if (vcnt == VMAX) 
  	          vcnt <= 0; 
          end 
        end
      end 
	  

      // compute sync signals (active low) 
      assign hsync  = ~( (hcnt >= (HACTIVE + HFP)) & (hcnt < (HACTIVE + HFP + HSYN)) ); 
      assign vsync  = ~( (vcnt >= (VACTIVE + VFP)) & (vcnt < (VACTIVE + VFP + VSYN)) ); 
      // assign sync_b = hsync & vsync; 
      assign sync_b = 1'b0;  // this should be 0 for newer monitors

      // force outputs to black when not writing pixels
      // The following also works: assign blank_b = hsync & vsync; 
      assign blank_b = (hcnt < HACTIVE) & (vcnt < VACTIVE); 
endmodule 


module videoGen(input  logic [9:0] x, y,
                input  logic [9:0] p1y1, p1y2,
                input  logic [9:0] p2y1, p2y2,
		input  logic [9:0] ballx1, ballx2,
                output logic [7:0] r, g, b); 
  // Used to determine where to draw to screen
  logic inp1, inp2, inball, inbartop, inbarbot; 
  // 
  rectgen barrierTop(x, y, 10'd1, 10'd1, 10'd640, 10'd10, inbartop);
  rectgen barrierBottom(x, y, 10'd1, 10'd471, 10'd640, 10'd480, inbarbot);
  // Game elements  
  rectgen paddle1(x, y, 10'd50, p1y1, 10'd75, p1y2, inp1); 
  rectgen paddle2(x, y, 10'd565, p2y1, 10'd590, p2y2, inp2);
  rectgen ball(x, y, ballx1, 10'd225, ballx2, 10'd255, inball);
  // Make all the game elements a single color.
  assign {r, g, b} = (inball) || (inp1) || (inp2) || (inbartop) || (inbarbot) ? {8'hFF, 8'hFF, 8'hFF} : {8'h00, 8'h00, 8'h00};
endmodule


module rectgen(input  logic [9:0] x, y, left, top, right, bot, 
               output logic inrect);
			   
  assign inrect = (x >= left & x < right & y >= top & y < bot); 
  
endmodule 


