module lfsrbatch(input logic clk, reset, 
             output logic [7:0] LFSR_q, r_addr,readdata, 
             output logic memwrite,
             output logic [31:0] pc,instr,
             output logic [6:0] tap_loc, 
             output logic [7:0] HD,avg);


logic [7:0] aluout; 

	mips mips(clk,reset,pc,instr,memwrite,r_addr,LFSR_q,readdata,tap_loc,HD,avg); 
	
	imem imem(pc[7:2], instr); 
	
	dmem dmem(clk, memwrite, r_addr, LFSR_q, readdata);

        dmem avgmem (clk,memwrite, r_addr , avg, readdata);
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

//----------------------------INSTRUCTION MEMORY---------------------------

module mips(input logic clk, reset, 
            output logic [31:0] pc,
            input logic [31:0]instr, 
            output logic memwrite, 
            output logic [7:0] r_addr, LFSR_q,
            input logic [7:0] readdata,
            output logic [6:0] tap_loc,
            output logic [7:0] HD,avg); 

logic [7:0] count,pccounter;
logic cycle;

always_comb
if(( instr[31:26] === 6'b000011 &&  instr [17:10] !== 8'b00000000 && cycle !== 1'b1) || instr [31:26] === 6'b001010)
count = 8'b00000001;
else count = 8'b0;

always_ff @(posedge clk)
if( reset || (instr [31:26] !== 6'b000011 && instr [31:26] !== 6'b001010) )
      pccounter <= 0;
else if(count === 8'b0000001)
      pccounter <= pccounter + count;
else
      pccounter <=0;

always_comb
if (instr[31:26] !== 6'b000011 && instr [31:26] !== 6'b001010) 
	cycle = 1'b1;

else if(pccounter !== instr[17:10])
          cycle = 1'b0;

else cycle = 1'b1;

controller c(instr,cycle,memwrite,pccount); 

			
datapath dp(clk, reset, instr, readdata,memwrite,pccount, LFSR_q, pc,HD,r_addr,avg,tap_loc,cycle,pccounter,count);
endmodule

//---------------------------------CONTROLLER-----------------------------------------

module controller(input logic [31:0] instr,input logic cycle,
                  output logic memwrite,pccount);


maindec md(instr,cycle,memwrite,pccount); 


endmodule

//-------------------------------------------------------------------------------------

//---------------------------------Main Decoder-----------------------------------------

module maindec( input logic [31:0] instr,input logic cycle,
               output logic memwrite,pccount);

logic [1:0] controls;

assign {memwrite, pccount} = controls;
	
always_comb 		
		case(instr[31:26]) 
			6'b000000: controls <= 2'b01; // halt
                        6'b000001: controls <= 2'b00; // config_l
			6'b000010: controls <= 2'b00; // init_L
			6'b000011: begin              //run_L
                                   if( cycle === 1'b1)
                                      controls = 2'b00;
                                   else controls = 2'b01;
                                   end
			6'b000100: controls <= 2'b10; // st_M_L
			6'b000101: controls <= 2'b00; // ld_M_L 
			6'b000110: controls <= 2'b00; // init_addr_loc
			6'b000111: controls <= 2'b00; // add_addr_num
			6'b001000: controls <= 2'b10; // st_M_HD
                        6'b001001: controls <= 2'b10; // avg_M_HD
                        6'b001010: begin              // batch_run_st_M_L_cycle
                                   if( cycle === 1'b1)
                                      controls = 2'b10;
                                   else controls = 2'b11;
                                   end 
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
                output logic [7:0] HD,r_addr,avg, 
                output logic [6:0] tap_loc,input logic cycle,input logic [7:0] pccounter,count);
		 
		            
		 					 					 
logic [31:0] pcnext, pcplus4;
                  	
chooseadd cadd (clk,reset,instr,pccounter,count,cycle,r_addr);	
      
logic temp;
assign temp = q[7];

always_ff @(posedge clk)
if(reset) 
   q <=0;
else if( instr [31:26] === 6'b000010)
   q <= instr [17:10];
else if (instr [31:26] === 6'b000101)
   q <= readdata;
else if ((instr [31:26] === 6'b000011 && cycle !== 1'b1)||(instr [31:26] === 6'b001010 && cycle !== 1'b1))
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

//------------------------HAMMING DISTANCE CALCULATOR-----------------------------------
logic [7:0] q_old;
logic hd0,hd1,hd2,hd3,hd4,hd5,hd6,hd7,hd8;                 

flopr #(32) hdcal(clk, reset, q, q_old);


always_comb
if (instr[31:26] != 6'b000010)
begin 
if ( q_old[0] === q[0])
   hd0 = 1'b0;
else hd0 = 1'b1;

if ( q_old[1] === q[1])
   hd1 = 1'b0;
else hd1 = 1'b1;


if ( q_old[2] === q[2])
   hd2 = 1'b0;
else hd2 = 1'b1;


if ( q_old[3] === q[3])
   hd3 = 1'b0;
else hd3 = 1'b1;


if ( q_old[4] === q[4])
   hd4 = 1'b0;
else hd4 = 1'b1;


if ( q_old[5] === q[5])
   hd5 = 1'b0;
else hd5 = 1'b1;


if ( q_old[6] === q[6])
   hd6 = 1'b0;
else hd6 = 1'b1;


if ( q_old[7] === q[7])
   hd7 = 1'b0;
else hd7 = 1'b1;

end

assign HD = hd0+hd1+hd2+hd3+hd4+hd5+hd6+hd7;

avgcal ac1(clk,reset,instr,HD,avg);


//----------------------------------------------------------------------------------
                           
flopr #(32) pcreg(clk, reset, pcnext, pc); 

adder pcadd1(pc, 32'b100, pcplus4); 
		
configure configure(clk,reset,instr, tap_loc);

mux2 #(32) pcmux(pcplus4, pc, pccount, pcnext);

endmodule

//-----------------------------------------------------------------------------------
//---------------------------------MUX to choose pc-------------------------------------
module mux2 #(parameter WIDTH=8) (input logic [WIDTH-1:0] d0, d1,
                                  input logic s, 
                                  output logic [WIDTH-1:0] y);

assign y=s ? d1 : d0; 

endmodule
//--------------------------------------------------------------------------------------

//--------------------------Choose r_addr-----------------------------------------
module chooseadd(input logic clk,reset,input logic [31:0] instr,input logic[7:0] pccounter,count,input logic cycle, output logic [7:0] r_addr);

always_ff @ (posedge clk)
if (reset)
		r_addr <= 0;

	else if (instr [31:26] === 6'b000110)
            r_addr <= instr[25:18];
        else if ( instr [31:26] === 6'b000111)
            r_addr <= r_addr + instr [17:10];
        else if (instr [31:26] === 6'b001001)
            r_addr <= 8'b00000000;
        else if ( instr [31:26] === 6'b001010 && pccounter === 8'b00000000 && count === 8'b00000001)
            r_addr <= r_addr;
        else if (instr[31:26] === 6'b001010 && cycle === 1'b0)
            r_addr <= r_addr + 1;
        else 
            r_addr <= r_addr;
                  	
endmodule

//-----------------------------------------------------------------------------------
//-------------------------------------AVERAGE CALCULATOR----------------------------
module avgcal(input logic clk,reset,input logic [31:0] instr,input logic [7:0] HD, output logic [7:0] avg);

logic [7:0] rc,runcount,HD_TOTAL;

always_comb
if(instr[31:26] === 6'b000011)
rc = 8'b00000001;
else rc = 8'b00000000;

always_ff @(posedge clk)
if (reset) 
begin
   HD_TOTAL <= 0;
   runcount <= 0;
end
else if (rc === 8'b00000001)
begin  
   HD_TOTAL <= HD_TOTAL + HD;
   runcount <= runcount + rc;
end
else 
begin
   HD_TOTAL <= HD_TOTAL;
   runcount <= runcount;
end

always_comb
if (instr [31:26] === 6'b001001)
avg = HD_TOTAL / runcount;
 
endmodule
//--------------------------------ADDER---------------------------------------------

module adder(input logic [31:0] a, b,  output logic [31:0] y); 

	assign y=a+b; 
endmodule
//-------------------------------------------------------------------------------------
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
//--------------------------------FLIP FLOP TO STORE-----------------------------------

module flopr #(parameter WIDTH=8) (input logic clk, reset, input logic [WIDTH-1:0] d, output logic [WIDTH-1:0] q);

	always_ff @(posedge clk, posedge reset) 
			
			if (reset) q <= 0;
			
			else q <= d; 

endmodule
//------------------------------------------------------------------------------------
//---------------------------------HAMMING DISTANCE MEMORY----------------------------

module sdmem(input logic clk, we, input logic [7:0] a, wd); 

	logic [7:0] RAM[255:0]; 
	
      	always_ff @(posedge clk) 

		if (we) RAM[a] <= wd;

endmodule

//-------------------------------------------------------------------------




