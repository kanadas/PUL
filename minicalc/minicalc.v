`default_nettype none

module divide(divident, divider, quotient, modulo);

parameter BITS = 4;

input wire [BITS - 1: 0] divident;
input wire [BITS - 1: 0] divider;
output wire [BITS - 1: 0] quotient;
output wire [BITS - 1: 0] modulo;

reg [BITS - 1: 0] tmp;
reg [BITS - 1: 0] res;
reg [2*(BITS - 1): 0] sub;
integer i;

always @(divident, divider)
begin
	tmp = divident;
	sub = {BITS-1'b0, divider} << BITS-1;
	for (i = BITS - 1; i >= 0; i = i - 1) begin :div_for
		if(sub <= tmp) begin
			res[i] = 1;
			tmp = tmp - sub;
		end else begin
			res[i] = 0;
		end
		sub = sub >> 1;
	end
end

assign modulo = tmp;
assign quotient = res;

endmodule


module minicalc(
	input wire [7:0] sw,
	input wire [3:0] btn,
	output wire [7:0] led
);

reg [7:0] res;

wire [7:0] divres;
divide #(.BITS(4)) div(.divident(sw[7:4]), .divider(sw[3:0]), .quotient(divres[7:4]), .modulo(divres[3:0]));

always @(sw, btn)
begin
	if(btn[0]) begin
		res[7:4] = sw[7:4] + sw[3:0];
		res[3:0] = sw[7:4] - sw[3:0];
	end else if(btn[1]) begin
		if(sw[7:4] > sw[3:0]) begin
			res[7:4] = sw[3:0];
			res[3:0] = sw[7:4];
		end else begin
			res[7:4] = sw[7:4];
			res[3:0] = sw[3:0];
		end
	end else if(btn[2]) begin
		res[7:0] = sw[7:4] * sw[3:0];
	end else if(btn[3]) begin
		res = divres;
	end else begin
		res[7:0] = 0;
	end
end

assign led = res;

endmodule
