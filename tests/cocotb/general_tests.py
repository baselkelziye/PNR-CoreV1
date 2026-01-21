import cocotb

from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge
import logging
import os, sys
current_dir = os.path.dirname(os.path.abspath(__file__))
# Get the parent directory (project_root)
parent_dir = os.path.dirname(current_dir)
# Add the parent directory to the system path so Python can see 'models'
sys.path.append(parent_dir)
from models.MemoryModel import MemoryModel
logging.basicConfig(level=logging.NOTSET)
logger = logging.getLogger("cocotb")
logger.setLevel(logging.INFO)
#NOETS:
#IF i don't add Wait after write_cache in bubblesort it fails
#IF i do add wait after write_cache in mem_copy it fails.

ENTRIES        = 32
WORDS_PER_LINE = 4
ADDRESS_WIDTH  = 32
DATA_WIDTH     = 32
INDEX_BITS     = 5        # $clog2(32) = 5
WORD_OFF_BITS  = 2        # $clog2(4) = 2
BYTE_OFF_BITS  = 2        # $clog2(4) = 2, but typically fixed at 2 for 32-bit words
TAG_SIZE       = ADDRESS_WIDTH - (INDEX_BITS + WORD_OFF_BITS + BYTE_OFF_BITS)
ADDR_TRAP_BASE  = 0x0000
ADDR_INSTR_BASE = 0x0
ADDR_DATA_BASE  = 0x16000

filepath = "machine_codes/"
period_ns = 4
datum_cache_size = 0x20000
instruction_cache_size = 0x2000
trap_handler = "trap_handler.hex"

async def get_register_file(dut):
    return dut.id_u.register_file_u.registers

async def reset_register_file(dut):
    for i in range(32):
        dut.id_u.register_file_u.registers[i].value = 0


async def reset(dut, mem_model=None):
    """
    Complete reset of the DUT.
    Args:
        dut: The device under test.
        mem_model: Instance of MemoryModel class (optional but recommended).
    """
    await FallingEdge(dut.clk_i)
    
    # 1. Pulse Hardware Reset
    dut.rst_i.value = 1
    await ClockCycles(dut.clk_i, 3, rising=True)
    dut.rst_i.value = 0
    await FallingEdge(dut.clk_i)
    
    # 2. Reset Architectural State (Registers)
    await reset_register_file(dut)

    # 3. Reset Unified Memory
    # Instead of calling specific functions for I-Cache/D-Cache, 
    # we ask the model to clear the physical RAM.
    if mem_model is not None:
        await mem_model.reset_memory()
    else:
        # Fallback log if you forget to pass the model
        dut._log.warning("MemoryModel not passed to reset(). RAM content was not cleared.")

    await ClockCycles(dut.clk_i, 2, rising=True)  # Allow cache clear to propagate
def get_CPI(dut):
    # Convert cocotb handle values to integers safely
    try:
        cycles = int(dut.termination_cycle.value)
        instrs = int(dut.executed_instructions_reg.value)
    except ValueError:
        dut._log.error("Signals are in an undefined (X/Z) state. Cannot calculate CPI.")
        return

    # 1. Guard against Divide-by-Zero
    if instrs == 0:
        dut._log.warning("CPI Calculation failed: Executed instructions is 0. Is the core stalled?")
        return
    
    if cycles == 0:
        dut._log.warning("CPI Calculation failed: Cycle count is 0. Check reset logic.")
        return

    # 2. Correct Formula: CPI = Total Cycles / Finished Instructions
    # (Your previous code was doing Instructions / Cycles, which is IPC)
    cpi = cycles / instrs
    ipc = instrs / cycles

    # 3. Clean Logging
    test_name = cocotb._regression_manager._test.name
    dut._log.info(f"--- Performance Metrics: {test_name} ---")
    dut._log.info(f"Total Cycles: {cycles}")
    dut._log.info(f"Instructions: {instrs}")
    dut._log.info(f"Final CPI:    {cpi:.3f}")
    dut._log.info(f"Final IPC:    {ipc:.3f}")
    dut._log.info("-" * 40)
    
