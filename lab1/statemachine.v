module statemachine ( slow_clock, resetb,
                      dscore, pscore, pcard3,
                      load_pcard1, load_pcard2,load_pcard3,
                      load_dcard1, load_dcard2, load_dcard3,
                      player_win_light, dealer_win_light);
							 
input slow_clock, resetb;
input [3:0] dscore, pscore, pcard3;
output load_pcard1, load_pcard2, load_pcard3;
output load_dcard1, load_dcard2, load_dcard3;
output player_win_light, dealer_win_light;

// States:
// INIT: start state, no one has cards
// PC1: Deal Player 1st card
// DC1: Deal Dealer 1st card
// PC2: Deal Player 2nd card
// DC2: Deal Dealer 2nd card
// ALLTWO: Determine if Player / Dealer get 3rd card
// LOADPC3: Offset one state to load value of pcard3
// PC3: Deal Player 3rd card
// DC3: Deal Dealer 3rd card
// NPC3: Do not deal Player 3rd card
// NDC3: Do not deal Dealer 3rd card
// GAMEWIN: Display winner or tie
enum {INIT, PC1, DC1, PC2, DC2, ALLTWO, LOADPC3, PC3, DC3, NPC3, NDC3, GAMEWIN} CURRENT_STATE, NEXT_STATE, RESET_STATE;

// The code describing your state machine will go here.  Remember that
// a state machine consists of next state logic, output logic, and the 
// registers that hold the state.  You will want to review your notes from
// CPEN 211 or equivalent if you have forgotten how to write a state machine.

// Change between states on rising clock
always_comb
	begin
	case(CURRENT_STATE)
		INIT: NEXT_STATE = PC1;
		PC1: NEXT_STATE = DC1;
		DC1: NEXT_STATE = PC2;
		PC2: NEXT_STATE = DC2;
		DC2: NEXT_STATE = ALLTWO;
		ALLTWO:
			if(pscore <= 5) NEXT_STATE = LOADPC3;
			else if(pscore >= 8 | dscore >= 8) NEXT_STATE = GAMEWIN;
			else NEXT_STATE = NPC3;
		LOADPC3: NEXT_STATE = PC3;
		PC3:
			if(pcard3 == 6 | pcard3 == 7) NEXT_STATE = DC3;
			else if(dscore == 7) NEXT_STATE = NDC3;
			else if(dscore == 6 & (pcard3 == 6 | pcard3 == 7)) NEXT_STATE = DC3;
			else if(dscore == 5 & (pcard3 <= 7 & pcard3 >= 4)) NEXT_STATE = DC3;
			else if(dscore == 4 & (pcard3 <= 7 & pcard3 >= 2)) NEXT_STATE = DC3;
			else if(dscore == 3 & pcard3 != 8) NEXT_STATE = DC3;
			else if(dscore <= 2) NEXT_STATE = DC3;
			else NEXT_STATE = NDC3;
		NPC3:
			if(dscore <= 5) NEXT_STATE = DC3;
			else NEXT_STATE = NDC3;
		DC3: NEXT_STATE = GAMEWIN;
		NDC3: NEXT_STATE = GAMEWIN;
		default: NEXT_STATE = CURRENT_STATE;
	endcase
end

// Tick through each state, with a synchronous reset
always_ff @(posedge slow_clock)
	if (resetb == 0) CURRENT_STATE <= INIT;
	else CURRENT_STATE <= NEXT_STATE;

// Assign values based on current state
always_comb
begin
	case(CURRENT_STATE)
		INIT: {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b11111100;
		PC1: {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b01111100;
		DC1: {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b11101100;
		PC2: {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b10111100;
		DC2: {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b11110100;
		ALLTWO: {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b11111100;
		LOADPC3: {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b11011100;
		PC3: {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b11111100;
		DC3: {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b11111000;
		NPC3: {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b11111100;
		NDC3: {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b11111100;
		GAMEWIN: 
			if(pscore > dscore) {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b11111110;
			else if(pscore < dscore) {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b11111101;
			else {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b11111111;
		default: {load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3, player_win_light, dealer_win_light} = 8'b11111100;
	endcase
end

endmodule
			
