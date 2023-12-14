module random_number_generator(
	input clk,
	input rst,
	input [15:0]random_seed,
	input new_random_seed,
	input random_number_output,
	output reg [19:0]random_number
);

//=======================================================
//  PORT declarations
//=======================================================
reg [127:0]lfsr; // this is a linear feedback shift register

//=======================================================
//  Design
//=======================================================

always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
		random_number <= 20'd0;
		lfsr <= 128'd42;
	end
	else
	begin
		if (new_random_seed == 1'b1)
		begin
			/* initialize every 8 bits with the random seed */
			lfsr <= {
						random_seed,
						random_seed,
						random_seed,
						random_seed,
						random_seed,
						random_seed,
						random_seed,
						random_seed};
						
		end
		else
		begin
			/* when to output a value */
			if (random_number_output == 1'b1)
				random_number = lfsr[79:59]; // picked an arbitrary sequence from the lfsr
			else
				/* constantly be shifting the lfsr */
				lfsr <= {lfsr[126:96], lfsr[0] ^ lfsr[62] ^ lfsr [120] ^ lfsr[2],  // 32 bits
						 lfsr[94:64], lfsr[5] ^ lfsr[81] ^ lfsr [97] ^ lfsr[94], // 32 bits
						 lfsr[62:32], lfsr[3] ^ lfsr[30] ^ lfsr [111] ^ lfsr[93],  // 32 bits
						 lfsr[30:0], lfsr[7] ^ lfsr[127] ^ lfsr [112] ^ lfsr[92]}; // 32 bits
		end
	end
end

endmodule