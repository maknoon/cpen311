// CONTROLLER/STATE MACHINE
module statemachine( clock, reset,
							xdone, ydone, cdone, alldone,
							initxOUT, inityOUT,
							loadxOUT, loadyOUT,
							initc, octantflag,
							selx, sely,
							plotOUT,
							colourbit,
							circle);

input clock, reset;
input xdone, ydone, cdone;
input [2:0] alldone;
output reg [2:0] circle;
output reg initxOUT, inityOUT;
output reg loadxOUT, loadyOUT;
output reg initc, octantflag;
output reg [2:0] selx, sely;
output reg plotOUT;
output reg colourbit;
enum {INIT, FILLX, FILLY, CIRCLE1, CIRCLE2, CIRCLE3, CIRCLE4, CIRCLE5, CIRCLE6,
CIRCLE7, CIRCLE8, CIRCLEOFFSET, SETCIRCLEB, SETCIRCLEY, SETCIRCLEW, SETCIRCLEG, 
SETCIRCLER} current_state, next_state;

	// Determine the current_state and the next_state for plotting pixels
	always_comb
	begin
		case (current_state)
			INIT: next_state <= FILLX;
			FILLX:
				begin
					if (xdone == 0) next_state <= FILLX;
					else if (ydone == 0) next_state <= FILLY;
					else next_state <= SETCIRCLEB;
				end
			FILLY: next_state <= FILLX;
			SETCIRCLEB: next_state <= CIRCLE1;
			SETCIRCLEY: next_state <= CIRCLE1;
			SETCIRCLEW: next_state <= CIRCLE1;
			SETCIRCLEG: next_state <= CIRCLE1;
			SETCIRCLER: next_state <= CIRCLE1;
			CIRCLE1: next_state <= CIRCLE2;
			CIRCLE2: next_state <= CIRCLE3;
			CIRCLE3: next_state <= CIRCLE4;
			CIRCLE4: next_state <= CIRCLE5;
			CIRCLE5: next_state <= CIRCLE6;
			CIRCLE6: next_state <= CIRCLE7;
			CIRCLE7: next_state <= CIRCLE8;
			CIRCLE8: next_state <= CIRCLEOFFSET;
			CIRCLEOFFSET:
				begin
					if (cdone == 1)
						begin
							case(alldone)
								3'b001: next_state <= SETCIRCLEY;
								3'b010: next_state <= SETCIRCLEW;
								3'b011: next_state <= SETCIRCLEG;
								3'b100: next_state <= SETCIRCLER;
								default: next_state <= CIRCLE1;
							endcase
						end
					else next_state <= CIRCLE1;
				end
			default: next_state <= INIT;
		endcase
	end

	// State machine driver with asynchronous reset
	always_ff @(posedge(clock), posedge(reset))
		if (reset == 1) current_state <= INIT;
		else current_state <= next_state;
	
	// What to set outputs of state machine to for each state
	always_comb
	begin
		case (current_state)
			INIT: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b11110100000000000;
			FILLX: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b00011000000000000;
			FILLY: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b10110000000000000;
			SETCIRCLEB: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b11110100000001000; // blue 000
			SETCIRCLEY: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b11110100000001001; // yellow 001
			SETCIRCLEW: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b11110100000001010; // white 010
			SETCIRCLEG: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b11110100000001011; // green 011
			SETCIRCLER: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b11110100000001100; // red 100
			CIRCLE1: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b00111000010011000; // 1 = 001 001
			CIRCLE2: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b00111000100101000; // 2 = 010 010
			CIRCLE3: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b00111001000101000; // 3 = 100 010
			CIRCLE4: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b00111000110011000; // 4 = 011 001
			CIRCLE5: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b00111000110111000; // 5 = 011 011
			CIRCLE6: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b00111001001001000; // 6 = 100 100
			CIRCLE7: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b00111000010111000; // 7 = 001 011
			CIRCLE8: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b00111000101001000; // 8 = 010 100
			CIRCLEOFFSET: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b00000010000000000;
			default: {initxOUT, inityOUT, loadyOUT, loadxOUT, plotOUT,
						initc, octantflag, selx, sely, colourbit, circle} <= 17'b00000000000000000;
		endcase
	end
			
endmodule
	