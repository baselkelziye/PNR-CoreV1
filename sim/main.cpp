#include "Vcore.h"
#include "verilated.h"

#ifdef TRACE
#include "verilated_vcd_c.h"
#endif

#include <iostream>
#include <memory>

// ---- Global simulation parameters ----
vluint64_t sim_time = 0;              // Simulation time in ps
// const vluint64_t MAX_CYCLES = 50000000;  // Number of cycles to run
const vluint64_t MAX_CYCLES = 1500;  // Number of cycles to run
const vluint64_t CLOCK_PERIOD = 1000; // 1ns = 1000ps clock period
const vluint64_t HALF_CLOCK_PERIOD = CLOCK_PERIOD / 2;

#ifdef TRACE
VerilatedVcdC* tfp = nullptr; // Use raw pointer for better control
#endif

Vcore* core = nullptr; // Use raw pointer

// Required by Verilator for timekeeping
double sc_time_stamp() {
    return sim_time;
}

void cleanup() {
#ifdef TRACE
    if (tfp) {
        tfp->close();
        delete tfp;
        tfp = nullptr;
    }
#endif
    
    if (core) {
        core->final();
        delete core;
        core = nullptr;
    }
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    try {
#ifdef TRACE
        Verilated::traceEverOn(true);
        tfp = new VerilatedVcdC();
#endif

        // Instantiate DUT
        core = new Vcore;

#ifdef TRACE
        core->trace(tfp, 99);
        tfp->open("core.vcd");
#endif

        // Apply reset
        core->rst_i = 1;
        core->clk_i = 0;

        // Reset sequence
        for (int i = 0; i < 20; i++) {
            core->clk_i = !core->clk_i;
            core->eval();
            sim_time += HALF_CLOCK_PERIOD;
#ifdef TRACE
            tfp->dump(sim_time);
#endif
        }

        core->rst_i = 0;

        // ---- Main simulation loop ----
        for (vluint64_t cycle = 0; cycle < MAX_CYCLES; cycle++) {
            core->clk_i = 1;
            core->eval();
            sim_time += HALF_CLOCK_PERIOD;
#ifdef TRACE
            tfp->dump(sim_time);
#endif

            core->clk_i = 0;
            core->eval();
            sim_time += HALF_CLOCK_PERIOD;
#ifdef TRACE
            tfp->dump(sim_time);
#endif
        }

        std::cout << "Simulation finished after " << MAX_CYCLES << " cycles." << std::endl;
        std::cout << "Total simulation time: " << sim_time << "ps" << std::endl;

    } catch (const std::exception& e) {
        std::cerr << "Exception caught: " << e.what() << std::endl;
    } catch (...) {
        std::cerr << "Unknown exception caught" << std::endl;
    }

    // Explicit cleanup
    cleanup();

    return 0;
}