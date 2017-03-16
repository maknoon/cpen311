// Implements a simple Nios II system for the DE-series board.
//          CLOCK_50 is the system clock
//          KEY[0] is the active-low system reset  

input [7:0] SW; 
input [0:0] KEY; 
output [7:0] LEDR;
output [6:0] HEX1, HEX0;
output [7:0] LEDG;
wire [7:0] numbers;

nios_system NiosII (
   .reset_reset_n(KEY), 
   .switches_export(SW), 
   .leds_export(LEDR),
	.out_out_export(numbers),
	.done_export(LEDG[2]),
	.is_prime_export(LEDG[1:0]));

// Instantiate two led drivers
leddriver leddriver_0(
	.num(numbers[3:0]),
	.seg7(HEX0[6:0]));

leddriver leddriver_1(
	.num(numbers[7:4]),
	.seg7(HEX1[6:0]));

endmodule