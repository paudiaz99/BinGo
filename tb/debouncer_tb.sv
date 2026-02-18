`timescale 1ns / 1ps

`include "rtl/debouncer.v"
`include "rtl/counter.v"

module debouncer_tb;

    // Inputs
    reg clk;
    reg rstn;
    // ms_16 is now an output from the counter, used as input to debouncer
    wire ms_16; 
    reg p;

    // Outputs
    wire rc;
    wire enc;
    wire debouncedP;

    // Instantiate the Unit Under Test (UUT)
    debouncer uut (
        .clk(clk), 
        .rstn(rstn), 
        .ms_16(ms_16), 
        .p(p), 
        .rc(rc), 
        .enc(enc), 
        .debouncedP(debouncedP)
    );

    // Instantiate the Timer Counter for ms_16 generation
    // Setting COUNT to a small value for simulation speed (e.g., 20 cycles)
    counter #(.COUNT(20)) ms_timer (
        .clk(clk),
        .rstn(rc),
        .enable(enc), // Always enable for free-running timer
        .val(),        // Unused
        .overflow(ms_16)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock (10ns period)
    end

    // Test Stimulus
    initial begin
        $dumpfile("debouncer_tb.vcd");
        $dumpvars(0, debouncer_tb);
        // Initialize Inputs
        rstn = 0;
        p = 0;

        // Wait 100 ns for global reset to finish
        #100;
        rstn = 1;

        // Test Case 1: Simple Press with no bounce
        #50;
        $display("Test 1: Simple Press (No Bounce)");
        p = 1;
        
        // Wait for debouncer to lock (needs multiple ms_16 ticks)
        wait(debouncedP); 
        $display(" - Debounced High Detected at %t", $time);
        
        #500; // Hold for a while
        p = 0;
        wait(!debouncedP);
        $display(" - Debounced Low Detected at %t", $time);

        // Test Case 2: Bouncing Press
        #200;
        $display("Test 2: Bouncing Press");
        repeat(5) begin
            p = 1; #20;
            p = 0; #20;
        end
        p = 1; // Final stable press
        wait(debouncedP);
        $display(" - Bouncing Press Stabilized at %t", $time);

        // Test Case 3: Bouncing Release
        #200;
        $display("Test 3: Bouncing Release");
        repeat(5) begin
            p = 0; #20;
            p = 1; #20;
        end
        p = 0; // Final stable release
        wait(!debouncedP);
        $display(" - Bouncing Release Stabilized at %t", $time);

        // Test Case 4: Short Glitch (should be ignored)
        #200;
        $display("Test 4: Short Glitch (Noise)");
        p = 1;
        // Wait less than one ms_16 tick ideally, but here ms_16 is every 200ns approx.
        // Glitch of 50ns is < 200ns
        #50; 
        p = 0;
        #500; // Wait to see if it triggers
        if(debouncedP) $error(" - Error: Glitch was not filtered!");
        else $display(" - Glitch successfully filtered.");

        #500;
        $display("Simulation Finished");
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%t | p=%b | ms_16=%b | state=%b | debouncedP=%b | rc=%b | enc=%b", 
                 $time, p, ms_16, uut.current_state, debouncedP, rc, enc);
    end

endmodule
