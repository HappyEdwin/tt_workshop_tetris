/*
 * Tetris VGA + Gamepad Pmod para TinyTapeout
 * Autor: HappyEdwin
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_example (
    input  wire [7:0] ui_in,    // ui_in[6]: data, ui_in[5]: clk, ui_in[4]: latch
    output wire [7:0] uo_out,   // Salidas TinyVGA Pmod
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      // Reloj ~25 MHz
    input  wire       rst_n     // Reset activo bajo
);

  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  wire _unused_ok = &{ena, ui_in[7], ui_in[3:0], uio_in};

  // Sincronización VGA
  wire hsync;
  wire vsync;
  reg  [1:0] R;
  reg  [1:0] G;
  reg  [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  hvsync_generator vga_sync_gen (
      .clk(clk),
      .reset(~rst_n),
      .hsync(hsync),
      .vsync(vsync),
      .display_on(video_active),
      .hpos(pix_x),
      .vpos(pix_y)
  );

  // Instancia del driver Gamepad Pmod
  wire inp_b, inp_y, inp_select, inp_start, inp_up, inp_down, inp_left, inp_right, inp_a, inp_x, inp_l, inp_r;

  gamepad_pmod_single driver (
      .rst_n(rst_n),
      .clk(clk),
      .pmod_data(ui_in[6]),
      .pmod_clk(ui_in[5]),
      .pmod_latch(ui_in[4]),
      .b(inp_b),
      .y(inp_y),
      .select(inp_select),
      .start(inp_start),
      .up(inp_up),
      .down(inp_down),
      .left(inp_left),
      .right(inp_right),
      .a(inp_a),
      .x(inp_x),
      .l(inp_l),
      .r(inp_r)
  );

  wire _unused_pad = &{inp_b, inp_y, inp_select, inp_start, inp_x, inp_l, inp_r};

  // -------------------------------------------------------------
  // Texto Superior: "TETRIS BY HAPPYEDWIN" (20 caracteres)
  // Posición: X = 160..480, Y = 36..52 (Caracteres 8x16 px)
  // -------------------------------------------------------------
  wire in_text_area = (pix_x >= 10'd160) && (pix_x < 10'd480) &&
                      (pix_y >= 10'd36)  && (pix_y < 10'd52);

  wire [4:0] char_idx = (pix_x - 10'd160) >> 4;
  wire [2:0] char_col = (pix_x - 10'd160) & 4'h7;
  wire [3:0] char_row = (pix_y - 10'd36);

  reg [4:0] char_code;
  always @(*) begin
    case (char_idx)
      5'd0:  char_code = 5'd20; // T
      5'd1:  char_code = 5'd5;  // E
      5'd2:  char_code = 5'd20; // T
      5'd3:  char_code = 5'd18; // R
      5'd4:  char_code = 5'd9;  // I
      5'd5:  char_code = 5'd19; // S
      5'd6:  char_code = 5'd0;  // Espacio
      5'd7:  char_code = 5'd2;  // B
      5'd8:  char_code = 5'd25; // Y
      5'd9:  char_code = 5'd0;  // Espacio
      5'd10: char_code = 5'd8;  // H
      5'd11: char_code = 5'd1;  // A
      5'd12: char_code = 5'd16; // P
      5'd13: char_code = 5'd16; // P
      5'd14: char_code = 5'd25; // Y
      5'd15: char_code = 5'd5;  // E
      5'd16: char_code = 5'd4;  // D
      5'd17: char_code = 5'd23; // W
      5'd18: char_code = 5'd9;  // I
      5'd19: char_code = 5'd14; // N
      default: char_code = 5'd0;
    endcase
  end

  reg [4:0] glyph_row_bits;
  wire [2:0] sub_y_char = char_row >> 1;
  always @(*) begin
    case (char_code)
      5'd1:  // A
        case (sub_y_char) 3'd0: glyph_row_bits = 5'b01110; 3'd1: glyph_row_bits = 5'b10001; 3'd2: glyph_row_bits = 5'b11111; 3'd3: glyph_row_bits = 5'b10001; 3'd4: glyph_row_bits = 5'b10001; default: glyph_row_bits = 5'b0; endcase
      5'd2:  // B
        case (sub_y_char) 3'd0: glyph_row_bits = 5'b11110; 3'd1: glyph_row_bits = 5'b10001; 3'd2: glyph_row_bits = 5'b11110; 3'd3: glyph_row_bits = 5'b10001; 3'd4: glyph_row_bits = 5'b11110; default: glyph_row_bits = 5'b0; endcase
      5'd4:  // D
        case (sub_y_char) 3'd0: glyph_row_bits = 5'b11110; 3'd1: glyph_row_bits = 5'b10001; 3'd2: glyph_row_bits = 5'b10001; 3'd3: glyph_row_bits = 5'b10001; 3'd4: glyph_row_bits = 5'b11110; default: glyph_row_bits = 5'b0; endcase
      5'd5:  // E
        case (sub_y_char) 3'd0: glyph_row_bits = 5'b11111; 3'd1: glyph_row_bits = 5'b10000; 3'd2: glyph_row_bits = 5'b11110; 3'd3: glyph_row_bits = 5'b10000; 3'd4: glyph_row_bits = 5'b11111; default: glyph_row_bits = 5'b0; endcase
      5'd8:  // H
        case (sub_y_char) 3'd0: glyph_row_bits = 5'b10001; 3'd1: glyph_row_bits = 5'b10001; 3'd2: glyph_row_bits = 5'b11111; 3'd3: glyph_row_bits = 5'b10001; 3'd4: glyph_row_bits = 5'b10001; default: glyph_row_bits = 5'b0; endcase
      5'd9:  // I
        case (sub_y_char) 3'd0: glyph_row_bits = 5'b11111; 3'd1: glyph_row_bits = 5'b00100; 3'd2: glyph_row_bits = 5'b00100; 3'd3: glyph_row_bits = 5'b00100; 3'd4: glyph_row_bits = 5'b11111; default: glyph_row_bits = 5'b0; endcase
      5'd14: // N
        case (sub_y_char) 3'd0: glyph_row_bits = 5'b10001; 3'd1: glyph_row_bits = 5'b11001; 3'd2: glyph_row_bits = 5'b10101; 3'd3: glyph_row_bits = 5'b10011; 3'd4: glyph_row_bits = 5'b10001; default: glyph_row_bits = 5'b0; endcase
      5'd16: // P
        case (sub_y_char) 3'd0: glyph_row_bits = 5'b11110; 3'd1: glyph_row_bits = 5'b10001; 3'd2: glyph_row_bits = 5'b11110; 3'd3: glyph_row_bits = 5'b10000; 3'd4: glyph_row_bits = 5'b10000; default: glyph_row_bits = 5'b0; endcase
      5'd18: // R
        case (sub_y_char) 3'd0: glyph_row_bits = 5'b11110; 3'd1: glyph_row_bits = 5'b10001; 3'd2: glyph_row_bits = 5'b11110; 3'd3: glyph_row_bits = 5'b10100; 3'd4: glyph_row_bits = 5'b10011; default: glyph_row_bits = 5'b0; endcase
      5'd19: // S
        case (sub_y_char) 3'd0: glyph_row_bits = 5'b01111; 3'd1: glyph_row_bits = 5'b10000; 3'd2: glyph_row_bits = 5'b01110; 3'd3: glyph_row_bits = 5'b00001; 3'd4: glyph_row_bits = 5'b11110; default: glyph_row_bits = 5'b0; endcase
      5'd20: // T
        case (sub_y_char) 3'd0: glyph_row_bits = 5'b11111; 3'd1: glyph_row_bits = 5'b00100; 3'd2: glyph_row_bits = 5'b00100; 3'd3: glyph_row_bits = 5'b00100; 3'd4: glyph_row_bits = 5'b00100; default: glyph_row_bits = 5'b0; endcase
      5'd23: // W
        case (sub_y_char) 3'd0: glyph_row_bits = 5'b10001; 3'd1: glyph_row_bits = 5'b10001; 3'd2: glyph_row_bits = 5'b10101; 3'd3: glyph_row_bits = 5'b11011; 3'd4: glyph_row_bits = 5'b10001; default: glyph_row_bits = 5'b0; endcase
      5'd25: // Y
        case (sub_y_char) 3'd0: glyph_row_bits = 5'b10001; 3'd1: glyph_row_bits = 5'b01010; 3'd2: glyph_row_bits = 5'b00100; 3'd3: glyph_row_bits = 5'b00100; 3'd4: glyph_row_bits = 5'b00100; default: glyph_row_bits = 5'b0; endcase
      default: glyph_row_bits = 5'b00000;
    endcase
  end

  wire text_pixel = in_text_area && (char_col >= 3'd1 && char_col <= 3'd5) &&
                    (sub_y_char < 3'd5) && glyph_row_bits[3'd5 - char_col];

  // -------------------------------------------------------------
  // Pozo de Tetris (10x20 bloques, 16x16 px)
  // -------------------------------------------------------------
  localparam BOARD_X1 = 10'd240;
  localparam BOARD_X2 = 10'd400;
  localparam BOARD_Y1 = 10'd80;
  localparam BOARD_Y2 = 10'd400;

  wire in_board = (pix_x >= BOARD_X1) && (pix_x < BOARD_X2) &&
                  (pix_y >= BOARD_Y1) && (pix_y < BOARD_Y2);

  wire in_border = (((pix_x >= BOARD_X1 - 4 && pix_x < BOARD_X1) ||
                     (pix_x >= BOARD_X2     && pix_x < BOARD_X2 + 4)) &&
                    (pix_y >= BOARD_Y1     && pix_y <= BOARD_Y2)) ||
                   ((pix_y >= BOARD_Y2     && pix_y < BOARD_Y2 + 4) &&
                    (pix_x >= BOARD_X1 - 4 && pix_x < BOARD_X2 + 4));

  wire [3:0] col_idx = (pix_x - BOARD_X1) >> 4;
  wire [4:0] row_idx = (pix_y - BOARD_Y1) >> 4;

  wire [3:0] sub_px_x = (pix_x - BOARD_X1) & 4'hF;
  wire [3:0] sub_px_y = (pix_y - BOARD_Y1) & 4'hF;
  wire grid_edge = (sub_px_x == 4'd0 || sub_px_x == 4'd15 || sub_px_y == 4'd0 || sub_px_y == 4'd15);

  // -------------------------------------------------------------
  // Memoria del Tablero: 20 registros discretos de 10 bits
  // -------------------------------------------------------------
  reg [9:0] r0,  r1,  r2,  r3,  r4,  r5,  r6,  r7,  r8,  r9;
  reg [9:0] r10, r11, r12, r13, r14, r15, r16, r17, r18, r19;

  reg [4:0] piece_r;
  reg [3:0] piece_c;
  reg [1:0] piece_shape;
  reg [5:0] fall_count;

  // Lógica de detección de flancos en botones (60 Hz)
  reg last_left, last_right, last_rot;
  wire vsync_tick;
  reg vsync_d;
  always @(posedge clk) vsync_d <= vsync;
  assign vsync_tick = (vsync && !vsync_d);

  wire btn_rot_input = inp_up | inp_a;

  // Renderizado de pieza en movimiento
  wire is_falling_pixel =
    (piece_shape == 2'd0) ?
      (row_idx >= piece_r && row_idx <= piece_r + 1 && col_idx >= piece_c && col_idx <= piece_c + 1) :
    (piece_shape == 2'd1) ?
      (row_idx >= piece_r && row_idx <= piece_r + 2 && col_idx == piece_c) :
    (piece_shape == 2'd2) ?
      (row_idx == piece_r && col_idx >= piece_c && col_idx <= piece_c + 2) :
      ((row_idx >= piece_r && row_idx <= piece_r + 1 && col_idx == piece_c) ||
       (row_idx == piece_r + 1 && col_idx == piece_c + 1));

  wire [3:0] max_col = (piece_shape == 2'd0) ? 4'd8 :
                       (piece_shape == 2'd1) ? 4'd9 :
                       (piece_shape == 2'd2) ? 4'd7 : 4'd8;

  // Lógica de colisión con filas discretas
  function [9:0] get_row;
    input [4:0] r_idx;
    case (r_idx)
      5'd0:  get_row = r0;
      5'd1:  get_row = r1;
      5'd2:  get_row = r2;
      5'd3:  get_row = r3;
      5'd4:  get_row = r4;
      5'd5:  get_row = r5;
      5'd6:  get_row = r6;
      5'd7:  get_row = r7;
      5'd8:  get_row = r8;
      5'd9:  get_row = r9;
      5'd10: get_row = r10;
      5'd11: get_row = r11;
      5'd12: get_row = r12;
      5'd13: get_row = r13;
      5'd14: get_row = r14;
      5'd15: get_row = r15;
      5'd16: get_row = r16;
      5'd17: get_row = r17;
      5'd18: get_row = r18;
      5'd19: get_row = r19;
      default: get_row = 10'd0;
    endcase
  endfunction

  wire [4:0] next_r = piece_r + 1'b1;
  wire hit_floor = (piece_shape == 2'd0) ? (next_r + 1 >= 20) :
                   (piece_shape == 2'd1) ? (next_r + 2 >= 20) :
                   (piece_shape == 2'd2) ? (next_r     >= 20) :
                                           (next_r + 1 >= 20);

  wire [9:0] row_below_0 = get_row(next_r);
  wire [9:0] row_below_1 = get_row(next_r + 1);
  wire [9:0] row_below_2 = get_row(next_r + 2);
  wire [9:0] curr_row_bits = get_row(piece_r);

  wire hit_blocks =
    (piece_shape == 2'd0) ? (next_r + 1 < 20 && (row_below_1[piece_c] || row_below_1[piece_c + 1])) :
    (piece_shape == 2'd1) ? (next_r + 2 < 20 && row_below_2[piece_c]) :
    (piece_shape == 2'd2) ? (next_r     < 20 && (row_below_0[piece_c] || row_below_0[piece_c + 1] || row_below_0[piece_c + 2])) :
                            (next_r + 1 < 20 && (row_below_1[piece_c] || row_below_1[piece_c + 1]));

  // -------------------------------------------------------------
  // Estampado y Eliminación de Líneas (Pipeline de asignación)
  // -------------------------------------------------------------
  reg [9:0] s0, s1, s2, s3, s4, s5, s6, s7, s8, s9;
  reg [9:0] s10, s11, s12, s13, s14, s15, s16, s17, s18, s19;

  // Paso 1: Estampar la pieza activa
  always @(*) begin
    s0 = r0;   s1 = r1;   s2 = r2;   s3 = r3;   s4 = r4;
    s5 = r5;   s6 = r6;   s7 = r7;   s8 = r8;   s9 = r9;
    s10 = r10; s11 = r11; s12 = r12; s13 = r13; s14 = r14;
    s15 = r15; s16 = r16; s17 = r17; s18 = r18; s19 = r19;

    case (piece_shape)
      2'd0: begin // Cuadrado 2x2
        case (piece_r)
          5'd0:  begin s0[piece_c] = 1'b1; s0[piece_c+1] = 1'b1; s1[piece_c] = 1'b1; s1[piece_c+1] = 1'b1; end
          5'd1:  begin s1[piece_c] = 1'b1; s1[piece_c+1] = 1'b1; s2[piece_c] = 1'b1; s2[piece_c+1] = 1'b1; end
          5'd2:  begin s2[piece_c] = 1'b1; s2[piece_c+1] = 1'b1; s3[piece_c] = 1'b1; s3[piece_c+1] = 1'b1; end
          5'd3:  begin s3[piece_c] = 1'b1; s3[piece_c+1] = 1'b1; s4[piece_c] = 1'b1; s4[piece_c+1] = 1'b1; end
          5'd4:  begin s4[piece_c] = 1'b1; s4[piece_c+1] = 1'b1; s5[piece_c] = 1'b1; s5[piece_c+1] = 1'b1; end
          5'd5:  begin s5[piece_c] = 1'b1; s5[piece_c+1] = 1'b1; s6[piece_c] = 1'b1; s6[piece_c+1] = 1'b1; end
          5'd6:  begin s6[piece_c] = 1'b1; s6[piece_c+1] = 1'b1; s7[piece_c] = 1'b1; s7[piece_c+1] = 1'b1; end
          5'd7:  begin s7[piece_c] = 1'b1; s7[piece_c+1] = 1'b1; s8[piece_c] = 1'b1; s8[piece_c+1] = 1'b1; end
          5'd8:  begin s8[piece_c] = 1'b1; s8[piece_c+1] = 1'b1; s9[piece_c] = 1'b1; s9[piece_c+1] = 1'b1; end
          5'd9:  begin s9[piece_c] = 1'b1; s9[piece_c+1] = 1'b1; s10[piece_c] = 1'b1; s10[piece_c+1] = 1'b1; end
          5'd10: begin s10[piece_c] = 1'b1; s10[piece_c+1] = 1'b1; s11[piece_c] = 1'b1; s11[piece_c+1] = 1'b1; end
          5'd11: begin s11[piece_c] = 1'b1; s11[piece_c+1] = 1'b1; s12[piece_c] = 1'b1; s12[piece_c+1] = 1'b1; end
          5'd12: begin s12[piece_c] = 1'b1; s12[piece_c+1] = 1'b1; s13[piece_c] = 1'b1; s13[piece_c+1] = 1'b1; end
          5'd13: begin s13[piece_c] = 1'b1; s13[piece_c+1] = 1'b1; s14[piece_c] = 1'b1; s14[piece_c+1] = 1'b1; end
          5'd14: begin s14[piece_c] = 1'b1; s14[piece_c+1] = 1'b1; s15[piece_c] = 1'b1; s15[piece_c+1] = 1'b1; end
          5'd15: begin s15[piece_c] = 1'b1; s15[piece_c+1] = 1'b1; s16[piece_c] = 1'b1; s16[piece_c+1] = 1'b1; end
          5'd16: begin s16[piece_c] = 1'b1; s16[piece_c+1] = 1'b1; s17[piece_c] = 1'b1; s17[piece_c+1] = 1'b1; end
          5'd17: begin s17[piece_c] = 1'b1; s17[piece_c+1] = 1'b1; s18[piece_c] = 1'b1; s18[piece_c+1] = 1'b1; end
          5'd18: begin s18[piece_c] = 1'b1; s18[piece_c+1] = 1'b1; s19[piece_c] = 1'b1; s19[piece_c+1] = 1'b1; end
          default: ;
        endcase
      end
      2'd1: begin // Barra 1x3 vertical
        case (piece_r)
          5'd0:  begin s0[piece_c] = 1'b1; s1[piece_c] = 1'b1; s2[piece_c] = 1'b1; end
          5'd1:  begin s1[piece_c] = 1'b1; s2[piece_c] = 1'b1; s3[piece_c] = 1'b1; end
          5'd2:  begin s2[piece_c] = 1'b1; s3[piece_c] = 1'b1; s4[piece_c] = 1'b1; end
          5'd3:  begin s3[piece_c] = 1'b1; s4[piece_c] = 1'b1; s5[piece_c] = 1'b1; end
          5'd4:  begin s4[piece_c] = 1'b1; s5[piece_c] = 1'b1; s6[piece_c] = 1'b1; end
          5'd5:  begin s5[piece_c] = 1'b1; s6[piece_c] = 1'b1; s7[piece_c] = 1'b1; end
          5'd6:  begin s6[piece_c] = 1'b1; s7[piece_c] = 1'b1; s8[piece_c] = 1'b1; end
          5'd7:  begin s7[piece_c] = 1'b1; s8[piece_c] = 1'b1; s9[piece_c] = 1'b1; end
          5'd8:  begin s8[piece_c] = 1'b1; s9[piece_c] = 1'b1; s10[piece_c] = 1'b1; end
          5'd9:  begin s9[piece_c] = 1'b1; s10[piece_c] = 1'b1; s11[piece_c] = 1'b1; end
          5'd10: begin s10[piece_c] = 1'b1; s11[piece_c] = 1'b1; s12[piece_c] = 1'b1; end
          5'd11: begin s11[piece_c] = 1'b1; s12[piece_c] = 1'b1; s13[piece_c] = 1'b1; end
          5'd12: begin s12[piece_c] = 1'b1; s13[piece_c] = 1'b1; s14[piece_c] = 1'b1; end
          5'd13: begin s13[piece_c] = 1'b1; s14[piece_c] = 1'b1; s15[piece_c] = 1'b1; end
          5'd14: begin s14[piece_c] = 1'b1; s15[piece_c] = 1'b1; s16[piece_c] = 1'b1; end
          5'd15: begin s15[piece_c] = 1'b1; s16[piece_c] = 1'b1; s17[piece_c] = 1'b1; end
          5'd16: begin s16[piece_c] = 1'b1; s17[piece_c] = 1'b1; s18[piece_c] = 1'b1; end
          5'd17: begin s17[piece_c] = 1'b1; s18[piece_c] = 1'b1; s19[piece_c] = 1'b1; end
          default: ;
        endcase
      end
      2'd2: begin // Barra 3x1 horizontal
        case (piece_r)
          5'd0:  begin s0[piece_c] = 1'b1; s0[piece_c+1] = 1'b1; s0[piece_c+2] = 1'b1; end
          5'd1:  begin s1[piece_c] = 1'b1; s1[piece_c+1] = 1'b1; s1[piece_c+2] = 1'b1; end
          5'd2:  begin s2[piece_c] = 1'b1; s2[piece_c+1] = 1'b1; s2[piece_c+2] = 1'b1; end
          5'd3:  begin s3[piece_c] = 1'b1; s3[piece_c+1] = 1'b1; s3[piece_c+2] = 1'b1; end
          5'd4:  begin s4[piece_c] = 1'b1; s4[piece_c+1] = 1'b1; s4[piece_c+2] = 1'b1; end
          5'd5:  begin s5[piece_c] = 1'b1; s5[piece_c+1] = 1'b1; s5[piece_c+2] = 1'b1; end
          5'd6:  begin s6[piece_c] = 1'b1; s6[piece_c+1] = 1'b1; s6[piece_c+2] = 1'b1; end
          5'd7:  begin s7[piece_c] = 1'b1; s7[piece_c+1] = 1'b1; s7[piece_c+2] = 1'b1; end
          5'd8:  begin s8[piece_c] = 1'b1; s8[piece_c+1] = 1'b1; s8[piece_c+2] = 1'b1; end
          5'd9:  begin s9[piece_c] = 1'b1; s9[piece_c+1] = 1'b1; s9[piece_c+2] = 1'b1; end
          5'd10: begin s10[piece_c] = 1'b1; s10[piece_c+1] = 1'b1; s10[piece_c+2] = 1'b1; end
          5'd11: begin s11[piece_c] = 1'b1; s11[piece_c+1] = 1'b1; s11[piece_c+2] = 1'b1; end
          5'd12: begin s12[piece_c] = 1'b1; s12[piece_c+1] = 1'b1; s12[piece_c+2] = 1'b1; end
          5'd13: begin s13[piece_c] = 1'b1; s13[piece_c+1] = 1'b1; s13[piece_c+2] = 1'b1; end
          5'd14: begin s14[piece_c] = 1'b1; s14[piece_c+1] = 1'b1; s14[piece_c+2] = 1'b1; end
          5'd15: begin s15[piece_c] = 1'b1; s15[piece_c+1] = 1'b1; s15[piece_c+2] = 1'b1; end
          5'd16: begin s16[piece_c] = 1'b1; s16[piece_c+1] = 1'b1; s16[piece_c+2] = 1'b1; end
          5'd17: begin s17[piece_c] = 1'b1; s17[piece_c+1] = 1'b1; s17[piece_c+2] = 1'b1; end
          5'd18: begin s18[piece_c] = 1'b1; s18[piece_c+1] = 1'b1; s18[piece_c+2] = 1'b1; end
          5'd19: begin s19[piece_c] = 1'b1; s19[piece_c+1] = 1'b1; s19[piece_c+2] = 1'b1; end
          default: ;
        endcase
      end
      default: begin // Forma L
        case (piece_r)
          5'd0:  begin s0[piece_c] = 1'b1; s1[piece_c] = 1'b1; s1[piece_c+1] = 1'b1; end
          5'd1:  begin s1[piece_c] = 1'b1; s2[piece_c] = 1'b1; s2[piece_c+1] = 1'b1; end
          5'd2:  begin s2[piece_c] = 1'b1; s3[piece_c] = 1'b1; s3[piece_c+1] = 1'b1; end
          5'd3:  begin s3[piece_c] = 1'b1; s4[piece_c] = 1'b1; s4[piece_c+1] = 1'b1; end
          5'd4:  begin s4[piece_c] = 1'b1; s5[piece_c] = 1'b1; s5[piece_c+1] = 1'b1; end
          5'd5:  begin s5[piece_c] = 1'b1; s6[piece_c] = 1'b1; s6[piece_c+1] = 1'b1; end
          5'd6:  begin s6[piece_c] = 1'b1; s7[piece_c] = 1'b1; s7[piece_c+1] = 1'b1; end
          5'd7:  begin s7[piece_c] = 1'b1; s8[piece_c] = 1'b1; s8[piece_c+1] = 1'b1; end
          5'd8:  begin s8[piece_c] = 1'b1; s9[piece_c] = 1'b1; s9[piece_c+1] = 1'b1; end
          5'd9:  begin s9[piece_c] = 1'b1; s10[piece_c] = 1'b1; s10[piece_c+1] = 1'b1; end
          5'd10: begin s10[piece_c] = 1'b1; s11[piece_c] = 1'b1; s11[piece_c+1] = 1'b1; end
          5'd11: begin s11[piece_c] = 1'b1; s12[piece_c] = 1'b1; s12[piece_c+1] = 1'b1; end
          5'd12: begin s12[piece_c] = 1'b1; s13[piece_c] = 1'b1; s13[piece_c+1] = 1'b1; end
          5'd13: begin s13[piece_c] = 1'b1; s14[piece_c] = 1'b1; s14[piece_c+1] = 1'b1; end
          5'd14: begin s14[piece_c] = 1'b1; s15[piece_c] = 1'b1; s15[piece_c+1] = 1'b1; end
          5'd15: begin s15[piece_c] = 1'b1; s16[piece_c] = 1'b1; s16[piece_c+1] = 1'b1; end
          5'd16: begin s16[piece_c] = 1'b1; s17[piece_c] = 1'b1; s17[piece_c+1] = 1'b1; end
          5'd17: begin s17[piece_c] = 1'b1; s18[piece_c] = 1'b1; s18[piece_c+1] = 1'b1; end
          5'd18: begin s18[piece_c] = 1'b1; s19[piece_c] = 1'b1; s19[piece_c+1] = 1'b1; end
          default: ;
        endcase
      end
    endcase
  end

  // Paso 2: Cascada combinacional para colapsar filas llenas
  reg [9:0] c0, c1, c2, c3, c4, c5, c6, c7, c8, c9;
  reg [9:0] c10, c11, c12, c13, c14, c15, c16, c17, c18, c19;

  always @(*) begin
    c0 = s0;   c1 = s1;   c2 = s2;   c3 = s3;   c4 = s4;
    c5 = s5;   c6 = s6;   c7 = s7;   c8 = s8;   c9 = s9;
    c10 = s10; c11 = s11; c12 = s12; c13 = s13; c14 = s14;
    c15 = s15; c16 = s16; c17 = s17; c18 = s18; c19 = s19;

    if (&c19) begin c19=c18; c18=c17; c17=c16; c16=c15; c15=c14; c14=c13; c13=c12; c12=c11; c11=c10; c10=c9; c9=c8; c8=c7; c7=c6; c6=c5; c5=c4; c4=c3; c3=c2; c2=c1; c1=c0; c0=10'd0; end
    if (&c18) begin c18=c17; c17=c16; c16=c15; c15=c14; c14=c13; c13=c12; c12=c11; c11=c10; c10=c9; c9=c8; c8=c7; c7=c6; c6=c5; c5=c4; c4=c3; c3=c2; c2=c1; c1=c0; c0=10'd0; end
    if (&c17) begin c17=c16; c16=c15; c15=c14; c14=c13; c13=c12; c12=c11; c11=c10; c10=c9; c9=c8; c8=c7; c7=c6; c6=c5; c5=c4; c4=c3; c3=c2; c2=c1; c1=c0; c0=10'd0; end
    if (&c16) begin c16=c15; c15=c14; c14=c13; c13=c12; c12=c11; c11=c10; c10=c9; c9=c8; c8=c7; c7=c6; c6=c5; c5=c4; c4=c3; c3=c2; c2=c1; c1=c0; c0=10'd0; end
  end

  // -------------------------------------------------------------
  // Máquina de Estados del Juego (Sincronizada a Vsync)
  // -------------------------------------------------------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r0 <= 10'd0;  r1 <= 10'd0;  r2 <= 10'd0;  r3 <= 10'd0;  r4 <= 10'd0;
      r5 <= 10'd0;  r6 <= 10'd0;  r7 <= 10'd0;  r8 <= 10'd0;  r9 <= 10'd0;
      r10 <= 10'd0; r11 <= 10'd0; r12 <= 10'd0; r13 <= 10'd0; r14 <= 10'd0;
      r15 <= 10'd0; r16 <= 10'd0; r17 <= 10'd0; r18 <= 10'd0; r19 <= 10'd0;
      piece_r     <= 5'd0;
      piece_c     <= 4'd4;
      piece_shape <= 2'd0;
      fall_count  <= 6'd0;
      last_left   <= 1'b0;
      last_right  <= 1'b0;
      last_rot    <= 1'b0;
    end else if (vsync_tick) begin
      last_left  <= inp_left;
      last_right <= inp_right;
      last_rot   <= btn_rot_input;

      // Reinicio automático si la fila superior se llena
      if (|r0) begin
        r0 <= 10'd0;  r1 <= 10'd0;  r2 <= 10'd0;  r3 <= 10'd0;  r4 <= 10'd0;
        r5 <= 10'd0;  r6 <= 10'd0;  r7 <= 10'd0;  r8 <= 10'd0;  r9 <= 10'd0;
        r10 <= 10'd0; r11 <= 10'd0; r12 <= 10'd0; r13 <= 10'd0; r14 <= 10'd0;
        r15 <= 10'd0; r16 <= 10'd0; r17 <= 10'd0; r18 <= 10'd0; r19 <= 10'd0;
        piece_r     <= 5'd0;
        piece_c     <= 4'd4;
        piece_shape <= 2'd0;
        fall_count  <= 6'd0;
      end else begin
        // Movimiento a la izquierda
        if (inp_left && !last_left && piece_c > 4'd0) begin
          if (!curr_row_bits[piece_c - 1]) piece_c <= piece_c - 1'b1;
        end
        // Movimiento a la derecha
        else if (inp_right && !last_right && piece_c < max_col) begin
          piece_c <= piece_c + 1'b1;
        end

        // Rotación
        if (btn_rot_input && !last_rot) begin
          piece_shape <= piece_shape + 1'b1;
          if (piece_c > 4'd7 && piece_shape == 2'd1) piece_c <= 4'd7;
        end

        // Caída: rápida con botón abajo (3 frames) o normal (16 frames)
        if (fall_count >= (inp_down ? 6'd3 : 6'd16)) begin
          fall_count <= 6'd0;

          if (hit_floor || hit_blocks) begin
            r0 <= c0;   r1 <= c1;   r2 <= c2;   r3 <= c3;   r4 <= c4;
            r5 <= c5;   r6 <= c6;   r7 <= c7;   r8 <= c8;   r9 <= c9;
            r10 <= c10; r11 <= c11; r12 <= c12; r13 <= c13; r14 <= c14;
            r15 <= c15; r16 <= c16; r17 <= c17; r18 <= c18; r19 <= c19;

            piece_r     <= 5'd0;
            piece_c     <= 4'd4;
            piece_shape <= piece_shape + 1'b1;
          end else begin
            piece_r <= piece_r + 1'b1;
          end
        end else begin
          fall_count <= fall_count + 1'b1;
        end
      end
    end
  end

  // -------------------------------------------------------------
  // Generador de Salida Gráfica VGA (RGB 2:2:2)
  // -------------------------------------------------------------
  wire [9:0] active_display_row = get_row(row_idx);
  wire current_board_block = active_display_row[col_idx];

  always @(posedge clk) begin
    if (~rst_n || !video_active) begin
      R <= 2'b00;
      G <= 2'b00;
      B <= 2'b00;
    end else if (text_pixel) begin
      // Texto "TETRIS BY HAPPYEDWIN" en amarillo brillante
      R <= 2'b11;
      G <= 2'b11;
      B <= 2'b00;
    end else if (in_border) begin
      // Marco del pozo en blanco
      R <= 2'b11;
      G <= 2'b11;
      B <= 2'b11;
    end else if (in_board) begin
      if (is_falling_pixel) begin
        // Pieza activa en verde
        if (grid_edge) begin
          R <= 2'b00;
          G <= 2'b10;
          B <= 2'b00;
        end else begin
          R <= 2'b00;
          G <= 2'b11;
          B <= 2'b00;
        end
      end else if (current_board_block) begin
        // Bloques asentados en cian
        if (grid_edge) begin
          R <= 2'b00;
          G <= 2'b10;
          B <= 2'b10;
        end else begin
          R <= 2'b00;
          G <= 2'b11;
          B <= 2'b11;
        end
      end else begin
        // Fondo con rejilla tenue
        if (grid_edge) begin
          R <= 2'b00;
          G <= 2'b00;
          B <= 2'b01;
        end else begin
          R <= 2'b00;
          G <= 2'b00;
          B <= 2'b00;
        end
      end
    end else begin
      // Fondo exterior oscuro
      R <= 2'b00;
      G <= 2'b00;
      B <= 2'b01;
    end
  end

endmodule
