
module GoLv3(input Clock, sw_cont, b_init, b_iter, output reg[11:0] px, output hsync_out, vsync_out, output [8:0] LED, output [6:0] seg0, output [6:0] seg1, output [6:0] seg2, output [6:0] seg3);
	
	assign LED[8] = CWM;
	wire trig;
	wire R;
	
	wire [7:0] WriteValue;
	wire [7:0] WriteValueL;
	wire [7:0] DataIn;
	wire [6:0] WriteAddr;
	wire [6:0] ReadAddr;
	wire WriteEn, Shift, Reset;
	
	wire[15:0] ReadAddressA;
	wire[15:0] ReadAddressB; 
	wire [7:0] ReadValueA;
	wire[7:0] ReadValueB; 
	wire WriteEnable;
	wire CWM;
	wire[7:0] CVAL; 
	
	assign trig = ~b_iter;
	assign R = ~b_init;
	assign WriteValue = CWM? CVAL:WriteValueL;
	
	assign LED[7:0] = ReadValueB;
	
	VGADriver vd0 (Clock,  px, hsync_out, vsync_out, ReadAddressB, ReadValueB);
	
	Logic l0(WriteValueL, DataIn, WriteAddr, ReadAddr, Clock, WriteEn, Shift, Reset);
	
	Memory m0 (.*);
	
	Control c0 (ReadAddressA, WriteEnable, WriteAddr, ReadAddr,WriteEn,Shift,Reset, CWM , CVAL,Clock, trig, R);

	Hex2Seg h0 (ReadAddressA[3:0], seg0);
	Hex2Seg h1 (ReadAddressA[8:4], seg1);
	Hex2Seg h2 (ReadAddressA[12:9], seg2);
	Hex2Seg h3 ({1'b0,1'b0,ReadAddressA[14:13]}, seg3);
	
	
endmodule

module Hex2Seg(
    input  [3:0]x,
    output reg [6:0]z
    );
	always @ (x)
		case (x)
		4'b0000 :      //Hexadecimal 0
		z = 7'b1111110;
		4'b0001 :    	//Hexadecimal 1
		z = 7'b0110000  ;
		4'b0010 :  		// Hexadecimal 2
		z = 7'b1101101 ; 
		4'b0011 : 		// Hexadecimal 3
		z = 7'b1111001 ;
		4'b0100 :		// Hexadecimal 4
		z = 7'b0110011 ;
		4'b0101 :		// Hexadecimal 5
		z = 7'b1011011 ;  
		4'b0110 :		// Hexadecimal 6
		z = 7'b1011111 ;
		4'b0111 :		// Hexadecimal 7
		z = 7'b1110000;
		4'b1000 :     	//Hexadecimal 8
		z = 7'b1111111;
		4'b1001 :    	//Hexadecimal 9
		z = 7'b1111011 ;
		4'b1010 :  		// Hexadecimal A
		z = 7'b1110111 ; 
		4'b1011 : 		// Hexadecimal B
		z = 7'b0011111;
		4'b1100 :		// Hexadecimal C
		z = 7'b1001110 ;
		4'b1101 :		// Hexadecimal D
		z = 7'b0111101 ;
		4'b1110 :		// Hexadecimal E
		z = 7'b1001111 ;
		4'b1111 :		// Hexadecimal F
		z = 7'b1000111 ;
	endcase
 
endmodule


/// Control Unit

