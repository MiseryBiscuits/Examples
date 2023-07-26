`timescale 1ns / 1ps

module LogicSingle_tb();


	logic r;
	logic[7:0] neighbors;
	logic T;



	Logic_single  uut (.*);
	

	

	initial 
	begin
	
		T = '0;
		neighbors = '0;
		#10;
		
		for(int i = 0; i < 256; i = i+1) begin
			neighbors = i;
			#1;
		end
		#1;
		
		T = '1;
		neighbors = '0;
		#10;
		
		for(int i = 0; i < 256; i = i+1) begin
			neighbors = i;
			#1;
		end
		#1;
	end
	
endmodule
