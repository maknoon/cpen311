// Liesl Schwab 32296121
// Connie (Cong) Ma 56047129

module card7seg (card, seg7);

input [3:0] card;
output [6:0] seg7;

   // Your code for Phase 2 goes here.  Be sure to check the Slide Set 2 notes,
   // since one of the slides almost gives away the ancarder here.  I wrote this as
   // a single combinational always block containing a single case statement, but
   // there are other ways to do it.
always_comb
  case (card)
    4'b0001: seg7 = 7'b0001000; // 1 = ace
    4'b0010: seg7 = 7'b0100100; // 2
    4'b0011: seg7 = 7'b0110000; // 3
    4'b0100: seg7 = 7'b0011001; // 4
    4'b0101: seg7 = 7'b0010010; // 5
    4'b0110: seg7 = 7'b0000010; // 6
    4'b0111: seg7 = 7'b1111000; // 7
    4'b1000: seg7 = 7'b0000000; // 8
    4'b1001: seg7 = 7'b0010000; // 9
    4'b1010: seg7 = 7'b1000000; // 10 = 0
    4'b1011: seg7 = 7'b1110001; // 11 = J
    4'b1100: seg7 = 7'b0011000; // 12 = q
    4'b1101: seg7 = 7'b0001001; // 13 = K
    default: seg7 = 7'b1111111; // default = everything off
	endcase
endmodule
