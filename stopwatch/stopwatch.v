'default_nettype none

module showDigit(
	input wire [3: 0] digit;
	output wire [6: 0] seg;
);

always @*
begin
	case (digit)
		0: seg = 7'h40;
		1: seg = 7'h79;
		2: seg = 7'h24;
		3: seg = 7'h30;
		4: seg = 7'h19;
		5: seg = 7'h12;
		6: seg = 7'h02;
		7: seg = 7'h78;
		8: seg = 7'h00;
		9: seg = 7'h10;
		default: seg = 7'b1111111;
	endcase
end

endmodule


module display(
	input wire [15: 0] digits;
	input wire clk;
	output wire [3: 0] an;
	output wire [6: 0] seg;
);

localparam S_LOAD = 2'h0
localparam S_DISPLAY = 2'h1
localparam S_DISCHARGE = 2'h2

reg [1: 0] state = S_LOAD;
reg [3: 0] digit = 1;
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
		digit <= digit;
	end
end

wire [3: 0] cur_digit;

showDigit digit(.digit(cur_digit), .seg(seg));

always @*
begin
	case (state)
		S_LOAD:
			an = 4'hf;
		S_DISPLAY:
			an = !digit;
		S_DISCHARGE:
			an = 4'hf;
	endcase
	if(digit & 4'h1) cur_digit = digits[3: 0];
	else if(digit & 4'h2) cur_digit = digits[7: 4];
	else if(digit & 4'h3) cur_digit = digits[11: 8];
	else cur_digit = digits[15: 12];
end

endmodule
