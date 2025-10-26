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

// Global simulation time
vluint64_t main_time = 0;

// Called by $time in Verilog
double sc_time_stamp() {
    return main_time;
}


const uint32_t MEM_BASE = 0x80000000;
const uint32_t CACHE_SIZE = 0x200000;  // e.g., 2 MB, 2097152 bytes (Size of simulated main memory)

// --- L1 Data Cache Geometry Assumptions ---
// Assuming a 32KB cache with 32-byte lines (typical L1 structure)
const uint32_t ENTRIES = 64;
const uint32_t WORDS_PER_LINE = 2;
const uint32_t LINE_SIZE_BYTES = WORDS_PER_LINE * 4; // 8 bytes per line
const uint32_t BLOCK_OFFSET_BITS = 3;  // log2(LINE_SIZE_BYTES)
const uint32_t TAG_SHIFT = 9;          // INDEX_BITS (6) + BLOCK_OFFSET_BITS (3)
// ------------------------------------------

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
            // Accessing the RAM array via Verilator-generated path
            top->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__DATA_RAM_u__DOT__RAM[offset] = byte_val;
            offset++;
        }
    }

    mem_file.close();
    return true;
}

#include <fstream>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <string>
#include <cstdint>

void write_back_cache_to_mem(Vcore* top) {
    // --- Marker for execution ---
    std::ofstream marker("artifacts/writeback_marker.txt");
    marker << "write_back_cache_to_mem() executed\n";
    marker.close();

    // --- Read signature metadata file ---
    uint32_t sig_start = 0, sig_end = 0;
    {
        std::ifstream sigfile("artifacts/sig_meta.txt");
        if (sigfile.is_open()) {
            std::string line;
            if (std::getline(sigfile, line)) {
                std::istringstream iss(line);
                iss >> std::hex >> sig_start >> sig_end;
                std::cout << "Signature range loaded: 0x"
                          << std::hex << sig_start << " - 0x" << sig_end << std::dec << std::endl;
            } else {
                std::cerr << "WARNING: sig_meta.txt is empty or malformed.\n";
            }
        } else {
            std::cerr << "WARNING: Could not open artifacts/sig_meta.txt\n";
        }
    }

    // --- Open main log file ---
    std::ofstream log("artifacts/writeback_log.txt");
    if (!log.is_open()) {
        std::cerr << "ERROR: Could not open artifacts/writeback_log.txt for writing.\n";
        return;
    }

    std::cout << "Starting L1 D-Cache write-back to main memory..." << std::endl;
    std::cout.flush();

    for (uint32_t i = 0; i < ENTRIES; ++i) {
        bool valid = top->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__l1_dcache_array_u__DOT__valid_bit[i];
        bool dirty = top->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__l1_dcache_array_u__DOT__dirty_bit[i];

        if (valid) {
            uint32_t tag = top->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__l1_dcache_array_u__DOT__tag_arr[i];
            uint32_t physical_line_addr = (tag << TAG_SHIFT) | (i << BLOCK_OFFSET_BITS);

            log << "Entry: " << std::dec << i
                << " | " << (dirty ? "DIRTY" : "CLEAN")
                << " | Physical Line Addr: 0x" << std::hex << std::setw(8)
                << std::setfill('0') << physical_line_addr << std::dec << "\n";

            if (dirty) {
                if (physical_line_addr < MEM_BASE ||
                    (physical_line_addr - MEM_BASE) >= (CACHE_SIZE - LINE_SIZE_BYTES + 1)) {
                    std::cerr << "WARNING: Write-back target 0x" << std::hex << physical_line_addr
                              << " is outside simulated RAM bounds.\n";
                    log << "  WARNING: Write-back target out of bounds!\n";
                    continue;
                }

                // Iterate through the 8 words in the line
                for (uint32_t j = 0; j < WORDS_PER_LINE; ++j) {
                    uint32_t word = top->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__l1_dcache_array_u__DOT__data_cache[i][j];
                    uint32_t current_word_addr = physical_line_addr + (j * 4);
                    uint32_t mem_offset = current_word_addr - MEM_BASE;

                    // 🚫 Skip any writes at or beyond (sig_end - 4)
                    if (sig_end != 0 && current_word_addr >= (sig_end - 4)) {
                        log << "    SKIP: Word " << j
                            << " | Addr: 0x" << std::hex << std::setw(8) << current_word_addr
                            << " >= (sig_end - 4)=0x" << (sig_end - 4)
                            << " | Value: 0x" << std::setw(8) << word
                            << " | NOT WRITTEN\n" << std::dec;
                        continue;
                    }

                    // Normal write-back logging
                    log << "    Word " << std::setw(2) << j
                        << " | Addr: 0x" << std::hex << std::setw(8)
                        << std::setfill('0') << current_word_addr
                        << " | Value: 0x" << std::setw(8) << word << std::dec << "\n";

                    // Perform the actual write (little-endian)
                    for (int k = 0; k < 4; ++k) {
                        uint8_t byte_val = (word >> (8 * k)) & 0xFF;
                        top->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__DATA_RAM_u__DOT__RAM[mem_offset + k] = byte_val;
                    }
                }
            }
        }
    }

    log << "L1 D-Cache write-back complete.\n";
    log.close();

    std::cout << "L1 D-Cache write-back complete." << std::endl;
    std::cout.flush();
}


