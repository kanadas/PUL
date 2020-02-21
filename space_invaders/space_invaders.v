`default_nettype none

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

/*module blockram(
		input wire 	 clk,
		input wire 	 do_read,
		input wire [8:0] read_x,
		input wire [7:0] read_y,
		output wire 	 read_res,
		input wire 	 do_write,
		input wire [8:0] write_x,
		input wire [7:0] write_y,
		input wire 	 write
		);
    
    localparam BR_SIZE = 1024*16 - 1;
    
//    reg ram1 [BR_SIZE:0];
//    reg ram2 [BR_SIZE:0];
//    reg ram3 [BR_SIZE:0];
//    reg ram4 [BR_SIZE:0];

//    reg write_bit;
//    reg [0:0] read_bit;
  
    wire [3:0] read_bits;

    wire [13:0] read_addr;
    wire [13:0] write_addr;
    wire [3:0] 	read_ram;
    wire [3:0] 	write_ram;

    assign read_addr = (read_x + read_y * 320) >> 2;
    assign read_ram[0] = read_x[1:0] == 0 && do_read;
    assign read_ram[1] = read_x[1:0] == 1 && do_read;
    assign read_ram[2] = read_x[1:0] == 2 && do_read;
    assign read_ram[3] = read_x[1:0] == 3 && do_read;
    assign write_addr = (write_x + write_y * 320) >> 2;
    assign write_ram[0] = write_x[1:0] == 0 && do_write;
    assign write_ram[1] = write_x[1:0] == 1 && do_write;
    assign write_ram[2] = write_x[1:0] == 2 && do_write;
    assign write_ram[3] = write_x[1:0] == 3 && do_write;
    assign read_res = read_ram[0] ? read_bits[0] : (read_ram[1] ? read_bits[1] : 
						    (read_ram[2] ? read_bits[2] : read_bits[3]));
*/
/*    always @(posedge clk) begin
	case (read_ram)
	  0 : read_bit <= ram1[read_addr];
	  1 : read_bit <= ram2[read_addr];
	  2 : read_bit <= ram3[read_addr];
	  3 : read_bit <= ram4[read_addr];
	endcase // case (read_ram)
	read_res <= read_bit;
    end

    always @(posedge clk) begin
	write_bit <= write; //TODO
	case (write_ram)
	  0: ram1[write_addr] <= write_bit;
	  1: ram2[write_addr] <= write_bit;
	  2: ram3[write_addr] <= write_bit;
	  3: ram4[write_addr] <= write_bit;
	endcase // case (write_ram)
    end // always @ (posedge clk)
*/

//    assign read_res = read_bit;
/*
    RAMB16_S1_S1 RAMB16_S1_S1_inst1(.DOA(read_bits[0]),//PortA1-bitDataOutput
				    //.DOB(DOB),//PortB1-bitDataOutput
				    .ADDRA(read_addr),//PortA14-bitAddressInput
				    .ADDRB(write_addr),//PortB14-bitAddressInput
				    .CLKA(clk),//PortAClock
				    .CLKB(clk),//PortBClock
				    //.DIA(DIA),//PortA1-bitDataInput
				    .DIB(write),//PortB1-bitDataInput
				    .ENA(read_ram[0]),//PortARAMEnableInput
				    .ENB(write_ram[0]),//PortBRAMEnableInput
				    .SSRA(0),//PortASynchronousSet/ResetInput
				    .SSRB(0),//PortBSynchronousSet/ResetInput
				    .WEA(0),//PortAWriteEnableInput
				    .WEB(write_ram[0])//PortBWriteEnableInput
				    );

    
    RAMB16_S1_S1 RAMB16_S1_S1_inst2(.DOA(read_bits[1]),//PortA1-bitDataOutput
				    //.DOB(DOB),//PortB1-bitDataOutput
				    .ADDRA(read_addr),//PortA14-bitAddressInput
				    .ADDRB(write_addr),//PortB14-bitAddressInput
				    .CLKA(clk),//PortAClock
				    .CLKB(clk),//PortBClock
				    //.DIA(DIA),//PortA1-bitDataInput
				    .DIB(write),//PortB1-bitDataInput
				    .ENA(read_ram[1]),//PortARAMEnableInput
				    .ENB(write_ram[1]),//PortBRAMEnableInput
				    .SSRA(0),//PortASynchronousSet/ResetInput
				    .SSRB(0),//PortBSynchronousSet/ResetInput
				    .WEA(0),//PortAWriteEnableInput
				    .WEB(write_ram[1])//PortBWriteEnableInput
				    );

    
    RAMB16_S1_S1 RAMB16_S1_S1_inst3(.DOA(read_bits[2]),//PortA1-bitDataOutput
				    //.DOB(DOB),//PortB1-bitDataOutput
				    .ADDRA(read_addr),//PortA14-bitAddressInput
				    .ADDRB(write_addr),//PortB14-bitAddressInput
				    .CLKA(clk),//PortAClock
				    .CLKB(clk),//PortBClock
				    //.DIA(DIA),//PortA1-bitDataInput
				    .DIB(write),//PortB1-bitDataInput
				    .ENA(read_ram[2]),//PortARAMEnableInput
				    .ENB(write_ram[2]),//PortBRAMEnableInput
				    .SSRA(0),//PortASynchronousSet/ResetInput
				    .SSRB(0),//PortBSynchronousSet/ResetInput
				    .WEA(0),//PortAWriteEnableInput
				    .WEB(write_ram[2])//PortBWriteEnableInput
				    );

    
    RAMB16_S1_S1 RAMB16_S1_S1_inst4(.DOA(read_bits[3]),//PortA1-bitDataOutput
				    //.DOB(DOB),//PortB1-bitDataOutput
				    .ADDRA(read_addr),//PortA14-bitAddressInput
				    .ADDRB(write_addr),//PortB14-bitAddressInput
				    .CLKA(clk),//PortAClock
				    .CLKB(clk),//PortBClock
				    //.DIA(DIA),//PortA1-bitDataInput
				    .DIB(write),//PortB1-bitDataInput
				    .ENA(read_ram[3]),//PortARAMEnableInput
				    .ENB(write_ram[3]),//PortBRAMEnableInput
				    .SSRA(0),//PortASynchronousSet/ResetInput
				    .SSRB(0),//PortBSynchronousSet/ResetInput
				    .WEA(0),//PortAWriteEnableInput
				    .WEB(write_ram[3])//PortBWriteEnableInput
				    );

endmodule // blockram
*/

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
		   input wire [5:0] check_killed,
		   input wire [5:0] kill_invader,
		   input wire 	    do_kill_invader,
		   output wire 	    is_killed
		   );

    reg [54:0] killed_invaders;
    reg        read_res;

    assign is_killed = read_res;
    
    always @(posedge clk) begin    
	read_res <= killed_invaders[check_killed];
	if(do_kill_invader) begin
	    killed_invaders[kill_invader] <= 1;
	end
    end

endmodule // game_memory
 
module game(
	    input wire 	     clk,
	    input wire 	     next_move,
	    input wire 	     next_line,
	    input wire [1:0] cannon_action,
//	    input wire 	     do_write,
	    input wire [8:0] read_x,
	    input wire [7:0] read_y,
	    input wire 	     read_next,
	    output wire      pixel,

	    output wire      kill_debug
	    );

    reg 		     kill_debug_reg = 0;
    assign kill_debug = kill_debug_reg;
    
    localparam MAX_MOVE_DELAY = 55;
    localparam FIRST_COLUMN = 4;
    localparam FIRST_ROW = 20;
    localparam LAST_COLUMN = 320;
    localparam LAST_ROW = 180;
    
//    localparam STATE_INIT = 0;
    localparam STATE_WAIT = 0;
    localparam STATE_WRITE_LINE = 1;
//    localparam STATE_DRAW_SPRITE = 2;
//    localparam STATE_REDRAW = 3;
    localparam STATE_CHECK_COLLISIONS = 2;
//    localparam STATE_MOVE_ALIENS = 3;
    localparam STATE_GAME_OVER = 3;
//    localparam STATE_TEST_SIMULATION = 5;

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

    localparam CANNON_POS_Y = LAST_ROW + 1;
    
    reg [2:0]  state = STATE_WAIT;
//    reg        init_finished = 1;
   
//    reg [8:0]  invaders_x [54:0];
//    reg [7:0]  invaders_y [54:0];
    reg [8:0]  first_invader_x = FIRST_COLUMN;
    reg [7:0]  first_invader_y = FIRST_ROW; 
    reg [5:0] 	speed = 0;
    
    reg [5:0]  alien_move_cnt = MAX_MOVE_DELAY;
    reg [5:0]  cur_invader = 56;
    reg [8:0]  cur_invader_x;    
    reg [7:0]  cur_invader_y;
//    reg [1:0]  cur_sprite = SPRITE_SMALL_ALIEN;
//    reg [8:0]  sprite_x = FIRST_COLUMN + 16*11;
//    reg [7:0]  sprite_y = FIRST_ROW - 16;
//    reg [3:0]  draw_x = 0;
//    reg [3:0]  draw_y = 0;
    reg [1:0]  moving_direction = DIRECTION_RIGHT;
    reg        updated_direction;
    
    reg [8:0]  cannon_pos_x;
    reg [8:0]  cannon_bullet_x;
    reg [7:0]  cannon_bullet_y;
    reg        is_cannon_bullet = 0;

    localparam CANNON_ACTION_MAX_DELAY = 1000000;
    reg [31:0] cannon_action_delay = 0;
    
//    reg [5:0]  next_kill = 7;
    
    wire [8:0] rel_write_x;
    wire [7:0] rel_write_y;
    wire [4:0] write_alien_x;
    wire [3:0] write_alien_y;
    wire [3:0] write_sprite_x;
    wire [3:0] write_sprite_y;
    wire [8:0] rel_write_next_x;
    wire [4:0] write_alien_next_x;
    
    reg [5:0]  check_killed = 0;
    reg [5:0]  kill_invader;
    reg        do_kill_invader = 0;
    wire       is_killed;
    reg        is_invader = 0;
    reg        is_invader1 = 0;
    
    game_memory game_memory_inst(.clk(clk),
				 .check_killed(check_killed),
				 .kill_invader(kill_invader),
				 .do_kill_invader(do_kill_invader),
				 .is_killed(is_killed)
				 );

    reg        save_next = 0;
    reg        save_pixel;
    reg [8:0]  write_x = 0;
    wire [7:0]  write_y;
    assign write_y = read_y + 1;

    cache_lines cache_lines_inst(.clk(clk),
				 .save_x(write_x),
				 .save_y(write_y[0]),
				 .save_next(save_next),
				 .save_pixel(save_pixel),
				 .read_x(read_x),
				 .read_y(read_y[0]),
				 .read_next(1),
				 .read_pixel(pixel)
				 );

    
    assign rel_write_x = write_x - first_invader_x;
    assign rel_write_y = write_y - first_invader_y;
    assign write_alien_x = rel_write_x >> 4;
    assign write_alien_y = rel_write_y >> 4;
    assign write_sprite_x = rel_write_x[3:0];
    assign write_sprite_y = rel_write_y[3:0];

    assign rel_write_next_x = write_x + 2 - first_invader_x;
    assign write_alien_next_x = rel_write_next_x >> 4;
    
/*    always @* begin
	if(write_x >= first_invader_x && write_x < first_invader_x + 16*11
	   && write_y >= first_invader_y && write_y < first_invader_y + 16*5
	   && !killed_invaders[write_alien_x + write_alien_y * 11]) begin
	    //Read sprite pixel
	    if(write_sprite_y < 8) pixel = 0;
	    else if((write_sprite_x >= 2 && write_sprite_x < 10) ||
		    (write_sprite_x >= 1 && write_sprite_x < 11 && write_alien_y > 0) ||
		    (write_sprite_x < 12 && write_alien_y > 2))
	      pixel = 1;
	    else pixel = 0;
	end else pixel = 0;
    end // always @ *
*/

    always @(posedge clk) begin	
	case (state)
/*	  STATE_INIT : begin
	      if(cur_invader < 55) begin
		  if(sprite_x + 16 >= FIRST_COLUMN + 16*11) begin
		      sprite_x <= FIRST_COLUMN;
		      sprite_y <= sprite_y + 16;
		      invaders_x[cur_invader] <= FIRST_COLUMN;
		      invaders_y[cur_invader] <= sprite_y + 16;
		      if(cur_invader >= 33) cur_sprite <= SPRITE_BIG_ALIEN;
		      else if(cur_invader >= 11) cur_sprite <= SPRITE_MID_ALIEN;
		  end else begin
		      sprite_x <= sprite_x + 16;
		      invaders_x[cur_invader] <= sprite_x + 16;
		      invaders_y[cur_invader] <= sprite_y;
		  end
		  cur_invader <= cur_invader + 1;
		  state <= STATE_DRAW_SPRITE;
	      end else begin // if (cur_invader < 55)
		  cur_invader <= 0;
		  init_finished <= 0;
		  state <= STATE_WAIT;
	      end
	  end // case: STATE_INIT*/
	  STATE_WAIT: begin
	      if(next_move) begin
		  if(alien_move_cnt == 0) begin
		      alien_move_cnt <= MAX_MOVE_DELAY - speed;
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
		  end else alien_move_cnt <= alien_move_cnt - 1; // if (alien_move_cnt == 0)
		  if(is_cannon_bullet) begin
			     if(cannon_bullet_y > 1) cannon_bullet_y <= cannon_bullet_y - 2;
			     else is_cannon_bullet <= 0;
		  end
		  state <= STATE_CHECK_COLLISIONS;		      
	      end
	      if(next_line) begin
		  write_x <= 0;
		  //write_y <= write_y + 1;
		  state <= STATE_WRITE_LINE;
		  // There wont be any invider with x=0 so don't have to query memory here
		  is_invader <= 0;
	      end
	  end // case: STATE_WAIT
	  STATE_WRITE_LINE: begin
	      if(write_x < 320) begin
		  //Prefetch
		  if(write_y >= first_invader_y && write_y < first_invader_y + 16*5
		     && write_x + 2 >= first_invader_x && write_x + 2 < first_invader_x + 16*11) begin
		      is_invader1 <= 1;
		      check_killed <= write_alien_next_x + write_alien_y * 11;
		  end else is_invader1 <= 0;
		  is_invader <= is_invader1;
		  //TODO move it to generic sprite module
		  if(is_invader && !is_killed && write_sprite_y >= 8 &&
		     ((write_sprite_x >= 2 && write_sprite_x < 10) ||
		      (write_sprite_x >= 1 && write_sprite_x < 11 && write_alien_y > 0) ||
		      (write_sprite_x < 12 && write_alien_y > 2)))
		    save_pixel <= 1;
		  else if(write_y >= CANNON_POS_Y && write_y < CANNON_POS_Y + 8
			  && write_x >= cannon_pos_x && write_x < cannon_pos_x + 15)
		    save_pixel <= 1;
		  else if(is_cannon_bullet && cannon_bullet_x == write_x
			  && write_y >= cannon_bullet_y && write_y < cannon_bullet_y + 4)
		    save_pixel <= 1;
		  else save_pixel <= 0;
		  write_x <= write_x + 1;
		  save_next <= 1;
	      end else begin
		  state <= STATE_WAIT;
		  save_next <= 0;
		  is_invader <= 0;
	      end
	  end // case: STATE_WRITE_LINE
/*	  STATE_REDRAW: begin
	      if(cur_invader < 55) begin
		  if(!killed_invaders[cur_invader]) begin
		      sprite_x <= invaders_x[cur_invader];
		      sprite_y <= invaders_y[cur_invader];
		      if(cur_invader >= 33) cur_sprite <= SPRITE_BIG_ALIEN;
		      else if(cur_invader >= 11) cur_sprite <= SPRITE_MID_ALIEN;
		      else cur_sprite <= SPRITE_SMALL_ALIEN;
		      state <= STATE_DRAW_SPRITE;
		  end
		  cur_invader <= cur_invader + 1;
	      end else begin
		  cur_invader <= 0;
		  if(nxt_move == 0) begin
		      nxt_move <= MAX_MOVE_DELAY - speed;
		      state <= STATE_MOVE_ALIENS;
		  end else begin
		      nxt_move <= nxt_move - 1;
		      state <= STATE_WAIT;
		  end
	      end // else: !if(cur_invader < 55)
	  end // case: STATE_REDRAW*/
	  STATE_CHECK_COLLISIONS: begin
	      //Need 2 cycles to get result from ram
	      if(cur_invader == 56) begin
		  cur_invader <= 57;
		  check_killed <= 0;
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
			      //cur_invader <= 0;
			      //state <= STATE_TEST_SIMULATION;
			      if(moving_direction == DIRECTION_DOWN)
				if(cur_invader_x <= FIRST_COLUMN)
				  moving_direction <= DIRECTION_RIGHT;
				else moving_direction <= DIRECTION_LEFT;
			      else moving_direction <= DIRECTION_DOWN;
			  end
		      end // if (!updated_direction)
		      if(cur_invader_y + 16 >= LAST_ROW) state <= STATE_GAME_OVER;
		      
		      //Collision with bullet
		      if(is_cannon_bullet && cannon_bullet_y + 4 >= cur_invader_y
			 && cannon_bullet_y < cur_invader_y + 16
			 && ((cannon_bullet_x >= cur_invader_x + 2 
			      && cannon_bullet_x < cur_invader_x + 10) ||
			     (cannon_bullet_x >= cur_invader_x + 1 
			      && cannon_bullet_x < cur_invader_x + 11 && cur_invader > 10) ||
			     (cannon_bullet_x >= cur_invader_x 
			      && cannon_bullet_x < cur_invader_x + 12 && cur_invader > 32))) begin
			  kill_invader <= cur_invader;
			  do_kill_invader <= 1;
			  speed <= speed + 1;
			  is_cannon_bullet <= 0;

			  kill_debug_reg <= 1;
			  
		      end else do_kill_invader <= 0;
		  end // if (!is_killed)
		  cur_invader <= cur_invader + 1;
		  check_killed <= check_killed + 1;
		  if(cur_invader_x == first_invader_x + 10*16) begin
		      cur_invader_x <= first_invader_x;
		      cur_invader_y <= cur_invader_y + 16;
		  end else cur_invader_x <= cur_invader_x + 16;
	      end else begin // if (cur_invader < 55)
		  cur_invader <= 56;
		  check_killed <= 0;
		  //check_killed <= next_kill;
		  //state <= STATE_TEST_SIMULATION;
		  write_x <= 0;
		  state <= STATE_WRITE_LINE;
 	      end 	      
	  end
	  STATE_GAME_OVER: begin
	  end
/*	  STATE_TEST_SIMULATION: begin
//	      write_x <= 0;
//	      state <= STATE_WRITE_LINE;
	      if(next_kill + 7 >= 55) next_kill <= next_kill - 48;
	      else next_kill <= next_kill + 7;
	      if(!is_killed) begin
		  kill_invader <= next_kill;
		  do_kill_invader <= 1;
		  speed <= speed + 1;
	      end else do_kill_invader <= 0;
	      if(speed == 54 && !is_killed) state <= STATE_GAME_OVER;
	      else begin
		  check_killed <= 0;
		  //state <= STATE_WAIT;
		  write_x <= 0;
		  state <= STATE_WRITE_LINE;
	      end
	  end*/
	endcase // case (state)


	if(cannon_action_delay == 0) begin
	  case (cannon_action)
	    CANNON_MOVE_LEFT: begin
		if(cannon_pos_x >= FIRST_COLUMN) cannon_pos_x <= cannon_pos_x - 1;
		cannon_action_delay <= CANNON_ACTION_MAX_DELAY;
	    end
	    CANNON_MOVE_RIGHT: begin
		if(cannon_pos_x < LAST_COLUMN - 15) cannon_pos_x <= cannon_pos_x + 1;
		cannon_action_delay <= CANNON_ACTION_MAX_DELAY;
	    end
	    CANNON_SHOT: begin
		if(!is_cannon_bullet) begin
		    is_cannon_bullet <= 1;
		    cannon_bullet_x <= cannon_pos_x + 7;
		    cannon_bullet_y <= CANNON_POS_Y + 4;

		    kill_debug_reg <= 0;
		    
		end
		cannon_action_delay <= CANNON_ACTION_MAX_DELAY;
	    end
	  endcase // case (cannon_action)
	end else cannon_action_delay <= cannon_action_delay - 1; // if (cannon_action_delay == 0)
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
		       output wire [2:1] VGAB
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

    reg [3:0] btn1 = 0;
    reg [3:0] btn2 = 0;
    reg [3:0] btn3 = 0;
    
    always @(posedge clk) begin
	btn1 <= btn;
	btn2 <= btn1;
	btn3 <= btn2;
	if(btn3[0]) cannon_action <= CANNON_MOVE_RIGHT;
	else if(btn3[3]) cannon_action <= CANNON_MOVE_LEFT;
	else if(btn3[1] || btn3[2]) cannon_action <= CANNON_SHOT;
	else cannon_action <= CANNON_NO_ACTION;
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

		   .kill_debug(led[7])
		   );

    assign led[0] = VGAR[2];
    assign led[1] = VGAG[2];
    assign led[2] = VGAB[2];
    assign led[3] = HSYNC;
    assign led[4] = VSYNC;
    assign led[5] = read_res;
    assign led[6] = next_frame;
//    assign led[7] = save_pixel;

endmodule // space_invaders
