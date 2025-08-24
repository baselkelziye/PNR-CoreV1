import os
import re
import shutil
import subprocess
import shlex
import logging
import random
import string
from string import Template
import sys

import riscof.utils as utils
import riscof.constants as constants
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()

def get_signature_range(elf_path):
    import subprocess
    output = subprocess.check_output(
        ["riscv32-unknown-elf-nm", elf_path]
    ).decode()

    begin = end = None
    for line in output.splitlines():
        if 'begin_signature' in line:
            begin = int(line.split()[0], 16)
        if 'end_signature' in line:
            end = int(line.split()[0], 16)
    return begin, end

def rebase_hex_file(filename: str, base_addr: int) -> None:
    """
    Rebases all '@' addresses in the hex file by subtracting base_addr.
    Overwrites the original file with the adjusted addresses.

    Args:
        filename (str): Path to the hex file to rebase.
        base_addr (int): Base address to subtract from each '@' address.

    Raises:
        ValueError: If any address in the file is below the base address.
    """
    with open(filename, "r") as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        line = line.strip()
        if line.startswith("@"):
            addr = int(line[1:], 16)
            new_addr = addr - base_addr
            if new_addr < 0:
                raise ValueError(f"Address {hex(addr)} is below base {hex(base_addr)}")
            new_lines.append(f"@{new_addr:08X}\n")
        else:
            new_lines.append(line + "\n")

    with open(filename, "w") as f:
        f.writelines(new_lines)

    print(f"File '{filename}' rebased successfully by subtracting {hex(base_addr)}.")


def rearrange_mem_file(path):
    """
    Rearrange memory dump so that each 32-bit word is printed per line
    according to endianness. Lines starting with '@' are left untouched.
    The file is modified in-place.
    """
    with open(path, "r") as f:
        lines = f.readlines()

    new_lines = []
    byte_buffer = []

    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue  # skip empty lines

        if stripped.startswith("@"):
            # Flush any buffered bytes before an address change
            for i in range(0, len(byte_buffer), 4):
                word_bytes = byte_buffer[i:i+4]
                if len(word_bytes) < 4:
                    word_bytes += ["00"] * (4 - len(word_bytes))
                new_lines.append("".join(reversed(word_bytes)) + "\n")
            byte_buffer.clear()

            new_lines.append(line)  # keep address line as-is
        else:
            # Add bytes to buffer
            byte_buffer.extend(stripped.split())

    # Flush any remaining bytes at end of file
    for i in range(0, len(byte_buffer), 4):
        word_bytes = byte_buffer[i:i+4]
        if len(word_bytes) < 4:
            word_bytes += ["00"] * (4 - len(word_bytes))
        new_lines.append("".join(reversed(word_bytes)) + "\n")

    # Overwrite the file
    with open(path, "w") as f:
        f.writelines(new_lines)

