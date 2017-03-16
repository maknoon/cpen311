module flash_reader_de2( CLOCK_50, KEY,
    FL_ADDR,
    FL_CE_N,
    FL_DQ,
    FL_OE_N,
    FL_RST_N,
    FL_WE_N);
	 
input CLOCK_50;
input [3:0] KEY;

// Reference @ page 13 of datasheet
output [21:0] FL_ADDR; // Flash address
output FL_CE_N; // Flash chip enable
inout[7:0] FL_DQ; // Flash data IOs
output FL_OE_N; // Flash output enable
output FL_RST_N; // Flash hw reset
output FL_WE_N; // Flash write enable

wire clk, resetb;

assign clk = CLOCK_50;
assign resetb = KEY[3];

// From the handout

assign FL_WE_N = 1'b1;
assign FL_RST_N = 1'b1;

// States for reading from flash

typedef enum { state_init,
					state_flash_enable, state_delay_enable,
					state_set_LSB, state_delay_LSB, state_read_LSB,
					state_set_MSB, state_delay_MSB, state_read_MSB,
					state_write_au, state_increment,
					state_done
					} state_type;
					
state_type state;

/* AU memory */

// AU registers
reg [7:0] address;
reg [15:0] data, q;
reg wren;
// include AU memory structurally
au_memory u0(address, clk, data, wren, q);

// Additional registers
byte sample [2]; // FL_DQ is byte addressable
reg [21:0] flash_addr;
integer i, delay;
parameter DELAY_CYCLES = 3;

// The rest of your code goes here.  Remember to include the on-chip memory


// MAIN
always_ff @(posedge clk)
begin
	
	/* RESET */
	if (resetb == 0) begin
			i <= 0;
			delay = 0;
			flash_addr <= 22'd0;
			sample[0] <= 8'd0;
			sample[1] <= 8'd0;

			state <= state_init;
	end
	
	/* BEGIN */
	case (state)
			
		/* INITIALISE VALUES */
		
		state_init: begin
				i <= 0;
				delay = 0;
				flash_addr <= 22'd0;
				sample[0] <= 8'd0;
				sample[1] <= 8'd0;

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
				if (delay < DELAY_CYCLES) begin
					delay = delay + 1;
					state <= state_delay_LSB;
				end else begin
					delay = 0;
					state <= state_read_LSB;
				end
			end
		state_read_LSB: begin
				sample[1] <= FL_DQ;
				flash_addr <= flash_addr + 1'b1;
				
				state <= state_set_MSB;
			end

		/* READ MSB FROM FLASH */
		
		state_set_MSB: begin
				FL_ADDR <= flash_addr;
				
				state <= state_delay_MSB;
			end
		state_delay_MSB: begin
				if (delay < DELAY_CYCLES) begin
					delay = delay + 1;
					state <= state_delay_MSB;
				end else begin
					delay = 0;
					state <= state_read_MSB;
				end
			end
		state_read_MSB: begin
				sample[0] <= FL_DQ;
				flash_addr <= flash_addr + 1'b1;
				
				state <= state_write_au;
			end
			
		/* WRITE TO ON-CHIP MEMORY */
		
		state_write_au: begin
				address <= i;
				data <= {sample[0], sample[1]};
				wren <= 1'b1;
				
				i <= i + 1;
				state <= state_increment;
			end
		
		/* INCREMENT & CHECK IF DONE */
		
		state_increment: begin
				if (i > 255) state <= state_done;
				else state <= state_set_LSB;
			end
			
		/* FINISHED */
		
		state_done: begin
				state <= state_done;
			end
			
	endcase
	
end

endmodule