async def check_register_values(dut, expected_dict):
    """
    Generic register checker.
    Args:
        dut: Design handle
        expected_dict: Dictionary { register_index (int) : expected_value (int or hex str) }
    """
    # Access the register file array directly
    # Adjust path if your hierarchy changes!
    reg_file = dut.id_u.register_file_u.registers
    
    for reg_idx, expected_val in expected_dict.items():
        # Handle string input (e.g., "0x10") or int input
        if isinstance(expected_val, str):
            exp_int = int(expected_val, 16)
        else:
            exp_int = expected_val
            
        dut_val = reg_file[reg_idx].value.to_unsigned()
        
        assert dut_val == exp_int, (
            f"Register x{reg_idx} Mismatch! "
            f"Expected: {hex(exp_int)} ({exp_int}), "
            f"Got: {hex(dut_val)} ({dut_val})"
        )
    
    # dut._log.info(f"Verified {len(expected_dict)} registers successfully.")

@cocotb.test()
async def basel_bubblesort(dut):
    filename = "basel_bubblesort.hex"
    mem = MemoryModel(dut)
    # instr_pa_addr = mem.virt_to_phys(ADDR_INSTR_BASE)
    cocotb.start_soon(Clock(dut.clk_i, 2, unit="ns").start())
    await reset(dut, mem_model=mem)
    await mem.load_file(filepath +trap_handler ,0x0,is_va=False)
    await mem.load_file(filepath + filename,ADDR_INSTR_BASE,is_va=True)
    num_cycles = 10000
    await ClockCycles(dut.clk_i,num_cycles, rising=False)
    await mem.write_cache_to_memory()
    await ClockCycles(dut.clk_i,1, rising=False) #If we don't wait sometimes the cache update doesn't occur
    expected_data_values = ["0x01", "0x02", "0x03", "0x04", "0x05", "0x06", "0x07", "0x08", "0x09", "0x0b"]
    for i in range(10):
        mem_byte = mem.read_byte(ADDR_DATA_BASE+i,is_va=True)
        assert mem_byte == int(expected_data_values[i],16), f"Data memory value mismatch at index {i}. Expected: {int(expected_data_values[i],16)}, Got: {mem_byte}"
    get_CPI(dut)

@cocotb.test()
async def branch_flush_test(dut):
    filename = "branch_flush.hex"
    mem = MemoryModel(dut)
    cocotb.start_soon(Clock(dut.clk_i, 2, unit="ns").start())
    await reset(dut, mem_model=mem)
    #await mem.load_file(filepath +trap_handler ,0x0, is_va=False) #PA
    await mem.load_file(filepath+filename,ADDR_INSTR_BASE,is_va=True) #VA
    # await load_instruction_cache(dut, filepath + filename)
    num_cycles = 1000
    await ClockCycles(dut.clk_i,num_cycles, rising=False)
    expected_values = {
        1: "0x10000",
        2: "0x20000",
        3: "0x0",
        4: "0xbbbbb000",
        5: "0x0"
    }
    await check_register_values(dut, expected_values)
    get_CPI(dut)

@cocotb.test()
async def load_hazard_test(dut):
    filename = "load_hazard.hex"
    mem = MemoryModel(dut)
    cocotb.start_soon(Clock(dut.clk_i, 2, unit="ns").start())
    await reset(dut, mem_model=mem)
    #await mem.load_file(filepath +trap_handler ,0x0, is_va=False) #PA
    await mem.load_file(filepath+filename,ADDR_INSTR_BASE,is_va=True)
    # await load_instruction_cache(dut, filepath + filename)
    num_cycles = 1000
    await ClockCycles(dut.clk_i,num_cycles, rising=False)
    expected_values = {
        1: "0xa",
        2: "0xa",
        3: "0x14",
        4: "0x16001",
        5: "0xa",
        6: "0xa"
    }
    await check_register_values(dut,expected_values)
    get_CPI(dut)

