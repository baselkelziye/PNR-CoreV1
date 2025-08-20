// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Primary design header
//
// This header should be included by all source files instantiating the design.
// The class here is then constructed to instantiate the design.
// See the Verilator manual for examples.

#ifndef _VCORE_H_
#define _VCORE_H_  // guard

#include "verilated_heavy.h"

//==========

class Vcore__Syms;

//----------

VL_MODULE(Vcore) {
  public:
    
    // PORTS
    // The application code writes and reads these signals to
    // propagate new values into/out from the Verilated model.
    VL_IN8(clk_i,0,0);
    VL_IN8(rst_i,0,0);
    
    // LOCAL SIGNALS
    // Internals; generally not touched by application code
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        CData/*0:0*/ core__DOT__branch_is_taken_prediction_if_o;
        CData/*4:0*/ core__DOT__rd_label_id_o;
        CData/*4:0*/ core__DOT__rs1_label_id_o;
        CData/*4:0*/ core__DOT__rs2_label_id_o;
        CData/*0:0*/ core__DOT__load_store_forward_sel_id_o;
        CData/*0:0*/ core__DOT__reg_write_en_id_o;
        CData/*0:0*/ core__DOT__rs1_pc_sel_id_o;
        CData/*0:0*/ core__DOT__rs2_imm_sel_id_o;
        CData/*0:0*/ core__DOT__is_branch_instr_id_o;
        CData/*0:0*/ core__DOT__is_store_instr_id_o;
        CData/*0:0*/ core__DOT__is_load_instr_id_o;
        CData/*1:0*/ core__DOT__wb_sel_id_o;
        CData/*3:0*/ core__DOT__alu_op_id_o;
        CData/*2:0*/ core__DOT__funct3_id_o;
        CData/*0:0*/ core__DOT__unconditional_branch_id_o;
        CData/*0:0*/ core__DOT__branch_is_taken_prediction_id_o;
        CData/*0:0*/ core__DOT__load_store_forward_sel_ex_o;
        CData/*0:0*/ core__DOT__reg_write_en_ex_o;
        CData/*0:0*/ core__DOT__is_load_instr_ex_o;
        CData/*0:0*/ core__DOT__is_store_instr_ex_o;
        CData/*4:0*/ core__DOT__rd_label_ex_o;
        CData/*1:0*/ core__DOT__wb_sel_ex_o;
        CData/*2:0*/ core__DOT__funct3_ex_o;
        CData/*0:0*/ core__DOT__branching_ex_o;
        CData/*4:0*/ core__DOT__rd_label_mem_o;
        CData/*0:0*/ core__DOT__reg_write_en_mem_o;
        CData/*0:0*/ core__DOT__if_u__DOT__branch_is_taken_prediction;
        CData/*1:0*/ core__DOT__if_u__DOT__bimodal_predictor_u__DOT__ex_pc_2bit_counter;
        CData/*0:0*/ core__DOT__id_u__DOT__load_stall;
        CData/*0:0*/ core__DOT__id_u__DOT__load_store_forward_sel;
        CData/*0:0*/ core__DOT__id_u__DOT__id_flush;
        CData/*7:0*/ core__DOT__id_u__DOT__control_unit_u__DOT__control_signals;
        CData/*0:0*/ core__DOT__id_u__DOT__control_unit_u__DOT__is_load_instr;
        CData/*0:0*/ core__DOT__id_u__DOT__control_unit_u__DOT__is_store_instr;
        CData/*0:0*/ core__DOT__id_u__DOT__control_unit_u__DOT__is_branch_instr;
        CData/*0:0*/ core__DOT__id_u__DOT__control_unit_u__DOT__unconditional_branch;
        CData/*3:0*/ core__DOT__id_u__DOT__control_unit_u__DOT__alu_op;
        CData/*0:0*/ core__DOT__ex_u__DOT__branch_is_taken;
        CData/*0:0*/ core__DOT__ex_u__DOT__wrong_prediction_NT_T;
        CData/*1:0*/ core__DOT__ex_u__DOT__forwardA;
        CData/*1:0*/ core__DOT__ex_u__DOT__forwardB;
        CData/*0:0*/ core__DOT__ex_u__DOT__forwarding_unit_u__DOT__rs1_mem_match;
        CData/*0:0*/ core__DOT__ex_u__DOT__forwarding_unit_u__DOT__rs2_mem_match;
        CData/*0:0*/ core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r;
        CData/*0:0*/ core__DOT__mem_u__DOT__o_wbs_ack;
        CData/*7:0*/ core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_byte;
        SData/*15:0*/ core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_half;
        IData/*31:0*/ core__DOT__pc_incremented_if_o;
        IData/*31:0*/ core__DOT__fetched_instruction_if_o;
        IData/*31:0*/ core__DOT__rs1_data_id_o;
        IData/*31:0*/ core__DOT__rs2_data_id_o;
        IData/*31:0*/ core__DOT__imm_value_id_o;
        IData/*31:0*/ core__DOT__pc_id_o;
        IData/*31:0*/ core__DOT__fetched_instruction_id_o;
        IData/*31:0*/ core__DOT__alu_result_ex_o;
        IData/*31:0*/ core__DOT__pc_ex_o;
        IData/*31:0*/ core__DOT__latest_rs2_value_ex_o;
        IData/*31:0*/ core__DOT__branch_address_ex_o;
        IData/*31:0*/ core__DOT__fetched_instruction_ex_o;
        IData/*31:0*/ core__DOT__load_value_mem_o;
        IData/*31:0*/ core__DOT__rd_value_mem_wo;
        IData/*31:0*/ core__DOT__rd_value_mem_ro;
        IData/*31:0*/ core__DOT__trace_file;
        IData/*31:0*/ core__DOT__if_u__DOT__pc_next;
    };
    struct {
        IData/*31:0*/ core__DOT__if_u__DOT__fetched_instruction;
        IData/*31:0*/ core__DOT__if_u__DOT__btb_predicted_pc;
        IData/*31:0*/ core__DOT__if_u__DOT__pc_reg;
        IData/*31:0*/ core__DOT__if_u__DOT__BTB__DOT__i;
        IData/*31:0*/ core__DOT__if_u__DOT__bimodal_predictor_u__DOT__i;
        IData/*31:0*/ core__DOT__id_u__DOT__imm_gen_u__DOT__imm_r;
        IData/*31:0*/ core__DOT__ex_u__DOT__alu1_input;
        IData/*31:0*/ core__DOT__ex_u__DOT__alu2_input;
        IData/*31:0*/ core__DOT__ex_u__DOT__rs1_latest_value;
        IData/*31:0*/ core__DOT__ex_u__DOT__rs2_latest_value;
        IData/*31:0*/ core__DOT__ex_u__DOT__ALU_u__DOT__result_r;
        IData/*31:0*/ core__DOT__mem_u__DOT__forwarded_store_value;
        IData/*31:0*/ core__DOT__mem_u__DOT__o_wbs_data;
        IData/*31:0*/ core__DOT__mem_u__DOT__loaded_data;
        IData/*31:0*/ core__DOT__mem_u__DOT__data_read_from_mem;
        IData/*31:0*/ core__DOT__mem_u__DOT__datum_cache_u__DOT__i;
        CData/*7:0*/ core__DOT__if_u__DOT__instr_cache_u__DOT__instructions[33554432];
        IData/*31:0*/ core__DOT__if_u__DOT__BTB__DOT__BTB[1024];
        CData/*1:0*/ core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer[1024];
        IData/*31:0*/ core__DOT__id_u__DOT__register_file_u__DOT__registers[32];
        CData/*7:0*/ core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[2097152];
    };
    
    // LOCAL VARIABLES
    // Internals; generally not touched by application code
    CData/*5:0*/ __Vtableidx1;
    CData/*0:0*/ __Vdlyvset__core__DOT__id_u__DOT__register_file_u__DOT__registers__v0;
    CData/*4:0*/ __Vdlyvdim0__core__DOT__id_u__DOT__register_file_u__DOT__registers__v1;
    CData/*0:0*/ __Vdlyvset__core__DOT__id_u__DOT__register_file_u__DOT__registers__v1;
    CData/*0:0*/ __Vclklast__TOP__clk_i;
    CData/*0:0*/ __Vclklast__TOP__rst_i;
    IData/*31:0*/ __Vdlyvval__core__DOT__id_u__DOT__register_file_u__DOT__registers__v1;
    static CData/*0:0*/ __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[64];
    
    // INTERNAL VARIABLES
    // Internals; generally not touched by application code
    Vcore__Syms* __VlSymsp;  // Symbol table
    
    // CONSTRUCTORS
  private:
    VL_UNCOPYABLE(Vcore);  ///< Copying not allowed
  public:
    /// Construct the model; called by application code
    /// The special name  may be used to make a wrapper with a
    /// single model invisible with respect to DPI scope names.
    Vcore(const char* name = "TOP");
    /// Destroy the model; called (often implicitly) by application code
    ~Vcore();
    
    // API METHODS
    /// Evaluate the model.  Application must call when inputs change.
    void eval() { eval_step(); }
    /// Evaluate when calling multiple units/models per time step.
    void eval_step();
    /// Evaluate at end of a timestep for tracing, when using eval_step().
    /// Application must call after all eval() and before time changes.
    void eval_end_step() {}
    /// Simulation complete, run final blocks.  Application must call on completion.
    void final();
    
    // INTERNAL METHODS
  private:
    static void _eval_initial_loop(Vcore__Syms* __restrict vlSymsp);
  public:
    void __Vconfigure(Vcore__Syms* symsp, bool first);
  private:
    static QData _change_request(Vcore__Syms* __restrict vlSymsp);
    static QData _change_request_1(Vcore__Syms* __restrict vlSymsp);
    void _ctor_var_reset() VL_ATTR_COLD;
  public:
    static void _eval(Vcore__Syms* __restrict vlSymsp);
  private:
#ifdef VL_DEBUG
    void _eval_debug_assertions();
#endif  // VL_DEBUG
  public:
    static void _eval_initial(Vcore__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _eval_settle(Vcore__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _initial__TOP__1(Vcore__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _sequent__TOP__3(Vcore__Syms* __restrict vlSymsp);
    static void _sequent__TOP__4(Vcore__Syms* __restrict vlSymsp);
    static void _sequent__TOP__6(Vcore__Syms* __restrict vlSymsp);
    static void _settle__TOP__5(Vcore__Syms* __restrict vlSymsp) VL_ATTR_COLD;
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

//----------


#endif  // guard
