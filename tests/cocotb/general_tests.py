import cocotb

from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge
import logging
logging.basicConfig(level=logging.NOTSET)
logger = logging.getLogger("cocotb")
logger.setLevel(logging.INFO)


ENTRIES        = 32
WORDS_PER_LINE = 4
ADDRESS_WIDTH  = 32
DATA_WIDTH     = 32
INDEX_BITS     = 5        # $clog2(32) = 5
WORD_OFF_BITS  = 2        # $clog2(4) = 2
BYTE_OFF_BITS  = 2        # $clog2(4) = 2, but typically fixed at 2 for 32-bit words
TAG_SIZE       = ADDRESS_WIDTH - (INDEX_BITS + WORD_OFF_BITS + BYTE_OFF_BITS)

filepath = "machine_codes/"
period_ns = 4
datum_cache_size = 0x2000
instruction_cache_size = 0x2000

def get_int_value(signal):
    """Return integer value from cocotb signal or BinaryValue safely."""
    try:
        # Works for handles and BinaryValue objects
        return int(signal.value)
    except AttributeError:
        return int(signal)


async def get_register_file(dut):
    return dut.id_u.register_file_u.registers

def get_data_cache(dut):
    return dut.mem_u.data_mem_subsystem_u.DATA_RAM_u.RAM

async def reset_register_file(dut):
    for i in range(32):
        dut.id_u.register_file_u.registers[i].value = 0

async def reset_instruction_cache(dut):
    for i in range(0, instruction_cache_size, 4):
        # Write 0x00000013 as little-endian bytes
        dut.if_u.instr_cache_u.instructions[i].value = 0x13    # LSB
        dut.if_u.instr_cache_u.instructions[i + 1].value = 0x00
        dut.if_u.instr_cache_u.instructions[i + 2].value = 0x00
        dut.if_u.instr_cache_u.instructions[i + 3].value = 0x00  # MSB

async def reset_data_mem(dut):
    data_mem =  get_data_cache(dut)
    for i in range(datum_cache_size):
        data_mem[i].value = 0x0
    
async def reset(dut):
    """Complete reset of the DUT including hardware reset pulse"""
    await FallingEdge(dut.clk_i)
    # Pulse hardware reset
    dut.rst_i.value = 1
    await ClockCycles(dut.clk_i, 3, rising=True)
    dut.rst_i.value = 0
    await FallingEdge(dut.clk_i)
    
    # Reset all memory structures
    await reset_register_file(dut)
    await reset_instruction_cache(dut)
    await reset_data_mem(dut)

async def load_instruction_cache(dut, file_path):

    with open(file_path, "r") as file:
        lines = file.readlines()
        instruction_index = 0
        for line in lines:
            line = line.strip()
            if not line:  # Skip empty lines
                continue
            
            # Split the line into individual byte strings
            byte_strings = line.split()
            
            # Each byte is already in the correct order (little-endian)
            # Store each byte directly in memory
            for byte_str in byte_strings:
                byte_value = int(byte_str, 16)
                dut.if_u.instr_cache_u.instructions[instruction_index].value = byte_value
                instruction_index += 1

async def load_data_cache(dut, file_path, start_addr=0):
    """
    Load data memory contents from a .mem/.hex file into the DUT's data RAM.
    The memory is byte-addressable.
    
    Args:
        dut: The DUT handle (simulation top-level object).
        file_path (str): Path to the memory initialization file.
        start_addr (int): Starting byte address in the RAM where data should be written.
    """
    data_mem = get_data_cache(dut)

    with open(file_path, "r") as file:
        lines = file.readlines()
        data_index = start_addr  # Start writing from given address offset

        for line in lines:
            line = line.strip()
            if not line:
                continue  # Skip empty lines

            # Split line into individual bytes
            byte_strings = line.split()

            for byte_str in byte_strings:
                byte_value = int(byte_str, 16)  # Convert hex string to integer
                data_mem[data_index].value = byte_value
                data_index += 1


