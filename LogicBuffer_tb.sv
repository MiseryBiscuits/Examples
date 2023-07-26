`timescale 1ns / 1ps

module LogicBuffer_tb();



	logic DataLeft[3]; 
	logic DataRight[3];
	logic [7:0] Data[3]; 
	logic[7:0] DataIn; 
	logic[7:0] WriteAddr; 
	logic[7:0] ReadAddr; 
	logic Clock, WriteEn, Shift, Reset;


	LogicBuffer  uut (.*);
	
	initial
	begin
		DataIn = '0;
		WriteAddr = '0;
		ReadAddr = '0;
		Clock = '0;
		WriteEn = '1;
		Shift = '0;
		Reset = '0;
		#1;
		
		// write to block
		WriteEn = '1;
		for(int i = 0; i < 240; i++)begin
			WriteAddr = i;
			DataIn = i;
			Clock = '1;
			#1;
			Clock = '0;
			#1;
		end
		WriteEn = '0;
		#5;
		
		// Shifting
		Shift = '1;
		Clock = '1;
		#1;
		Clock = '0;
		#1;
		Shift = '0;
		
		// write to block
		WriteEn = '1;
		for(int i = 0; i < 240; i++)begin
			WriteAddr = i;
			DataIn = 239-i;
			Clock = '1;
			#1;
			Clock = '0;
			#1;
		end
		WriteEn = '0;
		#5;
		
		// Shifting
		Shift = '1;
		Clock = '1;
		#1;
		Clock = '0;
		Shift = '0;
		#1;
		
		// reading
		
		for(int i = 0; i < 240; i++) begin
			ReadAddr = i;
			Clock = '1;
			#1;
			Clock = '0;
			#1;
		end
		
		#5;
		
		Reset = '1;
			Clock = '1;
			#1;
			Clock = '0;
			#1;
			Reset = '0;
			Clock = '1;
			#1;
			Clock = '0;
			#1;
		
	end

	
endmodule