// Function to dump the data memory contents to a file, printing every 4 bytes (a word) per line, including zeros.
void dump_data_memory(const char* filename, Vcore* top) {
    std::ofstream dump_file(filename);
    if (!dump_file.is_open()) {
        std::cerr << "ERROR: Cannot create " << filename << " for memory dump.\n";
        return;
    }

    // Setup output stream formatting
    dump_file << std::hex << std::uppercase << std::setfill('0');
    
    // Iterate through the RAM array, advancing by 4 bytes (one word)
    for (uint32_t offset = 0; offset < CACHE_SIZE; offset += 4) {
        uint32_t word = 0;

        // Read 4 bytes from memory and combine them into a word (little-endian)
        for (int i = 0; i < 4; ++i) {
            uint32_t byte_offset = offset + i;
            uint8_t val = top->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__DATA_RAM_u__DOT__RAM[byte_offset];
            word |= (uint32_t)val << (8 * i);
        }

        // Physical Address (MEM_BASE + offset)
        dump_file << "0x" << std::setw(8) << (MEM_BASE + offset) << ": ";
        
        // 32-bit word of data
        dump_file << std::setw(8) << word << "\n";
    }

    dump_file.close();
    std::cout << "Memory dumped successfully to " << filename << " (all words, 4 bytes per line)\n";
    std::cout.flush(); // Ensure the message is printed
}


int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Vcore* top = new Vcore;
    bool memory_loaded = false;

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


    while (!Verilated::gotFinish() && main_time < 1500000) {
        // Toggle clock
        top->clk_i = !top->clk_i;

        // Apply reset after 20 time units
        if (main_time > 20)
            top->rst_i = 0;

            if (main_time > 20 && !memory_loaded) {
                // Load data memory on the first rising edge after reset release
                if (top->clk_i == 1) {
                    if (!load_data_memory("artifacts/data_mem.hex", top)) {
                        std::cerr << "Failed to load data memory!" << std::endl;
                        delete top;
                        return 1;
                    }
                    memory_loaded = true;
                    // dump_data_memory("artifacts/memory_before.txt", top);
                }
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
    
    std::cout << "[DEBUG] About to call write_back_cache_to_mem()" << std::endl;

    // === Write-back cache contents before memory operations ===
    write_back_cache_to_mem(top);

    // === MANDATORY: Memory Dump before termination ===
    // dump_data_memory("artifacts/memory_dump.txt", top);

    // === Signature extraction ===
    std::ifstream sig_meta("artifacts/sig_meta.txt");
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
    std::ofstream sig_out("artifacts/DUT.signature");
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
            uint8_t val = top->core__DOT__mem_u__DOT__data_mem_subsystem_u__DOT__DATA_RAM_u__DOT__RAM[offset];
            word |= val << (8 * i);
        }
    
        sig_out << std::hex << std::setw(8) << std::setfill('0') << word << "\n";
    }
    
    sig_out.close();
    delete top;
    return 0;
}