def get_tag_array(dut):
    valid_bit_arr = dut.mem_u.data_mem_subsystem_u.l1_dcache_array_u.valid_bit
    dirty_bit_arr = dut.mem_u.data_mem_subsystem_u.l1_dcache_array_u.dirty_bit
    tag_arr = dut.mem_u.data_mem_subsystem_u.l1_dcache_array_u.tag_arr
    data_cache_arr = dut.mem_u.data_mem_subsystem_u.l1_dcache_array_u.data_cache
    return valid_bit_arr,dirty_bit_arr,tag_arr,data_cache_arr

async def write_cache_to_memory(dut):
    """
    Writes all valid & dirty cache lines back to byte-addressable main memory.
    """
    valid_bit_arr, dirty_bit_arr, tag_arr, data_cache_arr = get_tag_array(dut)
    data_ram = get_data_cache(dut)

    for index in range(ENTRIES):
        valid = int(valid_bit_arr[index].value)
        dirty = int(dirty_bit_arr[index].value)

        if not (valid and dirty):
            continue

        tag = int(tag_arr[index].value)

        for widx in range(WORDS_PER_LINE):
            WORD_OFF = widx

            # Construct physical word address:
            # {tag, index, {BYTE_OFF_BITS{1'b0}}, WORD_OFF}
            addr_word = (tag << (INDEX_BITS + WORD_OFF_BITS + BYTE_OFF_BITS)) \
                      | (index << (WORD_OFF_BITS + BYTE_OFF_BITS)) \
                      | (WORD_OFF << BYTE_OFF_BITS)

            # Read 32-bit word from cache
            try:
                data_val = int(data_cache_arr[index][widx].value)
            except:
                flat_index = index * WORDS_PER_LINE + widx
                data_val = int(data_cache_arr[flat_index].value)

            # Write each byte separately (little-endian)
            for byte_i in range(4):  # 32-bit = 4 bytes
                byte_val = (data_val >> (8 * byte_i)) & 0xFF
                byte_addr = addr_word + byte_i
                
                # Write single byte to byte-addressable memory
                data_ram[byte_addr].value = byte_val
                
                # Allow time for write to propagate
                await Timer(1, units='ns')

@cocotb.test()
async def basel_bubblesort(dut):
    filename = "basel_bubblesort.hex"
    cocotb.start_soon(Clock(dut.clk_i, 2, units="ns").start())
    await reset(dut)
    await load_instruction_cache(dut, filepath + filename)
    num_cycles = 1250
    await ClockCycles(dut.clk_i,num_cycles, rising=False)
    await write_cache_to_memory(dut)
    data_memory =  get_data_cache(dut)
    expected_data_values = ["0x01", "0x02", "0x03", "0x04", "0x05", "0x06", "0x07", "0x08", "0x09", "0x0b"]
    for i in range(10):
        assert data_memory[256 + i].value == int(expected_data_values[i],16), f"Data memory value mismatch at index {i}. Expected: {int(expected_data_values[i],16)}, Got: {data_memory[256 + i]}"


@cocotb.test()
async def branch_flush_test(dut):
    filename = "branch_flush.hex"
    cocotb.start_soon(Clock(dut.clk_i, 2, units="ns").start())
    await reset(dut)
    await load_instruction_cache(dut, filepath + filename)
    num_cycles = 100
    await ClockCycles(dut.clk_i,num_cycles, rising=False)
    registers = await get_register_file(dut)
    expected_register_values = ["0x10000", "0x20000", "0x0", "0xbbbbb000", "0x0"]
    for i in range(5):
        assert registers[i+1].value == int(expected_register_values[i],16), f"Register value mismatch at Register: {i+1}. Expected: {int(expected_register_values[i],16)}, Got: {registers[i+1]}"


@cocotb.test()
async def load_hazard_test(dut):
    filename = "load_hazard.hex"
    cocotb.start_soon(Clock(dut.clk_i, 2, units="ns").start())
    await reset(dut)
    await load_instruction_cache(dut, filepath + filename)
    num_cycles = 100
    await ClockCycles(dut.clk_i,num_cycles, rising=False)
    registers = await get_register_file(dut)
    expected_register_values = ["0xa", "0xa", "0x14", "0x1", "0xa", "0xa"]
    registers_id = [1,2,3,4,5,6]
    for idx, reg in enumerate(registers_id):
        dut_value = registers[reg].value
        expected_value = int(expected_register_values[idx],16)
        assert dut_value == expected_value, f"Register value mismatch at Register: {reg}. Expected: {expected_value}, Got: {dut_value}"