@cocotb.test()
async def forwarding_test(dut):
    filename = "forwarding_test.hex"
    mem = MemoryModel(dut)
    cocotb.start_soon(Clock(dut.clk_i, 2, unit="ns").start())
    await reset(dut, mem_model=mem)
    #await mem.load_file(filepath +trap_handler ,0x0, is_va=False) #PA
    await mem.load_file(filepath+filename,ADDR_INSTR_BASE, is_va=True)
    # await load_instruction_cache(dut, filepath + filename)
    num_cycles = 1000
    await ClockCycles(dut.clk_i,num_cycles, rising=False)
    expected_values = {
        1: "0xc",
        2: "0x2",
        3: "0xe",
        5: "0xa",
        6: "0x55555000",
        12: "0x2",
        13: "0x55555002",
        14: "0x4",
        15: "0x2"
    }
    await check_register_values(dut,expected_values)
    get_CPI(dut)

@cocotb.test()
async def loop_test(dut):
    filename = "loop.hex"
    mem = MemoryModel(dut)
    cocotb.start_soon(Clock(dut.clk_i, 2, unit="ns").start())
    await reset(dut, mem_model=mem)
    #await mem.load_file(filepath +trap_handler ,0x0, is_va=False) #PA
    await mem.load_file(filepath+filename,ADDR_INSTR_BASE, is_va=True)
    num_cycles = 4000
    await ClockCycles(dut.clk_i,num_cycles, rising=False)
    expected_values = {
        1: "0xa",
        2: "0xb",
        3: "0x00eef000"
    }
    await check_register_values(dut,expected_values)
    get_CPI(dut)

@cocotb.test()
async def buffer_sum_test(dut):
    performance_filepath = "../performance_test/"
    machine_code_filename = "machine_codes/buffer_sum.hex"
    data_mem_filename = "memory_files/buffer_sum.mem"
    mem = MemoryModel(dut)
    cocotb.start_soon(Clock(dut.clk_i, 2, unit="ns").start())
    await reset(dut, mem_model=mem)
    #Load Instructions at 0x4000
    #await mem.load_file(filepath +trap_handler ,0x0, is_va=False) #PA
    await mem.load_file(performance_filepath+machine_code_filename,ADDR_INSTR_BASE, is_va=True)
    #Load Data at 0x16000
    await mem.load_file(performance_filepath+data_mem_filename,ADDR_DATA_BASE,is_va=True)
    num_cycles =5000
    #Assign Base Array Addres to avoid recompiling
    # dut.id_u.register_file_u.registers[1].value = ADDR_DATA_BASE
    await ClockCycles(dut.clk_i, num_cycles, rising=False)
    expected_values = {
        5: "0x00002040"
    }
    await check_register_values(dut,expected_values)
    get_CPI(dut)

@cocotb.test()
async def mem_copy_test(dut):
    performance_filepath = "../performance_test/"
    machine_code_filename = "machine_codes/mem_copy.hex"
    mem = MemoryModel(dut)
    A_ARR_ADDR = 0x16000
    B_ARR_ADDR = 0x18000
    BUFFER_SIZE = 128
    CONST_VALUE = 5
    cocotb.start_soon(Clock(dut.clk_i, 2, unit="ns").start())
    await reset(dut, mem_model=mem)
    #await mem.load_file(filepath +trap_handler ,0x0, is_va=False) #PA
    await mem.load_file(performance_filepath+machine_code_filename,ADDR_INSTR_BASE,is_va=True)
    num_cycles = 10000
    await ClockCycles(dut.clk_i, num_cycles, rising=False)
    await mem.write_cache_to_memory()
    await ClockCycles(dut.clk_i,10, rising=False) #If we don't wait sometimes the cache update doesn't occur
    # await write_cache_to_memory(dut)
    for i in range(0, BUFFER_SIZE * 4, 4):
    # Calculate current byte offsets
        addr_a = A_ARR_ADDR + i
        addr_b = B_ARR_ADDR + i

        # Check Source (A)
        val_a = mem.read_word(addr_a,is_va=True)
        assert val_a == CONST_VALUE, f"Data Memory Mismatch at ARR A (Addr: {hex(addr_a)}): Expected {CONST_VALUE}, got {val_a}"

        # Check Destination (B)
        val_b = mem.read_word(addr_b,is_va=True)
        # dut._log.info(f"Addr: 0x{addr_b:08x}, val_b: 0x{val_b:08x}")
        assert val_b == CONST_VALUE, f"Data Memory Mismatch at ARR B (Addr: {hex(addr_b)}): Expected {CONST_VALUE}, got {val_b}"
    get_CPI(dut)

