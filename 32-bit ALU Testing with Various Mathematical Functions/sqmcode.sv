module sqmcode ( input logic [7:0]A, input logic [3:0]B, output logic [7:0]Y);
logic [7:0]C;
assign C = B * B;
assign Y = C % A;
endmodule