@cocotb.test()
async def forwarding_test(dut):
    filename = "forwarding_test.hex"
    cocotb.start_soon(Clock(dut.clk_i, 2, units="ns").start())
    await reset(dut)
    await load_instruction_cache(dut, filepath + filename)
    num_cycles = 100
    await ClockCycles(dut.clk_i,num_cycles, rising=False)
    registers = await get_register_file(dut)
    expected_register_values = ["0xc", "0x2", "0xe", "0xa", "0x55555000", "0x2", "0x55555002", "0x4", "0x2"]
    registers_id = [1,2,3,5,6,12,13,14,15]
    for idx, reg in enumerate(registers_id):
        dut_value = registers[reg].value
        expected_value = int(expected_register_values[idx],16)
        assert dut_value == expected_value, f"Register value mismatch at Register: {reg}. Expected: {expected_value}, Got: {dut_value}"

@cocotb.test()
async def loop_test(dut):
    filename = "loop.hex"
    cocotb.start_soon(Clock(dut.clk_i, 2, units="ns").start())
    await reset(dut)
    await load_instruction_cache(dut, filepath + filename)
    num_cycles = 400
    await ClockCycles(dut.clk_i,num_cycles, rising=False)
    registers = await get_register_file(dut)
    expected_register_values = ["0xa", "0xb", "0x00eef000"]
    registers_id = [1,2,3]
    for idx, reg in enumerate(registers_id):
        dut_value = registers[reg].value
        expected_value = int(expected_register_values[idx],16)
        # logger.info(f"Register {reg}: {dut_value:#010x}")
        assert dut_value == expected_value, f"Register value mismatch at Register: {reg}. Expected: {expected_value}, Got: {int(dut_value):#010x}"

@cocotb.test()
async def buffer_sum_test(dut):
    performance_filepath = "../performance_test/"
    machine_code_filename = "machine_codes/buffer_sum.hex"
    data_mem_filename = "memory_files/buffer_sum.mem"
    MEM_OFFSET = 256
    cocotb.start_soon(Clock(dut.clk_i, 2, units="ns").start())
    await reset(dut)
    await load_instruction_cache(dut, performance_filepath + machine_code_filename)
    await load_data_cache(dut, performance_filepath +data_mem_filename, MEM_OFFSET )
    num_cycles = 2000
    await ClockCycles(dut.clk_i, num_cycles, rising=False)
    registers = await get_register_file(dut)
    expected_register_values = ["0x00002040"]
    registers_id = [5]
    for idx, reg in enumerate(registers_id):
        dut_value = registers[reg].value
        expected_value = int(expected_register_values[idx],16)
        # logger.info(f"Register {reg}: {dut_value:#010x}")
        assert dut_value == expected_value, f"Register value mismatch at Register: {reg}. Expected: {expected_value}, Got: {int(dut_value):#010x}"

@cocotb.test()
async def mem_copy_test(dut):
    performance_filepath = "../performance_test/"
    machine_code_filename = "machine_codes/mem_copy.hex"
    A_ARR_ADDR = 256
    B_ARR_ADDR = 1024
    BUFFER_SIZE = 128
    CONST_VALUE = 5
    cocotb.start_soon(Clock(dut.clk_i, 2, units="ns").start())
    await reset(dut)
    await load_instruction_cache(dut, performance_filepath + machine_code_filename)
    num_cycles = 4000
    await ClockCycles(dut.clk_i, num_cycles, rising=False)
    await write_cache_to_memory(dut)
    data_memory =  get_data_cache(dut)
    for i in range (0,BUFFER_SIZE*4,4):
        assert data_memory[A_ARR_ADDR+i].value == CONST_VALUE, f"Data Memory Mismatch at ARR A"
        assert data_memory[B_ARR_ADDR+i].value == CONST_VALUE, f"Data Memory Mismatch at ARR B"

