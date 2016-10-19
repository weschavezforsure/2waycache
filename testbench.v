//test bench
module testbench ();
	reg clk, reset, enableread, enablewrite;
	reg [1:0] writebyte;
	reg [15:0] address;
	reg [7:0] tb_data_1, tb_data_2, tb_data_3, tb_data_4;
	reg [7:0] datain;
	reg [3:0] index_counter,max_index,data_counter,max_data;
	wire [7:0] dataout;
	wire hitmiss;

	cache mycache(
		clk,			//input
		reset,			//input 
		enableread,		//input 	//Assert high to enter read state
		enablewrite,		//input 	//Assert high to enter write state.  Don't assert both enableread and enablewrite!
		address,		//input		//10 bit tag, 4 bit index, 2 bit byte-select
		datain,			//input		//Data to write
		writebyte,		//input		//Tells the cache which byte of cache line to write

		dataout,		//output reg[7:0] //Data to read
		hitmiss			//output reg 	// 1: hit, 0: miss
		);

		
	always // no sensitivity list, so it always executes
 	begin
 		clk = 1; #10; clk = 0; #10;
 	end 
		
initial begin
	//test case where all of the indexes are filled
	/*
	Check all hashes filled and checked:
	Fill all the memory with 1.8 of the data numerically 0 1 2 3…
	Tag 0 value 0 1 2 3
	Tag 4 value 4 5 6 7
	
	*/
	$display($time, "<< beginning of test1 >>"); 
	index_counter = 0;
	max_index ='hF;//maxim index for cache
	max_data=4;
	reset=0; //assuring reset is disabled
	enablewrite=1; //enable write
	for(index_counter=0;index_counter<max_index;index_counter=index_counter+1) begin
		address=index_counter*4;
		for (data_counter=0;max_data>data_counter;data_counter=data_counter+1) begin
			datain=index_counter*4+data_counter;
			writebyte=data_counter;//This parses out the writebyte options
			#20;
		end
	end	
	//optional point to do some selective reading	
		
	/*	
	Purpose check multiple reads and write read and first location:
	Read location 0 value 0? //this is from previous assignment
	Read location 0 //this checks that reading is not destructive
	Write location 0 value 1
	Read location 0 // this checks that value is now 1
	Read location 0 //this checks that reading is not destructive
	*/
	//Read location 0 value 0? //this is from previous assignment
	$display($time, "Test2:check multiple reads are not destructive, and a write");
	enablewrite=0;
	enableread=1;
	address=0;
	#20;
	$display($time, "<< read 1:dataout = %d (should be 0)>>",dataout); 
	//Read location 0 //this checks that reading is not destructive
	#20
	$display($time, "<< read 2:dataout = %d (same as before)>>",dataout); 
	//Write location 0 value 1
	enablewrite=1; enableread=0;//set for write
	datain=1;
	writebyte=0;
	#20;
	writebyte=1;
	#20;
	writebyte=2;
	#20;
	writebyte=3;
	#20;
	#20
	$display($time, "<< write:datain = %d>>",datain); 
	//Read location 0 // this checks that value is now 1
	enablewrite=0; enableread=1;
	#20
	$display($time, "<< read 3:dataout = %d (should be 1...what we wrote in)>>",dataout); 
	//Read location 0 //this checks that reading is not 
	#20
	$display($time, "<< read 3:dataout = %d (same as before)>>",dataout); 

	
	/*
	Purpose check last location:
	Read last location value 0?
	Write last byte location 42
	Read last location
	Check last byte is 42
	*/
	$display($time, "Test 3: check the last location to make sure the full range is hashed"); 
	//Read last location value 0?
	address='hFFFF;
	enableread=1;enablewrite=0;//enable read
	#20;
	$display($time, "<< Test3-Read 1:Dataout = %d >>",dataout); 
	//Write last byte location 42
	enableread=0;enablewrite=1;//enable write
	datain=42;
	$display($time, "<< Test3-Write 1:Datain = %d >>",datain); 
	#20;
	//	Read last location
	address='hFFFF;
	enableread=1;enablewrite=0;//enable read
	#20;
	//Check last byte is 42
	$display($time, "<< Test3-Read 1:Dataout = %d (should be 42)>>",dataout); 
	
	
	/*
	Check neighboring values are not effected:
	Read locations 0-8
	Write location 4 with 42
	Write Location 3 with 41
	Write Location 2 with 40 
	Write Location 1 with 39
	Read locations 0-8 
	Check 0-8 with expected values
	*/
	$display($time, "Test 4: check that all data is saved and not overflowed"); 	
	address='h0000;
	enableread=1;enablewrite=0;//enable read
	writebyte=address%4;//This parses out the writebyte options
	//Read locations 0-8
	address='h0000;
	#20;

	//Check last byte is 42
	$display($time, "<< Test3-Read 1: Address = %d, Dataout = %d (should be 42)>>",address,dataout); 
	address='h0001;
	#20;
	$display($time, "<< Test3-Read 1: Address = %d, Dataout = %d (should be 41)>>",address,dataout); 
	address='h0002;
	#20;
	$display($time, "<< Test3-Read 1: Address = %d, Dataout = %d (should be 40)>>",address,dataout); 
	address='h0003;
	#20;
	$display($time, "<< Test3-Read 1: Address = %d, Dataout = %d (should be 39)>>",address,dataout); 

	/*
	Test the maximum byte to test overflow to other hashes
	Write in hash index 0=0
	Write in hash index 1=0xFFFF 
	Write in hash index 2=0
	Read hash index 0 assure value == 0
	Read hash index 1 assure value == 0xFFFF
	Read hash index 0 assure value == 0
	
	*/
	enablewrite=1; enableread=0;//set for write
	address=0;
	writebyte=address%4;
	datain=0;
	//	Write in hash index 0=0
	writebyte=0;
	#20;
	writebyte=1;
	#20;
	writebyte=2;
	#20;
	writebyte=3;
	#20;
	//Write in hash index 1=0xFFFF 
	address=4;
	datain='hF;
	writebyte=0;
	#20;
	writebyte=1;
	#20;
	writebyte=2;
	#20;
	writebyte=3;
	#20;

	//	Write in hash index 0=0
	address=8;
	datain=0;
	writebyte=0;
	#20;
	writebyte=1;
	#20;
	writebyte=2;
	#20;
	writebyte=3;
	#20;	
	/*
	*/
	
	//test reset function
	

end



endmodule
