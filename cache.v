module cache (
		input clk,
		input reset,
		input enableread,	//Assert high to enter read state
		input enablewrite,	//Assert high to enter write state.  Don't assert both enableread and enablewrite!
		input [15:0] address,	//10 bit tag, 4 bit index, 2 bit byte-select
		input [7:0] datain,	//Data to write
		input [1:0] writebyte,	//Tells the cache which byte of cache line to write

		output reg[7:0] dataout,	//Data to read
		output reg hitmiss		// 1: hit, 0: miss
		);

reg [7:0] mem0 [0:15] [0:3];		//Associative set 0
reg [7:0] mem1 [0:15] [0:3];		//Associative set 1
reg [9:0] tag0 [0:15];			//Tags for set 0
reg [9:0] tag1 [0:15];			//Tags for set 1
reg [0:15] valid0;			//Valid bits for set 0
reg [0:15] valid1;			//Valid bits for set 1
reg [0:15] lru;				//LRU (Least Recently Used)
					//One bit for each cache line.  0: Cache line for set 0 was least recently read
reg [2:0] state;			//				1: Cache line for set 1 was least recently read
reg writeset;				//Which set to write to
parameter idlestate = 3'b000;
parameter readstate = 3'b001;
parameter wheretowritestate = 3'b010;
parameter writebyte0 = 3'b011;
parameter writebyte1 = 3'b100;
parameter writebyte2 = 3'b101;
parameter writebyte3 = 3'b110;

always @(posedge clk, reset) begin
	if (reset) begin			//Idle state on reset
		valid0 <= 16'b0;
		valid1 <= 16'b0;
		state <= idlestate;
	end
	else begin
		case (state)
		idlestate: begin		//Do we want to read or write to cache
			dataout <= 8'b0;
			if (enableread)
				state <= readstate;
			if (enablewrite)
				state <= wheretowritestate;
		end
		readstate: begin
			if (valid0[address[5:2]]) begin							//If data at that line in set 0 is valid...
				if (tag0[address[5:2]]===address[15:6]) begin				//If tag 0 match...
					dataout <= mem0[address[5:2]][address[1:0]];			//Output data
					hitmiss <= 1;							//Declare cache hit
					lru[address[5:2]] <= 1;						//Corresponding line in set 1 was least recently used
				end
				else begin								//Line in set 0 is valid, but tag 0 mismatch
					if (valid1[address[5:2]]) begin					//If data at that line in set 1 is valid...
						if (tag1[address[5:2]]===address[15:6]) begin		//If tag 1 match...
							dataout <= mem1[address[5:2]][address[1:0]];	//Output data
							hitmiss <= 1;					//Declare cache hit
							lru[address[5:2]] <= 0;				//Corresponding line in set 0 was least recently used
						end
						else							//Line in set 0 is valid, tag 0 mismatch, line in set 1 is valid, tag 1 mismatch
							hitmiss <= 0;					//Declare cache miss
					end
					else								//Line in set 0 is valid, tag 0 mismatch, line in set 1 is invalid
						hitmiss <=0;						//Declare cache miss
				end
			end
			else begin									//Line in set 0 is invalid
				if (valid1[address[5:2]]) begin						//If line in set 1 is valid...
					if (tag1[address[5:2]]===address[15:6]) begin			//If tag 1 match...
						dataout <= mem1[address[5:2]][address[1:0]];		//Output data
						hitmiss <= 1;						//Declare cache hit
						lru[address[5:2]] <= 0;					//Corresponding line in set 0 was least recently used
					end
					else								//Line in set 0 is invalid, line in set 1 is valid, tag 1 mismatch
						hitmiss <= 0;						//Declare cache miss
				end
				else									//Line in set 0 is invalid, line in set 1 is invalid
					hitmiss <=0;							//Declare cache miss
			end
			state <= idlestate;								//Read complete, go back to idle.	
		end	
		wheretowritestate: begin
			if (!valid0[address[5:2]]) begin	//If line in set 0 is invalid...
				writeset <= 0;			//Write to set 0
				state <= writebyte0;
			end
			else if (!valid1[address[5:2]]) begin	//Line in set 0 is valid, but if line in set 1 is invalid...
				writeset <= 1;			//Write to set 1
				state <= writebyte0;
			end
			else begin				//Both lines are valid
				if (!lru[address[5:2]]) begin	//If line in set 0 is least recently used...
					writeset <= 0;		//Write to set 0
					state <= writebyte0;
				end
				else begin			//Line in set 1 is least recently used
					writeset <= 1;		//Write to set 1
					state <= writebyte0;
				end
			end
		end
		writebyte0: begin						//Write byte 0 in line
			if (writebyte === 2'b00 && writeset === 0) begin	//writebyte condition makes sure cache knows the data on bus is for byte 0
				mem0[address[5:2]][0] <= datain;
				state <= writebyte1; 
			end
			else if (writebyte === 2'b00 && writeset === 1)	begin
				mem1[address[5:2]][0] <= datain;
				state <= writebyte1;
			end
		end			
		writebyte1: begin						//Write byte 1 in line
			if (writebyte === 2'b01 && writeset === 0) begin
				mem0[address[5:2]][1] <= datain;
				state <= writebyte2;
			end
			else if (writebyte === 2'b01 && writeset === 1)	begin
				mem1[address[5:2]][1] <= datain;
				state <= writebyte2;
			end
		end			
		writebyte2: begin						//Write byte 2 in line
			if (writebyte === 2'b10 && writeset === 0) begin
				mem0[address[5:2]][2] <= datain;
				state <= writebyte3;
			end
			else if (writebyte === 2'b10 && writeset === 1)	begin
				mem1[address[5:2]][2] <= datain;
				state <= writebyte3;
			end
		end			
		writebyte3: begin						//Write byte 3 in line
			if (writebyte === 2'b11 && writeset === 0) begin
				mem0[address[5:2]][3] <= datain;
				valid0[address[5:2]] <= 1;
				state <= idlestate;
			end
			else if (writebyte === 2'b11 && writeset === 1)	begin
				mem1[address[5:2]][3] <= datain;
				valid1[address[5:2]] <= 1;
				state <= idlestate;
			end
		end
		endcase
	end
end
endmodule
