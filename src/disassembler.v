/*
 * A simple disassembler for RiscV written in VERILOG.
 * Modified to return a string instead of printing.
 * Bruno Levy, August 2022, modified 2025
 * usage:
 * module XXX( ... );
 *   ...
 *   ...
 *   `include "riscv_disassembly.v" // yes, *inside* module definition.
 *   always @(posedge clk) begin
 *      str = riscv_disasm(instr, PC);
 *      $display("%s",str);
 *   end
 * endmodule
 */

 parameter RISCV_DISASM_STRLEN = 128;

 /* Functions to decode immediates */
 
 function signed [31:0] riscv_disasm_Iimm;
  input [31:0] instr;
  riscv_disasm_Iimm = {{21{instr[31]}}, instr[30:20]};
 endfunction
 
 function signed [31:0] riscv_disasm_Simm;
  input [31:0] instr;
  riscv_disasm_Simm = {{21{instr[31]}}, instr[30:25],instr[11:7]};
 endfunction
 
 function [19:0] riscv_disasm_Uimm_raw;
  input [31:0] instr;
  riscv_disasm_Uimm_raw = {instr[31:12]};
 endfunction
 
 function [31:0] riscv_disasm_Uimm;
  input [31:0] instr;
  riscv_disasm_Uimm = {instr[31],instr[30:12],{12{1'b0}}};
 endfunction
 
 function [31:0] riscv_disasm_Bimm;
  input [31:0] instr;
  riscv_disasm_Bimm = {
      {20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0
  };
 endfunction
 
 function [31:0] riscv_disasm_Jimm;
  input [31:0] instr;
  riscv_disasm_Jimm = {
          {12{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0
  };
 endfunction
 
 
 /* 
 * disassembler (now returns a string)
 */ 
 function [8*RISCV_DISASM_STRLEN-1:0] riscv_disasm;
   input [31:0] instr;
   input [31:0] PC;   
   reg [8*RISCV_DISASM_STRLEN-1:0] s;
   begin
      s = "";
      case(instr[6:0])
    7'b0110011: begin
       if(instr[31:7] == 0) begin
         $swrite(s,"nop");
       end else begin
          if(instr[25]) begin  // RV32M instructions
         case(instr[14:12])
           3'b000: $swrite(s,"mul x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
           3'b001: $swrite(s,"mulh x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
           3'b010: $swrite(s,"mulhsu x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
           3'b011: $swrite(s,"mulhu x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
           3'b100: $swrite(s,"div x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
           3'b101: $swrite(s,"divu x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
           3'b110: $swrite(s,"rem x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
           3'b111: $swrite(s,"remu x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
         endcase 
          end else begin
         case(instr[14:12])
           3'b000: $swrite(s,"%s x%0d,x%0d,x%0d",
                      instr[30] ? "sub" : "add",
                      instr[11:7],instr[19:15],instr[24:20]);
           3'b001: $swrite(s,"sll x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
           3'b010: $swrite(s,"slt x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
           3'b011: $swrite(s,"sltu x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
           3'b100: $swrite(s,"xor x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
           3'b101: $swrite(s,"%s x%0d,x%0d,x%0d",
                      instr[30] ? "sra" : "srl",
                      instr[11:7],instr[19:15],instr[24:20]);
           3'b110: $swrite(s,"or x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
           3'b111: $swrite(s,"and x%0d,x%0d,x%0d",instr[11:7],instr[19:15],instr[24:20]);
         endcase 
          end
       end
    end
    7'b0010011: begin
       case(instr[14:12])
         3'b000: $swrite(s,"addi x%0d,x%0d,%0d",
             instr[11:7],instr[19:15],riscv_disasm_Iimm(instr));
         3'b010: $swrite(s,"slti x%0d,x%0d,%0d",
             instr[11:7],instr[19:15],riscv_disasm_Iimm(instr));
         3'b011: $swrite(s,"sltiu x%0d,x%0d,%0d",
             instr[11:7],instr[19:15],riscv_disasm_Iimm(instr));
         3'b100: $swrite(s,"xori x%0d,x%0d,%0d",
             instr[11:7],instr[19:15],riscv_disasm_Iimm(instr));
         3'b110: $swrite(s,"ori x%0d,x%0d,%0d",
             instr[11:7],instr[19:15],riscv_disasm_Iimm(instr));
         3'b111: $swrite(s,"andi x%0d,x%0d,%0d",
             instr[11:7],instr[19:15],riscv_disasm_Iimm(instr));
         3'b001: $swrite(s,"slli x%0d,x%0d,%0d",
             instr[11:7],instr[19:15],instr[24:20]);
         3'b101: $swrite(s,"%s x%0d,x%0d,%0d",
             instr[30] ? "srai" : "srli",
             instr[11:7],instr[19:15],instr[24:20]);
       endcase
    end
    7'b1100011: begin
       case(instr[14:12])
         3'b000: $swrite(s,"beq x%0d,x%0d,0x%0h",
          instr[19:15],instr[24:20],PC+riscv_disasm_Bimm(instr));
         3'b001: $swrite(s,"bne x%0d,x%0d,0x%0h",
          instr[19:15],instr[24:20],PC+riscv_disasm_Bimm(instr));
         3'b100: $swrite(s,"blt x%0d,x%0d,0x%0h",
          instr[19:15],instr[24:20],PC+riscv_disasm_Bimm(instr));
         3'b101: $swrite(s,"bge x%0d,x%0d,0x%0h",
          instr[19:15],instr[24:20],PC+riscv_disasm_Bimm(instr));
         3'b110: $swrite(s,"bltu x%0d,x%0d,0x%0h",
          instr[19:15],instr[24:20],PC+riscv_disasm_Bimm(instr));
         3'b111: $swrite(s,"bgeu x%0d,x%0d,0x%0h",
          instr[19:15],instr[24:20],PC+riscv_disasm_Bimm(instr));
         default: $swrite(s,"B???");
       endcase 
    end
    7'b1100111:
      $swrite(s,"jalr x%0d,x%0d,%0d",
         instr[11:7],instr[19:15],riscv_disasm_Iimm(instr)
      );
    7'b1101111:
      $swrite(s,"jal x%0d,0x%0h",instr[11:7],PC+riscv_disasm_Jimm(instr));
    7'b0010111:
      $swrite(s,"auipc x%0d,0x%0h <0x%0h>",
         instr[11:7],
         riscv_disasm_Uimm_raw(instr),PC+riscv_disasm_Uimm(instr)
      );	  	  	  	  
    7'b0110111:
      $swrite(s,"lui x%0d,0x%0h <0x%0h>",
         instr[11:7],
         riscv_disasm_Uimm_raw(instr),riscv_disasm_Uimm(instr)
          );	  
    7'b0000011: begin
       case(instr[14:12])
         3'b000: $swrite(s,"lb x%0d,%0d(x%0d)",
          instr[11:7],riscv_disasm_Iimm(instr),instr[19:15]);
         3'b001: $swrite(s,"lh x%0d,%0d(x%0d)",
          instr[11:7],riscv_disasm_Iimm(instr),instr[19:15]);
         3'b010: $swrite(s,"lw x%0d,%0d(x%0d)",
          instr[11:7],riscv_disasm_Iimm(instr),instr[19:15]);
         3'b100: $swrite(s,"lbu x%0d,%0d(x%0d)",
          instr[11:7],riscv_disasm_Iimm(instr),instr[19:15]);
         3'b101: $swrite(s,"lhu x%0d,%0d(x%0d)",
          instr[11:7],riscv_disasm_Iimm(instr),instr[19:15]);
         default: $swrite(s,"l?? x%0d,%0d(x%0d)",
          instr[11:7],riscv_disasm_Iimm(instr),instr[19:15]);
       endcase 
    end
    7'b0100011: begin
       case(instr[14:12])
         3'b000: $swrite(s,"sb x%0d,%0d(x%0d)",
          instr[24:20],riscv_disasm_Simm(instr),instr[19:15]);
         3'b001: $swrite(s,"sh x%0d,%0d(x%0d)",
          instr[24:20],riscv_disasm_Simm(instr),instr[19:15]);
         3'b010: $swrite(s,"sw x%0d,%0d(x%0d)",
          instr[24:20],riscv_disasm_Simm(instr),instr[19:15]);
         default: $swrite(s,"s?? x%0d,%0d(x%0d)",
          instr[24:20],riscv_disasm_Simm(instr),instr[19:15]);
       endcase 
    end
    7'b1110011: begin
      // CSR / SYSTEM instructions
      // funct3 codes:
      // 000: ECALL/EBREAK (and some SYSTEMs)
      // 001: CSRRW
      // 010: CSRRS  (or rdcycle/rdinstret special cases)
      // 011: CSRRC
      // 101: CSRRWI
      // 110: CSRRSI
      // 111: CSRRCI
      reg [11:0] csr;
      csr = instr[31:20];

      case(instr[14:12])
        3'b000: begin
          // ECALL (0x00000073) or EBREAK (0x00100073) or generic SYSTEM
          if (instr == 32'h00000073) $swrite(s,"ecall");
          else if (instr == 32'h00100073) $swrite(s,"ebreak");
          else if (instr == 32'h10200073 ) $swrite(s,"sret");
          else $swrite(s,"SYSTEM");
        end

        3'b001: // CSRRW rd, csr, rs1
          $swrite(s,"csrrw x%0d,0x%0h,x%0d",
                  instr[11:7], csr, instr[19:15]);

        3'b010: begin
          // RFC: the original code special-cased counter CSRs here.
          // Keep those special names when CSR matches, otherwise it's CSRRS.
          case (csr)
            12'hC00: $swrite(s,"rdcycle x%0d",   instr[11:7]);
            12'hC80: $swrite(s,"rdcycleh x%0d",  instr[11:7]);
            12'hC02: $swrite(s,"rdinstret x%0d", instr[11:7]);
            12'hC82: $swrite(s,"rdinstreth x%0d",instr[11:7]);
            default:
              // CSRRS rd, csr, rs1
              $swrite(s,"csrrs x%0d,0x%0h,x%0d",
                      instr[11:7], csr, instr[19:15]);
          endcase
        end

        3'b011: // CSRRC rd, csr, rs1
          $swrite(s,"csrrc x%0d,0x%0h,x%0d",
                  instr[11:7], csr, instr[19:15]);

        3'b101: // CSRRWI rd, csr, zimm
          $swrite(s,"csrrwi x%0d,0x%0h,%0d",
                  instr[11:7], csr, instr[19:15]); // rs1 holds zimm for immediate forms

        3'b110: // CSRRSI rd, csr, zimm
          $swrite(s,"csrrsi x%0d,0x%0h,%0d",
                  instr[11:7], csr, instr[19:15]);

        3'b111: // CSRRCI rd, csr, zimm
          $swrite(s,"csrrci x%0d,0x%0h,%0d",
                  instr[11:7], csr, instr[19:15]);

        default:
          $swrite(s,"SYSTEM");
      endcase
   end

    default:
      $swrite(s,"?????");
      endcase
      riscv_disasm = s;
   end
 endfunction
 
 
 /* Instruction recognizers for the 10 RV32I instructions */
 function riscv_disasm_isALUreg; input [31:0] I; riscv_disasm_isALUreg=(I[6:0]==7'b0110011); endfunction
 function riscv_disasm_isALUimm; input [31:0] I; riscv_disasm_isALUimm=(I[6:0]==7'b0010011); endfunction
 function riscv_disasm_isBranch; input [31:0] I; riscv_disasm_isBranch=(I[6:0]==7'b1100011); endfunction
 function riscv_disasm_isJALR;   input [31:0] I; riscv_disasm_isJALR  =(I[6:0]==7'b1100111); endfunction
 function riscv_disasm_isJAL;    input [31:0] I; riscv_disasm_isJAL   =(I[6:0]==7'b1101111); endfunction
 function riscv_disasm_isAUIPC;  input [31:0] I; riscv_disasm_isAUIPC =(I[6:0]==7'b0010111); endfunction
 function riscv_disasm_isLUI;    input [31:0] I; riscv_disasm_isLUI   =(I[6:0]==7'b0110111); endfunction
 function riscv_disasm_isLoad;   input [31:0] I; riscv_disasm_isLoad  =(I[6:0]==7'b0000011); endfunction
 function riscv_disasm_isStore;  input [31:0] I; riscv_disasm_isStore =(I[6:0]==7'b0100011); endfunction
 function riscv_disasm_isSYSTEM; input [31:0] I; riscv_disasm_isSYSTEM=(I[6:0]==7'b1110011); endfunction
 function riscv_disasm_isRV32M;  input [31:0] I; riscv_disasm_isRV32M=riscv_disasm_isALUreg(I) && I[25]; endfunction
 
 /* Utility functions: register indices */
 function [4:0] riscv_disasm_rs1Id; input [31:0] I; riscv_disasm_rs1Id = I[19:15];      endfunction
 function [4:0] riscv_disasm_rs2Id; input [31:0] I; riscv_disasm_rs2Id = I[24:20];      endfunction
 function [4:0] riscv_disasm_shamt; input [31:0] I; riscv_disasm_shamt = I[24:20];      endfunction   
 function [4:0] riscv_disasm_rdId;  input [31:0] I; riscv_disasm_rdId  = I[11:7];       endfunction
 function [1:0] riscv_disasm_csrId; input [31:0] I; riscv_disasm_csrId = {I[27],I[21]}; endfunction
 
 /* Utility functions: funct3 and funct7 */
 function [2:0] riscv_disasm_funct3; input [31:0] I; riscv_disasm_funct3 = I[14:12]; endfunction
 function [6:0] riscv_disasm_funct7; input [31:0] I; riscv_disasm_funct7 = I[31:25]; endfunction      
 
 function riscv_disasm_readsRs1;
   input [31:0] I;
   riscv_disasm_readsRs1 = !(riscv_disasm_isJAL(I) || riscv_disasm_isAUIPC(I) || riscv_disasm_isLUI(I));
 endfunction
 
 function riscv_disasm_readsRs2;
   input [31:0] I;
   riscv_disasm_readsRs2 = riscv_disasm_isALUreg(I) || riscv_disasm_isBranch(I) || riscv_disasm_isStore(I);
 endfunction
 