module topmulti(input logic clk, reset,
                output logic [31:0] writedata, adr,
                output logic memwrite);

logic [31:0] readdata;

//microprocessor (control & datapath)
mips mips(clk, reset, adr, writedata, memwrite, readdata);

//memory
mem mem(clk, memwrite, adr, writedata, readdata);

endmodule 

module mem(input logic clk, we,
           input logic [31:0] a, wd,
           output logic [31:0] rd);

logic [31:0] RAM[63:0];

 
initial
begin
 $readmemh("C:/intelFPGA/17.1/PROJALU/memfile.dat",RAM);
end

assign rd = RAM[a[31:2]]; //word aligned

always_ff @(posedge clk)
if (we)
RAM[a[31:2]] <= wd;

endmodule


module mips(input logic clk, reset,
            output logic [31:0] adr, writedata,
            output logic memwrite,
            input logic [31:0] readdata);

logic zero, pcen, irwrite, regwrite, alusrca, iord, memtoreg, regdst;
logic [1:0] alusrcb, pcsrc;
logic [2:0] alucontrol;
logic [5:0] op, funct;

controller c(clk, reset, op, funct, zero, pcen, memwrite, irwrite, regwrite, alusrca, iord, memtoreg, regdst, alusrcb, pcsrc, alucontrol);

datapath dp(clk, reset, pcen, irwrite, regwrite, alusrca, iord, memtoreg, regdst, alusrcb, pcsrc, alucontrol, op, funct, zero, adr, writedata, readdata);

endmodule

module controller(input logic clk, reset,
                  input logic [5:0] op, funct,
                  input logic zero,
                  output logic pcen, memwrite, irwrite, regwrite,
                  output logic alusrca, iord, memtoreg, regdst,
                  output logic [1:0] alusrcb, pcsrc,
                  output logic [2:0] alucontrol);

logic [1:0] aluop;
logic branch, pcwrite;
logic skip;
logic [3:0] state;
logic [14:0] controls;

//Main Decoder and ALU Decoder subunits.
maindec md(clk, reset, op, pcwrite, memwrite, irwrite, regwrite, alusrca, branch, iord, memtoreg, regdst, alusrcb, pcsrc, aluop,state,controls);

aludec ad(funct, aluop, alucontrol);

assign skip = branch & zero;

assign pcen = pcwrite ? pcwrite : skip;

endmodule 

module maindec(input logic clk, reset,
               input logic [5:0] op,
               output logic pcwrite, memwrite, irwrite, regwrite,
               output logic alusrca, branch, iord, memtoreg, regdst,
               output logic [1:0] alusrcb, pcsrc,
               output logic [1:0] aluop,output logic [3:0] state , output logic[14:0] controls);

parameter FETCH   = 4'b0000; // State 0
parameter DECODE  = 4'b0001; // State 1
parameter MEMADR  = 4'b0010; // State 2
parameter MEMRD   = 4'b0011; // State 3
parameter MEMWB   = 4'b0100; // State 4
parameter MEMWR   = 4'b0101; // State 5
parameter RTYPEEX = 4'b0110; // State 6
parameter RTYPEWB = 4'b0111; // State 7
parameter BEQEX   = 4'b1000; // State 8
parameter ADDIEX  = 4'b1001; // State 9
parameter ADDIWB  = 4'b1010; // state 10
parameter JEX     = 4'b1011; // State 11
parameter LW      = 6'b100011; // Opcode for lw
parameter SW      = 6'b101011; // Opcode for sw
parameter RTYPE   = 6'b000000; // Opcode for R-type
parameter BEQ     = 6'b000100; // Opcode for beq
parameter ADDI    = 6'b001000; // Opcode for addi
parameter J       = 6'b000010; // Opcode for j
 
logic [3:0] nextstate;
//logic [14:0] controls;

//state register
always_ff @(posedge clk or posedge reset)
if(reset) state <= FETCH;
else state <= nextstate;