@cocotb.test()
async def matrix_mul_small(dut):
    performance_filepath = "../performance_test/"
    machine_code_filename = "machine_codes/matrix_mul_small.hex"
    data_mem_filenameA = "memory_files/small_a.mem"
    data_mem_filenameB = "memory_files/small_b.mem"
    data_mem_filenameC = "memory_files/small_c.mem"  # Add this line
    RESULT_MATRIX_BASE_ADDR = 0x2000
    A_MATRIX_BASE_ADDR = 0x0
    B_MATRIX_BASE_ADDR = 0x1000
    MATRIX_SIZE = 3

    
    cocotb.start_soon(Clock(dut.clk_i, 2, units="ns").start())
    await reset(dut)
    await load_instruction_cache(dut, performance_filepath + machine_code_filename)
    await load_data_cache(dut, performance_filepath + data_mem_filenameA, A_MATRIX_BASE_ADDR)
    await load_data_cache(dut, performance_filepath + data_mem_filenameB, B_MATRIX_BASE_ADDR)
    num_cycles = 1200
    await ClockCycles(dut.clk_i, num_cycles, rising=False)
    await write_cache_to_memory(dut)
    data_memory = get_data_cache(dut)

    with open(performance_filepath + data_mem_filenameC, 'r') as f:
        content = f.read()
    
    # Parse the hex values from the text
    expected_values = []
    lines = content.strip().split('\n')
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        # Split by spaces and parse each 2-character hex string
        tokens = line.split()
        for token in tokens:
            # Each token is like "05", "0B", "11" etc.
            # Convert from hex string to integer
            value = int(token, 16)
            expected_values.append(value)
    
    # Debug: Print what we parsed
    print(f"Parsed {len(expected_values)} expected values:")
    for i, val in enumerate(expected_values):
        print(f"  C[{i//MATRIX_SIZE}][{i%MATRIX_SIZE}]: 0x{val:02x}")
    
    # Verify each element
    for i in range(MATRIX_SIZE * MATRIX_SIZE):
        memory_int = data_memory[RESULT_MATRIX_BASE_ADDR + i].value.integer
        expected_value = expected_values[i]
        
        assert memory_int == expected_value, (
            f"Matrix C[{i//MATRIX_SIZE}][{i%MATRIX_SIZE}] mismatch: "
            f"Expected 0x{expected_value:02x}, Got 0x{memory_int:02x}"
        )
    
    dut._log.info("Matrix multiplication test passed! All results match.")



# @cocotb.test()
# async def peripheral_test(dut):
#     filename = "peripheral.hex"
#     dut.rst_i.value = 1
#     await Timer(period_ns, units='ns')
#     dut.rst_i.value = 0
#     await Timer(period_ns, units='ns')
#     await load_instruction_cache(dut, filepath + filename)
#     num_cycles = 500
#     await run_clock(dut, num_cycles, period_ns)
#     registers = await get_register_file(dut)
#     expected_register_values = ["0xCC"]
#     registers_id = [1]
#     for idx, reg in enumerate(registers_id):
#         dut_value = registers[reg].value
#         expected_value = int(expected_register_values[idx],16)
#         assert dut_value == expected_value, f"Register value mismatch at Register: {reg}. Expected: {expected_value:#10x}, Got: {int(dut_value):#010x}"
#     #FIFO Tests
#     tx_fifo_array = dut.mem_u.wbs_uart_u.uart_unit.fifo_tx_unit.array_reg
#     rx_fifo_array = dut.mem_u.wbs_uart_u.uart_unit.fifo_rx_unit.array_reg
#     # logger.info(f"tx_fifo_array: {tx_fifo_array[0].value}")
#     expected_fifo_values = ["0xA5", "0xF0", "0x55"]
#     for i in range(3):
#         assert tx_fifo_array[i].value == int(expected_fifo_values[i],16), f"TX FIFO value mismatch at index {i}. Expected: {int(expected_fifo_values[i],16)}, Got: {tx_fifo_array[i]}"