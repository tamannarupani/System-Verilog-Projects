module alu(input logic [31:0]srca, 
           input logic [31:0]srcb, 
           input logic [2:0]alucontrol, 
           output logic [31:0]aluout, 
           output logic zero);

logic [31:0]sum;
logic [31:0]srcbmux;

always_comb
case(alucontrol[2])

1'b0: srcbmux = srcb;
1'b1: srcbmux = ~srcb;

endcase

assign sum = srca + srcbmux + alucontrol[2];

always_comb
case (alucontrol[1:0])
2'b00: aluout = srca & srcbmux;	
2'b01: aluout = srca | srcbmux;
2'b10: aluout = sum;
2'b11: aluout = {31'b0000000000000000000000000000000, sum[31]};
endcase

assign zero = (aluout==32'b0);

endmodule
