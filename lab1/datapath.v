module datapath ( slow_clock, fast_clock, resetb,
                  load_pcard1, load_pcard2, load_pcard3,
                  load_dcard1, load_dcard2, load_dcard3,
                  pcard3_out,
                  pscore_out, dscore_out,
                  HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

input slow_clock, fast_clock, resetb;
input load_pcard1, load_pcard2, load_pcard3;
input load_dcard1, load_dcard2, load_dcard3;
output [3:0] pcard3_out;
output [3:0] pscore_out, dscore_out;
output [6:0] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

// wires
wire [3:0] new_card;
wire [3:0] p_card1, p_card2;
wire [3:0] d_card1, d_card2, d_card3;

// The code describing your datapath will go here.  Your datapath
// will hierarchically instantiate six card7seg blocks, two scorehand
// blocks, and a dealcard block.  The registers may either be instatiated
// or included as sequential always blocks directly in this file.
//
// Follow the block diagram in the Lab 1 handout closely as you write this code

// card7seg
// Player card 1
card7seg p1 (.card(p_card1), .seg7(HEX0));

// Player card 2
card7seg p2 (.card(p_card2), .seg7(HEX1));

// Player card 3
card7seg p3 (.card(pcard3_out), .seg7(HEX2));

// Dealer card 1
card7seg d1 (.card(d_card1), .seg7(HEX3));

// Dealer card 2
card7seg d2 (.card(d_card2), .seg7(HEX4));

// Dealer card 3
card7seg d3 (.card(d_card3), .seg7(HEX5));

card7seg p0 (.card(14), .seg7(HEX6));
card7seg d0 (.card(14), .seg7(HEX7));

// dealcard
// inputs: 
//				fast_clock <- used for the RNG
// 			slow_clock <- signal to generate a new card
// outputs: new_card <- goes to reg4 for the player or dealer and card number
dealcard dc (.clock(fast_clock),
             .resetb(resetb),
             .new_card(new_card));

// reg4
// inputs: new_card
//         load_pcard1 <- if 0 then new_card is 'saved'
//         resetb
//         slow_clock
// outputs: card_value <- same as new_card, goes to scorehand
reg4 pcard1 (.CLK(slow_clock), 
				 .reset(resetb), 
				 .load_card(load_pcard1), 
				 .incard(new_card), 
				 .outcard(p_card1));
				 
reg4 pcard2 (.CLK(slow_clock), 
				 .reset(resetb), 
				 .load_card(load_pcard2), 
				 .incard(new_card), 
				 .outcard(p_card2));	

reg4 pcard3 (.CLK(slow_clock), 
				 .reset(resetb), 
				 .load_card(load_pcard3), 
				 .incard(new_card), 
				 .outcard(pcard3_out));
		
reg4 dcard1 (.CLK(slow_clock), 
				 .reset(resetb), 
				 .load_card(load_dcard1), 
				 .incard(new_card), 
				 .outcard(d_card1));	

reg4 dcard2 (.CLK(slow_clock), 
				 .reset(resetb), 
				 .load_card(load_dcard2), 
				 .incard(new_card), 
				 .outcard(d_card2)); 

reg4 dcard3 (.CLK(slow_clock), 
				 .reset(resetb), 
				 .load_card(load_dcard3), 
				 .incard(new_card), 
				 .outcard(d_card3));
				 
// scorehand
// inputs: 3x card_value <- one for each of the cards in hand
// output: score <- goes to state machine
scorehand ps (.card1(p_card1),
              .card2(p_card2),
              .card3(pcard3_out),
              .total(pscore_out));

scorehand ds (.card1(d_card1),
              .card2(d_card2),
              .card3(d_card3),
              .total(dscore_out));

endmodule

