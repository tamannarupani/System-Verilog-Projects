module testbenchmod();
logic clk; logic reset;
logic [31:0] writedata, aluout; 
logic memwrite;
logic [31:0] pc, instr, readdata;
topmod dut (clk, reset, writedata, aluout, memwrite,pc, instr, readdata);
initial 
begin 
reset <= 1; # 22; reset <= 0; 
end

always 
begin 
clk <= 1; # 5; clk <= 0; # 5; 
end

always @(negedge clk) 
begin 
	if (memwrite) 
	begin 
		if (aluout===84) 
		begin 
		$display("Simulation succeeded"); 
		$stop; 
		end 
		else if (aluout !==80) 
		begin 
		$display("Simulation failed"); 
		$stop; 
		end 
	end 
end 

endmodule
