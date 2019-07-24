module onesstringcode( input logic [7:0]Y, output logic [3:0]Z);
always_comb
begin
casez (Y)

8'b00000000 : Z = 4'b0000 ; // Maximum length on one's string = 0

8'b0?0?0?01 : Z = 4'b0001 ; // Maximum length on one's string = 1
8'b?0?0?010 : Z = 4'b0001 ; // Maximum length on one's string = 1
8'b0?0?010? : Z = 4'b0001 ; // Maximum length on one's string = 1
8'b?0?010?0 : Z = 4'b0001 ; // Maximum length on one's string = 1
8'b0?010?0? : Z = 4'b0001 ; // Maximum length on one's string = 1
8'b?010?0?0 : Z = 4'b0001 ; // Maximum length on one's string = 1
8'b010?0?0? : Z = 4'b0001 ; // Maximum length on one's string = 1
8'b10?0?0?0 : Z = 4'b0001 ; // Maximum length on one's string = 1

8'b??0??011 : Z = 4'b0010 ; // Maximum length on one's string = 2
8'b?0??0110 : Z = 4'b0010 ; // Maximum length on one's string = 2
8'b0??0110? : Z = 4'b0010 ; // Maximum length on one's string = 2
8'b??0110?0 : Z = 4'b0010 ; // Maximum length on one's string = 2
8'b?0110??? : Z = 4'b0010 ; // Maximum length on one's string = 2
8'b0110??0? : Z = 4'b0010 ; // Maximum length on one's string = 2
8'b110??0?? : Z = 4'b0010 ; // Maximum length on one's string = 2

8'b0???0111 : Z = 4'b0011 ; // Maximum length on one's string = 3
8'b???01110 : Z = 4'b0011 ; // Maximum length on one's string = 3
8'b??01110? : Z = 4'b0011 ; // Maximum length on one's string = 3
8'b?01110?0 : Z = 4'b0011 ; // Maximum length on one's string = 3
8'b01110??? : Z = 4'b0011 ; // Maximum length on one's string = 3
8'b1110???0 : Z = 4'b0011 ; // Maximum length on one's string = 3

8'b???01111 : Z = 4'b0100 ; // Maximum length on one's string = 4
8'b??011110 : Z = 4'b0100 ; // Maximum length on one's string = 4
8'b?011110? : Z = 4'b0100 ; // Maximum length on one's string = 4
8'b011110?0 : Z = 4'b0100 ; // Maximum length on one's string = 4
8'b11110??? : Z = 4'b0100 ; // Maximum length on one's string = 4

8'b??011111 : Z = 4'b0101 ; // Maximum length on one's string = 5
8'b?0111110 : Z = 4'b0101 ; // Maximum length on one's string = 5
8'b0111110? : Z = 4'b0101 ; // Maximum length on one's string = 5
8'b111110?? : Z = 4'b0101 ; // Maximum length on one's string = 5

8'b?0111111 : Z = 4'b0110 ; // Maximum length on one's string = 6
8'b01111110 : Z = 4'b0110 ; // Maximum length on one's string = 6
8'b1111110? : Z = 4'b0110 ; // Maximum length on one's string = 6

8'b01111111 : Z = 4'b0111 ; // Maximum length on one's string = 7
8'b11111110 : Z = 4'b0111 ; // Maximum length on one's string = 7

8'b11111111 : Z = 4'b1000 ; // Maximum length on one's string = 8

endcase
end
endmodule 
