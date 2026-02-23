module keyboard_ctrl (
    input clk,
    input rstn,
    input [2:0] keyboard_cols,
    
    output reg [3:0] keyboard_rows,
    output reg start_game,
    output reg [1:0] num_count,
    output wire [7:0] cascade_reg
);
    // Matric keyboard row generation
    wire shift_enable = ~new_num & ~start_game;
    
    always @(posedge clk) begin
        if(~rstn) begin
            keyboard_rows <= 4'b0001; // Start with first row active
        end else if(shift_enable) begin
            keyboard_rows <= {keyboard_rows[2:0], keyboard_rows[3]};
        end
    end

    // Keyboard Control
    wire new_num;
    wire new_num_debounced;
    wire [3:0] number_keyboard;

    keyboard_lut kb_ctrl(
        .rows(keyboard_rows),
        .cols(keyboard_cols),
        .number(number_keyboard),
        .new_num(new_num)
    );

    // 64-Bit Counter
    wire overflow;
    wire reset_counter;
    wire enable_counter;
    wire [63:0] unconnect_val;

    counter #(
        .COUNT(800000) // 800000 for 16ms @ 50MHz
    )debounce_counter(
        .clk(clk),
        .rstn(reset_counter),
        .enable(enable_counter),
        .val(unconnect_val),
        .overflow(overflow)
    );

    // Debouncer Control for keyboard
    debouncer denouncer_inst(
        .clk(clk),
        .rstn(rstn),
        .ms_16(overflow),
        .p(new_num),
        .rc(reset_counter),
        .enc(enable_counter),
        .debouncedP(new_num_debounced)
    );

    // Edge detector for new number
    wire new_num_edge;
    reg new_num_edge_r;

    always @(posedge clk) begin
        if(~rstn) begin
            new_num_edge_r <= 1'b0;
        end else begin
            new_num_edge_r <= new_num_debounced;
        end
    end

    // Rising edge detection to capture press
    assign new_num_edge = ~new_num_edge_r & new_num_debounced;

    always @(posedge clk) begin
        if(~rstn) num_count <= 2'b00;
        else if(new_num_edge) begin
             if(num_count == 2'b10) num_count <= 2'b01; // After first number, reset to 1
             else num_count <= num_count + 1;
        end
    end

    // Cascade Registers for storing the introduced numbers
    reg4Bit num1(
        .clk(clk),
        .rstn(rstn),
        .enable(new_num_edge),
        .d(number_keyboard),
        .q(cascade_reg[3:0])
    );

    reg4Bit num2(
        .clk(clk),
        .rstn(rstn),
        .enable(new_num_edge),
        .d(cascade_reg[3:0]),
        .q(cascade_reg[7:4])
    );
    always @(posedge clk) begin
        if(~rstn) start_game <= 1'b0;
        else if(cascade_reg[3:0] == 4'b1011 & ~start_game) start_game <= 1'b1;
    end

endmodule