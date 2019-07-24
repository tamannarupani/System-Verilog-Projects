module lfsr(input logic clk, reset, 
             output logic [7:0] LFSR_q, r_addr,readdata, 
             output logic memwrite,
             output logic [31:0] pc,instr,
             output logic [6:0] tap_loc);
           


logic [7:0] aluout; 

	mips mips(clk,reset,pc,instr,memwrite,r_addr,LFSR_q,readdata,tap_loc); 
	
	imem imem(pc[7:2], instr); 
	
	dmem dmem(clk, memwrite, r_addr, LFSR_q, readdata);
endmodule
//-------------------------------------------------------------------------

//---------------------------------DATA MEMORY----------------------------

module dmem(input logic clk, we, 
            input logic [7:0] a, wd, 
            output logic [7:0] rd); 

logic [7:0] RAM[255:0]; 
	
assign rd = RAM[a]; 

always_ff @(posedge clk) 
	if (we) RAM[a] <= wd;

endmodule

//----------------------------INSTRUCTION MEMORY---------------------------
module imem(input logic [5:0]  a, output logic [31:0] rd);

	logic [31:0] RAM[63:0];
	
	initial 
		
		$readmemh ("C:/intelFPGA/17.1/PROJALU/memfilelfsr.dat",RAM);
		
		assign rd=RAM[a]; 

endmodule

//-------------------------------------------------------------------------
//mips mips(clk,reset,pc,instr,memwrite,r_addr,LFSR_q,readdata,tap_loc,HD);  
//----------------------------INSTRUCTION MEMORY---------------------------

module mips(input logic clk, reset, 
            output logic [31:0] pc,
            input logic [31:0]instr, 
            output logic memwrite, 
            output logic [7:0] r_addr, LFSR_q,
            input logic [7:0] readdata,
            output logic [6:0] tap_loc);
            
	
controller c(instr[31:26],memwrite,pccount); 
				
datapath dp(clk, reset, instr, readdata,memwrite,pccount, LFSR_q, pc,r_addr,tap_loc);
endmodule

//---------------------------------CONTROLLER-----------------------------------------

module controller(input logic [5:0] op, 
                  output logic memwrite,pccount);


maindec md(op,memwrite,pccount); 

endmodule

//-------------------------------------------------------------------------------------

//---------------------------------Main Decoder-----------------------------------------

module maindec(input logic [5:0] op, 
               output logic memwrite,pccount);

logic [1:0] controls;

assign {memwrite, pccount} = controls;
	
always_comb 		
		case(op) 
			6'b000000: controls <= 2'b01; // halt
                        6'b000001: controls <= 2'b00; // config_l
			6'b000010: controls <= 2'b00; // init_L
			6'b000011: controls <= 2'b00; // run_L
			6'b000100: controls <= 2'b10; // st_M_L
			6'b000101: controls <= 2'b00; // ld_M_L 
			6'b000110: controls <= 2'b00; // init_addr_loc
			6'b000111: controls <= 2'b00; // add_addr_num
		        default: controls <= 2'bxx; // illegal op 
		endcase 

endmodule
//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
module datapath(input logic clk, reset, 
                input logic [31:0]instr, 
                input logic [7:0] readdata,
                input logic memwrite,				
		input logic pccount, output logic[7:0] q,
		output logic [31:0] pc,
                output logic [7:0] r_addr,
                output logic [6:0] tap_loc);
		 
		            
		 					 					 
logic [31:0] pcnext, pcplus4;

chooseadd cadd (clk,reset,instr,r_addr);	                
	
      
logic temp;
assign temp = q[7];

always_ff @(posedge clk)
if(reset) 
   q <=0;
else if( instr [31:26] === 6'b000010)
   q <= instr [17:10];
else if (instr [31:26] === 6'b000101)
   q <= readdata;
else if (instr [31:26] === 6'b000011)
   begin      	
	 		if (tap_loc[0] === 1'b1) 
			  q[7] <= q[6] ^ temp;
			else			
  	  		  q[7] <= q[6];
		 	if (tap_loc[1] === 1'b1)	
		 	  q[6] <= q[5] ^ temp;	
			else				
		          q[6] <= q[5];
			if (tap_loc[2] === 1'b1)		
 		 	  q[5] <= q[4] ^ temp;	
			else				
			  q[5] <= q[4];
		        if (tap_loc[3] === 1'b1)		
			  q[4] <= q[3] ^ temp;	
			else				
			  q[4] <= q[3];
			if (tap_loc[4] === 1'b1)		
			  q[3] <= q[2] ^ temp;	
			else				
			  q[3] <= q[2];
           	        if (tap_loc[5] === 1'b1)		
		 	  q[2] <= q[1] ^ temp;	
 			else				
			  q[2] <= q[1];
		        if (tap_loc[6] === 1'b1)	
			  q[1] <= q[0] ^ temp;	
			else	
                          begin			
		  	   q[1] <= q[0];
                          end
	                  q[0] <= temp;
   end
else 
q <= q;
                           
flopr #(32) pcreg(clk, reset, pcnext, pc); 

adder pcadd1(pc, 32'b100, pcnext); 
		
configure configure(clk,reset,instr, tap_loc);

endmodule

//-----------------------------------------------------------------------------------
//--------------------------------Config---------------------------------------------
module configure (input logic clk, reset,input logic [31:0] instr, output logic [6:0] tap_loc);

always_ff @ (posedge clk)
if (reset)
		tap_loc <= 0;

	else
	begin
		case(instr[31:26])
	
        		6'b000001: tap_loc <= instr[6:0];
			default: tap_loc <= tap_loc;
		
		endcase
	end
endmodule
//----------------------------------------------------------------------------------
//--------------------------Choose r_addr-----------------------------------------
module chooseadd(input logic clk,reset,input logic [31:0] instr, output logic [7:0] r_addr);

always_ff @ (posedge clk)
if (reset)
		r_addr <= 0;

	else if (instr [31:26] === 6'b000110)
            r_addr <= instr[25:18];
        else if ( instr [31:26] === 6'b000111)
            r_addr <= r_addr + instr [17:10];
        else 
            r_addr <= r_addr;
                  	
endmodule

//-----------------------------------------------------------------------------------
//--------------------------------ADDER---------------------------------------------

module adder(input logic [31:0] a, b,  output logic [31:0] y); 

	assign y=a+b; 

endmodule
//-------------------------------------------------------------------------------------
//--------------------------------FLIP FLOP TO STORE-----------------------------------

module flopr #(parameter WIDTH=8) (input logic clk, reset, input logic [WIDTH-1:0] d, output logic [WIDTH-1:0] q);

	always_ff @(posedge clk, posedge reset) 
			
			if (reset) q <= 0;
			
			else q <= d; 

endmodule
//------------------------------------------------------------------------------------




