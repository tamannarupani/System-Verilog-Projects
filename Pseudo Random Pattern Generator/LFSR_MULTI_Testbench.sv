module LFSRmulticycle_testbench();
logic clk;
logic reset;
logic [7:0] LFSR_q,r_addr; 
logic memwrite;
logic [31:0] pc, instr; 
logic [7:0] readdata;
logic [6:0] tap_loc;
logic [7:0] HD,AVG;

lfsrmulticycle dut (clk, reset,LFSR_q, r_addr,readdata,memwrite,pc,instr,tap_loc,HD,AVG);

initial
begin 
reset <= 1; # 5; reset <= 0; 
end


always 
begin 
clk <= 1; # 5; clk <= 0; # 5; 
end

endmodule