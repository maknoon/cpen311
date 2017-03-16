// =======================================
//	Lab5_2 : Based off sound.sv and task 2
// =======================================

module lab5_2 (CLOCK_50, CLOCK_27, KEY,
         AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,AUD_ADCDAT,
			I2C_SDAT, I2C_SCLK,AUD_DACDAT,AUD_XCK,
			FL_ADDR,
		   FL_CE_N,
		   FL_DQ,
		   FL_OE_N,
		   FL_RST_N,
		   FL_WE_N,
			SW);

// === From sound.sv ===
input CLOCK_50,CLOCK_27,AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,AUD_ADCDAT;
input [3:0] KEY;
input [1:0] SW;
inout I2C_SDAT;
output I2C_SCLK,AUD_DACDAT,AUD_XCK;

// === Flash Memory ===
// Reference @ page 13 of datasheet
output [21:0] FL_ADDR; // Flash address
output FL_CE_N; // Flash chip enable
inout[7:0] FL_DQ; // Flash data IOs
output FL_OE_N; // Flash output enable
output FL_RST_N; // Flash hw reset
output FL_WE_N; // Flash write enable

// === Set signals that we don't need ===
// From the handout, not writing so set to 1
assign FL_WE_N = 1'b1;
assign FL_RST_N = 1'b1;
// we will never read from the microphone in this lab, so we might as well set read_s to 0.
assign read_s = 1'b0;

// === From sound.sv ===
// signals that are used to communicate with the audio core
reg read_ready, write_ready, write_s;
reg [15:0] writedata_left, writedata_right;
reg [15:0] readdata_left, readdata_right;	
wire reset, read_s;

// instantiate the parts of the audio core. 
clock_generator my_clock_gen (CLOCK_27, reset, AUD_XCK);
audio_and_video_config cfg (CLOCK_50, reset, I2C_SDAT, I2C_SCLK);
audio_codec codec (CLOCK_50,reset,read_s,write_s,writedata_left, writedata_right,AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,read_ready, write_ready,readdata_left, readdata_right,AUD_DACDAT);

// The audio core requires an active high reset signal
assign reset = ~(KEY[3]);

// === State Machine States ===
typedef enum { state_init,
					state_flash_enable, state_delay_enable,
					state_flash_disable, state_delay_disable,
					state_set_LSB, state_delay_LSB, state_read_LSB,
					state_set_MSB, state_delay_MSB, state_read_MSB,
					state_increment,
					state_done,
					state_wait_until_ready, 
					state_send_sample,
					state_wait_for_accepted
					} state_type;
					
state_type state;

// === Additional Registers ===
//byte signed sample [2]; // FL_DQ is byte addressable
reg signed [7:0] sample_msb;
reg [7:0] sample_lsb;
reg signed [15:0] sample_send; // For sending samples to audio core

reg [21:0] flash_addr;
integer i, delay, num_delays, skip_sample;
parameter DELAY_CYCLES = 3;
parameter NUM_SAMPLES = 2097152; // 0x200000
parameter signed QUIET = 15'd64;

// === Switches Change "Playback Mode" ===
always_comb
begin
	if (SW[0] == 1'b1) begin 
		num_delays = 512;
		skip_sample = 1;
	end else if (SW[1] == 1'b1 && SW[0] == 1'b0) begin
		num_delays = 256;
		skip_sample = 2;
	end else begin 
		num_delays = 256;
		skip_sample = 1;
	end
end

// === State Machine ===
always_ff @(posedge CLOCK_50, posedge reset)
   if (reset == 1'b1) begin
			// reset to beginning of state machine
         state <= state_init;
			// Reset values for audio core
         write_s <= 1'b0;
			// Reset values for reading flash mem
			i <= 0;
			delay = 0;
			flash_addr <= 22'd0;
			sample_msb <= 8'd0;
			sample_lsb <= 8'd0;
   end else begin
			/* BEGIN */
	case (state)
			
		/* INITIALISE VALUES */
		
		state_init: begin
				i <= 0;
				delay = 0;
				flash_addr <= 22'd0;
				sample_msb <= 8'd0;
				sample_lsb <= 8'd0;

				state <= state_flash_enable;
			end
			
		/* ENABLE FLASH CE/OE */
		
		state_flash_enable: begin		
				// enable flash chip/output
				FL_CE_N <= 1'b0;
				FL_OE_N <= 1'b0;
				
				state <= state_delay_enable;
			end
		state_delay_enable: begin
				if (delay < DELAY_CYCLES) begin
					delay = delay + 1;
					state <= state_delay_enable;
				end else begin
					delay = 0;
					state <= state_set_LSB;
				end
			end
		
		/* READ LSB FROM FLASH */
		
		state_set_LSB: begin
				FL_ADDR <= flash_addr;
				
				state <= state_delay_LSB;
			end
		state_delay_LSB: begin
				if (delay < num_delays) begin
					delay = delay + 1;
					state <= state_delay_LSB;
				end else begin
					delay = 0;
					state <= state_read_LSB;
				end
			end
		state_read_LSB: begin
				sample_lsb <= FL_DQ[7:0];
				if (skip_sample == 1) flash_addr <= flash_addr + 1'b1;
				else flash_addr <= flash_addr + 2'b11;
				
				state <= state_set_MSB;
			end

		/* READ MSB FROM FLASH */
		
		state_set_MSB: begin
				FL_ADDR <= flash_addr;
				
				state <= state_delay_MSB;
			end
		state_delay_MSB: begin
				if (delay < num_delays) begin
					delay = delay + 1;
					state <= state_delay_MSB;
				end else begin
					delay = 0;
					state <= state_read_MSB;
				end
			end
		state_read_MSB: begin
				sample_msb <= $signed(FL_DQ[7:0]);
				flash_addr <= flash_addr + 1'b1;

				state <= state_wait_until_ready;
			end
		
		/* WAIT UNTIL AUDIO CORE WILL ACCEPT NEW VALUES */
		state_wait_until_ready: begin
			// In this state, we set write_s to 0,
			// and wait for write_ready to become 1.
			// The write_ready signal will go 1 when the FIFOs
			// are ready to accept new data.  We can't do anything
			// until this signal goes to a 1.
			
			// Combine sample and make it quieter
			sample_send = $signed({sample_msb[7:0], sample_lsb[7:0]}) / $signed(QUIET);
			
			write_s <= 1'b0;
		
			if(write_ready == 1'b1) state <= state_send_sample;
			else state <= state_wait_until_ready;
		end
		
		/* SEND SAMPLE */
		state_send_sample: begin
			// Mono
			writedata_right <= sample_send;
			writedata_left <= sample_send;
			write_s <= 1'b1;  // indicate we are writing a value
			state <= state_wait_for_accepted;
		end
		
		/* WAIT UNTIL SAMPLE ACCEPTED */
		state_wait_for_accepted: begin
			
			// now we have to wait until the core has accepted
	      // the value. We will know this has happened when
	      // write_ready goes to 0.   Once it does, we can 
			// go back to the top, set write_s to 0, and 
			// wait until the core is ready for a new sample.
					 
			if(write_ready == 1'b0) begin
				i <= i + skip_sample;
				state <= state_increment;
			end
			else state <= state_wait_for_accepted;
		end
		
		/* CHECK IF DONE */
		
		state_increment: begin
				if (i >= NUM_SAMPLES) state <= state_init;
				else state <= state_set_LSB;
			end
			
		endcase
   end
endmodule