module Control (output [15:0] MemAddress, output WE_MEM, output [6:0] WA_Buffer, output [6:0] RA_Buffer, output WE_Buffer, output Shift, output Reset,output CWM,output [7:0] CVAL, input Clock, input trig, input R);

	int RowCount;
	wire trigLast;
	wire START = trigLast^trig; 
	wire FIRSTROW = (ROWCount == 1);
	
	wire RLast;
	wire INIT = RLast^R;

	logic [15:0] RA_MEM;
	logic [15:0] WA_MEM;
	
	assign MemAddress = WE_MEM  ? WA_MEM : RA_MEM;
	
	wire RowMax = (RowCount > 480);
	
	typedef enum {S0,S1,S1a,S1b,S2,S2a,S2b,S3,S3a,S3b} e_State;
	
	e_State cS, nS;
	
	always_comb begin
		CVAL = WA_MEM %256;
	end
	
	always_ff @(posedge Clock)begin
		cS <= nS;
	end
	
	always @(posedge Clock) begin
		trigLast <= trig;
		RLast <= R;
	end
	
	always @(posedge Clock) begin
		case(cS) 
			S0:begin
				CWM <= '0;
				RA_MEM <= '0;
				WA_MEM <= '0;
				WE_MEM <= '0;
				RA_Buffer <= '0;
				WA_Buffer <= '0;
				WE_Buffer <= '0;
				RowCount <= -1;
				Reset <= '1;
			end
			
			S1:begin
				Reset <= '0;
				WE_Buffer <= '1;
				WA_Buffer <= '0;
				Shift <= '1;
				RowCount++;
			end
			
			S1a:begin
				Shift <= '0;
				RA_MEM++;
				WA_Buffer++;
			end
			
			S1b:begin
				WE_Buffer <= '0;
			end
			
			S2:begin
				WE_MEM <= '1;
				RA_Buffer <= '0;
			end
			
			S2a:begin
				WA_MEM++;
				RA_Buffer++;
			end
			
			S2b:begin
				WE_MEM <= '0;
			end
			
			S3:begin
				WE_MEM <= '1;
				WA_MEM <= '0;
				CWM = '1;
			end
			
			S3a:begin
				WA_MEM++;
			end
			
			S3b:begin
				WE_MEM <= '0;
				CWM = '0;
			end
			
			default:begin end
		endcase
	end
	
	always_comb begin
		case(cS)
			S0:begin
				if(START)begin
					nS = S1;
				end else if(INIT) begin
					nS = S3;
				end else begin 
					nS = S0;
				end
			end
			S1:begin
				nS = S1a;
			end
			S1a:begin
				nS = (WA_Buffer >= 79)? S1b:S1a;
			end
			S1b:begin
				if(FIRSTROW)
					nS = S1;
				else
					nS = S2;
			end
			S2:begin
			
				nS = S2a;
			end
			S2a:begin
				nS = (RA_Buffer >= 79)? S2b:S2a;
			end
			S2b:begin
				nS = (RowMax)? S0:S1;
			end
			S3: begin
				nS = S3a;
			end
			S3a: begin
				nS = (WA_MEM > 38399)? S3b:S3a; 
			end
			S3b: begin
				nS = S0;
			end
			default:begin
				nS = S0;
			end
		endcase
	end

endmodule


/// VGA Driver

