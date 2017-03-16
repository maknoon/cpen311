// DATAPATH
module datapath ( clock,
						initx, inity, initc,
						loadx, loady, octantflag,
						radius,
						c_x, c_y,
						ydone, xdone, cdone, alldone,
						selx, sely,
						outx, outy,
					   colour,
						colourbit,
						circle);
						
input clock;
input initx, loadx;
input inity, loady;
input initc, octantflag;
input [7:0] radius, c_x, c_y;
input [2:0] selx, sely;
input [2:0] circle;
input colourbit;
output reg[6:0] outy;
output reg[7:0] outx;
output reg xdone, ydone, cdone;
output reg [2:0] alldone;
output reg [2:0] colour; // the colour of the pixel to draw
reg [6:0] y;
reg [7:0] x;
reg [7:0] center_x, center_y;
reg signed [8:0] crit;
reg [7:0] offset_x, offset_y;
reg [2:0] currentcircle;

// Select the colour and pixels
always_comb
	begin
		case (colourbit)
			1'b0: colour <= 3'b000; // black background
			1'b1: 
				begin
					case(currentcircle)
						3'b000: colour <= 3'b001; // BLUE
						3'b001: colour <= 3'b110; // YELLOW
						3'b010: colour <= 3'b111; // WHITE
						3'b011: colour <= 3'b010; // GREEN
						3'b100: colour <= 3'b100; // RED
						default: colour <= 3'b100; // something else
					endcase 
				end
		endcase
	
		// select the x
		case (selx)
			3'b001: outx <= center_x + offset_x; // octant 1, octant 7
			3'b010: outx <= center_x + offset_y; // octant 2, octant 8
			3'b011: outx <= center_x - offset_x; // octant 4, octant 5
			3'b100: outx <= center_x - offset_y; // octant 3, octant 6
			default: outx <= x;
		endcase

		// select the y
		case (sely)
			3'b001: outy <= center_y[6:0] + offset_y[6:0]; // octant 1, octant 4
			3'b010: outy <= center_y[6:0] + offset_x[6:0]; // octant 2, octant 3
			3'b011: outy <= center_y[6:0] - offset_y[6:0]; // octant 5, octant 7
			3'b100: outy <= center_y[6:0] - offset_x[6:0]; // octant 6, octant 8
			default: outy <= y;
		endcase
	end

// Each clock cycle, draw one pixel with one colour.
// Done when we reach the end of the screen.
always_ff @(posedge(clock))
	begin

		// filling the screen
		if (loady == 1)
			begin 
				if (inity == 1) y = 0;
				else y ++;
			end
		if (loadx == 1)
			begin
				if (initx == 1) x = 0;
				else x ++;
			end

		// circle
		// starting values for offset & crit
		if (initc == 1)
			begin
				currentcircle = circle;
				case (currentcircle)
					// yellow
					3'b001:
						begin
							center_x = c_x + 8'd26;
							center_y = c_y * 8'd2 - 8'd10;
						end
					// white	
					3'b010:
						begin
							center_x = c_x * 8'd2 + 8'd22;
							center_y = c_y;
						end
					// green	
					3'b011:
						begin
							center_x = c_x + 8'd78;
							center_y = c_y * 8'd2 - 8'd10;
						end
					// red	
					3'b100:
						begin
							center_x = c_x * 8'd4 + 8'd14;
							center_y = c_y;
						end
					// blue
					default:
						begin
							center_x = c_x;
							center_y = c_y;
						end						
				endcase
				
				offset_x = radius;
				offset_y = 8'd0;
				crit = 1'd1 - radius;
			end

		// shift to next set of bits for each octant
		if (octantflag == 1)
			begin
				if (offset_y <= offset_x)
					begin
					offset_y ++;
					if (crit <= 0) crit = crit + 2'b10 * offset_y + 1'b1;
					else
						begin
							offset_x --;
							crit = crit + 2'b10 * (offset_y - offset_x) + 1'b1;
						end
					end
			end
					
		// know when we are finished
		ydone <= 0;
		xdone <= 0;
		cdone <= 0;
		alldone <= currentcircle;
		if (outy == 120) ydone <= 1;
		if (outx == 159) xdone <= 1;
		if (offset_y > offset_x)
			begin
				cdone <= 1;
				alldone <= currentcircle + 1'b1;
			end

	end

endmodule