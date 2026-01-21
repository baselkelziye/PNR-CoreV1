import cocotb
from cocotb.triggers import Timer
import logging

class MemoryModel:
    # --- Hardware Constants ---
    ENTRIES        = 32
    WORDS_PER_LINE = 4
    ADDRESS_WIDTH  = 32
    DATA_WIDTH     = 32
    INDEX_BITS     = 5        # $clog2(32)
    WORD_OFF_BITS  = 2        # $clog2(4)
    BYTE_OFF_BITS  = 2        # Fixed at 2 for 32-bit words
    
    # Address Construction Shifts
    SHIFT_TAG      = INDEX_BITS + WORD_OFF_BITS + BYTE_OFF_BITS
    SHIFT_INDEX    = WORD_OFF_BITS + BYTE_OFF_BITS
    SHIFT_WORD_OFF = BYTE_OFF_BITS
    SATP            = 0x00005000
    TRANSLATION_BASE = 0x00410000

    def __init__(self, dut, size=None):
        self.dut = dut
        self.log = logging.getLogger("cocotb.memory")
        
        # 1. Locate the Unified Physical Memory
        try:
            self.phys_ram = dut.RAM_u.MEMORY
            # self.log.info("Linked to Unified Physical Memory")
        except AttributeError:
            self.log.error("Could not find Unified RAM. check hierarchy.")
            # raise

        # 2. Determine Memory Size (Safely)
        if size:
            self.mem_size = size
        else:
            try:
                self.mem_size = len(self.phys_ram)
            except Exception:
                self.log.warning("Could not determine memory size automatically. Defaulting to 64KB bounds checks.")
                self.mem_size = 65536 # Default safety fallback
        self.vm_enabled = False

    def virt_to_phys(self, va):
        pa = va + self.TRANSLATION_BASE
        # pa = va
        return pa


    def write_byte(self, addr, value, is_va=True):
        if is_va:
            pa = self.virt_to_phys(addr)
        else:
            pa = addr

        if pa >= self.mem_size:
            # Optional: Catch out of bounds here
            pass
        
        self.phys_ram[pa].value = value

    def read_byte(self, addr, is_va=True):
        if is_va:
            pa = self.virt_to_phys(addr)
        else:
            pa = addr
            
        return self.phys_ram[pa].value.to_unsigned()

    # --- Word Access Helpers (Little Endian) ---
    def write_word(self, addr, value, is_va=True):
        self.write_byte(addr,   value & 0xFF,        is_va)
        self.write_byte(addr+1, (value >> 8) & 0xFF, is_va)
        self.write_byte(addr+2, (value >> 16) & 0xFF, is_va)
        self.write_byte(addr+3, (value >> 24) & 0xFF, is_va)

    def read_word(self, addr, is_va=True):
        """Reads a 32-bit integer."""
        b0 = self.read_byte(addr,   is_va)
        b1 = self.read_byte(addr+1, is_va)
        b2 = self.read_byte(addr+2, is_va)
        b3 = self.read_byte(addr+3, is_va)
        return (b3 << 24) | (b2 << 16) | (b1 << 8) | b0

    async def load_file(self, filename, target_base_va,is_va = True):
        # self.log.info(f"Loading {filename} at Virtual Base {hex(target_base_va)}")
        with open(filename, "r") as f:
            lines = f.readlines()
        
        current_va = target_base_va
        for line in lines:
            line = line.strip()
            if not line: continue
            byte_strings = line.split()
            for byte_str in byte_strings:
                if byte_str.startswith('@'): continue # Skip address markers if present
                val = int(byte_str, 16)
                self.write_byte(current_va, val,is_va)
                current_va += 1

    async def reset_memory(self):
        """
        Zeros out 0x2000 bytes at specific memory regions.
        """
        regions = [
            0x00410000,
            0x00428000,
        ]
        size = 0x2000

        for base in regions:
            # self.log.info(
            #     f"Zeroing out {size:#x} bytes starting at address {base:#010x}..."
            # )
            end = base + size
            for addr in range(base, end):
                self.phys_ram[addr].value = 0


    # --- Cache Backdoor Access ---

    def _get_cache_arrays(self):
        """
        Helper to retrieve internal signals from the DUT hierarchy.
        Adjust path strings if RTL hierarchy changes.
        """
        try:
            # Accessing internal RTL signals via dot notation
            valid_bit_arr = self.dut.mem_u.data_mem_subsystem_u.l1_dcache_array_u.valid_bit
            dirty_bit_arr = self.dut.mem_u.data_mem_subsystem_u.l1_dcache_array_u.dirty_bit
            tag_arr = self.dut.mem_u.data_mem_subsystem_u.l1_dcache_array_u.tag_arr
            
            # Try to access data_cache as a 2D array
            data_cache_arr = self.dut.mem_u.data_mem_subsystem_u.l1_dcache_array_u.data_cache
            
            return valid_bit_arr, dirty_bit_arr, tag_arr, data_cache_arr
        except AttributeError as e:
            self.log.error(f"Failed to find cache arrays in DUT hierarchy: {e}")
            raise

    async def write_cache_to_memory(self):
        """
        Writes all valid & dirty cache lines back to byte-addressable main memory.
        Used for verification to ensure memory consistency before ending simulation.
        """
        # self.log.info("Flushing Valid+Dirty Cache lines to Main Memory...")
        valid_bit_arr, dirty_bit_arr, tag_arr, data_cache_arr = self._get_cache_arrays()

        flush_count = 0

        for index in range(self.ENTRIES):
            # Resolve signal values to integers
            valid = int(valid_bit_arr[index].value)
            dirty = int(dirty_bit_arr[index].value)

            # We only care about Write-Back (Dirty) lines that are Valid
            if not (valid and dirty):
                continue
            
            flush_count += 1
            tag = int(tag_arr[index].value)

            for widx in range(self.WORDS_PER_LINE):
                WORD_OFF = widx

                # Construct physical byte address base for this word:
                # {tag, index, word_offset, 2'b00}
                addr_word = (tag << self.SHIFT_TAG) \
                        | (index << self.SHIFT_INDEX) \
                        | (WORD_OFF << self.SHIFT_WORD_OFF)

                # Try different methods to read the 2D array
                data_val = 0
                try:
                    # Method 1: Direct 2D access
                    data_val = int(data_cache_arr[index][widx].value)
                    # self.log.debug(f"Read using 2D access: data_cache[{index}][{widx}]")
                except:
                    try:
                        # Method 2: Access as a handle and use range
                        handle = data_cache_arr[index]
                        # Get the range/size of the second dimension
                        if hasattr(handle, '__len__'):
                            data_val = int(handle[widx].value)
                            # self.log.debug(f"Read using handle[{widx}]")
                        else:
                            # Method 3: Try to access as a flat array
                            flat_index = index * self.WORDS_PER_LINE + widx
                            data_val = int(data_cache_arr[flat_index].value)
                            # self.log.debug(f"Read using flat index {flat_index}")
                    except Exception as e:
                        self.log.error(f"Failed to read data_cache[{index}][{widx}]: {e}")
                        continue
                
                # self.log.info(
                #     f"Flushing line idx={index}, tag=0x{tag:X}, word[{widx}] = 0x{data_val:08X} "
                #     f"→ base addr 0x{addr_word:08X}"
                #     )
                
                # Write each byte separately (little-endian)
                for byte_i in range(4):  # 32-bit = 4 bytes
                    byte_val = (data_val >> (8 * byte_i)) & 0xFF
                    byte_addr = addr_word + byte_i
                    
                    # Direct backdoor write to physical RAM handle
                    if byte_addr < self.mem_size:
                        self.phys_ram[byte_addr].value = byte_val
                    else:
                        self.log.warning(f"Cache flush out of bounds: {hex(byte_addr)}")
        
        # self.log.info(f"Flush complete. {flush_count} dirty lines written back.")


    
    async def clear_cache(self):
        """
        Backdoor clear of the cache tag, valid, and dirty arrays.
        Effective for resetting cache state between tests.
        """
        # self.log.info("Clearing (Invalidating) L1 Data Cache...")
        valid_bit_arr, dirty_bit_arr, tag_arr, _ = self._get_cache_arrays()

        for index in range(self.ENTRIES):
            valid_bit_arr[index].value = 0
            dirty_bit_arr[index].value = 0
            tag_arr[index].value = 0
        
        # self.log.info("Cache arrays cleared.")

def main():
    mem = MemoryModel(None)
    print(f"PA: 0X{mem.virt_to_phys(0x16000):08X}")

if __name__ == "__main__":
    main()