module VGADriver (input clk_50, output reg[11:0] px, output hsync_out, vsync_out, output[15:0] ReadAddress, input [7:0] Data);

	wire inDisplay;
	wire [9:0] CountX;
	wire [9:0] CountY;
	wire clk_25;
	wire [9:0] col;
	
	freqDivider vgaclock(clk_50,1'b1, clk_25);

	hvsync_handler hvsync(clk_25, hsync_out,vsync_out, inDisplay,CountX,CountY);
	
	
	// drawing to display
	always @(posedge clk_25)
	begin
     if (inDisplay) begin
		if(CountX==0 && CountY==0)
			ReadAddress <= '0;
		else if(CountX%8 == 0)
			ReadAddress <= ReadAddress + 1;
			
	  if(Data[CountX%8] == 1)
			px = CountY & CountX;
	  else
			px = '0;
	  end
	end
endmodule

module freqDivider(input clk, rst, output reg out_clk);
	always @(posedge clk)
	begin
		if(~rst)
			out_clk <= 1'b0;
		else
			out_clk <= ~out_clk;
	end
endmodule

module hvsync_handler(input clk, output vga_hsync, vga_vsync,
								output reg inDisplay,
								output reg [9:0] CountX,
								output reg [9:0] CountY );
								
		reg vga_HS, vga_VS;
		wire CounterXmax = (CountX == 800);
		wire CounterYmax = (CountY == 525);
		
		always @(posedge clk)
		begin
			if(CounterXmax) begin
				CountX <= 0;
			end else begin
				CountX <= CountX + 1;
			end
		end
		
		always @(posedge clk)
		begin
			if(CounterXmax) begin
				if(CounterYmax) begin
					CountY <= 0;
				end else begin
					CountY <= CountY + 1;
				end
			end 
		end

		always @(posedge clk)
		begin
			vga_HS <= (CountX > (640 + 16) && (CountX < (640 + 16 + 96)));   // active for 96 clocks
			vga_VS <= (CountY > (480 + 10) && (CountY < (480 + 10 + 2)));
		end
		
		always @(posedge clk)
		 begin
			  inDisplay <= (CountX < 640) && (CountY < 480);
		 end
		
		 assign vga_hsync = ~vga_HS;
		 assign vga_vsync = ~vga_VS;
				
endmodule

/// RAM

// presets for 1980x1080 resolution

module Memory #(parameter N = 8, parameter A = 16,parameter O = 38400) (input[A-1:0] ReadAddressA,input[A-1:0] ReadAddressB, output[N-1:0] ReadValueA,
																										output[N-1:0] ReadValueB, input WriteEnable, input Clock, input [N-1:0] WriteValue);
		logic [N-1:0] registers[O];
		
		always @(posedge Clock)
		begin
			ReadValueA <= registers[ReadAddressA];
			ReadValueB <= registers[ReadAddressB];
			
			if(WriteEnable)
				registers[ReadAddressA] <= WriteValue;
		end
		
endmodule



/// Logic Block

module Logic #(parameter N = 8, parameter L = 7, parameter O = 80)(
					output [N-1:0] DataOut, input [N-1:0] DataIn, input[L-1:0] WriteAddr, input[L-1:0] ReadAddr,
					input Clock, input WriteEn, input Shift, input Reset
					);
			wire DataLeft[3];
			wire DataRight[3];
			wire [N-1:0] Data [3];
			
			LogicBuffer #(.N(N), .L(L), .O(O)) LB0 (.*);
			LogicGen #(N) LG0 (.*);
	
endmodule


module LogicBuffer #(parameter N = 8, parameter L = 7, parameter O = 80)(output reg DataLeft[3], output reg DataRight[3], output reg [N-1:0] Data[3], input[N-1:0] DataIn, input[L-1:0] WriteAddr, input[L-1:0] ReadAddr, input Clock, input WriteEn, input Shift, input Reset);

		logic [N-1:0] regA [O]; // mem stored
		logic [N-1:0] regB [O];
		logic [N-1:0] regC [O];
		
		
		always @(posedge Clock)
		begin
			Data[0] <= regA[ReadAddr];
			Data[1] <= regB[ReadAddr];
			Data[2] <= regC[ReadAddr];
			
			if(ReadAddr == 0)
			begin
				DataLeft <= '{0,0,0};
			end else begin
				DataLeft[0] <= regA[ReadAddr -1][0];
				DataLeft[1] <= regB[ReadAddr -1][0];
				DataLeft[2] <= regC[ReadAddr -1][0];
			end
			
			if(ReadAddr == O-1)
			begin
				DataRight <= '{0,0,0};
			end else begin
				DataRight[0] <= regA[ReadAddr +1][N-1];
				DataRight[1] <= regB[ReadAddr +1][N-1];
				DataRight[2] <= regC[ReadAddr +1][N-1];
			end
			
			if(WriteEn)
				regA[WriteAddr] <= DataIn;
				
			if(Shift) begin
				regC <= regB;
				regB <= regA;
				regA <= '{O{'0}};
			end
			
			if(Reset) begin
				regC <= '{O{'0}};
				regB <= '{O{'0}};
				regA <= '{O{'0}};
			end
		end


