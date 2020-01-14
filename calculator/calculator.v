`default_nettype none

module showDigit(
	input wire [3: 0] digit,
	input wire is_digit,
	output wire [6: 0] seg
);

reg [6: 0] seg1;

assign seg = seg1;

//TODO -5 / 2 nie ustawia bitu znaku

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

module div1(divident, divider, bitidx, res, rem);

parameter BITS = 32;

input wire [BITS-1: 0] divident;
input wire [BITS-1: 0] divider;
input wire [BITS - 1 : 0] bitidx;
output reg res;
output reg [BITS-1: 0] rem;

always @*
begin
	if(divident >= (divider << bitidx)) begin
		res = 1;
		rem = divident - (divider << bitidx);
	end else begin
		res = 0;
		rem = divident;
	end
end

endmodule

module uns_divide(divident, divider, quotient, modulo, input_vld, output_vld, clk);
parameter BITS = 32;

input wire [BITS - 1: 0] divident;
input wire [BITS - 1: 0] divider;
output wire [BITS - 1: 0] quotient;
output wire [BITS - 1: 0] modulo;
input wire input_vld;
output wire output_vld;
input wire clk;

reg [BITS - 1: 0] bitidx = 0;
reg active = 0;
reg [BITS - 1: 0] tmp_divt;
reg [BITS - 1: 0] tmp_res;

assign modulo = tmp_divt;
assign quotient = tmp_res;
assign output_vld = !active;

wire q1;
wire [BITS - 1: 0] out;

div1 #(.BITS(2*BITS)) dzielacz(.divident(tmp_divt), .divider(divider), .bitidx(bitidx), .res(q1), .rem(out));
always @(posedge clk)
begin
	if(!active) begin
		if(input_vld) begin
			tmp_divt <= divident;
			tmp_res <= 0;
			active <= 1;
			bitidx <= BITS - 1;
		end
	end else begin
		tmp_divt <= out;
		tmp_res[bitidx] <= q1;
		if(bitidx == 0)
			active <= 0;
		bitidx <= bitidx - 1;
	end
end

endmodule

module divide(divident, divider, quotient, modulo, input_vld, output_vld, clk);
parameter BITS = 32;

input wire [BITS - 1: 0] divident;
input wire [BITS - 1: 0] divider;
output reg [BITS - 1: 0] quotient;
output reg [BITS - 1: 0] modulo;
input wire input_vld;
output wire output_vld;
input wire clk;

reg [BITS - 1: 0] tdivt;
reg [BITS - 1: 0] tdivr;
wire [BITS - 1: 0] tquot;
//reg [BITS - 1: 0] tquot2;
wire [BITS - 1: 0] tmod;
//reg [BITS - 1: 0] tmod2;
reg tinvld;
wire toutvld;
reg active = 0;
reg divtsgn;
reg divrsgn;

assign output_vld = !active;

always @(posedge clk)
begin
	if(!active) begin
		if(input_vld) begin
			active <= 1;
			tinvld <= 1;
			if(divider[BITS - 1]) begin
				tdivr <= (~divider) + 1;	//*(-1)
				divrsgn <= 1;
			end else begin
				tdivr <= divider;
				divrsgn <= 0;
			end
			if(divident[BITS - 1]) begin
				tdivt <= (~divident) + 1;
				divtsgn <= 1;
			end else begin
				tdivt <= divident;
				divtsgn <= 0;
			end
		end
	end else begin
		tinvld <= 0;
		if(!tinvld && toutvld) begin
			active <= 0;
			if(!divtsgn || tmod == 0) begin
				if({0,divtsgn} + {0,divrsgn} == 1)
					quotient <= (~tquot) + 1;
				else quotient <= tquot;
				modulo <= tmod;
			end else begin
				if({0,divtsgn} + {0,divrsgn} == 1)
					quotient <= (~tquot);
				else quotient <= tquot - 1;
				modulo <= tdivr - tmod;
			end
		end
	end
end

//assign quotient = tquot2;
//assign modulo = tmod2;

uns_divide #(.BITS(BITS)) udiv(
	.divident(tdivt),
	.divider(tdivr),
	.quotient(tquot),
	.modulo(tmod),
	.input_vld(tinvld),
	.output_vld(toutvld),
	.clk(clk));

endmodule

module calculator (
	input wire [3:0] btn,
	input wire [7:0] sw,
	input wire uclk,
	output wire [3:0] an,
	output wire [6:0] seg,
	output wire [7:0] led
);

localparam SPUSH = 3'b000;
localparam SPOP = 3'b001;
localparam SINSTR = 3'b010;
localparam WAITDIV = 3'b100;

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
reg [2:0] state = SINSTR;
wire div_done;
reg do_div;
reg res_is_div;

assign not_empty = len > 0;

display disp(.digits(disp_num), .is_number(not_empty), .clk(uclk), .an(an), .seg(seg));

divide #(.BITS(32)) div(
	.divident(top2),
	.divider(top),
	.quotient(quot),
	.modulo(mod),
	.input_vld(do_div),
	.output_vld(div_done),
	.clk(uclk));

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
			shead <= shead + 1;
			state <= SINSTR;
		end
		SPOP: begin
			top2 <= stack[shead];
			shead <= shead - 1;
			state <= SINSTR;
		end
		WAITDIV: begin
			do_div <= 0;
			if(!do_div && div_done) begin
				if(shead > 0)
					state <= SPOP;
				else state <= SINSTR;
				len <= len - 1;
				if(res_is_div) top <= quot;
				else top <= mod;
			end
		end
		SINSTR: begin
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
				case(sw2[2:0])
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
							state <= WAITDIV;
							do_div <= 1;
							res_is_div <= 1;
							error <= 0;
						end else error <= 1;
					3'b100:
						if(len > 1 && top != 0) begin
							state <= WAITDIV;
							do_div <= 1;
							res_is_div <= 0;
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
