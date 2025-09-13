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
logging.basicConfig(level=logging.DEBUG)

def get_signature_range(elf_path):
    import subprocess
    output = subprocess.check_output(
        ["/opt/riscv/bin/riscv64-unknown-elf-nm", elf_path]
    ).decode()

    begin = end = None
    for line in output.splitlines():
        if 'begin_signature' in line:
            begin = int(line.split()[0], 16)
        if 'end_signature' in line:
            end = int(line.split()[0], 16)
    return begin, end

class spike(pluginTemplate):
    __model__ = "spike"

    #TODO: please update the below to indicate family, version, etc of your DUT.
    __version__ = "1.1.1"

    def __init__(self, *args, **kwargs):
        sclass = super().__init__(*args, **kwargs)

        config = kwargs.get('config')

        self.ref_exe = os.path.join(config['PATH'] if 'PATH' in config else "","spike")
        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)
        self.pluginpath=os.path.abspath(config['pluginpath'])
        self.isa_spec = os.path.abspath(config['ispec']) if 'ispec' in config else ''
        self.platform_spec = os.path.abspath(config['pspec']) if 'ispec' in config else ''
        self.make = config['make'] if 'make' in config else 'make'
        logger.debug("spike plugin initialised using the following configuration.")
        for entry in config:
            logger.debug(entry+' : '+config[entry])
        return sclass

    def initialise(self, suite, work_dir, archtest_env):
        self.suite = suite
        if shutil.which(self.ref_exe) is None:
            logger.error('Please install Executable for DUTNAME to proceed further')
            raise SystemExit(1)
        self.work_dir = work_dir

        #TODO: The following assumes you are using the riscv-gcc toolchain. If
        #      not please change appropriately
        self.objdump_cmd = 'riscv{1}-unknown-elf-objdump -D {0} > {2};'
        self.compile_cmd = 'riscv{1}-unknown-elf-gcc -march={0} \
         -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles \
         -T '+self.pluginpath+'/env/link.ld\
         -I '+self.pluginpath+'/env/\
         -I ' + archtest_env

        # set all the necessary variables like compile command, elf2hex
        # commands, objdump cmds. etc whichever you feel necessary and required
        # for your plugin.

    def build(self, isa_yaml, platform_yaml):
        ispec = utils.load_yaml(isa_yaml)['hart0']
        self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')
        self.isa = 'rv' + self.xlen
        #TODO: The following assumes you are using the riscv-gcc toolchain. If
        #      not please change appropriately
        self.compile_cmd = self.compile_cmd+' -mabi='+('lp64 ' if 64 in ispec['supported_xlen'] else 'ilp32 ')
        if "I" in ispec["ISA"]:
            self.isa += 'i'
        if "M" in ispec["ISA"]:
            self.isa += 'm'
        if "C" in ispec["ISA"]:
            self.isa += 'c'
        if "F" in ispec["ISA"]:
            self.isa += 'f'
        if "D" in ispec["ISA"]:
            self.isa += 'd'

        # based on the validated isa and platform configure your simulator or
        # build your RTL here

    def runTests(self, testList, cgf_file=None):
        if os.path.exists(self.work_dir+ "/Makefile." + self.name[:-1]):
            os.remove(self.work_dir+ "/Makefile." + self.name[:-1])
        make = utils.makeUtil(makefilePath=os.path.join(self.work_dir, "Makefile." + self.name[:-1]))
        make.makeCommand = self.make + ' -j' + self.num_jobs
        for file in testList:
            testentry = testList[file]
            test = testentry['test_path']
            name = self.name[:-1]
            test_dir = testentry['work_dir']
            test_name = test.rsplit('/',1)[1][:-2]

            elf = 'ref.elf'
            # elf_path = os.path.join(test_dir,elf)
            # sig_begin,sig_end = get_signature_range(elf_path)
            # print(f"sig_begin: {sig_begin}, sig_end: {sig_end}")
            # sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")

            execute = "@cd "+testentry['work_dir']+";"

            # Use the dynamic ISA from the testentry
            cmd = self.compile_cmd.format(testentry['isa'].lower(), self.xlen) + ' ' + test + ' -o ' + elf
            
            # We are using -D to enable compile time macros.
            compile_cmd = cmd + ' -D' + " -D".join(testentry['macros'])
            

            execute+=compile_cmd+";"

            objdump_cmd = self.objdump_cmd.format(elf, self.xlen, 'ref.disass')
            # print(f"📦 Disassembling ELF: {objdump_cmd}")
            execute += objdump_cmd

            # Run Spike. The --log flag saves the memory state to 'ref.log'.
            # This command is correct.
            # spike_cmd = self.ref_exe + ' --isa=' + self.isa + ' --log-commits -l --log=' + 'ref.log' + ' ' + elf
            spike_cmd = self.ref_exe + f' --isa={self.isa} --log-commits +signature={name}.signature +signature-granularity=4 {elf} > ref.log 2>&1'
            execute += spike_cmd + ';'
            # print(f"Spike Command: {spike_cmd}")
            print(f"\n🚀Spike Compiling with: {execute}\n")

            make.add_target(execute)
        make.execute_all(self.work_dir)
