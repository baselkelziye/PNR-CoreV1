#include "Vcore.h"
#include "verilated.h"
#include "verilated_vcd_c.h"  // For waveform tracing

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    
    // Enable tracing
    Verilated::traceEverOn(true);  // Required for wave tracing

    // Instantiate the module
    Vcore* core = new Vcore;
    
    // Initialize inputs
    core->clk_i = 0;  // Initialize clock to 0
    core->rst_i = 1;  // Set reset to active (assuming active high)

    // Create a VCD (Value Change Dump) object for tracing
    VerilatedVcdC* tfp = new VerilatedVcdC;
    core->trace(tfp, 99);  // Trace depth (set appropriately)
    tfp->open("waveform.vcd");  // Open VCD file for writing

    // Simulation loop
    for (int i = 0; i < 20; i++) {
        // Toggle clock
        core->clk_i = !core->clk_i;  // Toggle clock every iteration
        
        // Step the simulation
        core->eval();  // Evaluate the core module
        
        // Dump variables to VCD
        tfp->dump(i);  // Dump current state
        
        // Simulate reset for a few cycles
        if (i < 5) {
            core->rst_i = 1;  // Keep reset active for 5 cycles
        } else {
            core->rst_i = 0;  // Deactivate reset after 5 cycles
        }
    }

    // Close the trace file
    tfp->close();
    
    // Clean up
    delete core;
    delete tfp;
    
    return 0;
}
