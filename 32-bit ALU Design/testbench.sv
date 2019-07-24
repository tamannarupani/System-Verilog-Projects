module testbench();

logic clk, reset; // Clock and Reset are internal
logic [31:0]A; // Input 1
logic [31:0]B; // Input 2
logic [2:0]F; // Control element
logic [31:0]yexpected; // Expected value of the output
logic zeroexp; // Expected zero value
logic zero; // Values from testvectors
logic [31:0]Y; // Output of circuit
reg [31:0]vectornum, errors; // Bookkeeping variables
reg [99:0]testvectors[0:10000];// Array of testvectors

alu dut(.F(F), .A(A), .B(B), .Y(Y), .zero(zero));  // Instantiate device under test

// Generate clock
always // No sensitivity list, so it always executes
begin
clk = 1; #5; clk = 0; #5; // 10ns period
end

// At start of test, load vectors
// And pulse reset
initial // Will execute at the beginning once
begin              
$readmemb("D:/MS Sem 2/ECE 469 HDL/Project 1/Part 1/alutv.txt", testvectors); // Read vectors
vectornum = 0; errors = 0; // Initialize
reset = 1; #10; reset = 0; // Apply reset wait
end

// Apply test vectors on rising edge of clk
always @(posedge clk)
begin
#1; {F, A, B, yexpected, zeroexp} = testvectors[vectornum];
end

// Check results on falling edge of clk
always @(negedge clk)
if (~reset) // Skip during reset
begin
if (Y !== yexpected)
begin
$display("Error: inputs = %b", {F, A, B});
$display(" outputs = %b (%b expected)",Y,yexpected);
errors = errors + 1;
end

// Increment array index and read next testvector
vectornum = vectornum + 1;
if ( vectornum == 50)
begin
$display("%d tests completed with %d errors",
vectornum, errors);
$finish; // End simulation
end
end
endmodule 
