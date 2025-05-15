module ADS_FREQ(
	input clk, //50MHz clk//User Input Baud controls
	input reset,
	output reg mod_clk //clock with 
);

	reg [10:0] counter; //counter register

	always@(posedge clk)begin //updates and increments the counter
		if(reset)begin
			mod_clk <= 1'b0;
			counter <= 11'd0;
		end
		else if(counter==11'd1110)begin
			counter <= 11'd1;
			mod_clk <= ~mod_clk;
		end
		else
			counter <= counter + 1'b1;
	end

endmodule
