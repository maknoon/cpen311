module ksa(CLOCK_50, KEY, LEDR);

input CLOCK_50;
input [3:0] KEY;
output [9:0] LEDR;

// state names here as you complete your design

typedef enum {state_init, state_fill,
				  state_read_si1, state_read_si2, state_read_si3,
				  state_setj, state_setj2,
				  state_read_sj1, state_read_sj2, state_read_sj3,
				  state_swap_si, state_swap_sj, state_wait,
				  state_done_swap1, state_done_swap2,
				  state_initloop2, state_init_loop3,
				  state_setread_si1, state_setread_si2, state_setread_si3,
				  state_read_sf1, state_read_sf2, state_read_sf3,
				  state_decrypt1, state_decrypt2, state_decrypt3, state_decrypt4,
				  state_check_decrypt, state_incr_key1, state_incr_key2,
				  state_read_dk1, state_read_dk2,
				  state_done_decrypt, state_done_failed
				  } state_type;
state_type state;

// these are signals that connect to the memory

reg [7:0] address, data, q; // S
reg [7:0] address_encr, q_encr; // E
reg [7:0] address_decr, data_decr, q_decr; // D
reg wren, wren_decr;

// Additional signals
integer i, j, k, f;
integer value_si, value_sj, value_sf, value_ek, value_dk;
byte secret_key [3];
reg [23:0] secret_key_count;
reg cracked, failed;

// include S, E, D memory structurally

s_memory u0(address, CLOCK_50, data, wren, q);
e_memory u1(address_encr, CLOCK_50, q_encr); // ROM has no write enable
d_memory u2(address_decr, CLOCK_50, data_decr, wren_decr, q_decr);

// Write your code here.  As described in the lectures, this code will drive
// the address, data, and wren signals to fill the memory with the values 0..255.

