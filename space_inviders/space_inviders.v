`default_nettype none

module display_vga (
		    input wire 	      clk,
		    output wire       HSYNC,
		    output wire       VSYNC,
		    output reg [2:0]  VGAR,
		    output reg [2:0]  VGAG,
		    output reg [2:1]  VGAB,
		    input wire 	      pixel,
		    output wire       read,
		    output wire [9:0] read_h,
		    output wire [8:0] read_v
		    );

    localparam ACTIVE_H =  640;
    localparam FRONT_H = 16;
    localparam SYNC_H = 96;
    localparam BACK_H = 48;
    localparam ACTIVE_V =  400;
    localparam FRONT_V = 12;
    localparam SYNC_V = 2;
    localparam BACK_V = 35;

    localparam MAX_V = ACTIVE_V + FRONT_V + SYNC_V + BACK_V;
    localparam MAX_H = ACTIVE_H + FRONT_H + SYNC_H + BACK_H;

    reg [9:0] pos_h = 0;
    reg [8:0] pos_v = 0;
    reg       next_pxl;
    reg       read1;      
    
    assign read = (pos_h < ACTIVE_H) && (pos_v < ACTIVE_V);
    assign HSYNC = (pos_h >= ACTIVE_H + FRONT_H) && (pos_h < ACTIVE_H + FRONT_H + SYNC_H);
    assign VSYNC = (pos_v >= ACTIVE_V + FRONT_V) && (pos_v < ACTIVE_V + FRONT_V + SYNC_V);
    assign VGAR = (read1 && pixel) ? 7 : 0;
    assign VGAG = (read1 && pixel) ? 7 : 0;
    assign VGAB = (read1 && pixel) ? 3 : 0;

    always @(posedge clk) begin
	next_pxl <= !next_pxl;
	if(next_pxl) begin
	    if(pos_h == MAX_H - 1) begin
		pos_h <= 0;
		if(pos_v == MAX_V - 1) begin
		    pos_v <= 0;
		end else pos_v <= pos_v - 1;
	    end else pos_h  <= pos_h + 1;
	end
	
	read1 <= read;	
    end // always @ (posedge clk)

endmodule; // display_vga

module blockram(
		input wire 	 clk,
		input wire 	 do_read,
		input wire [8:0] read_x,
		input wire [7:0] read_y,
		output reg 	 read_res,
		input wire 	 do_write,
		input wire [8:0] write_x,
		input wire [7:0] write_y,
		input wire 	 write
		);
    
    localparam BR_SIZE = 1024*16 - 1;
    
    reg ram1 [BR_SIZE:0];
    reg ram2 [BR_SIZE:0];
    reg ram3 [BR_SIZE:0];
    reg ram4 [BR_SIZE:0];

    wire [13:0] read_addr;
    wire [13:0] write_addr;
    wire [2:0] 	read_ram;
    wire [2:0] 	write_ram;

    assign read_addr = (read_x >> 2) + (read_y << 7);
    assign read_ram = {~do_read, read_x[1:0]};
    assign write_addr = (write_x >> 2) + (write_y << 7);
    assign write_ram = {~do_write, write_x[1:0]};

    always @(posedge clk) begin
	case (read_ram)
	  0 : read_res <= ram1[read_addr];
	  1 : read_res <= ram2[read_addr];
	  2 : read_res <= ram3[read_addr];
	  3 : read_res <= ram4[read_addr];
	endcase // case (read_ram)
	case (write_ram)
	  0: ram1[write_addr] <= write;
	  1: ram2[write_addr] <= write;
	  2: ram3[write_addr] <= write;
	  3: ram4[write_addr] <= write;
	endcase // case (write_ram)
    end // always @ (posedge clk)

endmodule; // blockram

module game(
	    input wire 	      clk,
	    input wire 	      draw,
	    output wire       do_write,
	    output wire [8:0] write_x,
	    output wire [7:0] write_y,
	    output reg 	      write
	    );

    localparam MAX_MOVE_DELAY = 50;
    localparam FIRST_COLUMN = 4;
    localparam FIRST_ROW = 20;
    localparam LAST_COLUMN = 320 - 4;
    localparam LAST_ROW = 180;
    
    localparam STATE_INIT = 0;
    localparam STATE_WAIT = 1;
    localparam STATE_DRAW_SPRITE = 2;
    localparam STATE_REDRAW = 3;
    localparam STATE_MOVE_ALIENS = 4;
    localparam STATE_GAME_OVER = 5;

    localparam SPRITE_BIG_ALIEN = 0;
    localparam SPRITE_MID_ALIEN = 1;
    localparam SPRITE_SMALL_ALIEN = 2;

    localparam DIRECTION_RIGHT = 0;
    localparam DIRECTION_LEFT = 1;
    localparam DIRECTION_DOWN = 2;
    
    reg [2:0]  state = STATE_INIT;
    reg        is_init = 1;
   
    reg [8:0]  inviders_x [54:0];
    reg [7:0]  inviders_y [54:0];
    reg        killed_inviders [54:0];
    reg [5:0]  speed = 0;
    
    reg [5:0]  nxt_move <= MAX_MOVE_DELAY;
    reg [5:0]  cur_invader = 0;
    reg [1:0]  cur_sprite = SPRITE_SMALL_ALIEN;
    reg [8:0]  sprite_x = FIRST_COLUMN + 16*11;
    reg [7:0]  sprite_y = FIRST_ROW - 16;
    reg [3:0]  draw_x = 0;
    reg [3:0]  draw_y = 0;
    reg [1:0]  moving_direction = DIRECTION_RIGHT;
    reg [1:0]  nxt_mov_dir; 

    assign do_write = state == STATE_DRAW_SPRITE;
    assign write_x = sprite_x + draw_x;
    assign write_y = sprite_y + draw_y;
    
    always @(posedge clk) begin
	case (state)
	  STATE_INIT : begin
	      if(cur_invader < 55) begin
		  if(sprite_x + 16 >= FIRST_COLUMN + 16*11) begin
		      sprite_x <= FIRST_COLUMN;
		      sprite_y <= sprite_y + 16;
		      inviders_x[cur_invider] <= FIRST_COLUMN;
		      inviders_y[cur_invider] <= sprite_y + 16;
		      if(cur_invider >= 33) cur_sprite <= SPRITE_BIG_ALIEN;
		      else if(cur_invider >= 11) cur_sprite <= SPRITE_MID_ALIEN;
		  end else begin
		      sprite_x <= sprite_x + 16;
		      inviders_x[cur_invider] <= sprite_x + 16;
		      inviders_y[cur_invider] <= sprite_y;
		  end
		  cur_invider <= cur_invider + 1;
		  state <= STATE_DRAW_SPRITE;
	      end else begin // if (cur_invader < 55)
		  cur_invader <= 0;
		  is_init <= 0;
		  state <= STATE_WAIT;
	      end
	  end // case: STATE_INIT
	  STATE_WAIT: 
	    if(draw) state <= STATE_REDRAW;
	  STATE_DRAW_SPRITE: begin
	      case(cur_sprite)
		SPRITE_BIG_ALIEN: begin
		    if(draw_x < 12 && draw_y >= 8) write <= 1;
		    else write <= 0;
		end
		SPRITE_MID_ALIEN: begin
		    if(draw_x < 11 && draw_y >= 8) write <= 1;
		    else write <= 0;
		end
		SPRITE_SMALL_ALIEN: begin
		    if(draw_x < 8 && draw_y >= 8) write <= 1;
		    else write <= 0;
		end
	      endcase // case (cur_sprite)
	      if(draw_x == 15) begin
		  draw_x <= 0;
		  if(draw_y == 15) begin
		      draw_y <= 0;
		      if(is_init) state <= STATE_INIT;
		      else state <= STATE_REDRAW;
		  end else draw_y <= draw_y + 1;
	      end else draw_x <= draw_x + 1;
	  end // case: STATE_DRAW_SPRITE
	  STATE_REDRAW: begin
	      if(cur_invader < 55) begin
		  if(!killed_invaders[cur_invader]) begin
		      sprite_x <= invaders_x[cur_invader];
		      sprite_y <= invaders_y[cur_invader];
		      if(cur_invider >= 33) cur_sprite <= SPRITE_BIG_ALIEN;
		      else if(cur_invider >= 11) cur_sprite <= SPRITE_MID_ALIEN;
		      else cur_sprite <= SPRITE_SMALL_ALIEN;
		      state <= STATE_DRAW_SPRITE;
		  end
		  cur_invider <= cur_invider + 1;
	      end else begin
		  cur_invider <= 0;
		  if(nxt_move == 0) begin
		      nxt_move <= MAX_MOVE_DELAY - speed;
		      state <= STATE_MOVE_ALIENS;
		  end else begin
		      nxt_move <= nxt_move - 1;
		      state <= STATE_WAIT;
		  end
	      end // else: !if(cur_invader < 55)
	  end // case: STATE_REDRAW
	  STATE_MOVE_ALIENS: begin
	      if(cur_invader < 55) begin
		  if(!killed_invaders[cur_invader]) begin
		    case(moving_direction)
		      DIRECTION_RIGHT: begin
			  invaders_x[cur_invader] <= invaders_x[cur_invader] + 1;
			  if(invaders_x[cur_invader] + 1 == LAST_COLUMN) 
			    nxt_mov_dir <= DIRECTION_DOWN;
		      end
		      DIRECTION_LEFT: begin
			  invaders_x[cur_invader] <= invaders_x[cur_invader] - 1;
			  if(invaders_x[cur_invader] - 1 == FIRST_COLUMN)
			    nxt_mov_dir <= DIRECTION_DOWN;
		      end
		      DIRECTION_DOWN: begin
			  invaders_y[cur_invader] <= invaders_y[cur_invader] + 8;
			  if(invaders_y[cur_invader] == LAST_COLUMN)
			    state <= STATE_GAME_OVER;
		      end
		    endcase // case (moving_direction)
		  end
		  cur_invader <= cur_invader + 1;
	      end else begin // if (cur_invader < 55)
		  cur_invader <= 0;
		  state <= STATE_WAIT;
		  moving_direction <= nxt_mov_dir;
		  if(nxt_mov_dir == DIRECTION_DOWN)
		    nxt_mov_dir <= moving_direction == DIRECTION_RIGHT ? DIRECTION_LEFT 
				   : DIRECTION_RIGHT;
 	      end // else: !if(cur_invader < 55)
	  end // case: STATE_MOVE_ALIENS
	  STATE_GAME_OVER: begin
	  end
	endcase // case (state)
    end // always @ (posedge clk)

endmodule // game

module space_inviders (
		       input wire 	 uclk,
		       input wire [3:0]  btn,
		       input wire [7:0]  sw,
		       output wire [7:0] led,
		       output reg 	 HSYNC,
		       output reg 	 VSYNC,
		       output reg [2:0]  VGAR,
		       output reg [2:0]  VGAG,
		       output reg [2:1]  VGAB
		       );

    wire clk;
   // 32MHZ * 11/7 = ~25.175MHZ * 2
    DCM_SP #(
	     .CLKFX_DIVIDE(7),
	     .CLKFX_MULTIPLY(11)
	     ) moj_dcm (
			.CLKIN(uclk),
			.CLKFX(clk),
			.RST(0)
			);

    wire [8:0] read_h;
    wire [7:0] read_v;
    wire       do_read;
    wire       read_res;
    wire       do_write;
    wire [8:0] write_x;
    wire [7:0] write_y;
    wire       write;
    
    blockram ram(
		.clk(clk),
		.do_read(do_read),
		.read_x(read_h >> 1),
		.read_y(read_v >> 1),
		.read_res(read_res),
		.do_write(do_write),
		.write_x(write_x),
		.write_y(write_y),
		.write(write)
		);
    
    display_vga disp(
		    .clk(clk),
		    .HSYNC(HSYNC),
		    .VSYNC(VSYNC),
		    .VGAR(VGAR),
		    .VGAG(VGAG),
		    .VGAB(VGAB),
		    .pixel(read_res),
		    .read(do_read),
		    .read_h(read_h),
		    .read_v(read_v)
		    );

    game ggame(
	    .clk(clk),
	    .draw(~do_read),
	    .do_write(do_write),
	    .write_x(write_x),
	    .write_y(write_y),
	    .write(write)
	    );

endmodule // space_inviders