def extract_data_memory_from_hex(hex_filename, output_filename):
    """
    Parses the hex file and extracts all data sections annotated by addresses
    other than 0. Writes the data to output file with address and data bytes.

    :param hex_filename: Input .hex file path
    :param output_filename: Output file path for data memory dump
    """
    current_addr = None
    data_bytes = {}
    collect_data = False

    with open(hex_filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith('@'):
                current_addr = int(line[1:], 16)
                collect_data = (current_addr != 0)  # Only collect if addr != 0
            else:
                if current_addr is None:
                    raise ValueError("Data found before any address annotation")
                if collect_data:
                    bytes_str = line.split()
                    for b_str in bytes_str:
                        b = int(b_str, 16)
                        data_bytes[current_addr] = b
                        current_addr += 1
                else:
                    # Skip this data block entirely, just advance addr pointer
                    bytes_count = len(line.split())
                    current_addr += bytes_count

    # Write out the data memory content, 16 bytes per line
    sorted_addrs = sorted(data_bytes.keys())

    with open(output_filename, 'w') as out:
        line_start = None
        line_bytes = []

        for addr in sorted_addrs:
            if line_start is None:
                line_start = addr
            if addr != line_start + len(line_bytes):
                if line_bytes:
                    out.write(f"{line_start:08X}  " + ' '.join(f"{b:02X}" for b in line_bytes) + "\n")
                line_start = addr
                line_bytes = []
            line_bytes.append(data_bytes[addr])
            if len(line_bytes) == 16:
                out.write(f"{line_start:08X}  " + ' '.join(f"{b:02X}" for b in line_bytes) + "\n")
                line_start = None
                line_bytes = []

        if line_bytes:
            out.write(f"{line_start:08X}  " + ' '.join(f"{b:02X}" for b in line_bytes) + "\n")



# Usage example:
# extract_data_memory_from_hex('program.hex', 'data_memory_dump.txt')


class pnr_core(pluginTemplate):
    __model__ = "pnr_core"

    #TODO: please update the below to indicate family, version, etc of your DUT.
    __version__ = "latest"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        config = kwargs.get('config')

        # If the config node for this DUT is missing or empty. Raise an error. At minimum we need
        # the paths to the ispec and pspec files
        if config is None:
            print("Please enter input file paths in configuration.")
            raise SystemExit(1)

        # In case of an RTL based DUT, this would be point to the final binary executable of your
        # test-bench produced by a simulator (like verilator, vcs, incisive, etc). In case of an iss or
        # emulator, this variable could point to where the iss binary is located. If 'PATH variable
        # is missing in the config.ini we can hardcode the alternate here.
        self.dut_exe = os.path.join(config['PATH'] if 'PATH' in config else "","pnr_core")

        # Number of parallel jobs that can be spawned off by RISCOF
        # for various actions performed in later functions, specifically to run the tests in
        # parallel on the DUT executable. Can also be used in the build function if required.
        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)

        # Path to the directory where this python file is located. Collect it from the config.ini
        self.pluginpath=os.path.abspath(config['pluginpath'])

        # Collect the paths to the  riscv-config absed ISA and platform yaml files. One can choose
        # to hardcode these here itself instead of picking it from the config.ini file.
        self.isa_spec = os.path.abspath(config['ispec'])
        self.platform_spec = os.path.abspath(config['pspec'])

        #We capture if the user would like the run the tests on the target or
        #not. If you are interested in just compiling the tests and not running
        #them on the target, then following variable should be set to False
        if 'target_run' in config and config['target_run']=='0':
            self.target_run = False
        else:
            self.target_run = True

    def initialise(self, suite, work_dir, archtest_env):

       # capture the working directory. Any artifacts that the DUT creates should be placed in this
       # directory. Other artifacts from the framework and the Reference plugin will also be placed
       # here itself.
       self.work_dir = work_dir

       # capture the architectural test-suite directory.
       self.suite_dir = suite


       self.objdump_cmd = 'riscv{1}-unknown-elf-objdump -D {0} > {2};'

       self.compile_cmd = 'riscv{1}-unknown-elf-gcc -march={0} \
        -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles  \
        -T ' + self.pluginpath + '/env/link.ld \
        -I ' + self.pluginpath + '/env/ \
        -I ' + archtest_env + ' {2} -o {3} {4}'
    # add more utility snippets here
       

    def build(self, isa_yaml, platform_yaml):

      # load the isa yaml as a dictionary in python.
      ispec = utils.load_yaml(isa_yaml)['hart0']

      # capture the XLEN value by picking the max value in 'supported_xlen' field of isa yaml. This
      # will be useful in setting integer value in the compiler string (if not already hardcoded);
      self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')

      # for pnr_core start building the '--isa' argument. the self.isa is dutnmae specific and may not be
      # useful for all DUTs
      self.isa = 'rv' + self.xlen
      self.compile_cmd = self.compile_cmd+' -mabi='+('lp64 ' if 64 in ispec['supported_xlen'] else 'ilp32 ')

      if "I" in ispec["ISA"]:
          self.isa += 'i'
      if "M" in ispec["ISA"]:
          self.isa += 'm'
      if "F" in ispec["ISA"]:
          self.isa += 'f'
      if "D" in ispec["ISA"]:
          self.isa += 'd'
      if "C" in ispec["ISA"]:
          self.isa += 'c'

      #TODO: The following assumes you are using the riscv-gcc toolchain. If
      #      not please change appropriately
    #   self.compile_cmd = self.compile_cmd+' -mabi='+('lp64 ' if 64 in ispec['supported_xlen'] else 'ilp32 ')

      

    def runTests(self, testList):
        for testname in testList:
            testentry = testList[testname]
            test_dir = testentry['work_dir']
            test = testentry['test_path']
            elf = 'my.elf'
            sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")
            compile_macros = ' -D' + " -D".join(testentry['macros'])
            make_dir = os.path.abspath('./')

                # Run 'make clean' in ../../
            utils.shellCommand('make clean').run(cwd=make_dir)

            # Step 1: Compile the test to an ELF
            marchstr = testentry['isa'].lower()
            cmd = self.compile_cmd.format(marchstr, self.xlen, test, elf, compile_macros)
            print(f"\n🚀DUT Compiling with: {cmd}\n")
            utils.shellCommand(cmd).run(cwd=test_dir)

            objdump_cmd = self.objdump_cmd.format(elf,self.xlen,'dut.disass')
            utils.shellCommand(objdump_cmd).run(cwd=test_dir)

            if self.target_run:
                # Step 2: Convert ELF to Verilog HEX (placed at RTL hardcoded location)
                elf_path = os.path.join(test_dir, elf)
                binary_path = os.path.abspath('./artifacts/program_test.bin')
                hex_path = os.path.abspath('./artifacts/program_test.hex')
                data_mem_path = os.path.abspath('./artifacts/data_mem.hex')
               
                # Ensure directory exists
                os.makedirs(os.path.dirname(hex_path), exist_ok=True)

                convert_cmd = f"riscv32-unknown-elf-objcopy -O verilog  {elf_path} {hex_path}"
                # convert_cmd = f"riscv32-unknown-elf-objcopy -O verilog --verilog-data-width=4 {elf_path} {hex_path}"

            #     convert_cmd = (
            #     f"riscv32-unknown-elf-objcopy -O binary {elf_path} {binary_path} "
            #     f"&& hexdump -ve '1/4 \"%08x\\n\"' {binary_path} > {hex_path}"
            # )
                utils.shellCommand(convert_cmd).run()

                rebase_hex_file(hex_path,0x80000000)
                extract_data_memory_from_hex(hex_path,data_mem_path)

                # rearrange_mem_file(hex_path)


                # Extract signature addresses from ELF and write to meta file
                sig_begin, sig_end = get_signature_range(elf_path)
                # Create the artifacts directory if it doesn't exist
                artifacts_dir = os.path.abspath('./artifacts')
                os.makedirs(artifacts_dir, exist_ok=True)  # This creates the directory

                sig_meta_path = os.path.abspath('./artifacts/sig_meta.txt')
                with open(sig_meta_path, 'w') as f:
                    f.write(f"{sig_begin:x} {sig_end:x}\n")



                # Run 'make' in ../../
                utils.shellCommand('make riscof').run(cwd=make_dir)
                # Step 3: Run Verilator simulation (assumes hardcoded hex read in RTL)
                here = os.path.dirname(__file__)
                simcmd = os.path.join(here, '../artifacts/Vcore')
                simcmd = os.path.abspath(simcmd)
                utils.shellCommand(simcmd).run()

                # Step 4: Copy DUT-generated signature
                sig_out = './artifacts/DUT.signature'
                print("Looking for DUT signature at:", os.path.abspath(sig_out))
                if os.path.exists(sig_out):
                    shutil.copy(sig_out, sig_file)
                else:
                    logger.warning(f"Expected signature file {sig_out} not found.")

        if not self.target_run:
            raise SystemExit
