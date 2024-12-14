import cocotb

from cocotb.triggers import Timer
import logging
logging.basicConfig(level=logging.NOTSET)
logger = logging.getLogger("cocotb")
logger.setLevel(logging.INFO)



filepath = "machine_codes/"
period_ns = 4
datum_cache_size = 1024
instruction_cache_size = 100

async def get_register_file(dut):
    return dut.id_u.register_file_u.registers

async def get_data_cache(dut):
    return dut.mem_u.datum_cache_u.cache_r

async def reset_register_file(dut):
    for i in range(32):
        dut.id_u.register_file_u.registers[i].value = 0

async def reset_data_cache(dut):
    for i in range(datum_cache_size):
        dut.mem_u.datum_cache_u.cache_r[i].value = 0

async def reset_instruction_cache(dut):
    for i in range(instruction_cache_size):
        dut.if_u.instr_cache_u.instructions[i].value = 0x13

async def load_instruction_cache(dut, file_path):
    #We reset instruction cache, datum cache and register file to mimic a full reset
    await reset_register_file(dut)
    await reset_data_cache(dut)
    await reset_instruction_cache(dut)
    
    await Timer(period_ns, units='ns')

    with open(file_path, "r") as file:
        lines = file.readlines()
        for i, line in enumerate(lines):
            instruction = int(line.strip(), 16)
            dut.if_u.instr_cache_u.instructions[i].value = instruction



@cocotb.coroutine
async def run_clock(dut, num_cycles, period_ns):
    """
    Coroutine to drive the clock signal of the DUT.
    
    :param dut: The device under test.
    :param num_cycles: Number of clock cycles to run.
    :param period_ns: Clock period in nanoseconds.
    """
    # Half period time calculation for toggling the clock.
    half_period = period_ns // 2

    # Run the clock for a specified number of cycles.
    for _ in range(num_cycles):
        dut.clk_i.value = 0
        await Timer(half_period, units='ns')
        dut.clk_i.value = 1
        await Timer(half_period, units='ns')



@cocotb.test()
async def basel_bubblesort(dut):
    filename = "basel_bubblesort.hex"
    dut.rst_i.value = 1
    await Timer(period_ns, units='ns')
    dut.rst_i.value = 0
    await Timer(period_ns, units='ns')
    await load_instruction_cache(dut, filepath + filename)
    num_cycles = 1250
    await run_clock(dut, num_cycles, period_ns)
    data_memory = await get_data_cache(dut)
    expected_data_values = ["0x01", "0x02", "0x03", "0x04", "0x05", "0x06", "0x07", "0x08", "0x09", "0x0b"]
    for i in range(10):
        assert data_memory[256 + i].value == int(expected_data_values[i],16), f"Data memory value mismatch at index {i}. Expected: {int(expected_data_values[i],16)}, Got: {data_memory[256 + i]}"


@cocotb.test()
async def branch_flush_test(dut):
    filename = "branch_flush.hex"
    dut.rst_i.value = 1
    await Timer(period_ns, units='ns')
    dut.rst_i.value = 0
    await Timer(period_ns, units='ns')
    await load_instruction_cache(dut, filepath + filename)
    num_cycles = 100
    await run_clock(dut, num_cycles, period_ns)
    registers = await get_register_file(dut)
    expected_register_values = ["0x10000", "0x20000", "0x0", "0xbbbbb000", "0x0"]
    for i in range(5):
        assert registers[i+1].value == int(expected_register_values[i],16), f"Register value mismatch at Register: {i+1}. Expected: {int(expected_register_values[i],16)}, Got: {registers[i+1]}"


@cocotb.test()
async def load_hazard_test(dut):
    filename = "load_hazard.hex"
    dut.rst_i.value = 1
    await Timer(period_ns, units='ns')
    dut.rst_i.value = 0
    await Timer(period_ns, units='ns')
    await load_instruction_cache(dut, filepath + filename)
    num_cycles = 100
    await run_clock(dut, num_cycles, period_ns)
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
    dut.rst_i.value = 1
    await Timer(period_ns, units='ns')
    dut.rst_i.value = 0
    await Timer(period_ns, units='ns')
    await load_instruction_cache(dut, filepath + filename)
    num_cycles = 100
    await run_clock(dut, num_cycles, period_ns)
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
    dut.rst_i.value = 1
    await Timer(period_ns, units='ns')
    dut.rst_i.value = 0
    await Timer(period_ns, units='ns')
    await load_instruction_cache(dut, filepath + filename)
    num_cycles = 400
    await run_clock(dut, num_cycles, period_ns)
    registers = await get_register_file(dut)
    expected_register_values = ["0xa", "0xb", "0x00eef000"]
    registers_id = [1,2,3]
    for idx, reg in enumerate(registers_id):
        dut_value = registers[reg].value
        expected_value = int(expected_register_values[idx],16)
        # logger.info(f"Register {reg}: {dut_value:#010x}")
        assert dut_value == expected_value, f"Register value mismatch at Register: {reg}. Expected: {expected_value}, Got: {int(dut_value):#010x}"

@cocotb.test()
async def peripheral_test(dut):
    filename = "peripheral.hex"
    dut.rst_i.value = 1
    await Timer(period_ns, units='ns')
    dut.rst_i.value = 0
    await Timer(period_ns, units='ns')
    await load_instruction_cache(dut, filepath + filename)
    num_cycles = 500
    await run_clock(dut, num_cycles, period_ns)
    registers = await get_register_file(dut)
    expected_register_values = ["0xCC"]
    registers_id = [1]
    for idx, reg in enumerate(registers_id):
        dut_value = registers[reg].value
        expected_value = int(expected_register_values[idx],16)
        assert dut_value == expected_value, f"Register value mismatch at Register: {reg}. Expected: {expected_value:#10x}, Got: {int(dut_value):#010x}"
    #FIFO Tests
    tx_fifo_array = dut.mem_u.wbs_uart_u.uart_unit.fifo_tx_unit.array_reg
    rx_fifo_array = dut.mem_u.wbs_uart_u.uart_unit.fifo_rx_unit.array_reg
    # logger.info(f"tx_fifo_array: {tx_fifo_array[0].value}")
    expected_fifo_values = ["0xA5", "0xF0", "0x55"]
    for i in range(3):
        assert tx_fifo_array[i].value == int(expected_fifo_values[i],16), f"TX FIFO value mismatch at index {i}. Expected: {int(expected_fifo_values[i],16)}, Got: {tx_fifo_array[i]}"
    