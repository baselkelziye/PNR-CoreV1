#include "Vcore.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <iostream>
#include <fstream>
#include <iomanip>
#include <cstdint>
#include <cstring>
#include <sstream>
#include <unistd.h>

// ========================================================
// Global simulation time
// ========================================================
vluint64_t main_time = 0;

// Called by $time in Verilog
double sc_time_stamp() {
    return main_time;
}

// ========================================================
// Memory configuration
// ========================================================
const uint32_t MEM_BASE   = 0x80000000;
// 0x200000 bytes (2 MB) / 4 bytes/word = 0x80000 words.
// This is the number of 32-bit elements in your RAM array.
const uint32_t MEM_WORDS  = 0x80000;

// ========================================================
// Load memory contents from hex file into 32-bit wide RAM
// (Uses RMW (Read-Modify-Write) to handle little-endian byte loading)
// ========================================================
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

        uint32_t byte_addr = 0;
        std::stringstream ss;
        ss << std::hex << addr_str;
        ss >> byte_addr;

        // Calculate offset and index based on byte address
        uint32_t word_offset = (byte_addr - MEM_BASE) / 4; // Index into the 32-bit RAM array
        uint32_t byte_index  = (byte_addr - MEM_BASE) % 4; // Byte position within the 32-bit word

        if (word_offset >= MEM_WORDS) {
            std::cerr << "WARNING: Address out of range: 0x" 
                      << std::hex << byte_addr << std::endl;
            continue;
        }

        std::string byte_str;
        while (iss >> byte_str) {
            if (byte_str.length() != 2) {
                std::cerr << "WARNING: Invalid byte format '" 
                          << byte_str << "'\n";
                break;
            }

            uint8_t byte_val = static_cast<uint8_t>(
                std::stoul(byte_str, nullptr, 16)
            );

            // Access the 32-bit word element using the word offset
            // NOTE: Assumes the RAM path structure from our previous conversation.
            uint32_t& word = 
                top->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__DATA_RAM_u__DOT__RAM[word_offset];

            // 1. Clear the target byte location (0xFF mask shifted by byte_index * 8)
            word &= ~(0xFFu << (byte_index * 8));
            // 2. Insert the new byte value (shifted into the correct position)
            word |= (static_cast<uint32_t>(byte_val) << (byte_index * 8));

            // Move to the next byte position
            byte_index++;
            if (byte_index == 4) {
                // Crossed word boundary, reset byte index and move to next word
                byte_index = 0;
                word_offset++;
                if (word_offset >= MEM_WORDS) break; // End of RAM
            }
        }
    }

    mem_file.close();
    return true;
}

// ========================================================
// Memory dump function (Writes to a specified file)
// ========================================================
void dump_memory(Vcore* top, const char* output_filename) {
    std::ofstream out_file(output_filename);

    if (!out_file.is_open()) {
        std::cerr << "ERROR: Cannot create memory dump file: " << output_filename << std::endl;
        return;
    }

    std::cout << "\nWriting memory dump to: " << output_filename << std::endl;
    
    out_file << "========================================================" << std::endl;
    out_file << "MEMORY DUMP (Address: Value)" << std::endl;
    uint32_t last_addr = MEM_BASE + (MEM_WORDS * 4) - 4;
    out_file << "Range: 0x" << std::hex << std::uppercase << std::setw(8) << std::setfill('0') << MEM_BASE 
              << " - 0x" << std::setw(8) << std::setfill('0') << last_addr << std::endl;
    out_file << "========================================================" << std::endl;

    for (uint32_t word_offset = 0; word_offset < MEM_WORDS; ++word_offset) {
        uint32_t address = MEM_BASE + (word_offset * 4);
        
        // Read the full 32-bit word directly
        uint32_t word = top->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__DATA_RAM_u__DOT__RAM[word_offset];

        if (word != 0x0) {
            out_file << "0x" << std::setw(8) << std::setfill('0') << address
                     << ": 0x" << std::setw(8) << std::setfill('0') << word << std::endl;
        }
    }
    
    out_file << "========================================================" << std::endl;
    out_file.close();
    std::cout << std::dec << std::nouppercase;
}

// ========================================================
// Main simulation entry point
// ========================================================
int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Vcore* top = new Vcore;
    bool memory_loaded = false;
    // dump_enabled is no longer needed since we are dumping unconditionally
    // bool dump_enabled  = false; 

    // Check for dump flag in command line arguments (only trace is checked now)
    for (int i = 1; i < argc; ++i) {
        // We still need this loop if you want to keep checking for --dump, 
        // but its result (dump_enabled) is ignored for the dump_memory call.
        // It's removed here for simplicity based on the request.
        /* if (std::strcmp(argv[i], "--dump") == 0) {
            dump_enabled = true;
        } */
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

        // Load memory once after reset deassertion
        if (main_time > 20 && !memory_loaded) {
            if (!load_data_memory("artifacts/data_mem.hex", top)) {
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

    // Dump memory unconditionally after simulation
    dump_memory(top, "artifacts/memory_dump.txt");

    // ====================================================
    // Signature extraction (now using word-addressed access)
    // ====================================================
    std::ifstream sig_meta("artifacts/sig_meta.txt");
    uint32_t sig_begin = 0, sig_end = 0;
    if (!sig_meta.is_open()) {
        std::cerr << "ERROR: Cannot open sig_meta.txt\n";
        delete top;
        return 1;
    }

    sig_meta >> std::hex >> sig_begin >> sig_end;
    sig_meta.close();
    std::cout << "Signature range: 0x" << std::hex 
              << sig_begin << " - 0x" << sig_end << std::endl;

    std::ofstream sig_out("artifacts/DUT.signature");
    if (!sig_out.is_open()) {
        std::cerr << "ERROR: Cannot create DUT.signature\n";
        delete top;
        return 1;
    }

    // Loop through byte addresses, advancing by 4 for each word
    for (uint32_t addr = sig_begin; addr < sig_end; addr += 4) {
        // Check for out-of-bounds access
        if (addr < MEM_BASE || (addr - MEM_BASE) >= (MEM_WORDS * 4)) {
            std::cerr << "ERROR: Attempt to access out-of-bounds memory at 0x"
                      << std::hex << addr << std::endl;
            delete top;
            return 1;
        }

        // Compute the word index (offset)
        uint32_t word_offset = (addr - MEM_BASE) / 4;
        
        // Read the full 32-bit word directly from the array
        uint32_t word = 
            top->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__DATA_RAM_u__DOT__RAM[word_offset];

        // Output the word to the signature file
        sig_out << std::hex << std::setw(8) 
                << std::setfill('0') << word << "\n";
    }

    sig_out.close();
    delete top;
    return 0;
}
