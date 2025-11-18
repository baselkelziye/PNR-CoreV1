function [1023:0] csr_name(input [11:0] csr_addr);
begin
    case (csr_addr)
        // Machine Information Registers
        12'hf11: csr_name = "MVENDORID";
        12'hf12: csr_name = "MARCHID";
        12'hf13: csr_name = "MIMPID";
        12'hf14: csr_name = "MHARTID";

        // Machine Trap Setup
        12'h300: csr_name = "MSTATUS";
        12'h301: csr_name = "MISA";
        12'h302: csr_name = "MEDELEG";
        12'h303: csr_name = "MIDELEG";
        12'h304: csr_name = "MIE";
        12'h305: csr_name = "MTVEC";
        12'h306: csr_name = "MCOUNTEREN";

        // Machine Trap Handling
        12'h340: csr_name = "MSCRATCH";
        12'h341: csr_name = "MEPC";
        12'h342: csr_name = "MCAUSE";
        12'h343: csr_name = "MTVAL";
        12'h344: csr_name = "MIP";

        // Supervisor Trap Setup
        12'h100: csr_name = "SSTATUS";
        12'h102: csr_name = "SEDELEG";
        12'h103: csr_name = "SIDELEG";
        12'h104: csr_name = "SIE";
        12'h105: csr_name = "STVEC";
        12'h106: csr_name = "SCOUNTEREN";

        // Supervisor Trap Handling
        12'h140: csr_name = "SSCRATCH";
        12'h141: csr_name = "SEPC";
        12'h142: csr_name = "SCAUSE";
        12'h143: csr_name = "STVAL";
        12'h144: csr_name = "SIP";

        // Supervisor Protection and Translation
        12'h180: csr_name = "SATP";

        // Memory Protection
        12'h3A0: csr_name = "PMPCFG0";
        12'h3A1: csr_name = "PMPCFG1";
        12'h3A2: csr_name = "PMPCFG2";
        12'h3A3: csr_name = "PMPCFG3";
        12'h3B0: csr_name = "PMPADDR0";
        12'h3B1: csr_name = "PMPADDR1";

        // Performance Counters
        12'hB00: csr_name = "MCYCLE";
        12'hB01: csr_name = "MTIME";
        12'hB02: csr_name = "MINSTRET";
        12'hB03: csr_name = "MHPMCOUNTER3";
        12'hB04: csr_name = "MHPMCOUNTER4";
        12'hB05: csr_name = "MHPMCOUNTER5";
        12'hB06: csr_name = "MHPMCOUNTER6";
        12'hB07: csr_name = "MHPMCOUNTER7";
        12'hB08: csr_name = "MHPMCOUNTER8";
        12'hB09: csr_name = "MHPMCOUNTER9";
        12'hB0A: csr_name = "MHPMCOUNTER10";
        12'hB0B: csr_name = "MHPMCOUNTER11";
        12'hB0C: csr_name = "MHPMCOUNTER12";
        12'hB0D: csr_name = "MHPMCOUNTER13";
        12'hB0E: csr_name = "MHPMCOUNTER14";
        12'hB0F: csr_name = "MHPMCOUNTER15";
        12'hB10: csr_name = "MHPMCOUNTER16";
        12'hB11: csr_name = "MHPMCOUNTER17";
        12'hB12: csr_name = "MHPMCOUNTER18";
        12'hB13: csr_name = "MHPMCOUNTER19";
        12'hB14: csr_name = "MHPMCOUNTER20";
        12'hB15: csr_name = "MHPMCOUNTER21";
        12'hB16: csr_name = "MHPMCOUNTER22";
        12'hB17: csr_name = "MHPMCOUNTER23";
        12'hB18: csr_name = "MHPMCOUNTER24";
        12'hB19: csr_name = "MHPMCOUNTER25";
        12'hB1A: csr_name = "MHPMCOUNTER26";
        12'hB1B: csr_name = "MHPMCOUNTER27";
        12'hB1C: csr_name = "MHPMCOUNTER28";
        12'hB1D: csr_name = "MHPMCOUNTER29";
        12'hB1E: csr_name = "MHPMCOUNTER30";
        12'hB1F: csr_name = "MHPMCOUNTER31";

        // Upper halves of performance counters
        12'hB80: csr_name = "MCYCLEH";
        12'hB81: csr_name = "MTIMEH";
        12'hB82: csr_name = "MINSTRETH";
        12'hB83: csr_name = "MHPMCOUNTER3H";
        12'hB84: csr_name = "MHPMCOUNTER4H";
        12'hB85: csr_name = "MHPMCOUNTER5H";
        12'hB86: csr_name = "MHPMCOUNTER6H";
        12'hB87: csr_name = "MHPMCOUNTER7H";
        12'hB88: csr_name = "MHPMCOUNTER8H";
        12'hB89: csr_name = "MHPMCOUNTER9H";
        12'hB8A: csr_name = "MHPMCOUNTER10H";
        12'hB8B: csr_name = "MHPMCOUNTER11H";
        12'hB8C: csr_name = "MHPMCOUNTER12H";
        12'hB8D: csr_name = "MHPMCOUNTER13H";
        12'hB8E: csr_name = "MHPMCOUNTER14H";
        12'hB8F: csr_name = "MHPMCOUNTER15H";
        12'hB90: csr_name = "MHPMCOUNTER16H";
        12'hB91: csr_name = "MHPMCOUNTER17H";
        12'hB92: csr_name = "MHPMCOUNTER18H";
        12'hB93: csr_name = "MHPMCOUNTER19H";
        12'hB94: csr_name = "MHPMCOUNTER20H";
        12'hB95: csr_name = "MHPMCOUNTER21H";
        12'hB96: csr_name = "MHPMCOUNTER22H";
        12'hB97: csr_name = "MHPMCOUNTER23H";
        12'hB98: csr_name = "MHPMCOUNTER24H";
        12'hB99: csr_name = "MHPMCOUNTER25H";
        12'hB9A: csr_name = "MHPMCOUNTER26H";
        12'hB9B: csr_name = "MHPMCOUNTER27H";
        12'hB9C: csr_name = "MHPMCOUNTER28H";
        12'hB9D: csr_name = "MHPMCOUNTER29H";
        12'hB9E: csr_name = "MHPMCOUNTER30H";
        12'hB9F: csr_name = "MHPMCOUNTER31H";

        // Counter/Event Control
        12'h320: csr_name = "MCOUNTINHIBIT";
        12'h323: csr_name = "MHPMEVENT3";
        12'h324: csr_name = "MHPMEVENT4";
        12'h325: csr_name = "MHPMEVENT5";
        12'h326: csr_name = "MHPMEVENT6";
        12'h327: csr_name = "MHPMEVENT7";
        12'h328: csr_name = "MHPMEVENT8";
        12'h329: csr_name = "MHPMEVENT9";
        12'h32A: csr_name = "MHPMEVENT10";
        12'h32B: csr_name = "MHPMEVENT11";
        12'h32C: csr_name = "MHPMEVENT12";
        12'h32D: csr_name = "MHPMEVENT13";
        12'h32E: csr_name = "MHPMEVENT14";
        12'h32F: csr_name = "MHPMEVENT15";
        12'h330: csr_name = "MHPMEVENT16";
        12'h331: csr_name = "MHPMEVENT17";
        12'h332: csr_name = "MHPMEVENT18";
        12'h333: csr_name = "MHPMEVENT19";
        12'h334: csr_name = "MHPMEVENT20";
        12'h335: csr_name = "MHPMEVENT21";
        12'h336: csr_name = "MHPMEVENT22";
        12'h337: csr_name = "MHPMEVENT23";
        12'h338: csr_name = "MHPMEVENT24";
        12'h339: csr_name = "MHPMEVENT25";
        12'h33A: csr_name = "MHPMEVENT26";
        12'h33B: csr_name = "MHPMEVENT27";
        12'h33C: csr_name = "MHPMEVENT28";
        12'h33D: csr_name = "MHPMEVENT29";
        12'h33E: csr_name = "MHPMEVENT30";
        12'h33F: csr_name = "MHPMEVENT31";

        default: csr_name = "UNKNOWN";
    endcase
end
endfunction


function [127:0] privilege_mode_converter(input [1:0] current_execution_mode);

case (current_execution_mode)
    `U_MODE: privilege_mode_converter = "U_MODE";
    `S_MODE: privilege_mode_converter = "S_MODE";
    `M_MODE: privilege_mode_converter = "M_MODE";
    default: privilege_mode_converter = "PANIC_MODE";
endcase

endfunction