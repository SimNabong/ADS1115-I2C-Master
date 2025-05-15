/*
	This is the Top Module of the i2c controller for the ads1115. This doesnt use a PLL hence there's a frequency controller module(ADS_FREQ).
	
	This module is set to the constant slave address 0x48(the GND ADDR PIN CONNECTION) and is in constant conversion mode(ADDRESS POINT REGISTER P1=0 and P2=0)

	other possible slave ADDR PIN CONNECTION SLAVE ADDRESS
		GND 1001000(only one currently used)
		VDD 1001001
		SDA 1001010
		SCL 1001011
*/

module I2C_ADS1115( //Top Module
	input clk,
	input start,
	input wire reset,
	inout wire SDA,
	output SCL,
	output wire [3:0] state_checkw //DUT only, DO NOT CONNECT
);

	wire mod_clkw; //Comment In if not DUT

	ADS_FREQ ADSFInst(
		.clk(clk), //50MHz clk//User Input Baud controls
		.reset(reset),
		.mod_clk(mod_clkw) //clock with 
	);
	
	I2C_MASTER I2CMInst(
		.clk(clk),
		.mod_clk(mod_clkw),
		.start(start),
		.reset(reset),
		.SDA(SDA),
		.SCL(SCL),
		.state_check(state_checkw)
	);

endmodule
