#include "Vcore.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>
#include <iomanip>
#include <cstdint>
#include <cstring>
#include <unistd.h>
#include <sstream>
#include "Vcore___024root.h" 

// Global simulation time
vluint64_t main_time = 0;

double sc_time_stamp() {
    return main_time;
}

// --- Configuration Constants ---
const uint32_t PA_OFFSET  = 0x00410000; // VA + OFFSET = PA
const uint32_t MEM_SIZE   = 0x800000;   // 8MB Physical RAM
const uint32_t ENTRIES    = 32;         // Cache Lines
const uint32_t WORDS_PER_LINE = 4;
const uint32_t BLOCK_OFFSET_BITS = 4;
const uint32_t TAG_SHIFT = 9;

// --- Helper to verify bounds ---
bool is_valid_pa(uint32_t pa) {
    return (pa < MEM_SIZE);
}

// 1. Load Virtual Hex into Physical RAM
bool load_data_memory(const char* filename, Vcore* top) {
    std::ifstream mem_file(filename);
    if (!mem_file.is_open()) {
        std::cerr << "ERROR: Could not open hex file: " << filename << std::endl;
        return false;
    }

    // Create the trace log file
    std::ofstream load_log("artifacts/load_memory_trace.txt");
    load_log << "MDU/Core Memory Load Trace\n";
    load_log << "PA_OFFSET: 0x" << std::hex << std::setw(8) << std::setfill('0') << PA_OFFSET << "\n";
    load_log << "--------------------------------------------------\n";
    load_log << "Virtual VA  |  Physical PA  |  Data Byte\n";
    load_log << "--------------------------------------------------\n";

    std::string line;
    uint32_t current_va = 0;

    while (std::getline(mem_file, line)) {
        // Remove potential carriage returns from Windows-style files
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.empty()) continue;

        if (line[0] == '@') {
            // Handle Address Header (e.g., @00000000) 
            current_va = std::stoul(line.substr(1), nullptr, 16);
            load_log << "--- Jump to VA Header: 0x" << std::hex << std::setw(8) << current_va << " ---\n";
        } else {
            // Handle Data Line (e.g., 37 08 5C 7D ...) 
            std::istringstream iss(line);
            std::string byte_str;
            
            while (iss >> byte_str) {
                uint8_t byte_val = static_cast<uint8_t>(std::stoul(byte_str, nullptr, 16));
                uint32_t pa_addr = current_va + PA_OFFSET;

                // Log the individual byte translation
                load_log << "0x" << std::setw(8) << current_va 
                         << "  |  0x" << std::setw(8) << pa_addr 
                         << "  |  " << std::setw(2) << (int)byte_val << "\n";

                // Safety Check: Prevent writing outside of the allocated Verilator RAM array
                if (pa_addr < MEM_SIZE) {
                    top->rootp->core__DOT__RAM_u__DOT__MEMORY[pa_addr] = byte_val;
                } else {
                    load_log << "!! ERROR: PA 0x" << std::hex << pa_addr << " is OUT OF BOUNDS !!\n";
                }

                current_va++; // Move to next byte address
            }
        }
    }

    std::cout << "Memory load complete. Trace saved to artifacts/load_memory_trace.txt" << std::endl;
    load_log.close();
    mem_file.close();
    return true;
}

// 2. Write-back Cache (Physical) to Memory (Physical)
void write_back_cache_to_mem(Vcore* top) {
    uint32_t sig_start_va = 0, sig_end_va = 0;
    std::ifstream sigfile("artifacts/sig_meta.txt");
    if (sigfile >> std::hex >> sig_start_va >> sig_end_va) {
        std::cout << "Signature VA Range: 0x" << std::hex << sig_start_va 
                  << " - 0x" << sig_end_va << std::endl;
    }

    std::ofstream log("artifacts/writeback_log.txt");
    
    for (uint32_t i = 0; i < ENTRIES; ++i) {
        bool valid = top->rootp->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__l1_dcache_array_u__DOT__valid_bit[i];
        bool dirty = top->rootp->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__l1_dcache_array_u__DOT__dirty_bit[i];

        if (valid && dirty) {
            uint32_t tag = top->rootp->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__l1_dcache_array_u__DOT__tag_arr[i];
            uint32_t pa_line = (tag << TAG_SHIFT) | (i << BLOCK_OFFSET_BITS);

            for (uint32_t j = 0; j < WORDS_PER_LINE; ++j) {
                uint32_t word = top->rootp->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__l1_dcache_array_u__DOT__data_cache[i][j];
                uint32_t pa_word = pa_line + (j * 4);

                if (is_valid_pa(pa_word + 3)) {
                    for (int k = 0; k < 4; ++k) {
                        top->rootp->core__DOT__RAM_u__DOT__MEMORY[pa_word + k] = (word >> (8 * k)) & 0xFF;
                    }
                }
            }
        }
    }
    log.close();
}

// 3. Dump Physical Memory
void dump_data_memory(const char* filename, Vcore* top) {
    std::ofstream dump_file(filename);
    dump_file << std::hex << std::uppercase << std::setfill('0');
    
    for (uint32_t pa = 0; pa < MEM_SIZE; pa += 4) {
        uint32_t word = 0;
        for (int i = 0; i < 4; ++i) {
            word |= (uint32_t)top->rootp->core__DOT__RAM_u__DOT__MEMORY[pa + i] << (8 * i);
        }
        dump_file << "0x" << std::setw(8) << pa << ": " << std::setw(8) << word << "\n";
    }
    dump_file.close();
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vcore* top = new Vcore;
    bool memory_loaded = false;

    // Reset loop
    top->rst_i = 1;
    top->clk_i = 0;

    while (!Verilated::gotFinish() && main_time < 1000000) {
        top->clk_i = !top->clk_i;
        if (main_time > 100) top->rst_i = 0;

        if (top->rst_i == 0 && !memory_loaded && top->clk_i == 1) {
            load_data_memory("artifacts/program_test.hex", top);
            memory_loaded = true;
        }

        top->eval();
        main_time += 5;
    }

    // --- Post-Simulation Processing ---
    write_back_cache_to_mem(top);
    dump_data_memory("artifacts/memory_dump.txt", top);

    // Extract Signature using Translated Addresses
    std::ifstream sig_meta("artifacts/sig_meta.txt");
    uint32_t sig_begin_va = 0, sig_end_va = 0;
    sig_meta >> std::hex >> sig_begin_va >> sig_end_va;

    std::ofstream sig_out("artifacts/DUT.signature");
    for (uint32_t va = sig_begin_va; va < sig_end_va; va += 4) {
        uint32_t pa = va + PA_OFFSET;
        uint32_t word = 0;
        if (is_valid_pa(pa + 3)) {
            for (int i = 0; i < 4; ++i) {
                word |= (uint32_t)top->rootp->core__DOT__RAM_u__DOT__MEMORY[pa + i] << (8 * i);
            }
        }
        sig_out << std::hex << std::setw(8) << std::setfill('0') << word << "\n";
    }

    delete top;
    return 0;
}