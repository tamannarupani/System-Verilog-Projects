module lfsrhd(input logic clk, reset, 
             output logic [7:0] LFSR_q, r_addr,readdata, 
             output logic memwrite,
             output logic [31:0] pc,instr,
             output logic [6:0] tap_loc, 
             output logic [7:0] HD,st_M_HDdata);


logic [7:0] aluout; 

	mips mips(clk,reset,pc,instr,memwrite,r_addr,LFSR_q,readdata,st_M_HDdata,tap_loc,HD); 
	
	imem imem(pc[7:2], instr); 
	
	dmem dmem(clk, memwrite, instr,r_addr, LFSR_q, readdata);

        sdmem HDmem(clk,memwrite,instr,r_addr, HD,st_M_HDdata);
endmodule
//-------------------------------------------------------------------------

//---------------------------------DATA MEMORY----------------------------

module dmem(input logic clk, we, input logic [31:0] instr,
            input logic [7:0] a, wd, 
            output logic [7:0] rd); 

logic [7:0] RAM[255:0]; 
	
assign rd = RAM[a]; 

always_ff @(posedge clk) 
	if (we & instr[31:26]=== 6'b000100) RAM[a] <= wd;

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
            input logic [7:0] readdata,st_M_HDdata,
            output logic [6:0] tap_loc,
            output logic [7:0] HD); 

	
	//logic [2:0] alucontrol; 

controller c(instr[31:26],memwrite,pccount); 
				
datapath dp(clk, reset, instr, readdata,st_M_HDdata,memwrite,pccount, LFSR_q, pc,HD,r_addr,tap_loc);
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
			6'b001000: controls <= 2'b10; // st_M_HD
                        default: controls <= 2'bxx; // illegal op 
		endcase 

endmodule
//-------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------
module datapath(input logic clk, reset, 
                input logic [31:0]instr, 
                input logic [7:0] readdata,st_M_HDdata,
                input logic memwrite,				
		input logic pccount, output logic[7:0] q,
		output logic [31:0] pc,
                output logic [7:0] HD,r_addr, 
                output logic [6:0] tap_loc );
		 
		            
		 					 					 
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
else if (instr [31:26] === 6'b001000)
   q <= st_M_HDdata;
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

logic [7:0] tmpry;


flopr #(32) hdcal(clk, reset, q, q_old);

assign tmpry = q_old;

hdcalc hd1 (clk,reset,q,tmpry,HD);

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
        else if (instr [31:26] === 6'b001001)
            r_addr <= 8'b00000000;
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
//---------------------------------HAMMING DISTANCE MEMORY----------------------------

module sdmem(input logic clk, we,input logic [31:0] instr, input logic [7:0] a, wd,output logic [7:0] st_M_HDdata); 

logic [7:0] RAM[255:0]; 
	
assign st_M_HDdata = RAM[a];

	
      	always_ff @(posedge clk) 

		if (we & instr[31:26] === 6'b001000) RAM[a] <= wd;

endmodule

//-------------------------------------------------------------------------

//------------------------HAMMING DISTANCE CALCULATOR-----------------------------------
module hdcalc (inout logic clk,reset,input logic [7:0] q,q_old, output logic [7:0] HD);

logic hd0,hd1,hd2,hd3,hd4,hd5,hd6,hd7,hd8;                 


logic tmp;

always_comb
if( q_old === q )
   tmp=1'b1;
else tmp = 1'b0;

always_comb
if ( q_old[0] === q[0])
   hd0 = 1'b0;
else hd0 = 1'b1;

always_comb
if ( q_old[1] === q[1])
   hd1 = 1'b0;
else hd1 = 1'b1;

always_comb
if ( q_old[2] === q[2])
   hd2 = 1'b0;
else hd2 = 1'b1;

always_comb
if ( q_old[3] === q[3])
   hd3 = 1'b0;
else hd3 = 1'b1;

always_comb
if ( q_old[4] === q[4])
   hd4 = 1'b0;
else hd4 = 1'b1;

always_comb
if ( q_old[5] === q[5])
   hd5 = 1'b0;
else hd5 = 1'b1;

always_comb
if ( q_old[6] === q[6])
   hd6 = 1'b0;
else hd6 = 1'b1;

always_comb
if ( q_old[7] === q[7])
   hd7 = 1'b0;
else hd7 = 1'b1;



always_ff @(posedge clk)
if (tmp )
   HD <= HD;
else
   HD <= hd0+hd1+hd2+hd3+hd4+hd5+hd6+hd7;

endmodule

//----------------------------------------------------------------------------------
                           