//next state logic
always_comb
case(state)
 FETCH:   nextstate = DECODE;
 DECODE:  case(op)
          LW: nextstate = MEMADR;
          SW: nextstate = MEMADR;
          RTYPE: nextstate = RTYPEEX;
          BEQ: nextstate = BEQEX;
          ADDI: nextstate = ADDIEX;
          J: nextstate = JEX;
          default: nextstate = 4'bx; // should never happen
          endcase
 MEMADR:  case(op)
          LW: nextstate = MEMRD;
          SW: nextstate = MEMWR;
          default: nextstate = 4'bx;// should never happen
          endcase
 MEMRD:   nextstate = MEMWB;
 MEMWB:   nextstate = FETCH;
 MEMWR:   nextstate = FETCH;
 RTYPEEX: nextstate = RTYPEWB;
 RTYPEWB: nextstate = FETCH;
 BEQEX:   nextstate = FETCH;
 ADDIEX:  nextstate = ADDIWB;
 ADDIWB:  nextstate = FETCH;
 JEX:     nextstate = FETCH;
 default: nextstate = 4'bx; // should never happen
endcase

//output logic
assign {pcwrite, memwrite, irwrite, regwrite, alusrca, branch, iord, memtoreg, regdst, alusrcb, pcsrc, aluop} = controls;

always_comb
case(state)
 FETCH:   controls = 15'h5010;
 DECODE:  controls = 15'h0030;
 MEMADR:  controls = 15'h0420;
 MEMRD:   controls = 15'h0100;
 MEMWB:   controls = 15'h0880;
 MEMWR:   controls = 15'h2100;
 RTYPEEX: controls = 15'h0402;
 RTYPEWB: controls = 15'h0840;
 BEQEX:   controls = 15'h0605;
 ADDIEX:  controls = 15'h0420;
 ADDIWB:  controls = 15'h0800;
 JEX:     controls = 15'h4008;
 default: controls = 15'hxxxx; // should never happen
endcase

endmodule

module aludec(input logic [5:0] funct,
              input logic [1:0] aluop,
              output logic [2:0] alucontrol);

always_comb  
case(aluop)  
2'b00: alucontrol <= 3'b010; // add (for lw/sw/addi)  
2'b01: alucontrol <= 3'b110; // sub (for beq)  
default: case(funct) // R-type instructions  
         6'b100000: alucontrol <= 3'b010; // add   
         6'b100010: alucontrol <= 3'b110; // sub  
         6'b100100: alucontrol <= 3'b000; // and  
         6'b100101: alucontrol <= 3'b001; // or  
         6'b101010: alucontrol <= 3'b111; // slt  
         default:   alucontrol <= 3'bxxx; // should never happen
         endcase  
endcase  
 
endmodule 

module datapath(input  logic clk, reset,
                input  logic pcen, irwrite, regwrite, 
                input  logic alusrca, iord, memtoreg, regdst, 
                input  logic [1:0]  alusrcb, pcsrc,
                input  logic [2:0]  alucontrol,  
                output logic [5:0]  op, funct,  
                output logic zero,
                output logic [31:0] adr, writedata,
                input  logic [31:0] readdata); 
 
//Internal signals of the datapath module. 
 
logic [4:0]  writereg;   
logic [31:0] pcnext, pc;  
logic [31:0] instr, data, srca, srcb;   
logic [31:0] a; 
logic [31:0] aluresult, aluout;   
logic [31:0] signimm;   // the sign-extended immediate   
logic [31:0] signimmsh; // the sign-extended immediate shifted left by 2   
logic [31:0] wd3, rd1, rd2; 
logic [31:0] jsignimm;
 

//op and funct fields to controller  
assign op = instr[31:26];   
assign funct = instr[5:0]; 
 
flopr #(32) pcreg(clk, reset,pcen, pcnext, pc); 

mux2 #(32) adrchoose(pc, aluout, iord,  adr);

flopr #(32) instrchoose(clk, reset,irwrite, readdata, instr); 

flop #(32) datachoose(clk, reset, readdata, data); 

mux2 #(5) wrmux(instr[20:16], instr[15:11], regdst, writereg); 

mux2 #(32) resmux(aluout, data, memtoreg, wd3); 

regfile rf(clk, regwrite, instr[25:21], instr[20:16], writereg, wd3, rd1,rd2); 

flop2 #(32) srcreg(clk, reset, rd1, rd2, a,writedata); 

mux2 #(32) srcachoice(pc, a, alusrca,  srca);

signext se(instr[15:0], signimm);

sl2 immsh(signimm, signimmsh); 

mux4  #(32) srcbchoice (writedata,32'b100,signimm,signimmsh,alusrcb,srcb);

aluproj alu(srca, srcb, alucontrol, aluresult, zero); 

flop #(32) aluchoose(clk, reset, aluresult, aluout); 

jsignim jsi(instr,jsignimm);

mux3 aluchoice(aluresult,aluout,jsignimm,pcsrc,pcnext);

endmodule 

