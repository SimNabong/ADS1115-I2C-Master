/*
	This module is an i2c master that interacts with the ads1115 IC.
	https://www.ti.com/lit/ds/symlink/ads1115.pdf
	
	This module is set to the constant TARGET address 0x48(the GND ADDR PIN CONNECTION) and is in constant conversion mode(ADDRESS POINT REGISTER P1=0 and P2=0)

	ADDR PIN CONNECTION TARGET ADDRESS
	GND 1001000
	VDD 1001001
	SDA 1001010
	SCL 1001011
	
	mux  14:12] config_REGISTER
	000b : AINP = AIN0 and AINN = AIN1 (default)
	001b : AINP = AIN0 and AINN = AIN3
	010b : AINP = AIN1 and AINN = AIN3
	011b : AINP = AIN2 and AINN = AIN3
	100b : AINP = AIN0 and AINN = GND
	101b : AINP = AIN1 and AINN = GND
	110b : AINP = AIN2 and AINN = GND
	111b : AINP = AIN3 and AINN = GND
	
	operating mode[8] config_REGISTER
	0b : Continuous-conversion mode
	1b : Single-shot mode or power-down state (default)
	
	data-rate[7:5] config_REGISTER
	000b : 8SPS
	001b : 16SPS
	010b : 32SPS
	011b : 64SPS
	100b : 128SPS (default)
	101b : 250SPS
	110b : 475SPS
	111b : 860SPS

	Configuration Register = [15]OS,[14:12]mux,[11:9]PGA,[8]operating mode,[7:5]data-rate, [4]comparator mode, [3:0] ALRT/RDY configuration
*/
module I2C_MASTER(
	input clk,
	input mod_clk,
	input start,
	input reset,
	inout SDA,
	output reg SCL,
	output wire [3:0] state_check //tells what state the i2c master is in
);

	parameter INITIAL=4'd0,			     	 	
		  START=4'd1,
		  TARGET_ADDRESS=4'd2, 	
		  TARGET_ACK=4'd3,
		  ADDRESS_POINT_REG=4'd4,
		  CONFIG_REGISTER=4'd5,
		  CONVERSION_REG=4'd6,
		  MASTER_ACK=4'd7,
		  STOP=4'd8,	
		  ERROR=4'd9;
				 
	reg [3:0] state, next_state;
	reg [7:0] slave_address;
	reg [15:0] register_config; //holds the configuration for the slave
	reg mod_clk0;//used to identify when the mod_clk goes from low to high
	reg [1:0] APR_count; //address point reg counter
	reg [1:0] byte_count; //counts how many bytes were sent
	reg [2:0] mclk_counter; //counts how many times modified clock goes high to low in each bit or state
	reg [3:0] bit_counter;//counts how many master or TARGET data are shifted
	reg MSDA; //master controlling SDA line
	reg CR_flag; //if HIGH, then CONFIG_REGISTER has been configured
	reg read_notwrite; //if HIGH then the master is reading, else it is writing
	reg R_ADDR_Pointer; //address point registers' LSB. If high then then it points to configuration reg, else to conversion reg 
	
	assign state_check = next_state;
	
	 //if in a not mentioned state it's the master controlling the SDA line
	assign SDA = (state==TARGET_ACK || state==CONVERSION_REG)?1'bz: MSDA;
	
	always@(posedge clk)begin
		mod_clk0 <= mod_clk;
	end
	
	always@(posedge clk)begin //when state is updated or moves to the next state
		if(reset)
			state <= INITIAL;
		else if(mod_clk && ~mod_clk0) //detects level transition which causes state change
			state <= next_state;
	end
	
	always@(*)begin //state flow
		case(state)
		
			INITIAL: 		 next_state = (start)? START:
								       state;
			
			START: 		 	 next_state = (mclk_counter==3'd6)? TARGET_ADDRESS: 
										    state;
			
			TARGET_ADDRESS: 	 next_state = (mclk_counter==3'd6 && bit_counter==4'd8)? TARGET_ACK: 
													 state;
			
			TARGET_ACK:		 next_state = (mclk_counter==3'd6 && (APR_count==0 ||(APR_count==2'd1 && CR_flag && byte_count==2'd0)))? ADDRESS_POINT_REG:
							      (mclk_counter==3'd6 && ~read_notwrite && (byte_count==2'd2 || APR_count==2'd2))?		 STOP:
							      (mclk_counter==3'd6 && ((APR_count==2'd1 && ~CR_flag) || byte_count==2'd1))?		 CONFIG_REGISTER:
							      (mclk_counter==3'd6 && read_notwrite)?							 CONVERSION_REG: 
							      (mclk_counter==3'd6 && MSDA)?								 ERROR:
							      												 state;
												 
			ADDRESS_POINT_REG:       next_state = (mclk_counter==3'd6 && bit_counter==4'd8)? TARGET_ACK: 
													 state;
														
			CONFIG_REGISTER:	 next_state = (mclk_counter==3'd6 && bit_counter==4'd8)? TARGET_ACK: 
													 state; 
														
			CONVERSION_REG:	         next_state = (mclk_counter==3'd6 && bit_counter==4'd8)? MASTER_ACK: 
													 state;
												
			MASTER_ACK:		 next_state = (mclk_counter==3'd6 && bit_counter==4'd0 && byte_count ==2'd1)? CONVERSION_REG:
							      (mclk_counter==3'd6 && bit_counter==4'd0 && byte_count ==2'd2)? STOP: 
															      state;
			
			STOP:			 next_state = (start && mclk_counter==3'd6 && bit_counter==4'd1)? START: 
														  state;
														
			ERROR:			 next_state = INITIAL;
			
			default: 		 next_state = INITIAL;
			
		endcase
	end
	
	always@(posedge clk)begin //what happens during each state
	
		if(reset)begin
			MSDA 		<= 1'b1;
			SCL 		<= 1'b1;
			mclk_counter	<= 3'd1;
			bit_counter 	<= 4'd0;
			APR_count 	<= 2'd0;
			byte_count 	<= 2'd0;
			CR_flag		<= 1'b0;
			read_notwrite	<= 1'b0;
			R_ADDR_Pointer	<= 1'b1;
			register_config <= 16'b1000_0100_1000_0011;
			slave_address	<= {7'b1001_000, read_notwrite};
		end
		
		else if(mod_clk && ~mod_clk0)begin
			case(next_state)
			
				INITIAL:begin
					MSDA 		<= 1'b1;
					SCL 		<= 1'b1;
					mclk_counter	<= 3'd1;
					bit_counter 	<= 4'd0;
					APR_count 	<= 2'd0;
					byte_count 	<= 2'd0;
					CR_flag		<= 1'b0;
					read_notwrite	<= 1'b0;
					R_ADDR_Pointer	<= 1'b1;
					slave_address	<= {7'b1001_000, read_notwrite};
					register_config <= 16'b1000_0100_1000_0011;
				end
				
				START:begin
					mclk_counter <= mclk_counter + 1'b1;
					if(mclk_counter==3'd1 && APR_count==2'd1) //changes pointer to conversion from configuration
						R_ADDR_Pointer <= 1'b0;
					else if(mclk_counter==3'd1 && APR_count==2'd2) //changes from write to read
						read_notwrite  <= 1'b1;
					else if(mclk_counter==3'd2)
						MSDA 	       <= 1'b0;
					else if(mclk_counter==3'd4)
						SCL	       <= 1'b0;
					else begin
						slave_address  <= {7'b1001_000, read_notwrite};
						byte_count     <= 2'd0;
						bit_counter    <= 4'd0;
					end
				end
				
				TARGET_ADDRESS:begin
					if(mclk_counter==3'd6)begin
						bit_counter   <= bit_counter + 1'b1;
						mclk_counter  <= 3'd1;
						MSDA	      <= slave_address[7];
						slave_address <= {slave_address[6:0],slave_address[7]};
					end
					else if(mclk_counter==3'd2 || mclk_counter==3'd4)begin //SCL condition
						mclk_counter  <= mclk_counter + 1'b1;
						SCL 	      <= ~SCL;
					end
					else
						mclk_counter  <= mclk_counter + 1'b1;
				end
				
				TARGET_ACK:begin
					if(mclk_counter==3'd6 && bit_counter==4'd8)begin
						bit_counter  <= 4'd0;
						mclk_counter <= 3'd1;
					end
					else if(mclk_counter==3'd2 || mclk_counter==3'd4)begin //SCL condition
						mclk_counter <= mclk_counter + 1'b1;
						SCL 	     <= ~SCL;
					end
					else if(mclk_counter==3'd3)begin //SCL condition
						mclk_counter <= mclk_counter + 1'b1;
						MSDA	     <= SDA;
					end
					else
						mclk_counter <= mclk_counter + 1'b1;
				end
				
				ADDRESS_POINT_REG:begin
					if(mclk_counter==3'd6 && ~(bit_counter==4'd7))begin
						MSDA 	     <= 1'b0;
						mclk_counter <= 3'd1;
						bit_counter  <= bit_counter + 1'b1;
					end
					else if(mclk_counter==3'd6 && bit_counter==4'd7)begin
						mclk_counter <= 1'b1;
						bit_counter  <= bit_counter + 1'b1;
						MSDA	     <= R_ADDR_Pointer;
						APR_count    <= APR_count + 1'b1;
					end
					else if(mclk_counter==3'd2 || mclk_counter==3'd4)begin //SCL condition
						mclk_counter <= mclk_counter + 1'b1;
						SCL 	     <= ~SCL;
					end
					else
						mclk_counter <= mclk_counter + 1'b1;
				end
				
				CONVERSION_REG:begin
					if(mclk_counter==3'd6)begin
						mclk_counter <= 3'd1;
						bit_counter  <= bit_counter + 1'b1;
					end						
					else if(mclk_counter==3'd2 || mclk_counter==3'd4)begin //SCL condition
						mclk_counter <= mclk_counter + 1'b1;
						SCL 	     <= ~SCL;
					end
					else if(mclk_counter==3'd3)begin
						mclk_counter <= mclk_counter + 1'b1;	
					end
					else
						mclk_counter <= mclk_counter + 1'b1;
				end
				
				MASTER_ACK:begin
					if(mclk_counter==3'd6 && bit_counter==4'd8)begin
						bit_counter  <= 4'd0;
						mclk_counter <= 3'd1;
						MSDA 	     <= 1'b0;
						byte_count   <= byte_count + 1'b1;
					end
					else if(mclk_counter==3'd2 || mclk_counter==3'd4)begin //SCL condition
						mclk_counter <= mclk_counter + 1'b1;
						SCL 	     <= ~SCL;
					end
					else
						mclk_counter <= mclk_counter + 1'b1;
				end
				
				CONFIG_REGISTER:begin
					CR_flag	<= 1'b1;
					if(mclk_counter==3'd6 && byte_count==2'd1)begin
						mclk_counter 	<= 3'd1;
						MSDA		<= 1'b1;
					end
					else if(mclk_counter==3'd5 && (byte_count==2'd1 || (byte_count==2'd0 && bit_counter==4'd8)))begin
						byte_count	<= byte_count + 1'b1;
						mclk_counter	<= mclk_counter + 1'b1;
					end	
					else if(mclk_counter==3'd6)begin
						bit_counter 	<= bit_counter + 1'b1;
						mclk_counter 	<= 3'd1;
						MSDA 		<= register_config[15];
						register_config <= {register_config[14:0],register_config[15]};
					end
					else if((mclk_counter==3'd2 || mclk_counter==3'd4) && ~(byte_count==2'd1))begin //SCL condition
						mclk_counter 	<= mclk_counter + 1'b1;
						SCL 		<= ~SCL;
					end
					else
						mclk_counter 	<= mclk_counter + 1'b1;
				end
				
				STOP:begin
					if(mclk_counter==3'd6)begin
						mclk_counter <= 3'd1;
						bit_counter  <= bit_counter + 1'b1; //might be removable
					end	
					else if(mclk_counter==3'd2)begin
						SCL 			 <= 1'b1;
						mclk_counter <= mclk_counter + 1'b1;
					end
					else if(mclk_counter==3'd4)begin
						MSDA 			 <= 1'b1;
						mclk_counter <= mclk_counter + 1'b1;
					end
					else
						mclk_counter <= mclk_counter + 1'b1;
				end
				
				ERROR:begin
					MSDA <= 1'b1;
					SCL  <= 1'b1;
				end
				
				default:begin
					mclk_counter 	<= 3'd1;
					bit_counter 	<= 4'd0;
					slave_address	<= {7'b1001_000, read_notwrite};
					register_config <= 16'b1000_0100_1000_0011;
				end
				
			endcase
		end
	end
	
endmodule
