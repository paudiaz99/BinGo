module top (
    input clk,
    input rstn,
    
    input [2:0] keyboard_cols,
    
    input [7:0] hack_number,
    input load_hack,
    input next,

    output [3:0] keyboard_rows,
    output [7:0] hex_selcted_number_1,
    output [7:0] hex_selcted_number_2,
    output [7:0] hex_gessed_number_1,
    output [7:0] hex_gessed_number_2,

    output [7:0] game_state_leds
);

// ***********************************
// Keyboard Control
// ***********************************

wire start_game;
wire [1:0] num_count;
wire [7:0] cascade_reg;

keyboard_ctrl keyboard_ctrl_inst(
    .clk(clk),
    .rstn(rstn),
    .keyboard_cols(keyboard_cols),
    .keyboard_rows(keyboard_rows),
    .start_game(start_game),
    .num_count(num_count),
    .cascade_reg(cascade_reg)
);

// ***********************************
// Player Number Control
// ***********************************

// Detect when two numbers have been introduced
wire new_number_edge;
reg new_number_r;
wire two_numbers_introduced = ~num_count[0] & num_count[1];

always @(posedge clk) begin
    if(~rstn) begin
        new_number_r <= 1'b0;
    end else begin
        new_number_r <= two_numbers_introduced; // Two numbers introduced
    end
end

assign new_number_edge = ~new_number_r & two_numbers_introduced;

// Accumulate how many numbers have been introduced
reg [3:0] numbers_introduced;

always @(posedge clk) begin
    if(~rstn) begin
        numbers_introduced <= 4'b0000;
    end else if(new_number_edge) begin
        numbers_introduced <= numbers_introduced + 1;
    end
end

// ***********************************
// Game Memory 8 Entries Per Player
// ***********************************
wire [7:0] output_number;

game_mem #(
    .ENTRIES(16),
    .ADDR_WIDTH(4),
    .DATA_WIDTH(8)
) game_mem_inst (
    .clk(clk),
    .rstn(rstn),
    .addr(start_game ? ram_addr : numbers_introduced),
    .data_in(ram_delete ? 8'b0 : cascade_reg),
    .write_en(start_game ? ram_write_en : new_number_edge),
    .data_out(output_number)
);

// ***********************************
// PRNG
// ***********************************

wire [7:0] prng_number;

lfsr_prng lfsr_inst(
    .clk(clk),
    .rstn(rstn),
    .enable(1'b1),
    .number(prng_number)
);

// ***********************************
// Game Logic
// ***********************************

// Edge detector for button.
wire next_edge;
reg next_edge_r;

always @(posedge clk) begin
    if(~rstn) next_edge_r <= 1'b0;
    else next_edge_r <= next;
end

assign next_edge = ~next_edge_r & next;

wire [3:0] ram_addr;
wire ram_delete;
wire ram_write_en;
wire enable_displays;
wire [15:0] game_state;
wire toggle_1s;

wire [7:0] guessed_number = load_hack ? hack_number : prng_number;

game_logic #( 
    .DATA_WIDTH(8),
    .ADDR_WIDTH(4),
    .NUM_ENTRIES(16)
) game_logic_inst (
    .clk(clk),
    .rstn(rstn),
    .start_game(start_game),
    .ram_read_number(output_number),
    .guessed_number(guessed_number),
    .next_edge(next_edge),
    .game_state(game_state),
    .ram_delete(ram_delete),
    .ram_write_en(ram_write_en),
    .enable_displays(enable_displays),
    .ram_addr(ram_addr),
    .toggle_1s(toggle_1s)
    
);

assign game_state_leds = toggle_1s ? game_state[7:0] : game_state[15:8];


// ***********************************
// Visualization Controller
// ***********************************

endmodule