// Signals for LEDs
always_comb
	begin
		// Always show the upper bits
		LEDR[7:0] = secret_key_count[23:16];
		
		// When decryption is successful
		if (cracked == 1'b1) begin
			LEDR[8] = 1;
		end else begin
			LEDR[8] = 0;
		end
		
		// When key seach finished but unsuccessful
		if (failed == 1'b1) begin
			LEDR[9] = 1;
		end else begin
			LEDR[9] = 0;
		end
	end

// MAIN
always_ff @(posedge CLOCK_50)
	begin
	
	if(KEY[0] == 0) begin
		// initialise values
		i <= 0;
		j <= 0;
		k <= 0;
		f <= 0;
		value_si <= 0;
		value_sj <= 0;
		secret_key_count <= 24'd0;
		secret_key[0] <= 8'd0;
		secret_key[1] <= 8'd0;
		secret_key[2] <= 8'd0;
		cracked <= 1'b0;
		failed <= 1'b0;
		
		state <= state_init;
	end else begin
	
	case (state)
		/* =================================
				INITIALISE FILL LOOP
		   ================================= */
		state_init: begin
				// initialise values
				i <= 0;
				j <= 0;
				k <= 0;
				f <= 0;
				value_si <= 0;
				value_sj <= 0;
				secret_key_count <= 24'd0;
				secret_key[0] <= 8'd0;
				secret_key[1] <= 8'd0;
				secret_key[2] <= 8'd0;
				cracked <= 1'b0;
				failed <= 1'b0;
				
				state <= state_fill;
			end
		/* =================================
				INCREMENT THE KEY
		   ================================= */	
		state_incr_key1: begin
				secret_key_count = {secret_key[0], secret_key[1], secret_key[2]};
				secret_key_count = secret_key_count + 1'b1;
				
				state <= state_incr_key2;
			end
		state_incr_key2: begin
				secret_key[0] <= {2'b00, secret_key_count[21:16]};
				secret_key[1] <= secret_key_count[15:8];
				secret_key[2] <= secret_key_count[7:0];
				
				if ( secret_key_count > 24'hFFFFFF ) state <= state_done_failed;
				else state <= state_fill;
			end
		/* =================================
				FILL THE MEMORY
		   ================================= */
		state_fill: begin
				// fill memory
				address <= i;
				data <= i;
				wren <= 1'b1;
				
				i <= i + 1;
				
				// if the memory is full, move to done state, otherwise stay in fill
				if( i > 255 ) state <= state_initloop2;
				else state <= state_fill;
			end
		/* =================================
				INITIALISE THE SWAPPING LOOP
		   ================================= */
		state_initloop2: begin
				// reset counter i to the beginning
				i <= 0;
				
				state <= state_read_si1;
			end
		/* =================================
				READ THE VALUE OF S[i]
		   ================================= */
		state_read_si1: begin
				// specify that we will read
				address <= i;
				wren <= 1'b0;
				
				state <= state_read_si2;
			end
		state_read_si2: begin
				// waiting for a cycle
				state <= state_read_si3;
			end
		state_read_si3: begin
				// get value of s[i]
				value_si <= q;
				
				state <= state_setj;
			end
		/* =================================
				SET VALUE OF j
		   ================================= */
		state_setj: begin
				// set value of j, keylength is 3 in our implementation
				j <= (j + value_si + secret_key[i % 3]) % 256;
				
				state <= state_read_sj1;
			end
		/* =================================
				READ THE VALUE OF S[j]
		   ================================= */
		state_read_sj1: begin
				// reading s[j]
				address <= j;
				wren <= 1'b0;
				
				state <= state_read_sj2;
			end
		state_read_sj2: begin
				// Delay
				state <= state_read_sj3;
			end
		state_read_sj3: begin
				value_sj <= q;
				
				state <= state_swap_sj;
			end
		/* =================================
				SWAP VALUE OF S[i] AND S[j]
		   ================================= */
		state_swap_sj: begin
				// write value_sj to s[i]
				address <= i;
				data <= value_sj;
				wren <= 1'b1;
				
				if(i == 0) state <= state_wait;
				else state <= state_swap_si;
			end
		state_swap_si: begin
				if ( k == 0 ) begin
					// write value_si to s[j]
					address <= j;
					data <= value_si;
					wren <= 1'b1;
		
					// Set i for the next loop
					i = i + 1;
					
					// if we are done with the first swap
					if ( i > 255 ) state <= state_done_swap1;
					else state <= state_read_si1;
				
				end else if ( k >= 1 ) begin
					// write value_si to s[j]
					address <= j;
					data <= value_si;
					wren <= 1'b1;
					
					// if we are only done with the second swap
					state <= state_done_swap2;
				end
				
			end
		state_wait: begin
				state <= state_swap_si;
			end	
		state_done_swap1: begin
				state <= state_init_loop3;
			end
		/* =================================
				INITIALISE THE DECRYPTION LOOP
		   ================================= */
		state_init_loop3: begin
				// *NOTE* inelegant but k gets set to 1 so that the 
				// swap states know that we are in the second swap
				i <= 0;
				j <= 0;
				k <= 1;
				f <= 0;
				
				state <= state_setread_si1;
			end
		/* =================================
				SET AND READ THE VALUE OF
				S[(i + 1) mod 256]
		   ================================= */
		state_setread_si1: begin
				i = (i + 1) % 256;
				address <= i;
				wren <= 1'b0;		
				
				state <= state_setread_si2;
			end
		state_setread_si2: begin
				// waiting for a cycle
				state <= state_setread_si3;
			end
		state_setread_si3: begin
				// get value of s[i]
				value_si <= q;
				
				state <= state_setj2;
			end
		/* =================================
				SET VALUE OF j
			================================= */
		state_setj2: begin
				j <= (j + value_si) % 256;
				
				state <= state_read_sj1;
			end
		
		/* =================================
				READ F = s[(s[i]+s[j]) % 256]
			================================= */
		state_done_swap2: begin
				f <= (value_si + value_sj) % 256;
				
				state <= state_read_sf1;
			end
		state_read_sf1: begin
				address <= f;
				wren <= 1'b0;
				
				state <= state_read_sf2;
			end
		state_read_sf2: begin
				// delay
				state <= state_read_sf3;
			end
		state_read_sf3: begin
				// get value of s[f]
				value_sf <= q;

				state <= state_decrypt1;
			end
		
		/* =================================
				DECRYPT E[k] INTO D[k]
			================================= */
		state_decrypt1: begin
				// first we read E[k]
				address_encr <= k - 1;
				
				state <= state_decrypt2;
			end
		state_decrypt2: begin
				// wait for read E[k]				
				state <= state_decrypt3;
			end
		state_decrypt3: begin
				// get E[k]
				value_ek = q_encr;
				
				state <= state_decrypt4;
			end
		state_decrypt4: begin
				// compute data_decr and write it to D
				address_decr <= k - 1;
				data_decr <= value_sf ^ value_ek;
				wren_decr <= 1'b1;

				state <= state_read_dk1;
			end
		
		/* =================================
				READ AND CHECK D[K] 
			================================= */
		state_read_dk1: begin
				// *NOTE* we read k-1 because we started k at 1
				address_decr <= k - 1;
				wren_decr <= 1'b0;

				state <= state_read_dk2;
			end
		state_read_dk2: begin
				// delay
				state <= state_check_decrypt;
			end
		state_check_decrypt: begin
				// if D[k] is a space or any lowercase ascii, it is valid
				if ( (q_decr == 8'h20) || ((q_decr >= 8'h61) && (q_decr <= 8'h7A)) ) begin
					k = k + 1;
				
					if ( k > 32 ) state <= state_done_decrypt;
					//else state <= state_read_dk1;
					else state <= state_setread_si1;

				// otherwise no good; go to the next key
				end else begin
					// initialise values for new key
					i <= 0;
					j <= 0;
					k <= 0;
					f <= 0;
					value_si <= 0;
					value_sj <= 0;
					
					state <= state_incr_key1;
				end
			end
		/* =================================
				DONE EVERYTHING
			================================= */
		state_done_decrypt: begin
				cracked <= 1'b1;
				state <= state_done_decrypt;
			end
		state_done_failed: begin
				failed <= 1'b1;
				state <= state_done_failed;
			end
		endcase
	
	end
	
end

// You will likely be writing a state machine.  Ensure that after the memory is
// filled, you enter a DONE state which does nothing but loop back to itself.



endmodule



