`default_nettype none

module urand_7bit(
		  input wire 	    clk,
		  output wire [6:0] res
		  );

    //Should be odd (if is zero then results will be constant 0)
    localparam SEED = 7777;
    
    reg [3:0] d1 = SEED;
    reg [4:0] d2 = SEED;
    reg [5:0] d3 = SEED;
    reg [6:0] d4 = SEED;
    reg [8:0] d5 = SEED;
    reg [9:0] d6 = SEED;
    reg [10:0] d7 = SEED;

    assign res = {d1[0], d2[0], d3[0], d4[0], d5[0], d6[0], d7[0]};

    always @(posedge clk) begin
	d1 <= {d1[2:0], d1[3] ^ d1[2]};
	d2 <= {d2[3:0], d2[4] ^ d2[2]};
	d3 <= {d3[4:0], d3[5] ^ d3[4]};
	d4 <= {d4[5:0], d4[6] ^ d4[5]};
	d5 <= {d5[7:0], d5[8] ^ d5[4]};
	d6 <= {d6[8:0], d6[9] ^ d6[6]};
	d7 <= {d7[9:0], d7[10] ^ d7[8]};
    end
    
endmodule // urand_7bit

module display_vga (
		    input wire 	      clk,
		    output wire       HSYNC,
		    output wire       VSYNC,
		    output wire [2:0] VGAR,
		    output wire [2:0] VGAG,
		    output wire [2:1] VGAB,
		    input wire 	      pixel,
		    output wire [9:0] read_h,
		    output wire [8:0] read_v,
		    output wire       next_frame,
		    output wire       next_line      
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
    
    assign HSYNC = (pos_h >= ACTIVE_H + FRONT_H) && (pos_h < ACTIVE_H + FRONT_H + SYNC_H);
    assign VSYNC = (pos_v >= ACTIVE_V + FRONT_V) && (pos_v < ACTIVE_V + FRONT_V + SYNC_V);
    assign VGAR = pixel ? 7 : 0;
    assign VGAG = pixel ? 7 : 0;
    assign VGAB = pixel ? 3 : 0;
    assign read_h = pos_h < ACTIVE_H ? pos_h : 0;
    assign read_v = pos_v < ACTIVE_V ? pos_v : 0;
    assign next_frame = pos_h == ACTIVE_H && pos_v == ACTIVE_V;
    assign next_line = pos_h == ACTIVE_H && !pos_v[0] && pos_v < ACTIVE_V - 2;

    always @(posedge clk) begin
	next_pxl <= !next_pxl;
	if(next_pxl) begin
	    if(pos_h == MAX_H - 1) begin
		pos_h <= 0;
		if(pos_v == MAX_V - 1) begin
		    pos_v <= 0;
		end else pos_v <= pos_v + 1;
	    end else pos_h  <= pos_h + 1;
	end
	
    end // always @ (posedge clk)

endmodule // display_vga

module sprites(
	       input wire 	clk,
	       input wire [3:0] sprite,
	       input wire [6:0] sprite_x,
	       input wire [3:0] sprite_y,
	       input wire 	do_read,
	       output wire 	pixel
	       );

    reg [3:0] sprites [0:4095];
    reg [11:0] sprite_start_x;
    reg [11:0] sprite_start_y;
    wire [11:0] read_id;
    reg [3:0]  read_out;

    assign pixel = read_out[3];
    
    initial begin
	$readmemh("sprites.hex", sprites, 0, 979);
	$readmemh("you_lost.hex", sprites, 1024, 2023);
	$readmemh("you_won.hex", sprites, 2048, 3047);
    end

    always @* begin
	case(sprite)
	  0: begin
	      sprite_start_x = 1;
	      sprite_start_y = 1;
	  end
	  1: begin
	      sprite_start_x = 10;
	      sprite_start_y = 1;
	  end
	  2: begin
	      sprite_start_x = 23;
	      sprite_start_y = 1;
	  end
	  3: begin
	      sprite_start_x = 1;
	      sprite_start_y = 10;
	  end
	  4: begin
	      sprite_start_x = 10;
	      sprite_start_y = 10;
	  end
	  5: begin
	      sprite_start_x = 23;
	      sprite_start_y = 10;
	  end
	  6: begin
	      sprite_start_x = 1;
	      sprite_start_y = 19;
	  end
	  7: begin
	      sprite_start_x = 17;
	      sprite_start_y = 19;
	  end
	  8: begin
	      sprite_start_x = 1024;
	      sprite_start_y = 0;
	  end
	  9: begin
	      sprite_start_x = 2048;
	      sprite_start_y = 0;
	  end
	  default: begin
	      sprite_start_x = 0;
	      sprite_start_y = 0;
	  end
	endcase // case (sprite)
    end

    assign read_id = sprite < 8 ? sprite_start_x + sprite_x + (sprite_start_y + sprite_y) * 35
		      : sprite_start_x + sprite_x + sprite_y * 100;

    always @(posedge clk) begin
	if(do_read) read_out <= sprites[read_id];
    end
    
endmodule // sprites

module cache_lines(
		   input wire 	    clk,
		   input wire [8:0] save_x,
		   input wire 	    save_y,
		   input wire 	    save_next,
		   input wire 	    save_pixel,
		   input wire [8:0] read_x, 
		   input wire 	    read_y,
		   input wire 	    read_next,
		   output wire 	    read_pixel
		   );
    
    reg pixels[639:0];
    reg read;

    wire [9:0] save_idx;
    wire [9:0] read_idx;
    
    assign save_idx = save_x + (save_y ? 320 : 0);
    assign read_idx = read_x + (read_y ? 320 : 0);
    assign read_pixel = read;

    always @(posedge clk) begin
	if(save_next) pixels[save_idx] <= save_pixel;
	if(read_next) read <= pixels[read_idx];
    end
    
endmodule // cache_lines

module game_memory(input wire clk,
		   input wire [5:0]   check_killed,
		   input wire [5:0]   kill_invader,
		   input wire 	      do_kill_invader,
		   input wire 	      reset_killed,
		   output wire 	      is_killed,
		   input wire [1:0]   shot_id,
		   output wire [8:0]  shot_x,
		   output wire [7:0]  shot_y,
		   output wire 	      is_shot, 
		   input wire 	      do_save_shot,
		   input wire [1:0]   save_shot_id,
		   input wire 	      delete_shot, 
		   input wire [8:0]   save_shot_x,
		   input wire [7:0]   save_shot_y,
		   input wire [1:0]   get_bunker_id,
		   output wire [27:0] bunker,
		   input wire [1:0]   set_bunker_id,
		   input wire 	      do_save_bunker,
		   input wire [27:0]  set_bunker 
		   );

    reg [54:0] killed_invaders;
    reg        kill_read_res;

    reg [1:0]  num_shots;
    reg [1:0]  cur_shot;
    reg [17:0]  shots [3:0];
    reg [17:0]  shot_read;
    wire       do_save;
    wire [8:0] save_x;
    wire [8:0] save_y;

    reg [27:0] bunkers [3:0];
    reg [27:0] bunker_read;

    integer    i;
    initial begin
	for(i=0;i<4;i=i+1)
	  bunkers[i] = (1 << 23) + (1 << 24) + (1 << 25);
    end

    assign is_killed = kill_read_res;
    assign shot_x = shot_read[8:0];
    assign shot_y = shot_read[16:9];
    assign is_shot = shot_read[17];
    assign bunker = bunker_read;

    always @(posedge clk) begin    
	kill_read_res <= killed_invaders[check_killed];
	if(do_kill_invader) begin
	    killed_invaders[kill_invader] <= ~reset_killed;
	end
	
	shot_read <= shots[shot_id];
	if(do_save_shot) begin
	    shots[save_shot_id] <= {~delete_shot, save_shot_y, save_shot_x};
	end
	
	bunker_read <= bunkers[get_bunker_id];
	if(do_save_bunker) begin
	    bunkers[set_bunker_id] <= set_bunker;
	end
    end

endmodule // game_memory
 
module game(
	    input wire 	     clk,
	    input wire 	     next_move,
	    input wire 	     next_line,
	    input wire [1:0] cannon_action,
	    input wire [8:0] read_x,
	    input wire [7:0] read_y,
	    output wire      pixel,
	    input wire 	     reset_game
	    );

    localparam MAX_MOVE_DELAY = 28;
    localparam FIRST_COLUMN = 4;
    localparam FIRST_ROW = 4;
    localparam LAST_COLUMN = 316;
    localparam LAST_ROW = 160;
    
    localparam STATE_WAIT = 0;
    localparam STATE_WRITE_LINE = 1;
    localparam STATE_CHECK_COLLISIONS = 2;
    localparam STATE_GAME_OVER = 3;
    localparam STATE_MOVE_SHOTS = 4;
    localparam STATE_RESET_GAME = 5;
    localparam STATE_BUNKER_COLISIONS = 6;
    localparam STATE_WON = 7;

    localparam SPRITE_BIG_ALIEN = 0;
    localparam SPRITE_MID_ALIEN = 1;
    localparam SPRITE_SMALL_ALIEN = 2;

    localparam DIRECTION_RIGHT = 0;
    localparam DIRECTION_LEFT = 1;
    localparam DIRECTION_DOWN = 2;

    localparam CANNON_NO_ACTION = 0;
    localparam CANNON_MOVE_LEFT = 1;
    localparam CANNON_MOVE_RIGHT = 2;
    localparam CANNON_SHOT = 3;

    localparam CANNON_POS_Y = 180;
    localparam BUNKER_POS_Y = 160;
    localparam BUNKER_WIDTH = 28;
    localparam BUNKER_HEIGHT = 16;
    localparam FIRST_BUNKER = 52;
    localparam LAST_BUNKER = 320 - 52;
    
    reg [2:0]  state = STATE_WAIT;

    reg signed [10:0]  first_invader_x = FIRST_COLUMN;
    reg [7:0]  first_invader_y = FIRST_ROW; 
    reg [5:0]  speed = 0;
    
    reg [5:0]  alien_move_cnt = MAX_MOVE_DELAY;
    reg [5:0]  cur_invader = 56;
    reg signed [10:0]  cur_invader_x;    
    reg [7:0]  cur_invader_y;

    reg [1:0]  moving_direction = DIRECTION_RIGHT;
    reg        updated_direction;
    
    reg signed [10:0]  cannon_pos_x = 150;

    localparam CANNON_SHOT_ID = 3;
    reg [1:0]  shot_id = 0;
    reg [2:0]  shot_id1 = 0;
    wire [8:0] shot_x;
    wire [7:0] shot_y;
    wire       is_shot;
    reg [1:0]  save_shot_id;
    reg        do_save_shot;
    reg [8:0]  save_shot_x;
    reg [7:0]  save_shot_y;
    reg        delete_shot;
    reg [6:0]  shot_next_pixels = 0;

    localparam CANNON_ACTION_MAX_DELAY = 1000000;
    reg [31:0] cannon_action_delay = 0;
    reg        cannon_do_shot = 0;
    
//    reg [5:0]  next_kill = 7;
    
    wire [8:0] rel_write_x;
    wire [7:0] rel_write_y;
    wire [4:0] write_alien_x;
    wire [3:0] write_alien_y;
    wire [3:0] write_sprite_x;
    wire [3:0] write_sprite_y;
    wire [8:0] rel_write_next_x;
    wire [8:0] write_alien_next_x;
    
    reg [5:0]  check_killed = 0;
    reg [5:0]  kill_invader;
    reg        do_kill_invader = 0;
    wire       is_killed;
    reg        is_invader = 0;
    reg        is_invader1 = 0;
    wire       reset_kill;
    assign reset_kill = state == STATE_RESET_GAME;

    reg [2:0]   get_bunker_id;
    wire [27:0] bunker;
    reg [2:0] 	set_bunker_id;
    reg 	do_save_bunker = 0;
    reg [27:0] 	set_bunker;

    reg [1:0] 	bunker_col_state;

    reg [3:0]	cur_bunker_no = 0;
    reg [8:0] 	cur_bunker_x = 0;
    reg [3:0] 	cur_bunker_y;

    wire [6:0] random_bits;
    reg [3:0]  random_pos_x;
    reg [2:0]  random_pos_y;
    reg [3:0]  random_pos_x1;
    reg [2:0]  random_pos_y1;
    wire [3:0] rand_to_pos_x;
    wire [2:0] rand_to_pos_y;

    assign rand_to_pos_x = (random_bits[3:0] ^ cannon_pos_x[3:0]) < 11 ? 
			   random_bits[3:0] ^ cannon_pos_x[3:0] : 
			   (random_bits[3:0] ^ cannon_pos_x[3:0]) - 11;
    assign rand_to_pos_y = (random_bits[6:4] ^ cannon_pos_x[6:4]) < 5 ?
			   random_bits[6:4] ^ cannon_pos_x[6:4] :
			   (random_bits[6:4] ^ cannon_pos_x[6:4]) - 5;

    urand_7bit urand(
		     .clk(clk),
		     .res(random_bits)
		     );

    localparam SPRITE_SMALL = 0;
    localparam SPRITE_BIG = 1;
    localparam SPRITE_MED = 2;
    localparam SPRITE_CANNON = 6;
    localparam SPRITE_UFO = 7;
    localparam SPRITE_LOST = 8;
    localparam SPRITE_WON = 9;

    reg [3:0]  sprite_type;
    reg [6:0]  sprite_x;
    reg [3:0]  sprite_y;
    wire       sprite_pixel;
    reg        sprite_switch = 0;

    sprites sprites_inst(
	        	 .clk(clk),
			 .sprite(sprite_type),
			 .sprite_x(sprite_x),
			 .sprite_y(sprite_y),
	        	 .pixel(sprite_pixel),
			 .do_read(1)
			 );
    
    game_memory game_memory_inst(.clk(clk),
				 .check_killed(check_killed),
				 .kill_invader(kill_invader),
				 .do_kill_invader(do_kill_invader),
				 .reset_killed(reset_kill),
				 .is_killed(is_killed),
				 .shot_id(shot_id),
				 .shot_x(shot_x),
				 .shot_y(shot_y),
				 .is_shot(is_shot),
				 .do_save_shot(do_save_shot),
				 .save_shot_id(save_shot_id),
				 .delete_shot(delete_shot),
				 .save_shot_x(save_shot_x),
				 .save_shot_y(save_shot_y),
				 .get_bunker_id(get_bunker_id),
				 .bunker(bunker),
				 .set_bunker_id(set_bunker_id),
				 .do_save_bunker(do_save_bunker),
				 .set_bunker(set_bunker)
				 );

    reg        save_next = 0;
    reg        save_pixel;
    reg signed [10:0]  write_x = 0;
    wire [7:0]  write_y;
    assign write_y = read_y + 1;

    wire 	cache_pixel;
    reg 	is_pixel;
    reg 	is_sprite;
    reg 	is_pixel1;
    reg 	is_sprite1;

    cache_lines cache_lines_inst(.clk(clk),
				 .save_x(write_x >= 1 ? write_x - 1 : 0),
				 .save_y(write_y[0]),
				 .save_next(save_next),
				 .save_pixel(save_pixel),
				 .read_x(read_x),
				 .read_y(read_y[0]),
				 .read_next(1),
				 .read_pixel(cache_pixel)
				 );

    assign pixel = state == STATE_WON || state == STATE_GAME_OVER ? sprite_pixel : cache_pixel;
    
    assign rel_write_x = write_x - first_invader_x;
    assign rel_write_y = write_y - first_invader_y;
    assign write_alien_x = rel_write_x >> 4;
    assign write_alien_y = rel_write_y >> 4;
    assign write_sprite_x = rel_write_x[3:0];
    assign write_sprite_y = rel_write_y[3:0];

    assign rel_write_next_x = write_x + 2 - first_invader_x;
    assign write_alien_next_x = rel_write_next_x >> 4;

    wire [4:0] 	shot_top_to_bunker_pos;
    wire [4:0] 	shot_bot_to_bunker_pos;
    assign shot_top_to_bunker_pos = ((shot_x - cur_bunker_x) >> 2) + 
				    ((shot_y - BUNKER_POS_Y) >> 2) * 7;
    assign shot_bot_to_bunker_pos = ((shot_x - cur_bunker_x) >> 2) + 
				    ((shot_y + 4 - BUNKER_POS_Y) >> 2) * 7;

    always @(posedge clk) begin

	do_save_shot <= 0;
	case (state)
	  STATE_WAIT: begin
	      check_killed <= rand_to_pos_x + rand_to_pos_y * 11;
	      random_pos_x <= rand_to_pos_x;
	      random_pos_y <= rand_to_pos_y;
	      random_pos_x1 <= random_pos_x;
	      random_pos_y1 <= random_pos_y;
	      if(next_move) begin
		  if(alien_move_cnt == 0) begin
		      alien_move_cnt <= MAX_MOVE_DELAY - (speed >> 1);
		      case(moving_direction)
			DIRECTION_RIGHT: begin
			    first_invader_x <= first_invader_x + 2;
			end
			DIRECTION_LEFT: begin
			    first_invader_x <= first_invader_x - 2;
			end
			DIRECTION_DOWN: begin
			    first_invader_y <= first_invader_y + 8;
			end
		      endcase // case (moving_direction)
		      updated_direction <= 0;
		      sprite_switch <= ~sprite_switch;
		  end else alien_move_cnt <= alien_move_cnt - 1; // if (alien_move_cnt == 0)
		  shot_id <= 1;
		  state <= STATE_MOVE_SHOTS;
	      end
	      if(next_line) begin
		  write_x <= 0;
		  get_bunker_id <= 0;
		  //write_y <= write_y + 1;
		  state <= STATE_WRITE_LINE;
		  // There wont be any invider with x=0 so don't have to query memory here
		  is_invader <= 0;
	      end
	  end // case: STATE_WAIT
	  STATE_MOVE_SHOTS: begin
	      check_killed <= rand_to_pos_x + rand_to_pos_y * 11;
	      random_pos_x <= rand_to_pos_x;
	      random_pos_y <= rand_to_pos_y;
	      random_pos_x1 <= random_pos_x;
	      random_pos_y1 <= random_pos_y;
	      if(shot_id1 <= 3) begin
		  if(is_shot) begin
		      if((shot_y < 192 && shot_id1 != CANNON_SHOT_ID) 
			 || (shot_y > 1 && shot_id1 == CANNON_SHOT_ID)) begin
			  save_shot_x <= shot_x;
			  save_shot_y <= shot_y + (shot_id1 != CANNON_SHOT_ID ? 2 : -2);
			  delete_shot <= 0;
			  do_save_shot <= 1;
		      end else begin
			  delete_shot <= 1;
			  do_save_shot <= 1;
		      end
		      if(shot_id1 == CANNON_SHOT_ID) cannon_do_shot <= 0;
		  end else if(shot_id1 == CANNON_SHOT_ID) begin // if (is_shot)
		      if(cannon_do_shot) begin
			  save_shot_x <= cannon_pos_x + 7;
			  save_shot_y <= CANNON_POS_Y + 4;
		 	  delete_shot <= 0;
			  do_save_shot <= 1;
			  cannon_do_shot <= 0;
		      end
		  end else begin
		      if(random_bits[5:0] == 0 && !is_killed) begin
			  save_shot_x <= first_invader_x + (random_pos_x1 << 4) + 6;
			  save_shot_y <= first_invader_y + (random_pos_y1 << 4) + 12;
			  do_save_shot <= 1;
			  delete_shot <= 0;
		      end 
		  end

		  shot_id1 <= shot_id1 + 1;
		  shot_id <= shot_id + 1;
		  save_shot_id <= shot_id1;
	      end else begin // if (shot_id1 <= 3)
		  shot_id <= 0;		  
		  shot_id1 <= 0;
		  state <= STATE_CHECK_COLLISIONS;
	      end // else: !if(shot_id1 <= 3)
	  end // case: STATE_MOVE_SHOTS
	  STATE_WRITE_LINE: begin
	      shot_id <= shot_id + 1;
	      if(shot_id1 < 2) begin
		  if(is_shot && shot_x > write_x && shot_x <= write_x + 6
		     && write_y >= shot_y && write_y < shot_y + 4) begin
		      shot_next_pixels[shot_x - write_x] <= 1;
		  end
		  if(shot_id == 3) shot_id1 <= shot_id1 + 1;
	      end else if(write_x < 320) begin
		  //Prefetch
		  if(write_y >= first_invader_y && write_y < first_invader_y + 16*5
		     && write_x + 2 >= first_invader_x 
		     && write_x + 2 < first_invader_x + 16*11) begin
		      is_invader1 <= 1;
		      check_killed <= write_alien_next_x + write_alien_y * 11;
		  end else is_invader1 <= 0;
		  is_invader <= is_invader1;
		  is_sprite <= 0;

		  //Sprites
		  if(is_invader && !is_killed && write_sprite_y >= 8) begin
		      sprite_y <= write_sprite_y - 8;
		      if(write_sprite_x < 12 && write_alien_y > 0) begin
			  sprite_type <= (write_alien_y > 2 ? SPRITE_BIG : SPRITE_MED)
			    + (sprite_switch ? 3 : 0);
			  sprite_x <= write_sprite_x;
			  is_sprite <= 1;
		      end else if(write_sprite_x >= 2 && write_sprite_x < 10) begin
			  sprite_type <= SPRITE_SMALL + (sprite_switch ? 3 : 0);
			  sprite_x <= write_sprite_x - 2;
			  is_sprite <= 1;
		      end
		  end else if(write_y >= CANNON_POS_Y && write_y < CANNON_POS_Y + 8
			  && write_x >= cannon_pos_x && write_x < cannon_pos_x + 15) begin
		      sprite_type <= SPRITE_CANNON;
		      sprite_x <= write_x - cannon_pos_x;
		      sprite_y <= write_y - CANNON_POS_Y;
		      is_sprite <= 1;
		  end

		  //Shots & bunkers
		  if(shot_next_pixels[0])
		    is_pixel <= 1;
		  else if(write_y >= BUNKER_POS_Y && write_y < BUNKER_POS_Y + BUNKER_HEIGHT
			  && write_x >= FIRST_BUNKER && write_x < LAST_BUNKER && cur_bunker_no[0] 
			  && !bunker[(cur_bunker_x >> 2) + ((write_y - BUNKER_POS_Y) >> 2) * 7])
		    is_pixel <= 1;
		  else is_pixel <= 0;
		  
		  write_x <= write_x + 1;
		  if(is_shot && shot_x > write_x && shot_x <= write_x + 7
		     && write_y >= shot_y && write_y < shot_y + 4) begin
		      shot_next_pixels <= (shot_next_pixels >> 1) | (1 << (shot_x - write_x - 1));
		  end else shot_next_pixels <= shot_next_pixels >> 1;

		  if(write_x == FIRST_BUNKER - 1) begin
		      cur_bunker_no <= 1;
		      cur_bunker_x <= 0;
		  end else if(write_x >= FIRST_BUNKER) begin
		      if(cur_bunker_x < BUNKER_WIDTH - 1) begin
			  cur_bunker_x <= cur_bunker_x + 1;
			  if(cur_bunker_x == BUNKER_WIDTH - 2)
			    get_bunker_id <= (cur_bunker_no + 1) >> 1;
		      end else begin
			  cur_bunker_x <= 0;
			  cur_bunker_no <= cur_bunker_no + 1;
		      end
		  end
		      
		  is_pixel1 <= is_pixel;
		  is_sprite1 <= is_sprite;
		  save_pixel <= is_pixel1 || (is_sprite1 && sprite_pixel);
		  save_next <= 1;
	      end else begin
		  state <= STATE_WAIT;
		  save_next <= 0;
		  is_invader <= 0;
		  shot_id <= 0;
		  shot_id1 <= 0;
		  shot_next_pixels <= 0;
		  cur_bunker_x <= 0;
		  cur_bunker_no <= 0;
	      end
	  end // case: STATE_WRITE_LINE
	  STATE_CHECK_COLLISIONS: begin
	      //Need 2 cycles to get result from ram
	      if(cur_invader == 56) begin
		  cur_invader <= 57;
		  check_killed <= 0;
		  shot_id <= CANNON_SHOT_ID;
		  save_shot_id <= CANNON_SHOT_ID;
	      end else if(cur_invader == 57) begin
		  cur_invader_x <= first_invader_x;
		  cur_invader_y <= first_invader_y;
		  cur_invader <= 0;
		  check_killed <= 1;
	      end else if(cur_invader < 55) begin
		  if(!is_killed) begin
		      //Collision with screen edges
		      if(!updated_direction) begin
			  if(cur_invader_x <= FIRST_COLUMN 
			     || cur_invader_x >= LAST_COLUMN - 16) begin
			      updated_direction <= 1;
			      if(moving_direction == DIRECTION_DOWN)
				if(cur_invader_x <= FIRST_COLUMN)
				  moving_direction <= DIRECTION_RIGHT;
				else moving_direction <= DIRECTION_LEFT;
			      else moving_direction <= DIRECTION_DOWN;
			  end
		      end // if (!updated_direction)
		      if(cur_invader_y + 16 >= LAST_ROW) state <= STATE_GAME_OVER;
		      
		      //Collision with bullet
		      if(is_shot && shot_y + 4 >= cur_invader_y + 8 && shot_y < cur_invader_y + 16
			 && ((shot_x >= cur_invader_x + 2 && shot_x < cur_invader_x + 10) 
			     || (shot_x >= cur_invader_x + 1 && shot_x < cur_invader_x + 11 
				 && cur_invader > 10) 
			     || (shot_x >= cur_invader_x && shot_x < cur_invader_x + 12 
				 && cur_invader > 32))) begin
			  kill_invader <= cur_invader;
			  do_kill_invader <= 1;
			  speed <= speed + 1;
			  do_save_shot <= 1;
			  delete_shot <= 1;
			  if(speed == 54) state <= STATE_WON;
		      end else begin
			  do_kill_invader <= 0;
			  do_save_shot <= 0;
		      end
		  end // if (!is_killed)
		  cur_invader <= cur_invader + 1;
		  check_killed <= check_killed + 1;
		  if(cur_invader_x == first_invader_x + 10*16) begin
		      cur_invader_x <= first_invader_x;
		      cur_invader_y <= cur_invader_y + 16;
		  end else cur_invader_x <= cur_invader_x + 16;
		  if(cur_invader == 53) shot_id <= 0;
		  else if(cur_invader == 54) begin
		      shot_id <= 1;
		      shot_id1 <= 0;
		  end
	      end else if(shot_id1 != CANNON_SHOT_ID) begin
		  if(is_shot && shot_y + 4 >= CANNON_POS_Y && shot_y < CANNON_POS_Y + 8
		     && shot_x >= cannon_pos_x && shot_x < cannon_pos_x + 15) begin
		      state <= STATE_GAME_OVER;
		  end else do_save_shot <= 0;
		  shot_id1 <= shot_id1 + 1;
		  shot_id <= shot_id + 1;
	      end else begin // if (cur_invader < 55)
		  cur_invader <= 56;
		  check_killed <= 0;
		  write_x <= 0;
		  shot_id <= 0;
		  shot_id1 <= 0;
		  get_bunker_id <= 0;
		  state <= STATE_BUNKER_COLISIONS;
 	      end 	      
	  end // case: STATE_CHECK_COLLISIONS
	  STATE_BUNKER_COLISIONS: begin
	      if(shot_id == 0 && shot_id1 == 0) begin
		  shot_id <= 1;
		  cur_bunker_x <= FIRST_BUNKER;
		  cur_bunker_no <= 0;
	      end else if(cur_bunker_no >= 4) begin
		  shot_id <= 0;
		  shot_id1 <= 0;
		  get_bunker_id <= 0;
		  do_save_bunker <= 0;
		  state <= STATE_WRITE_LINE;
	      end else if(shot_id1 <= 3) begin
		  if(is_shot && shot_y + 4 >= BUNKER_POS_Y && shot_y < BUNKER_POS_Y + BUNKER_HEIGHT
		     && shot_x >= cur_bunker_x && shot_x < cur_bunker_x + BUNKER_WIDTH) begin
		      if(shot_y >= BUNKER_POS_Y && !bunker[shot_top_to_bunker_pos]) begin
			  save_shot_id <= shot_id1;
			  do_save_shot <= 1;
			  delete_shot <= 1;
			  do_save_bunker <= 1;
			  set_bunker_id <= cur_bunker_no;
			  set_bunker <= bunker | (1 << shot_top_to_bunker_pos);
		      end else if(shot_y + 4 < BUNKER_POS_Y + BUNKER_HEIGHT 
				  && !bunker[shot_bot_to_bunker_pos]) begin
			  save_shot_id <= shot_id1;
			  do_save_shot <= 1;
			  delete_shot <= 1;
			  do_save_bunker <= 1;
			  set_bunker_id <= cur_bunker_no;
			  set_bunker <= bunker | (1 << shot_bot_to_bunker_pos);
		      end else begin 
			  do_save_bunker <= 0;
		      end
		  end // if (is_shot && shot_y + 4 >= BUNKER_POS_Y...
		  shot_id <= shot_id + 1;
		  shot_id1 <= shot_id1 + 1;
		  if(shot_id1 == 2) begin
		      get_bunker_id <= get_bunker_id + 1;
		  end else if(shot_id1 == 3) begin
		      cur_bunker_no <= cur_bunker_no + 1;
		      shot_id1 <= 0;
		      cur_bunker_x <= cur_bunker_x + (BUNKER_WIDTH << 1);
		  end
	      end // if (shot_id1 <= 3)
	  end // case: STATE_BUNKER_COLISIONS
	  STATE_GAME_OVER: begin
	      sprite_type <= SPRITE_LOST;
	      if(read_x >= 120 && read_x < 220 && read_y >= 90 && read_y < 100) begin
		  sprite_x <= read_x - 120;
		  sprite_y <= read_y - 90;
	      end else begin
		  sprite_x <= 99;
		  sprite_y <= 0;
	      end
	  end
	  STATE_WON: begin
	      sprite_type <= SPRITE_WON;
	      if(read_x >= 120 && read_x < 220 && read_y >= 90 && read_y < 100) begin
		  sprite_x <= read_x - 120;
		  sprite_y <= read_y - 90;
	      end else begin
		  sprite_x <= 99;
		  sprite_y <= 0;
	      end
	  end
	  STATE_RESET_GAME: begin
	      if(kill_invader < 54) begin
		  kill_invader <= kill_invader + 1;
	      end else if(save_shot_id < 3) begin
		  save_shot_id <= save_shot_id + 1;
		  do_save_shot <= 1;
	      end else if(set_bunker_id < 4) begin
		  do_save_bunker <= 1;
		  set_bunker_id <= set_bunker_id + 1;
	      end else begin
		  state <= STATE_WAIT;
		  do_kill_invader <= 0;
		  kill_invader <= 1;
		  save_shot_id <= 0;
		  delete_shot <= 0;
		  do_save_bunker <= 0;
	      end
	  end
	endcase // case (state)

	if(cannon_action_delay == 0) begin
	  case (cannon_action)
	    CANNON_MOVE_LEFT: begin
		if(cannon_pos_x >= FIRST_COLUMN) cannon_pos_x <= cannon_pos_x - 1;
		cannon_action_delay <= CANNON_ACTION_MAX_DELAY;
	    end
	    CANNON_MOVE_RIGHT: begin
		if(cannon_pos_x < LAST_COLUMN - 20) cannon_pos_x <= cannon_pos_x + 1;
		cannon_action_delay <= CANNON_ACTION_MAX_DELAY;
	    end
	    CANNON_SHOT: begin
		cannon_do_shot <= 1;
		cannon_action_delay <= CANNON_ACTION_MAX_DELAY;
	    end
	  endcase // case (cannon_action)
	end else cannon_action_delay <= cannon_action_delay - 1; // if (cannon_action_delay == 0)

	if(reset_game || ((state == STATE_GAME_OVER || state == STATE_WON) 
			  && cannon_action == CANNON_SHOT)) begin
	    state <= STATE_RESET_GAME;
	    first_invader_x <= FIRST_COLUMN;
	    first_invader_y <= FIRST_ROW; 
	    speed <= 0;
	    alien_move_cnt <= MAX_MOVE_DELAY;
	    cur_invader <= 56;
	    moving_direction <= DIRECTION_RIGHT;
	    updated_direction <= 1;

	    kill_invader <= 0;
	    do_kill_invader <= 1;
	    save_shot_id <= 0;
	    do_save_shot <= 1;
	    delete_shot <= 1;
	    cannon_pos_x <= 150;
	    do_save_bunker <= 1;
	    set_bunker_id <= 0;
	    set_bunker <=  (1 << 23) + (1 << 24) + (1 << 25); //Initial bunker state
	end
    	    
    end // always @ (posedge clk)
    
endmodule // game

module space_invaders (
		       input wire 	 uclk,
		       input wire [3:0]  btn,
		       //input wire [7:0]  sw,
		       output wire [7:0] led,
		       output wire 	 HSYNC,
		       output wire 	 VSYNC,
		       output wire [2:0] VGAR,
		       output wire [2:0] VGAG,
		       output wire [2:1] VGAB,
		       input wire 	 PS2C,
		       input wire 	 PS2D
		       );

    wire clk;
   // 32MHZ * 11/7 = ~25.175MHZ * 2
    DCM_SP #(
	     .CLKFX_DIVIDE(7),
	     .CLKFX_MULTIPLY(11)
	     ) moj_dcm (
			.CLKIN(uclk),
			.CLKFX(clk),
			.RST(1'b0)
			);
    
    localparam CANNON_NO_ACTION = 0;
    localparam CANNON_MOVE_LEFT = 1;
    localparam CANNON_MOVE_RIGHT = 2;
    localparam CANNON_SHOT = 3;

    reg [1:0] cannon_action = CANNON_NO_ACTION;

    reg       reset_game = 0;

    reg [3:0] btn1 = 0;
    reg [3:0] btn2 = 0;
    reg [3:0] btn3 = 0;

    reg [10:0] key;
    reg [3:0]  key_cnt;
    reg        key_dissynch = 0;
    reg        key_clk = 1;
    reg        key_clk1 = 1;
    reg        key_clk2 = 1;
    reg        key_clk3 = 1;
    reg        key_data;
    reg        key_data1;
    reg        key_data2;
    reg        is_a = 0;
    reg        is_d = 0;
    reg        different_key;
    reg        long_char = 0;

    reg [7:0]  last_key_dbg;
    
    always @(posedge clk) begin
	btn1 <= btn;
	btn2 <= btn1;
	btn3 <= btn2;
	if(btn3[0] || is_d) cannon_action <= CANNON_MOVE_RIGHT;
	else if(btn3[3] || is_a) cannon_action <= CANNON_MOVE_LEFT;
	else if((btn2[1] || btn2[2]) && !(btn3[1] || btn3[2])) cannon_action <= CANNON_SHOT;
	else cannon_action <= CANNON_NO_ACTION;

	if(btn3[0] && btn3[1] && btn3[3]) reset_game <= 1;
	else reset_game <= 0;
	
	key_clk <= PS2C;
	key_clk1 <= key_clk;
	key_clk2 <= key_clk1;
	key_clk3 <= key_clk2;
	key_data <= PS2D;
	key_data1 <= key_data;
	key_data2 <= key_data1;
	if(!key_clk2 && key_clk3) begin
	    key_dissynch <= 0;
	    if(key_cnt == 0 && key_data2 == 1) key_dissynch <= 1;
	    else if(key_cnt == 10) begin
		if(key_data2 == 0) key_dissynch <= 1;
		else begin
		    key_cnt <= 0;
		    different_key <= 0;
		    last_key_dbg <= key[8:1];
		    case (key[8:1])
		      8'h29: begin//8'h39: //SPACE
			  cannon_action <= CANNON_SHOT;
			  long_char <= 0;
		      end
		      8'h1C: begin //8'h1E: //A press
			  if(long_char)
			    is_a <= 0;
			  else
			    is_a <= 1;
			  long_char <= 0;
		      end
		      8'h23: begin//8'h20: //D press
			  if(long_char)
			    is_d <= 0;
			  else
			    is_d <= 1;
			  long_char <= 0;
		      end
		      8'hF0: begin
			  long_char <= 1;
		      end
		      default:
			different_key <= 1;
		    endcase // case (key[8:1])
		    key <= 0;
		end
	    end else begin
		key[key_cnt] <= key_data2;
		key_cnt <= key_cnt + 1;
	    end
	end
    end
    
    wire [9:0] read_h;
    wire [8:0] read_v;
    wire       do_read;
    wire       read_res;
    wire       do_write;
    wire [8:0] write_x;
    wire [7:0] write_y;
    wire       write;
    wire       next_frame;
    wire       next_line;
    
    /*blockram ram(
		.clk(clk),
		.do_read(do_read),
		.read_x(read_h >> 1),
		.read_y(read_v >> 1),
		.read_res(read_res),
		.do_write(do_write),
		.write_x(write_x),
		.write_y(write_y),
		.write(write)
		);*/

    display_vga display_inst(
			     .clk(clk),
			     .HSYNC(HSYNC),
			     .VSYNC(VSYNC),
			     .VGAR(VGAR),
			     .VGAG(VGAG),
			     .VGAB(VGAB),
			     .pixel(read_res),
			     .read_h(read_h),
			     .read_v(read_v),
			     .next_frame(next_frame),
			     .next_line(next_line)
			     );

    game game_inst(
		   .clk(clk),
		   .next_move(next_frame),
		   .next_line(next_line),
		   .cannon_action(cannon_action),
		   .read_x(read_h >> 1),
		   .read_y(read_v >> 1),
		   .pixel(read_res),
		   .reset_game(reset_game)
		   );
    
endmodule // space_invaders
