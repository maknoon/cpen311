// TASK 2 MAIN
module task2 (CLOCK_50, 
		 KEY,             
       VGA_R, VGA_G, VGA_B, 
       VGA_HS,             
       VGA_VS,             
       VGA_BLANK,           
       VGA_SYNC,            
       VGA_CLK);
  
input CLOCK_50;
input [3:0] KEY;
output [9:0] VGA_R, VGA_G, VGA_B; 
output VGA_HS;             
output VGA_VS;          
output VGA_BLANK;           
output VGA_SYNC;            
output VGA_CLK;

// Some constants that might be useful for you

parameter SCREEN_WIDTH = 160;
parameter SCREEN_HEIGHT = 120;

parameter BLACK = 3'b000;
parameter BLUE = 3'b001;
parameter GREEN = 3'b010;
parameter YELLOW = 3'b110;
parameter RED = 3'b100;
parameter WHITE = 3'b111;

// To VGA adapter  
wire resetn;
wire [7:0] x;
wire [6:0] y;
reg [2:0] colour;
reg plot;

// wires to connect datapath and controller
wire loady, loadx, octantflag;
wire inity, initx, initc;
wire ydone, xdone, cdone;
wire [2:0] alldone;
wire colourbit;
wire [2:0] selx, sely;
wire [7:0] radius, center_x, center_y;

// which circle are we on
wire [2:0] circle;

// parameters for circle drawing
parameter CENTER_X = 8'd30;
parameter CENTER_Y = 8'd40;
parameter RADIUS = 8'd25;

// State Machine states
reg [3:0] current_state, next_state;

// instantiate VGA adapter 
	
vga_adapter #( .RESOLUTION("160x120"))
    vga_u0 (.resetn(KEY[3]),
	         .clock(CLOCK_50),
			   .colour(colour),
			   .x(x),
			   .y(y),
			   .plot(plot),
			   .VGA_R(VGA_R),
			   .VGA_G(VGA_G),
			   .VGA_B(VGA_B),	
			   .VGA_HS(VGA_HS),
			   .VGA_VS(VGA_VS),
			   .VGA_BLANK(VGA_BLANK),
			   .VGA_SYNC(VGA_SYNC),
			   .VGA_CLK(VGA_CLK));


// Your code to fill the screen goes here.  

// instantiate datapath
datapath dp (  .clock(CLOCK_50),
					.initx(initx),
					.inity(inity),
					.initc(initc),
					.loadx(loadx),
					.loady(loady),
					.octantflag(octantflag),
					.radius(RADIUS),
					.c_x(CENTER_X),
					.c_y(CENTER_Y),
					.ydone(ydone),
					.xdone(xdone),
					.cdone(cdone),
					.alldone(alldone),
					.selx(selx),
					.sely(sely),
					.outx(x),
					.outy(y),
				   .colour(colour),
					.colourbit(colourbit),
					.circle(circle));

// instantiate statemachine
statemachine sm ( .clock(CLOCK_50),
						.reset(KEY[3]),
						.xdone(xdone),
						.ydone(ydone),
						.cdone(cdone),
						.alldone(alldone),
						.selx(selx),
						.sely(sely),
						.initxOUT(initx),
						.inityOUT(inity),
						.loadxOUT(loadx),
						.loadyOUT(loady),
						.initc(initc),
						.octantflag(octantflag),
						.plotOUT(plot),
						.colourbit(colourbit),
						.circle(circle));

endmodule


