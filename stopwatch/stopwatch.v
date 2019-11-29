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
		default: seg1 = 7'b1111111;
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
		digit <= digit;
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

module stopwatch(
	input wire [3: 0] btn,
	input wire [7: 0] sw,
	input wire mclk,
	input wire uclk,
	output wire [3: 0] an,
	output wire [6: 0] seg,
	output wire [2: 0] led
);

localparam S_STOP = 0;
localparam S_STOP_BOUND = 1;
localparam S_COUNT_UP = 2;
localparam S_COUNT_DOWN = 3;
localparam S_INITIAL = 4;

reg [3: 0] btn1 = 0;
reg [3: 0] btn2 = 0;
reg [7: 0] sw1 = 0;
reg [7: 0] sw2 = 0;
reg [2:0] state = S_INITIAL;
wire clk;
reg [31:0] cnt = 0;
reg [15:0] digits;

BUFGMUX moj_bufor_globalny(.I0(mclk), .I1(uclk), .S(sw2[7]), .O(clk));

display disp(.digits(digits), .clk(clk), .an(an), .seg(seg));

always @(posedge clk)
begin
	btn1 <= btn;
	btn2 <= btn1;
	sw1 <= sw;
	sw2 <= sw1;
	case (state)
		S_INITIAL: begin
			digits <= 0;
			cnt <= 0;
		end
		S_COUNT_UP:
			if(cnt < 32'h2 ** sw2[4:0]) begin
				cnt <= cnt + 1;
			end else begin
				cnt <= 0;
				if(digits[3:0] == 9) begin
					digits[3:0] <= 0;
					if(digits[7:4] == 9) begin
						digits[7:4] <= 0;
						if(digits[11: 8] == 9) begin
							digits[11: 8] <= 0;
							if(digits[15: 12] == 9) begin
								digits[15: 0] <= 16'h9999;
								state <= S_STOP_BOUND;
							end else digits[15: 12] <= digits[15: 12] + 1;
						end else digits[11: 8] <= digits[11:8] + 1;
					end else digits[7:4] <= digits[7:4] + 1;
				end else digits[3:0] <= digits[3:0] + 1;
			end
		S_COUNT_DOWN:
			if(cnt < 32'h2 ** sw2[4:0]) begin
				cnt <= cnt + 1;
			end else begin
				cnt <= 0;
				if(digits[3:0] == 0) begin
					digits[3:0] <= 9;
					if(digits[7:4] == 0) begin
						digits[7:4] <= 9;
						if(digits[11: 8] == 0) begin
							digits[11: 8] <= 9;
							if(digits[15: 12] == 0) begin
								digits[15: 0] <= 0;
								state <= S_STOP_BOUND;
							end else digits[15: 12] <= digits[15: 12] - 1;
						end else digits[11: 8] <= digits[11:8] - 1;
					end else digits[7:4] <= digits[7:4] - 1;
				end else digits[3:0] <= digits[3:0] - 1;
			end
	endcase
	if(btn2[0]) state <= S_COUNT_DOWN;
	else if(btn2[1]) state <= S_COUNT_UP;
	else if(btn2[2]) state <= S_STOP;
	else if(btn2[3]) state <= S_INITIAL;
end

assign led[0] = state == S_COUNT_DOWN;
assign led[1] = state == S_COUNT_UP;
assign led[2] = state == S_STOP_BOUND;

endmodule