//-----------------------------Register File-----------------------------------------
module regfile(input logic clk,
               input logic we3, 
               input logic [4:0] ra1, ra2, wa3, 
               input logic [31:0] wd3, 
               output logic [31:0] rd1, rd2);

logic [31:0] rf[31:0];

always_ff @(posedge clk) 
if (we3) 
rf[wa3] <= wd3;

assign rd1=(ra1 !=0) ? rf[ra1] : 0; 
assign rd2=(ra2 !=0) ? rf[ra2] : 0; 

endmodule
//------------------------------------------------------------------------------------
//-------------------------------Alu--------------------------------------------------
module aluproj(input logic [31:0] a, b, 
               input logic [2:0] F, 
               output logic [31:0] Y, 
               output logic zero);
logic [31:0] S , B;

assign B = F[2]? ~b:b;

assign S = a + B + F[2];

always_comb
case(F[1:0])
2'b00 : Y = a & B;
2'b01 : Y = a | B;
2'b10 : Y = S;
2'b11 : Y = {31'b0,S[31]};
endcase


always_comb
if ( Y === 32'b0)
zero = 1;
else zero =0;

endmodule
//----------------------------------------------------------------------------------------
//----------------------To store values into register-------------------------------------
module flop #(parameter WIDTH=8) (input logic clk, reset,
                                   input logic [WIDTH-1:0] d, 
                                   output logic [WIDTH-1:0] q);

always_ff @(posedge clk, posedge reset) 
if (reset) q <= 0;
else  q <= d; 

endmodule
//----------------------------------------------------------------------------------------
//---------------------------------Register to save A and B values------------------------
module flop2 #(parameter WIDTH=8) (input logic clk, reset,
                                   input logic [WIDTH-1:0] d1, d2,
                                   output logic [WIDTH-1:0] q1,q2);

always_ff @(posedge clk, posedge reset) 
if (reset) 
begin 
q1 <= 0;
q2 <= 0;
end
else  
begin
q1 <= d1;
q2 <= d2;
end

endmodule
//-----------------------------------------------------------------------------------------
//---------------------- To store pc value only when en is 1-------------------------------
module flopr #(parameter WIDTH=8) (input logic clk, reset, pcen,
                                   input logic [WIDTH-1:0] d, 
                                   output logic [WIDTH-1:0] q);

always_ff @(posedge clk, posedge reset) 
if (reset) q <= 0;
else if (pcen) q <= d; 

endmodule
//-----------------------------------------------------------------------------------------
//---------------Sign extend for immediate values------------------------------------------
module signext(input logic [15:0] a, 
               output logic [31:0] y); 
 
assign y={{16{a[15]}}, a}; 

endmodule 
//-----------------------------------------------------------------------------------------
//----------------Left shift for beq instruction-------------------------------------------
module sl2(input logic [31:0] a, 
           output logic [31:0] y); 

assign y={a[29:0], 2'b00}; 

endmodule
//----------------------------------------------------------------------------------------
//----------------Left shift for Jump instruction-----------------------------------------
module jsignim(input logic [31:0] a, 
               output logic [31:0] y); 

assign y={a[31:28], {a[25:0], 2'b00}}; 

endmodule
//----------------------------------------------------------------------------------------
//--------------------------------MUX for 2 choices---------------------------------------
module mux2 #(parameter WIDTH=8) (input logic [WIDTH-1:0] d0, d1,
                                  input logic s, 
                                  output logic [WIDTH-1:0] y);

assign y=s ? d1 : d0; 

endmodule
//---------------------------------------------------------------------------------------
//--------------------------------MUX for 3 choices--------------------------------------
module mux3 #(parameter WIDTH = 8) (input  logic [WIDTH-1:0] d0, d1, d2,
                                    input  logic [1:0] s,   
                                    output logic [WIDTH-1:0] y); 
 
assign #1 y = s[1] ? d2 : (s[0] ? d1 : d0); 

endmodule 
//--------------------------------------------------------------------------------------
//----------------------Mux for 4 choices-----------------------------------------------
module mux4 #(parameter WIDTH = 8) (input  logic [WIDTH-1:0] d0, d1, d2, d3,     
                                    input  logic [1:0] s,       
                                    output logic [WIDTH-1:0] y); 
 
always_comb   
case(s)      
   2'b00: y = d0;         
   2'b01: y = d1;        
   2'b10: y = d2;       
   2'b11: y = d3;       
endcase 

endmodule 
//--------------------------------------------------------------------------------------- 