@cocotb.test()
async def matrix_mul_small(dut):
    performance_filepath = "../performance_test/"
    machine_code_filename = "machine_codes/matrix_mul_small.hex"
    data_mem_filenameA = "memory_files/small_a.mem"
    data_mem_filenameB = "memory_files/small_b.mem"
    data_mem_filenameC = "memory_files/small_c.mem"  # Add this line
    RESULT_MATRIX_BASE_ADDR = 0x20000
    A_MATRIX_BASE_ADDR = 0x16000
    B_MATRIX_BASE_ADDR = 0x18000
    MATRIX_SIZE = 3
    mem = MemoryModel(dut)
    cocotb.start_soon(Clock(dut.clk_i, 2, unit="ns").start())
    await reset(dut, mem_model=mem)
    #await mem.load_file(filepath +trap_handler ,0x0, is_va=False) #PA
    await mem.load_file(performance_filepath+machine_code_filename,ADDR_INSTR_BASE,is_va=True)
    await mem.load_file(performance_filepath+data_mem_filenameA,A_MATRIX_BASE_ADDR,is_va=True)
    await mem.load_file(performance_filepath+data_mem_filenameB,B_MATRIX_BASE_ADDR,is_va=True)
    num_cycles = 20000
    await ClockCycles(dut.clk_i, num_cycles, rising=False)
    await mem.write_cache_to_memory()
    await ClockCycles(dut.clk_i,1, rising=False) #If we don't wait sometimes the cache update doesn't occur
    # 7. Read Expected Results from File
    # 7. Read Expected Results from File
    expected_values = []
    with open(performance_filepath + data_mem_filenameC, 'r') as f:
        content = f.read()
    
    # Parse hex strings (e.g., "05", "0B") into integers
    lines = content.strip().split('\n')
    for line in lines:
        line = line.strip()
        if not line: continue
        tokens = line.split()
        for token in tokens:
            expected_values.append(int(token, 16))

    # 8. Verify Results using MemoryModel (Little Endian Word-wise)
    dut._log.info(f"Verifying Matrix Multiplication Results (Little Endian)...")
    
    # Iterate in chunks of 4 bytes (32-bit words)
    # We step i by 4: i, i+1, i+2, i+3 are the bytes for one word
    for i in range(0, len(expected_values), 4):
        # Ensure we have a full word left to read
        if i + 3 >= len(expected_values):
            break

        # Construct Expected Word (Little Endian: Byte 0 is LSB)
        b0 = expected_values[i]
        b1 = expected_values[i+1]
        b2 = expected_values[i+2]
        b3 = expected_values[i+3]
        expected_word = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)

        # Read Memory Word (MemoryModel.read_word is already Little Endian)
        addr = RESULT_MATRIX_BASE_ADDR + i
        memory_word = mem.read_word(addr,is_va=True)
        
        assert memory_word == expected_word, (
            f"Matrix Result Word mismatch at address {hex(addr)}: "
            f"Expected 0x{expected_word:08x}, Got 0x{memory_word:08x}"
        )

@cocotb.test()
async def store_buffer_test(dut):
    filename = "store_buffer.hex"
    mem = MemoryModel(dut)
    cocotb.start_soon(Clock(dut.clk_i, 2, unit="ns").start())
    await reset(dut, mem_model=mem)
    #await mem.load_file(filepath +trap_handler ,0x0, is_va=False) #PA
    await mem.load_file(filepath+filename,ADDR_INSTR_BASE, is_va=True)
    num_cycles = 4000
    await ClockCycles(dut.clk_i,num_cycles, rising=False)
    expected_values = {
        15: "0x44444000",
        16: "0x99999000",
        18: "0x99999077"
    }
    await check_register_values(dut,expected_values)
    get_CPI(dut)

