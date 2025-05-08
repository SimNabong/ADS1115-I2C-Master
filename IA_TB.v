`timescale 1ns/1ns

module IA_TB();
	reg clk;
	reg start;
	reg reset;
	wire SCL;
	wire SDA;
	//wire signal_edge;
	//wire [15:0] dataA; //DUT
	//wire [15:0] dataB; //DUT
	wire [3:0] state_check;
	//wire mod_clkw; //DUT
	//wire [2:0] mclk_counterW; //TBD for DUT
	//wire [3:0] bit_counterW; //TBD for DUT
	//wire [1:0] byte_countW;
	reg SCLr;
	reg SDAr;
	reg [15:0] con_dat;
	wire STOP_state;
	reg [3:0] STOP_state_Counter;
	
	I2C_ADS1115 DUTinst(
		.clk(clk),
		.start(start),
		.reset(reset),
		.SDA(SDA),
		.SCL(SCL),
		//.signal_edge(signal_edge),
		//.dataAw(dataA),
		//.dataBw(dataB),
		.state_checkw(state_check)
		//.mod_clkw(mod_clkw),
		//.bit_counterW(bit_counterW), //TBD for DUT
		//.mclk_counterW(mclk_counterW), //TBD for DUT
		//.byte_countW(byte_countW)
	);
	
	initial begin
		clk = 0; //initialized clock to 0 
		forever #1 clk = ~clk; //clock toggling forever
	end
	
	//if state is in slave acknowledge SDA it's 1'b0 else it's what the master wants it to be.
	assign SDA = (state_check==4'd3)?1'b0:(state_check==4'd6)?SDAr: 1'bz; 
	assign STOP_state = state_check==4'd8; //STOP_state state
	
	initial begin
		start = 1;
		reset = 1;
		STOP_state_Counter = 0;
		#20 reset = 0;
		#900ms $finish;
	end
		
	always@(posedge clk)begin
		SCLr <= SCL;
		if(state_check==4'd6 && ~SCLr && SCL)begin
			SDAr <= con_dat[15];
			con_dat <= {con_dat[14:0],con_dat[15]};			
		end
	end
	
	always@(posedge STOP_state)begin
		STOP_state_Counter <= STOP_state_Counter + 1'b1;
		case(STOP_state_Counter)
			4'd0: 	con_dat <= 16'b0001110011100001;
			4'd1:		con_dat <= 16'b1001110011100000;
			4'd2:		con_dat <= 16'b1001110011100011;
			4'd3:		con_dat <= 16'b1001110011000000;
			4'd4:		con_dat <= 16'b1001110011100000;
			4'd5:		con_dat <= 16'b1001110011100011;
			4'd6:		con_dat <= 16'b0001110011100011;
			4'd7:		con_dat <= 16'b0001110011101011;
			4'd8: 	con_dat <= 16'b1001110011100001;
			4'd9:		con_dat <= 16'b1001110011100000;
			4'd10:	con_dat <= 16'b1001110011100011;
			4'd11:	con_dat <= 16'b1001110011000000;
			4'd12:	con_dat <= 16'b1001110011100000;
			4'd13:	con_dat <= 16'b1001110011100011;
			4'd14:	con_dat <= 16'b0001110011100011;
			4'd15:	con_dat <= 16'b0001110011101011;
      endcase
	end
	
	always @(negedge clk) begin
		$display(
			"simtime=%g, start=%b, reset=%b, SCL=%b, SDA=%b, state_check=%b",
			$time, start, reset, SCL, SDA, state_check
		);
	end

	
endmodule