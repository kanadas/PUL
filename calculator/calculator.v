`default_nettype none

module showDigit(
	input wire [3: 0] digit,
	output wire [6: 0] seg
);

reg [6: 0] seg1;

assign seg = seg1;

always @*
begin
	case (digit)
		0: seg1 = 7'h40;
		1: seg1 = 7'h79;
		2: seg1 = 7'h24;
		3: seg1 = 7'h30;
		4: seg1 = 7'h19;
		5: seg1 = 7'h12;
		6: seg1 = 7'h02;
		7: seg1 = 7'h78;
		8: seg1 = 7'h00;
		9: seg1 = 7'h10;
		default: seg1 = 7'h3f;
	endcase
end

endmodule

module display(
	input wire [15: 0] digits,
	input wire clk,
	output reg [3: 0] an,
	output wire [6: 0] seg
);

localparam S_LOAD = 2'h0;
localparam S_DISPLAY = 2'h1;
localparam S_DISCHARGE = 2'h2;

reg [1: 0] state = S_LOAD;
reg [3: 0] digit = 4'h1;
reg [15: 0] cnt = 0;

always @(posedge clk)
begin
	if(cnt == 16'h4000) begin
		cnt <= 0;
		digit <= {digit[2: 0], digit[3]};
		state <= S_LOAD;
	end else begin
		if(cnt == 16'h400) begin
			state <= S_DISPLAY;
		end else if(cnt == 16'h3c00) begin
			state <= S_DISCHARGE;
		end
		cnt <= cnt + 1;
	end
end

reg [3: 0] cur_digit;

showDigit digidigi(.digit(cur_digit), .seg(seg));

always @*
begin
	case (state)
		S_LOAD:
			an = 4'hf;
		S_DISPLAY:
			an = ~digit;
		S_DISCHARGE:
			an = 4'hf;
	endcase
	if(digit & 4'h1) cur_digit = digits[3: 0];
	else if(digit & 4'h2) cur_digit = digits[7: 4];
	else if(digit & 4'h4) cur_digit = digits[11: 8];
	else cur_digit = digits[15: 12];
end

endmodule

module uns_divide(divident, divider, quotient, modulo);
//TODO zrobić to w wielu cyklach
parameter BITS = 4;

input wire [BITS - 1: 0] divident;
input wire [BITS - 1: 0] divider;
output wire [BITS - 1: 0] quotient;
output wire [BITS - 1: 0] modulo;

reg [BITS - 1: 0] tmp;
reg [BITS - 1: 0] res;
reg [2*(BITS - 1): 0] sub;
integer i;

always @*
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

module divide(divident, divider, quotient, modulo)
parameter BITS = 4;

input signed wire [BITS - 1: 0] divident;
input signed wire [BITS - 1: 0] divider;
output signed wire [BITS - 1: 0] quotient;
output signed wire [BITS - 1: 0] modulo;

wire [BITS - 2: 0] tdivt;
wire [BITS - 2: 0] tdivr;
wire [BITS - 2: 0] tquot;
wire [BITS - 2: 0] tmod;
wire [BITS - 2: 0] tquot2;

always @*
begin
	if(divider < 0) begin
		tdivr = (not divider) + 1;	//*(-1)
		tquot2 = (not tquot) + 1;
	end else begin
		tdivr = divider;
		tquot2 = tquot;
	end;
	if(divident < 0) begin
		tdivt = (not divident) + 1;
		if(tmod == 0) begin
			quotient = (not tquot2) + 1;
			modulo = tmod;
		end else begin
			quotient = (not tquot2);
			modulo = tdivr - tmod;
		end
	end else begin
		tdivt = divident;
		quotient = tquot2;
		modulo = tmod;
	end
end

uns_divide udiv(.divident(tdivt), .divider(tdivr), .quotient(tquot), .modulo(tmod));

endmodule

module to_decimal(
	input wire [15: 0] in;
	output wire [15: 0] dec;
)

endmodule

module calculator (
);

endmodule
