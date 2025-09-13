#include "Vcore.h"
#include "verilated.h"

#ifdef TRACE
#include "verilated_vcd_c.h"
#endif

#include <iostream>
#include <memory>

// ---- Global simulation parameters ----
vluint64_t sim_time = 0;              // Simulation time
const vluint64_t MAX_CYCLES = 10000;  // Number of cycles to run

#ifdef TRACE
// Trace pointer
std::unique_ptr<VerilatedVcdC> tfp;
#endif

// Required by Verilator for timekeeping
double sc_time_stamp() {
    return sim_time;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

#ifdef TRACE
    Verilated::traceEverOn(true);
#endif

    // Instantiate DUT
    std::unique_ptr<Vcore> core{new Vcore};

#ifdef TRACE
    tfp = std::make_unique<VerilatedVcdC>();
    core->trace(tfp.get(), 99);
    tfp->open("core.vcd");
#endif

    // Apply reset
    core->rst_i = 1;
    core->clk_i = 0;

    for (int i = 0; i < 10; i++) {
        core->clk_i = !core->clk_i;
        core->eval();
        sim_time++;
#ifdef TRACE
        tfp->dump(sim_time);
#endif
    }

    core->rst_i = 0; // Release reset

    // ---- Main simulation loop ----
    for (vluint64_t cycle = 0; cycle < MAX_CYCLES; cycle++) {
        core->clk_i = !core->clk_i; // Toggle clock
        core->eval();
        sim_time++;
#ifdef TRACE
        tfp->dump(sim_time);
#endif
    }

#ifdef TRACE
    tfp->close();
#endif

    core->final();
    std::cout << "Simulation finished after " << MAX_CYCLES << " cycles." << std::endl;
    return 0;
}
