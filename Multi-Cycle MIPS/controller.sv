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


module controller_testbench();
logic clk; 
logic reset;
logic [5:0] op, funct;
logic zero;
logic pcen, memwrite, irwrite, regwrite;
logic alusrca, iord, memtoreg, regdst;
logic [1:0] alusrcb, pcsrc;
logic [2:0] alucontrol;

controller dut (clk, reset, op, funct, zero,pcen,memwrite,irwrite,regwrite,alusrca,iord,memtoreg,regdst,alusrcb,pcsrc,alucontrol);

initial 
begin 
reset <= 1; # 5; reset <= 0; 
end

always 
begin 
clk <= 1; # 5; clk <= 0; # 5; 
end


initial
begin
op = 6'b000000; funct = 6'b100000; zero = 0; #40;
op = 6'b000000; funct = 6'b100010; zero = 0; #40;
op = 6'b000000; funct = 6'b100100; zero = 0; #40;
op = 6'b000000; funct = 6'b100101; zero = 0; #40;
op = 6'b000000; funct = 6'b101010; zero = 0; #40;
op = 6'b100011; funct = 6'b000000; zero = 0; #50;
op = 6'b101011; funct = 6'b000000; zero = 0; #40;
op = 6'b000100; funct = 6'b000000; zero = 0; #30;
op = 6'b000100; funct = 6'b000000; zero = 1; #30;
op = 6'b001000; funct = 6'b000000; zero = 0; #40;
op = 6'b000010; funct = 6'b000000; zero = 0; 
end

endmodule