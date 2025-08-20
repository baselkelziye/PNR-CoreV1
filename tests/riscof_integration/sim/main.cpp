#include "Vcore.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>
#include <iomanip>
#include <cstdint>
#include <cstring>

// Global simulation time
vluint64_t main_time = 0;

// Called by $time in Verilog
double sc_time_stamp() {
    return main_time;
}


const uint32_t MEM_BASE = 0x80000000;
const uint32_t CACHE_SIZE = 0x200000;  // e.g., 256 KB


bool load_data_memory(const char* filename, Vcore* top) {
    std::ifstream mem_file(filename);
    if (!mem_file.is_open()) {
        std::cerr << "ERROR: Cannot open " << filename << std::endl;
        return false;
    }

    std::string line;
    while (std::getline(mem_file, line)) {
        if (line.empty()) continue;

        std::istringstream iss(line);
        std::string addr_str;
        iss >> addr_str;

        uint32_t offset = 0;
        std::stringstream ss;
        ss << std::hex << addr_str;
        ss >> offset;

        if (offset >= CACHE_SIZE) {
            std::cerr << "WARNING: Address out of range: 0x" << std::hex << offset << std::endl;
            continue; // skip line
        }

        std::string byte_str;
        while (iss >> byte_str) {
            if (byte_str.length() != 2) {
                std::cerr << "WARNING: Invalid byte format '" << byte_str << "'\n";
                break;
            }

            uint8_t byte_val = static_cast<uint8_t>(std::stoul(byte_str, nullptr, 16));

            if (offset >= CACHE_SIZE) {
                std::cerr << "WARNING: Memory write out of bounds at offset 0x" << std::hex << offset << std::endl;
                break;
            }
            top->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[offset] = byte_val;
            offset++;
        }
    }

    mem_file.close();
    return true;
}





int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Vcore* top = new Vcore;
    bool memory_loaded = false;

    bool dump_enabled = false;
    // Check for dump flag in command line arguments
    for (int i = 1; i < argc; ++i) {
        if (std::strcmp(argv[i], "--dump") == 0) {
            dump_enabled = true;
        }
    }

    // Optional waveform tracing
    VerilatedVcdC* tfp = nullptr;
#ifdef TRACE
    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("core.vcd");
#endif

    // Reset sequence
    top->rst_i = 1;
    top->clk_i = 0;


    while (!Verilated::gotFinish() && main_time < 150000) {
        // Toggle clock
        top->clk_i = !top->clk_i;

        // Apply reset after 20 time units
        if (main_time > 20)
            top->rst_i = 0;

            if (main_time > 20 && !memory_loaded) {
                if (!load_data_memory("/home/bkelziye/Desktop/PNR-CoreV1/tests/riscof_integration/sim/data_mem.hex", top)) {
                    std::cerr << "Failed to load data memory!" << std::endl;
                    delete top;
                    return 1;
                }
                memory_loaded = true;
            }
            
        // Evaluate the DUT
        top->eval();

    

        if (tfp) tfp->dump(main_time);
        main_time += 5;
    }

    if (tfp) {
        tfp->close();
        delete tfp;
    }

    // === Signature extraction ===
    // (Your existing signature extraction code)
    // ...
    std::ifstream sig_meta("/home/bkelziye/Desktop/PNR-CoreV1/tests/riscof_integration/sim/sig_meta.txt");
    uint32_t sig_begin = 0, sig_end = 0;
    if (!sig_meta.is_open()) {
        std::cerr << "ERROR: Cannot open sig_meta.txt\n";
        delete top;
        return 1;
    }

    sig_meta >> std::hex >> sig_begin >> sig_end;
    sig_meta.close();
    std::cout << "Signature range: 0x" << std::hex << sig_begin << " - 0x" << sig_end << std::endl;

    // Output signature file
    std::ofstream sig_out("DUT.signature");
    if (!sig_out.is_open()) {
        std::cerr << "ERROR: Cannot create DUT.signature\n";
        delete top;
        return 1;
    }

    
    for (uint32_t addr = sig_begin; addr < sig_end; addr += 4) {
        uint32_t word = 0;
    
        for (int i = 0; i < 4; ++i) {
            uint32_t byte_addr = addr + i;
    
            // Compute memory offset
            if (byte_addr < MEM_BASE || (byte_addr - MEM_BASE) >= CACHE_SIZE) {
                std::cerr << "ERROR: Attempt to access out-of-bounds memory at 0x"
                          << std::hex << byte_addr << std::endl;
                delete top;
                return 1;
            }
    
            uint32_t offset = byte_addr - MEM_BASE;
            uint8_t val = top->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[offset];
            word |= val << (8 * i);
        }
    
        sig_out << std::hex << std::setw(8) << std::setfill('0') << word << "\n";
    }
    
    sig_out.close();

    if (dump_enabled) {
        std::ofstream mem_file("memory_dump.txt");
        if (mem_file.is_open()) {
            mem_file << "==== Data Memory (4-byte words, little-endian) ====" << std::endl;

            for (uint32_t addr = 0; addr < CACHE_SIZE; addr += 4) {
                uint32_t word = 0;
                for (int i = 0; i < 4; ++i) {
                    uint32_t byte_addr = addr + i;
                    uint8_t val = 0;
                    if (byte_addr < CACHE_SIZE) {
                        val = top->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[byte_addr];
                    }
                    word |= (val << (8 * i));
                }

                mem_file << std::hex << std::setw(8) << std::setfill('0') << addr+MEM_BASE << ": "
                         << std::hex << std::setw(8) << std::setfill('0') << word << std::endl;
            }

            mem_file.close();
        } else {
            std::cerr << "Error: Unable to open file memory_dump.txt" << std::endl;
        }

        // === Register file dump ===
        std::ofstream reg_file("register_dump.txt");
        if (reg_file.is_open()) {
            reg_file << "==== Register File Dump (x0 - x31) ====" << std::endl;

            for (int i = 0; i < 32; ++i) {
                uint32_t reg_val = top->core__DOT__id_u__DOT__register_file_u__DOT__registers[i];
                reg_file << "x" << std::dec << std::setw(2) << i << ": "
                         << "0x" << std::hex << std::setw(8) << std::setfill('0')
                         << reg_val << std::endl;
            }

            reg_file.close();
        } else {
            std::cerr << "Error: Unable to open file register_dump.txt" << std::endl;
        }
    }

    delete top;
    return 0;
}