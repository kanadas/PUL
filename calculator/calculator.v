`default_nettype none

module showDigit(
	input wire [3: 0] digit,
	input wire is_digit,
	output wire [6: 0] seg
);

reg [6: 0] seg1;

assign seg = seg1;

always @*
begin
	if (is_digit) begin
		case (digit)
			4'h0: seg1 = 7'h40;
			4'h1: seg1 = 7'h79;
			4'h2: seg1 = 7'h24;
			4'h3: seg1 = 7'h30;
			4'h4: seg1 = 7'h19;
			4'h5: seg1 = 7'h12;
			4'h6: seg1 = 7'h02;
			4'h7: seg1 = 7'h78;
			4'h8: seg1 = 7'h00;
			4'h9: seg1 = 7'h10;
			4'hA: seg1 = 7'h08;
			4'hB: seg1 = 7'h03;
			4'hC: seg1 = 7'h46;
			4'hD: seg1 = 7'h21;
			4'hE: seg1 = 7'h06;
			4'hF: seg1 = 7'h0e;
		endcase
	end else seg1 = 7'h3f;		//-
end

endmodule

module display(
	input wire [15: 0] digits,
	input wire is_number,
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

showDigit digidigi(.digit(cur_digit), .is_digit(is_number), .seg(seg));

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

module divide(divident, divider, quotient, modulo);
parameter BITS = 4;

input wire [BITS - 1: 0] divident;
input wire [BITS - 1: 0] divider;
output wire [BITS - 1: 0] quotient;
output wire [BITS - 1: 0] modulo;

reg [BITS - 1: 0] tdivt;
reg [BITS - 1: 0] tdivr;
wire [BITS - 1: 0] tquot;
reg [BITS - 1: 0] tquot2;
reg [BITS - 1: 0] tquot3;
wire [BITS - 1: 0] tmod;
reg [BITS - 1: 0] tmod2;

always @*
begin
	if(divider[BITS - 1]) begin
		tdivr = (~divider) + 1;	//*(-1)
		tquot2 = (~tquot) + 1;
	end else begin
		tdivr = divider;
		tquot2 = tquot;
	end
	if(divident[BITS - 1]) begin
		tdivt = (~divident) + 1;
		if(tmod == 0) begin
			tquot3 = (~tquot2) + 1;
			tmod2 = tmod;
		end else begin
			tquot3 = (~tquot2);
			tmod2 = tdivr - tmod;
		end
	end else begin
		tdivt = divident;
		tquot3 = tquot2;
		tmod2 = tmod;
	end
/*   if(divider[BITS - 1])
	   tdivr = (~divider) + 1;
   else
	   tdivr = divider
   if(divident[BITS - 1])
	   tdivt = (~divident) + 1;
	else
		tdivit = divident;
   if(divider[BITS - 1] && divident[BITS - 1])
	   if(tmod == 0) begin
			tquot2 = tquot;
			tmod2 = tmod;
		end else begin
			tquot2 = tquot - 1;
*/
end

assign quotient = tquot3;
assign modulo = tmod2;

uns_divide #(.BITS(BITS)) udiv(.divident(tdivt), .divider(tdivr), .quotient(tquot), .modulo(tmod));

endmodule

module calculator (
	input wire [3:0] btn,
	input wire [7:0] sw,
	input wire uclk,
	output wire [3:0] an,
	output wire [6:0] seg,
	output wire [7:0] led
);

localparam SPUSH = 2'b00;
localparam SPOP = 2'b01;
localparam SINSTR = 2'b10;

reg [3:0] btn1 = 0;
reg [3:0] btn2 = 0;
reg [3:0] btn3 = 0;
reg [7:0] sw1 = 0;
reg [7:0] sw2 = 0;
reg [31:0] stack [511:0];
reg [9:0] len = 0;
reg [8:0] shead = 0;
reg [15:0] disp_num;
wire not_empty;
reg error = 0;
wire [31:0] quot;
wire [31:0] mod;
reg signed [31:0] top;
reg signed [31:0] top2;
reg [31:0] push;
reg [1:0] state = SINSTR;
//reg [31:0] ram_in;
//reg [31:0] ram_out;
//reg ram_write;
//reg ram_read;

assign not_empty = len > 0;

display disp(.digits(disp_num), .is_number(not_empty), .clk(uclk), .an(an), .seg(seg));

//TODO with 32 bits doesn't synthesize
divide #(.BITS(4)) div(.divident(top2), .divider(top), .quotient(quot), .modulo(mod));

always @(posedge uclk)
begin
	btn1 <= btn;
	btn2 <= btn1;
	btn3 <= btn2;
	sw1 <= sw;
	sw2 <= sw1;
	case (state)
		SPUSH: begin
			stack[shead + 1] <= push;
			//ram_in <= push;
			//ram_write <= 1;
			//ram_read <= 0;
			shead <= shead + 1;
			state <= SINSTR;
		end
		SPOP: begin
			top2 <= stack[shead];
			//top2 <= ram_out;
			//ram_read <= 1;
			//ram_write <= 0;
			shead <= shead - 1;
			state <= SINSTR;
		end
		SINSTR: begin
			//ram_read <= 0;
			//ram_write <= 0;
			if(btn3[3] && btn3[0]) begin
				len <= 0;
				error <= 0;
			end else if(btn3[1] && !btn2[1]) begin
				if(len < 512) begin
					push <= top2;
					top2 <= top;
					top <= {24'h000000,sw2};
					error <= 0;
					if(len > 1)
						state <= SPUSH;
					len <= len + 1;
				end else error <= 1;
			end else if(btn3[2] && !btn2[2]) begin
				if(len > 0) begin
					top <= {top[23:0],sw2};
					error <= 0;
				end else error <= 1;
			end else if(btn3[3] && !btn2[3]) begin
				case(sw[2:0])
					3'b000:
						if(len > 1) begin
							top <= top2 + top;
							if(shead > 0)
								state <= SPOP;
							len <= len - 1;
							error <= 0;
						end else error <= 1;
					3'b001:
						if(len > 1) begin
							top <= top2 - top;
							if(shead > 0)
								state <= SPOP;
							len <= len - 1;
							error <= 0;
						end else error <= 1;
					3'b010:
						if(len > 1) begin
							top <= top2 * top;
							if(shead > 0)
								state <= SPOP;
							len <= len - 1;
							error <= 0;
						end else error <= 1;
					3'b011:
						if(len > 1 && top != 0) begin
							top <= quot;
							if(shead > 0)
								state <= SPOP;
							len <= len - 1;
							error <= 0;
						end else error <= 1;
					3'b100:
						if(len > 1 && top != 0) begin
							top <= mod;
							if(shead > 0)
								state <= SPOP;
							len <= len - 1;
							error <= 0;
						end else error <= 1;
					3'b101:
						if(len > 0) begin
							top <= top2;
							if(shead > 0)
								state <= SPOP;
							len <= len - 1;
							error <= 0;
						end else error <= 1;
					3'b110:
						if(len > 0) begin
							push <= top2;
							top2 <= top;
							if(len > 1)
								state <= SPUSH;
							len <= len + 1;
							error <= 0;
						end else error <= 1;
					3'b111:
						if(len > 1) begin
							top <= top2;
							top2 <= top;
							error <= 0;
						end else error <= 1;
				endcase
			end
		end
	endcase
end

always @*
begin
	if(btn3[0]) begin
		disp_num = top[31:16];
	end else begin
		disp_num = top[15:0];
	end
end

assign led[6:0] = len[6:0];
assign led[7] = error;
endmodule
