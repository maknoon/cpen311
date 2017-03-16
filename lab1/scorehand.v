module scorehand (card1, card2, card3, total);

input [3:0] card1, card2, card3;
output [3:0] total;
reg [3:0] cardscore1, cardscore2, cardscore3;

// The code describing scorehand will go here.  Remember this is a combinational
// block.  The function is described in the handout.  Be sure to read the section
// on representing numbers in Slide Set 2.
always_comb
	begin
		if (card1 >= 10)
			cardscore1 = 0;
		else
			cardscore1 = card1;
		if (card2 >= 10)
			cardscore2 = 0;
		else
			cardscore2 = card2;
		if (card3 >= 10)
			cardscore3 = 0;
		else
			cardscore3 = card3;
		total <= (cardscore1 + cardscore2 + cardscore3) % 10;
	end
endmodule
	
