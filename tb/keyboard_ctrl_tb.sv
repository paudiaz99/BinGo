`timescale 1ns / 1ps

`include "rtl/keyboard_ctrl.v"
`include "rtl/keyboard_lut.v"
`include "rtl/counter.v"
`include "rtl/debouncer.v"
`include "rtl/reg4Bit.v"

module keyboard_ctrl_tb;

    // Inputs
    reg clk;
    reg rstn;
    // user removed keyboard_rows from inputs, it's now an output from UUT driving the keypad
    wire [3:0] keyboard_rows; 
    reg [2:0] keyboard_cols;

    // Outputs
    wire start_game;
    wire [1:0] num_count;
    wire [7:0] cascade_reg;

    // Instantiate the Unit Under Test (UUT)
    keyboard_ctrl uut (
        .clk(clk), 
        .rstn(rstn), 
        .keyboard_cols(keyboard_cols), 
        .keyboard_rows(keyboard_rows),
        .start_game(start_game), 
        .num_count(num_count), 
        .cascade_reg(cascade_reg)
    );

    // Override the counter parameter for faster simulation
    defparam uut.debounce_counter.COUNT = 20;

    // Keypad Model State
    reg [3:0] pressed_row_mask; // One-hot mask of the row currently pressed
    reg [2:0] pressed_col_mask; // Value of col to drive when row matches

    // Keypad Logic: Drive cols based on rows and pressed key
    always @(*) begin
        if ((keyboard_rows & pressed_row_mask) != 0) begin
            // If the currently scanned row matches the pressed row, drive columns
            keyboard_cols = pressed_col_mask;
        end else begin
            // Otherwise high-Z (pulled low in this active-high logic? or just 0)
            // Assuming active-high logic based on previous code.
            keyboard_cols = 3'b0;
        end
    end

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Task to simulate a key press
    task press_key;
        input [3:0] r;
        input [2:0] c;
        input [3:0] expected_val; 
        begin
            $display("Time=%t | Pressing Key: RowMask=%b ColMask=%b (Expected: %h)", $time, r, c, expected_val);
            pressed_row_mask = r;
            pressed_col_mask = c;
            
            // Wait for debounce logic (stable high)
            // The scanner needs to find the row first.
            // Then debouncer needs time.
            #3000; 
            
            $display("Time=%t | Key Pressed State: num_count=%d cascade_reg=%h", $time, num_count, cascade_reg);
        end
    endtask

    task release_key;
        begin
            $display("Time=%t | Releasing Key", $time);
            pressed_row_mask = 4'b0;
            pressed_col_mask = 3'b0;
            
            // Wait for debounce logic (stable low)
            #2000;
            $display("Time=%t | Key Released State", $time);
        end
    endtask

    // Test Stimulus
    initial begin
        // Dump waves
        $dumpfile("keyboard_ctrl_tb.vcd");
        $dumpvars(0, keyboard_ctrl_tb);

        // Initialize Inputs
        rstn = 0;
        pressed_row_mask = 0;
        pressed_col_mask = 0;

        // Reset
        #100;
        rstn = 1;
        #100;
        
        // --- Verify Scanning ---
        // Wait a bit and check if rows are rotating
        #200;
        if(keyboard_rows == 0) $error("Error: keyboard_rows is 0! Scanning not working.");
        else $display("Scanning active. Rows=%b", keyboard_rows);


        // --- Test 1: Press '1' ---
        // Mapping: 7'b1000100 -> Row=1000, Col=100 -> '1'
        press_key(4'b1000, 3'b100, 4'h1);
        
        // Verification: Check if scanning stopped on the correct row?
        // uut logic: if(new_num) shift_enable=0.
        // new_num comes from lut(rows, cols).
        // If rows==1000 and cols==100 -> new_num=1. Scanning stops.
        
        if(uut.keyboard_rows !== 4'b1000) 
            $display("Info: Scanner halted on %b (Expected 1000 for key '1')", uut.keyboard_rows);
            
        if(cascade_reg[3:0] !== 4'h1) $error("Test 1 Failed: cascade_reg[3:0] should be 1, got %h", cascade_reg[3:0]);
        else $display("Test 1 Passed: '1' shifted in.");

        release_key();

        // --- Test 2: Press '2' ---
        // Mapping: 7'b1000010 -> Row=1000, Col=010 -> '2'
        press_key(4'b1000, 3'b010, 4'h2);
        
        if(cascade_reg[3:0] !== 4'h2) $error("Test 2 Failed: Low nibble should be 2, got %h", cascade_reg[3:0]);
        if(cascade_reg[7:4] !== 4'h1) $error("Test 2 Failed: High nibble should be 1, got %h", cascade_reg[7:4]);
        else $display("Test 2 Passed: '2' shifted in, '1' shifted to high nibble. Reg=%h", cascade_reg);
        
        release_key();

        // --- Test 3: Press 'Start Game' ('B') ---
        // Mapping: 7'b0001001 -> Row=0001, Col=001 -> 'B' (11)
        press_key(4'b0001, 3'b001, 4'hB);
        
        if(start_game) $display("Test 3 Passed: start_game signal asserted.");
        else $error("Test 3 Failed: start_game not asserted! cascade_reg[3:0]=%h", cascade_reg[3:0]);

        release_key();
        
        // --- Test 4: Verify Scanning Resumes ---
        #200;
        // After release, new_num=0, so shift_enable=1. Scanning should resume.
        // It might take a cycle to start shifting.
        // Monitor rows for changes.
        
        #500;
        $display("Final Check: Rows=%b", keyboard_rows);
        $display("Simulation Finished");
        $finish;
    end

endmodule
