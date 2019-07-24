module faultinjectioncode (input logic 	[7:0]A, input logic [3:0]B, input logic [2:0]f_loc, 
			input logic [1:0]f_type, output logic [7:0]Y,output logic [7:0]C, output logic [7:0]Cin);
assign Cin = B * B;
always_comb
begin
C = B * B;
case (f_loc[2:0])
3'b000 :
if (f_type == 2'b00)
C[0] = C[0] ;
else if (f_type == 2'b01)
C[0] = 0;
else if (f_type == 2'b10)
C[0] = 1;
else if (f_type == 2'b11)
C[0] = ~C[0] ;
3'b001 :
if (f_type == 2'b00)
C[1] = C[1] ;
else if (f_type == 2'b01)
C[1] = 0;
else if (f_type == 2'b10)
C[1] = 1;
else if (f_type == 2'b11)
C[1] = ~C[1] ;
3'b010 :
if (f_type == 2'b00)
C[2] = C[2] ;
else if (f_type == 2'b01)
C[2] = 0;
else if (f_type == 2'b10)
C[2] = 1;
else if (f_type == 2'b11)
C[2] = ~C[2] ;
3'b011 :
if (f_type == 2'b00)
C[3] = C[3] ;
else if (f_type == 2'b01)
C[3] = 0;
else if (f_type == 2'b10)
C[3] = 1;
else if (f_type == 2'b11)
C[3] = ~C[3] ;
3'b100 :
if (f_type == 2'b00)
C[4] = C[4] ;
else if (f_type == 2'b01)
C[4] = 0;
else if (f_type == 2'b10)
C[4] = 1;
else if (f_type == 2'b11)
C[4] = ~C[4] ;
3'b101 :
if (f_type == 2'b00)
C[5] = C[5] ;
else if (f_type == 2'b01)
C[5] = 0;
else if (f_type == 2'b10)
C[5] = 1;
else if (f_type == 2'b11)
C[5] = ~C[5] ;
3'b110 :
if (f_type == 2'b00)
C[6] = C[6] ;
else if (f_type == 2'b01)
C[6] = 0;
else if (f_type == 2'b10)
C[6] = 1;
else if (f_type == 2'b11)
C[6] = ~C[6] ;
3'b111 :
if (f_type == 2'b00)
C[7] = C[7] ;
else if (f_type == 2'b01)
C[7] = 0;
else if (f_type == 2'b10)
C[7] = 1;
else if (f_type == 2'b11)
C[7] = ~C[7] ;
endcase
if(A!=0)
	Y = C % A;
else
	Y = 8'bXXXXXXXX;
end
endmodule

