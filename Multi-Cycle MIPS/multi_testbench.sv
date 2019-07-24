module multi_testbench();
logic clk; logic reset;
logic [31:0] writedata, aluout; 
logic memwrite;

topmulti dut (clk, reset, writedata, adr, memwrite);

initial 
begin 
reset <= 1; # 22; reset <= 0; 
end

always 
begin 
clk <= 1; # 5; clk <= 0; # 5; 
end

endmodule