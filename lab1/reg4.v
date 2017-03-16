module reg4(CLK, reset, load_card, incard, outcard);

input CLK, reset, load_card;
input [3:0] incard;
output [3:0] outcard;

always_ff @(posedge CLK)
	if(reset == 0)
		outcard <= 0; //4'b0000;
	else if(load_card == 0)
		outcard <= incard;

endmodule