@cocotb.test()
async def rob_0_test(dut):
    filename = "rob_0.hex"
    mem = MemoryModel(dut)
    cocotb.start_soon(Clock(dut.clk_i, 2, unit="ns").start())
    await reset(dut, mem_model=mem)
    #await mem.load_file(filepath +trap_handler ,0x0, is_va=False) #PA
    await mem.load_file(filepath+filename,ADDR_INSTR_BASE,is_va=True)
    num_cycles = 2000
    await ClockCycles(dut.clk_i,num_cycles, rising=False)
    expected_values = {
        1: "0x1",
        2: "0x2",
        3: "0x3",
        4: "0x4",
        5: "0x5",
        6: "0x6",
        7: "0x7",
        8: "0x8",
        9: "0x9",
    }
    await check_register_values(dut,expected_values)
    get_CPI(dut)

@cocotb.test()
async def rob_1_test(dut):
    filename = "rob_1.hex"
    mem = MemoryModel(dut)
    cocotb.start_soon(Clock(dut.clk_i, 2, unit="ns").start())
    await reset(dut, mem_model=mem)
    #await mem.load_file(filepath +trap_handler ,0x0, is_va=False) #PA
    await mem.load_file(filepath+filename,ADDR_INSTR_BASE,is_va=True)
    num_cycles = 1500
    await ClockCycles(dut.clk_i,num_cycles, rising=False)
    expected_values = {
        10: "0xa",
        11: "0xf"
    }
    await check_register_values(dut,expected_values)
    get_CPI(dut)
#Works but takes forever
# @cocotb.test()
# async def matrix_mul_large(dut):
#     performance_filepath = "../performance_test/"
#     machine_code_filename = "machine_codes/matrix_mul_large.hex"
#     data_mem_filenameA = "memory_files/large_a.txt"
#     data_mem_filenameB = "memory_files/large_b.txt"
#     data_mem_filenameC = "memory_files/large_c.txt"  # Add this line
#     RESULT_MATRIX_BASE_ADDR = 0xa000
#     A_MATRIX_BASE_ADDR = 0x0
#     B_MATRIX_BASE_ADDR = 0x5000
#     MATRIX_SIZE = 128

    
#     cocotb.start_soon(Clock(dut.clk_i, 2, unit="ns").start())
#     await reset(dut, mem_model=mem)
#     await load_instruction_cache(dut, performance_filepath + machine_code_filename)
#     await load_data_cache(dut, performance_filepath + data_mem_filenameA, A_MATRIX_BASE_ADDR)
#     await load_data_cache(dut, performance_filepath + data_mem_filenameB, B_MATRIX_BASE_ADDR)
#     num_cycles = 50000000
#     await ClockCycles(dut.clk_i, num_cycles, rising=False)
#     await write_cache_to_memory(dut)
#     data_memory = get_data_cache(dut)

#     with open(performance_filepath + data_mem_filenameC, 'r') as f:
#         content = f.read()
    
#     # Parse the hex values from the text
#     expected_values = []
#     lines = content.strip().split('\n')
    
#     for line in lines:
#         line = line.strip()
#         if not line:
#             continue
            
#         # Split by spaces and parse each 2-character hex string
#         tokens = line.split()
#         for token in tokens:
#             # Each token is like "05", "0B", "11" etc.
#             # Convert from hex string to integer
#             value = int(token, 16)
#             expected_values.append(value)
    
#     # Verify each element
#     for i in range(MATRIX_SIZE * MATRIX_SIZE):
#         memory_int = data_memory[RESULT_MATRIX_BASE_ADDR + i].value.to_unsigned()
#         expected_value = expected_values[i]
        
#         assert memory_int == expected_value, (
#             f"Matrix C[{i//MATRIX_SIZE}][{i%MATRIX_SIZE}] mismatch: "
#             f"Expected 0x{expected_value:02x}, Got 0x{memory_int:02x}"
#         )
#     get_CPI(dut)