endmodule

module LogicGen #(parameter N = 8) (output [N-1:0] DataOut, input DataLeft [3],input [N-1:0] Data [3],input DataRight [3]);
	
	genvar i;
	generate
		for(i=0; i<N;i++) begin : block
		
			wire [7:0] neighbors0;
				
			if(i == 0) begin
			
				assign neighbors0 = {DataLeft[0],DataLeft[1],DataLeft[2],Data[0][i+1:i],Data[1][i+1],Data[2][i+1:i]};
				
			end else if (i == N-1) begin
			
				assign neighbors0 = {DataRight[0],DataRight[1],DataRight[2],Data[0][i:i-1], Data[1][i-1],Data[2][i:i-1]};
				
			end else begin
			
				assign neighbors0 = {Data[0][i+1:i-1], Data[1][i-1],Data[1][i+1],Data[2][i+1:i-1]};
				
			end
			
			Logic_single bL0 (DataOut[i], neighbors0, Data[1][i]);
		end
	endgenerate
	
endmodule


module Logic_single (output r, input[7:0] neighbors, input T); // since this is fundamental and unchanged we'll fix all the values as much as possible
	
	wire res2[28]; // results of 2 neighbors
	wire res3[56]; // results of 3 neighbors
	wire orRes2, orRes3; // or'ing all results for 2 and 3
	
	// res2 assigns (generated via script) 8C2 - combinations
	 assign res2[0] = (neighbors == 8'b00000011); assign res2[1] = (neighbors == 8'b00000101); assign res2[2] = (neighbors == 8'b00000110);
	 assign res2[3] = (neighbors == 8'b00001001); assign res2[4] = (neighbors == 8'b00001010); assign res2[5] = (neighbors == 8'b00001100);
	 assign res2[6] = (neighbors == 8'b00010001); assign res2[7] = (neighbors == 8'b00010010); assign res2[8] = (neighbors == 8'b00010100);
	 assign res2[9] = (neighbors == 8'b00011000);assign res2[10] = (neighbors == 8'b00100001);assign res2[11] = (neighbors == 8'b00100010);
	assign res2[12] = (neighbors == 8'b00100100);assign res2[13] = (neighbors == 8'b00101000);assign res2[14] = (neighbors == 8'b00110000);
	assign res2[15] = (neighbors == 8'b01000001);assign res2[16] = (neighbors == 8'b01000010);assign res2[17] = (neighbors == 8'b01000100);
	assign res2[18] = (neighbors == 8'b01001000);assign res2[19] = (neighbors == 8'b01010000);assign res2[20] = (neighbors == 8'b01100000);
	assign res2[21] = (neighbors == 8'b10000001);assign res2[22] = (neighbors == 8'b10000010);assign res2[23] = (neighbors == 8'b10000100);
	assign res2[24] = (neighbors == 8'b10001000);assign res2[25] = (neighbors == 8'b10010000);assign res2[26] = (neighbors == 8'b10100000);
	assign res2[27] = (neighbors == 8'b11000000);
		
		
	//res3 assigns (generated via script) 8C3 - combinations
	 assign res3[0] = (neighbors == 8'b00000111); assign res3[1] = (neighbors == 8'b00001011); assign res3[2] = (neighbors == 8'b00001101);
	 assign res3[3] = (neighbors == 8'b00001110); assign res3[4] = (neighbors == 8'b00010011); assign res3[5] = (neighbors == 8'b00010101);
	 assign res3[6] = (neighbors == 8'b00010110); assign res3[7] = (neighbors == 8'b00011001); assign res3[8] = (neighbors == 8'b00011010);
	 assign res3[9] = (neighbors == 8'b00011100);assign res3[10] = (neighbors == 8'b00100011);assign res3[11] = (neighbors == 8'b00100101);
	assign res3[12] = (neighbors == 8'b00100110);assign res3[13] = (neighbors == 8'b00101001);assign res3[14] = (neighbors == 8'b00101010);
	assign res3[15] = (neighbors == 8'b00101100);assign res3[16] = (neighbors == 8'b00110001);assign res3[17] = (neighbors == 8'b00110010);
	assign res3[18] = (neighbors == 8'b00110100);assign res3[19] = (neighbors == 8'b00111000);assign res3[20] = (neighbors == 8'b01000011);
	assign res3[21] = (neighbors == 8'b01000101);assign res3[22] = (neighbors == 8'b01000110);assign res3[23] = (neighbors == 8'b01001001);
	assign res3[24] = (neighbors == 8'b01001010);assign res3[25] = (neighbors == 8'b01001100);assign res3[26] = (neighbors == 8'b01010001);
	assign res3[27] = (neighbors == 8'b01010010);assign res3[28] = (neighbors == 8'b01010100);assign res3[29] = (neighbors == 8'b01011000);
	assign res3[30] = (neighbors == 8'b01100001);assign res3[31] = (neighbors == 8'b01100010);assign res3[32] = (neighbors == 8'b01100100);
	assign res3[33] = (neighbors == 8'b01101000);assign res3[34] = (neighbors == 8'b01110000);assign res3[35] = (neighbors == 8'b10000011);
	assign res3[36] = (neighbors == 8'b10000101);assign res3[37] = (neighbors == 8'b10000110);assign res3[38] = (neighbors == 8'b10001001);
	assign res3[39] = (neighbors == 8'b10001010);assign res3[40] = (neighbors == 8'b10001100);assign res3[41] = (neighbors == 8'b10010001);
	assign res3[42] = (neighbors == 8'b10010010);assign res3[43] = (neighbors == 8'b10010100);assign res3[44] = (neighbors == 8'b10011000);
	assign res3[45] = (neighbors == 8'b10100001);assign res3[46] = (neighbors == 8'b10100010);assign res3[47] = (neighbors == 8'b10100100);
	assign res3[48] = (neighbors == 8'b10101000);assign res3[49] = (neighbors == 8'b10110000);assign res3[50] = (neighbors == 8'b11000001);
	assign res3[51] = (neighbors == 8'b11000010);assign res3[52] = (neighbors == 8'b11000100);assign res3[53] = (neighbors == 8'b11001000);
	assign res3[54] = (neighbors == 8'b11010000);assign res3[55] = (neighbors == 8'b11100000);
	
	// OR all results
	assign orRes2 = res2[0] | res2[1] | res2[2] | res2[3] | res2[4] | res2[5] | res2[6] | res2[7] | res2[8] | res2[9] | res2[10] | res2[11] | 
						 res2[12] | res2[13] | res2[14] | res2[15] | res2[16] | res2[17] | res2[18] | res2[19] | res2[20] | res2[21] | res2[22] | 
						 res2[23] | res2[24] | res2[25] | res2[26] | res2[27];
						 
	// OR all results
	assign orRes3 = res3[0] | res3[1] | res3[2] | res3[3] | res3[4] | res3[5] | res3[6] | res3[7] | res3[8] | res3[9] | res3[10] | res3[11] | 
						 res3[12] | res3[13] | res3[14] | res3[15] | res3[16] | res3[17] | res3[18] | res3[19] | res3[20] | res3[21] | res3[22] | 
						 res3[23] | res3[24] | res3[25] | res3[26] | res3[27] | res3[28] | res3[29] | res3[30] | res3[31] | res3[32] | res3[33] | 
						 res3[34] | res3[35] | res3[36] | res3[37] | res3[38] | res3[39] | res3[40] | res3[41] | res3[42] | res3[43] | res3[44] | 
						 res3[45] | res3[46] | res3[47] | res3[48] | res3[49] | res3[50] | res3[51] | res3[52] | res3[53] | res3[54] | res3[55];
	
	assign r = (orRes2 & T)|orRes3; // if live and 2 or 3 neighbors live, if dead and 3 neighbors live, otherwise die
endmodule
