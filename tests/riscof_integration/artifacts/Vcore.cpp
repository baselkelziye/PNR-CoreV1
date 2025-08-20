// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vcore.h for the primary calling header

#include "Vcore.h"
#include "Vcore__Syms.h"

//==========

void Vcore::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vcore::eval\n"); );
    Vcore__Syms* __restrict vlSymsp = this->__VlSymsp;  // Setup global symbol table
    Vcore* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
#ifdef VL_DEBUG
    // Debug assertions
    _eval_debug_assertions();
#endif  // VL_DEBUG
    // Initialize
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) _eval_initial_loop(vlSymsp);
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Clock loop\n"););
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("src/core.v", 23, "",
                "Verilated model didn't converge\n"
                "- See DIDNOTCONVERGE in the Verilator manual");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

void Vcore::_eval_initial_loop(Vcore__Syms* __restrict vlSymsp) {
    vlSymsp->__Vm_didInit = true;
    _eval_initial(vlSymsp);
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        _eval_settle(vlSymsp);
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("src/core.v", 23, "",
                "Verilated model didn't DC converge\n"
                "- See DIDNOTCONVERGE in the Verilator manual");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

VL_INLINE_OPT void Vcore::_sequent__TOP__3(Vcore__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcore::_sequent__TOP__3\n"); );
    Vcore* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Variables
    CData/*0:0*/ __Vdlyvset__core__DOT__if_u__DOT__BTB__DOT__BTB__v0;
    CData/*1:0*/ __Vdlyvval__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v0;
    CData/*0:0*/ __Vdlyvset__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v0;
    CData/*1:0*/ __Vdlyvval__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v1;
    CData/*0:0*/ __Vdlyvset__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v1;
    CData/*7:0*/ __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v0;
    CData/*0:0*/ __Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v0;
    CData/*7:0*/ __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v1;
    CData/*0:0*/ __Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v1;
    CData/*7:0*/ __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v2;
    CData/*7:0*/ __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v3;
    CData/*0:0*/ __Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v3;
    CData/*7:0*/ __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v4;
    CData/*7:0*/ __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v5;
    CData/*7:0*/ __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v6;
    CData/*0:0*/ __Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v7;
    SData/*9:0*/ __Vdlyvdim0__core__DOT__if_u__DOT__BTB__DOT__BTB__v0;
    SData/*9:0*/ __Vdlyvdim0__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v0;
    SData/*9:0*/ __Vdlyvdim0__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v1;
    IData/*31:0*/ __Vdlyvval__core__DOT__if_u__DOT__BTB__DOT__BTB__v0;
    IData/*20:0*/ __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v0;
    IData/*20:0*/ __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v1;
    IData/*20:0*/ __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v2;
    IData/*20:0*/ __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v3;
    IData/*20:0*/ __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v4;
    IData/*20:0*/ __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v5;
    IData/*20:0*/ __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v6;
    IData/*20:0*/ __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v7;
    IData/*20:0*/ __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v8;
    IData/*20:0*/ __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v9;
    IData/*20:0*/ __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v10;
    // Body
    __Vdlyvset__core__DOT__if_u__DOT__BTB__DOT__BTB__v0 = 0U;
    __Vdlyvset__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v0 = 0U;
    __Vdlyvset__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v1 = 0U;
    vlTOPp->__Vdlyvset__core__DOT__id_u__DOT__register_file_u__DOT__registers__v0 = 0U;
    vlTOPp->__Vdlyvset__core__DOT__id_u__DOT__register_file_u__DOT__registers__v1 = 0U;
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__if_u__DOT__BTB__DOT__i = 0U;
        while (VL_GTS_III(1,32,32, 0x400U, vlTOPp->core__DOT__if_u__DOT__BTB__DOT__i)) {
            vlTOPp->core__DOT__if_u__DOT__BTB__DOT__BTB[(0x3ffU 
                                                         & vlTOPp->core__DOT__if_u__DOT__BTB__DOT__i)] = 0U;
            vlTOPp->core__DOT__if_u__DOT__BTB__DOT__i 
                = ((IData)(1U) + vlTOPp->core__DOT__if_u__DOT__BTB__DOT__i);
        }
    }
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__i = 0U;
        while ((0x200000U > vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__i)) {
            vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[(0x1fffffU 
                                                                        & vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__i)] = 0U;
            vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__i 
                = ((IData)(1U) + vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__i);
        }
    }
    __Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v0 = 0U;
    __Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v1 = 0U;
    __Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v3 = 0U;
    __Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v7 = 0U;
    vlTOPp->core__DOT__load_store_forward_sel_ex_o 
        = ((~ (IData)(vlTOPp->rst_i)) & (IData)(vlTOPp->core__DOT__load_store_forward_sel_id_o));
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__imm_value_id_o = 0U;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)))) {
            vlTOPp->core__DOT__imm_value_id_o = vlTOPp->core__DOT__id_u__DOT__imm_gen_u__DOT__imm_r;
        }
    }
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__rs1_pc_sel_id_o = 0U;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)))) {
            vlTOPp->core__DOT__rs1_pc_sel_id_o = (1U 
                                                  & ((IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__control_signals) 
                                                     >> 4U));
        }
    }
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__rs2_imm_sel_id_o = 0U;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)))) {
            vlTOPp->core__DOT__rs2_imm_sel_id_o = (1U 
                                                   & ((IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__control_signals) 
                                                      >> 3U));
        }
    }
    vlTOPp->core__DOT__branch_is_taken_prediction_id_o 
        = ((~ (IData)(vlTOPp->rst_i)) & ((~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)) 
                                         & (IData)(vlTOPp->core__DOT__branch_is_taken_prediction_if_o)));
    vlTOPp->core__DOT__unconditional_branch_id_o = 
        ((~ (IData)(vlTOPp->rst_i)) & ((~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)) 
                                       & (IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__unconditional_branch)));
    vlTOPp->core__DOT__latest_rs2_value_ex_o = ((IData)(vlTOPp->rst_i)
                                                 ? 0U
                                                 : vlTOPp->core__DOT__ex_u__DOT__rs2_latest_value);
    if ((1U & (~ (IData)(vlTOPp->rst_i)))) {
        if (((IData)(vlTOPp->core__DOT__is_branch_instr_id_o) 
             & (IData)(vlTOPp->core__DOT__branching_ex_o))) {
            __Vdlyvval__core__DOT__if_u__DOT__BTB__DOT__BTB__v0 
                = vlTOPp->core__DOT__branch_address_ex_o;
            __Vdlyvset__core__DOT__if_u__DOT__BTB__DOT__BTB__v0 = 1U;
            __Vdlyvdim0__core__DOT__if_u__DOT__BTB__DOT__BTB__v0 
                = (0x1ffU & (vlTOPp->core__DOT__pc_id_o 
                             >> 2U));
        }
    }
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__i = 0U;
        while (VL_GTS_III(1,32,32, 0x400U, vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__i)) {
            vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer[(0x3ffU 
                                                                                & vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__i)] = 0U;
            vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__i 
                = ((IData)(1U) + vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__i);
        }
    } else {
        if (((3U != (IData)(vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__ex_pc_2bit_counter)) 
             & ((IData)(vlTOPp->core__DOT__is_branch_instr_id_o) 
                & (IData)(vlTOPp->core__DOT__ex_u__DOT__branch_is_taken)))) {
            __Vdlyvval__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v0 
                = (3U & ((IData)(1U) + vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer
                         [(0x1ffU & (vlTOPp->core__DOT__pc_id_o 
                                     >> 2U))]));
            __Vdlyvset__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v0 = 1U;
            __Vdlyvdim0__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v0 
                = (0x1ffU & (vlTOPp->core__DOT__pc_id_o 
                             >> 2U));
        } else {
            if (((0U != (IData)(vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__ex_pc_2bit_counter)) 
                 & ((IData)(vlTOPp->core__DOT__is_branch_instr_id_o) 
                    & (~ (IData)(vlTOPp->core__DOT__ex_u__DOT__branch_is_taken))))) {
                __Vdlyvval__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v1 
                    = (3U & (vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer
                             [(0x1ffU & (vlTOPp->core__DOT__pc_id_o 
                                         >> 2U))] - (IData)(1U)));
                __Vdlyvset__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v1 = 1U;
                __Vdlyvdim0__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v1 
                    = (0x1ffU & (vlTOPp->core__DOT__pc_id_o 
                                 >> 2U));
            }
        }
    }
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__load_value_mem_o = 0U;
        vlTOPp->core__DOT__wb_sel_ex_o = 0U;
    } else {
        vlTOPp->core__DOT__load_value_mem_o = vlTOPp->core__DOT__mem_u__DOT__loaded_data;
        vlTOPp->core__DOT__wb_sel_ex_o = vlTOPp->core__DOT__wb_sel_id_o;
    }
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__rs2_label_id_o = 0U;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)))) {
            vlTOPp->core__DOT__rs2_label_id_o = (0x1fU 
                                                 & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                    >> 0x14U));
        }
    }
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__rs1_label_id_o = 0U;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)))) {
            vlTOPp->core__DOT__rs1_label_id_o = (0x1fU 
                                                 & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                    >> 0xfU));
        }
    }
    vlTOPp->core__DOT__mem_u__DOT__o_wbs_ack = 0U;
    if (vlTOPp->rst_i) {
        vlTOPp->__Vdlyvset__core__DOT__id_u__DOT__register_file_u__DOT__registers__v0 = 1U;
    } else {
        if (((IData)(vlTOPp->core__DOT__reg_write_en_mem_o) 
             & (0U != (IData)(vlTOPp->core__DOT__rd_label_mem_o)))) {
            vlTOPp->__Vdlyvval__core__DOT__id_u__DOT__register_file_u__DOT__registers__v1 
                = vlTOPp->core__DOT__rd_value_mem_ro;
            vlTOPp->__Vdlyvset__core__DOT__id_u__DOT__register_file_u__DOT__registers__v1 = 1U;
            vlTOPp->__Vdlyvdim0__core__DOT__id_u__DOT__register_file_u__DOT__registers__v1 
                = vlTOPp->core__DOT__rd_label_mem_o;
        }
    }
    if ((1U & (~ (IData)(vlTOPp->rst_i)))) {
        if (vlTOPp->core__DOT__is_store_instr_ex_o) {
            if ((0U == (IData)(vlTOPp->core__DOT__funct3_ex_o))) {
                __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v0 
                    = (0xffU & vlTOPp->core__DOT__mem_u__DOT__forwarded_store_value);
                __Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v0 = 1U;
                __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v0 
                    = (0x1fffffU & vlTOPp->core__DOT__alu_result_ex_o);
            } else {
                if ((1U == (IData)(vlTOPp->core__DOT__funct3_ex_o))) {
                    __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v1 
                        = (0xffU & vlTOPp->core__DOT__mem_u__DOT__forwarded_store_value);
                    __Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v1 = 1U;
                    __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v1 
                        = (0x1fffffU & vlTOPp->core__DOT__alu_result_ex_o);
                    __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v2 
                        = (0xffU & (vlTOPp->core__DOT__mem_u__DOT__forwarded_store_value 
                                    >> 8U));
                    __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v2 
                        = (0x1fffffU & ((IData)(1U) 
                                        + vlTOPp->core__DOT__alu_result_ex_o));
                } else {
                    if ((2U == (IData)(vlTOPp->core__DOT__funct3_ex_o))) {
                        __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v3 
                            = (0xffU & vlTOPp->core__DOT__mem_u__DOT__forwarded_store_value);
                        __Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v3 = 1U;
                        __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v3 
                            = (0x1fffffU & vlTOPp->core__DOT__alu_result_ex_o);
                        __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v4 
                            = (0xffU & (vlTOPp->core__DOT__mem_u__DOT__forwarded_store_value 
                                        >> 8U));
                        __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v4 
                            = (0x1fffffU & ((IData)(1U) 
                                            + vlTOPp->core__DOT__alu_result_ex_o));
                        __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v5 
                            = (0xffU & (vlTOPp->core__DOT__mem_u__DOT__forwarded_store_value 
                                        >> 0x10U));
                        __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v5 
                            = (0x1fffffU & ((IData)(2U) 
                                            + vlTOPp->core__DOT__alu_result_ex_o));
                        __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v6 
                            = (0xffU & (vlTOPp->core__DOT__mem_u__DOT__forwarded_store_value 
                                        >> 0x18U));
                        __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v6 
                            = (0x1fffffU & ((IData)(3U) 
                                            + vlTOPp->core__DOT__alu_result_ex_o));
                    } else {
                        __Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v7 = 1U;
                        __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v7 
                            = (0x1fffffU & vlTOPp->core__DOT__alu_result_ex_o);
                        __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v8 
                            = (0x1fffffU & ((IData)(1U) 
                                            + vlTOPp->core__DOT__alu_result_ex_o));
                        __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v9 
                            = (0x1fffffU & ((IData)(2U) 
                                            + vlTOPp->core__DOT__alu_result_ex_o));
                        __Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v10 
                            = (0x1fffffU & ((IData)(3U) 
                                            + vlTOPp->core__DOT__alu_result_ex_o));
                    }
                }
            }
        }
    }
    if (__Vdlyvset__core__DOT__if_u__DOT__BTB__DOT__BTB__v0) {
        vlTOPp->core__DOT__if_u__DOT__BTB__DOT__BTB[__Vdlyvdim0__core__DOT__if_u__DOT__BTB__DOT__BTB__v0] 
            = __Vdlyvval__core__DOT__if_u__DOT__BTB__DOT__BTB__v0;
    }
    if (__Vdlyvset__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v0) {
        vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer[__Vdlyvdim0__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v0] 
            = __Vdlyvval__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v0;
    }
    if (__Vdlyvset__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v1) {
        vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer[__Vdlyvdim0__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v1] 
            = __Vdlyvval__core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer__v1;
    }
    if (__Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v0) {
        vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[__Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v0] 
            = __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v0;
    }
    if (__Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v1) {
        vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[__Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v1] 
            = __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v1;
        vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[__Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v2] 
            = __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v2;
    }
    if (__Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v3) {
        vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[__Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v3] 
            = __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v3;
        vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[__Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v4] 
            = __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v4;
        vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[__Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v5] 
            = __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v5;
        vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[__Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v6] 
            = __Vdlyvval__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v6;
    }
    if (__Vdlyvset__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v7) {
        vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[__Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v7] = 0xa5U;
        vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[__Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v8] = 0xb6U;
        vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[__Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v9] = 0xc7U;
        vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[__Vdlyvdim0__core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r__v10] = 0xd8U;
    }
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__load_store_forward_sel_id_o = 0U;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)))) {
            vlTOPp->core__DOT__load_store_forward_sel_id_o 
                = vlTOPp->core__DOT__id_u__DOT__load_store_forward_sel;
        }
    }
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__branch_is_taken_prediction_if_o = 0U;
    } else {
        if (vlTOPp->core__DOT__branching_ex_o) {
            vlTOPp->core__DOT__branch_is_taken_prediction_if_o = 0U;
        } else {
            if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__load_stall)))) {
                vlTOPp->core__DOT__branch_is_taken_prediction_if_o 
                    = vlTOPp->core__DOT__if_u__DOT__branch_is_taken_prediction;
            }
        }
    }
    vlTOPp->core__DOT__is_branch_instr_id_o = ((~ (IData)(vlTOPp->rst_i)) 
                                               & ((~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)) 
                                                  & (IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__is_branch_instr)));
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__wb_sel_id_o = 0U;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)))) {
            vlTOPp->core__DOT__wb_sel_id_o = (3U & 
                                              ((IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__control_signals) 
                                               >> 5U));
        }
    }
}

VL_INLINE_OPT void Vcore::_sequent__TOP__4(Vcore__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcore::_sequent__TOP__4\n"); );
    Vcore* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Variables
    IData/*31:0*/ __Vtask_core__DOT__if_u__DOT__if_trace_log__0__file;
    IData/*31:0*/ __Vtask_core__DOT__id_u__DOT__id_trace_log__1__file;
    IData/*31:0*/ __Vtask_core__DOT__ex_u__DOT__ex_trace_log__2__file;
    IData/*31:0*/ __Vtask_core__DOT__ex_u__DOT__alu_op_trace__3__file;
    IData/*31:0*/ __Vtask_core__DOT__ex_u__DOT__ALU_u__DOT__alu_trace_log__4__file;
    IData/*31:0*/ __Vtask_core__DOT__ex_u__DOT__branch_op_trace__5__file;
    IData/*31:0*/ __Vtask_core__DOT__mem_u__DOT__mem_trace_log__6__file;
    IData/*31:0*/ __Vtask_core__DOT__mem_u__DOT__mem_op_trace__7__file;
    // Body
    VL_FWRITEF(vlTOPp->core__DOT__trace_file,"\n\n");
    __Vtask_core__DOT__if_u__DOT__if_trace_log__0__file 
        = vlTOPp->core__DOT__trace_file;
    VL_FWRITEF(__Vtask_core__DOT__if_u__DOT__if_trace_log__0__file,"\n***********Instruction Fetch Stage****************:");
    VL_FWRITEF(__Vtask_core__DOT__if_u__DOT__if_trace_log__0__file,"\nTime %1t, Instruction: 0x%8x, Program Counter: 0x%8x",
               64,(0x3e8ULL * (QData)(VL_TIME_UNITED_Q(1000))),
               32,vlTOPp->core__DOT__if_u__DOT__fetched_instruction,
               32,vlTOPp->core__DOT__if_u__DOT__pc_reg);
    __Vtask_core__DOT__id_u__DOT__id_trace_log__1__file 
        = vlTOPp->core__DOT__trace_file;
    VL_FWRITEF(__Vtask_core__DOT__id_u__DOT__id_trace_log__1__file,"\n***********Instruction Decode Stage****************:");
    VL_FWRITEF(__Vtask_core__DOT__id_u__DOT__id_trace_log__1__file,"\nTime %1t, Instruction: 0x%8x, Program Counter: 0x%8x",
               64,(0x3e8ULL * (QData)(VL_TIME_UNITED_Q(1000))),
               32,vlTOPp->core__DOT__fetched_instruction_if_o,
               32,vlTOPp->core__DOT__pc_incremented_if_o);
    __Vtask_core__DOT__ex_u__DOT__ex_trace_log__2__file 
        = vlTOPp->core__DOT__trace_file;
    VL_FWRITEF(__Vtask_core__DOT__ex_u__DOT__ex_trace_log__2__file,"\n***********Execution Stage****************:");
    VL_FWRITEF(__Vtask_core__DOT__ex_u__DOT__ex_trace_log__2__file,"\nTime: %1t, Instruction: 0x%8x, Program Counter: 0x%8x",
               64,(0x3e8ULL * (QData)(VL_TIME_UNITED_Q(1000))),
               32,vlTOPp->core__DOT__fetched_instruction_id_o,
               32,vlTOPp->core__DOT__pc_id_o);
    __Vtask_core__DOT__ex_u__DOT__alu_op_trace__3__file 
        = __Vtask_core__DOT__ex_u__DOT__ex_trace_log__2__file;
    VL_FWRITEF(__Vtask_core__DOT__ex_u__DOT__alu_op_trace__3__file,"\nTime: %1t rs1_latest_value_selector Mux, time, in0_i: 0x%8x, in1_i: 0x%8x, in2_i: 0x%8x, ForwardA: %0b, rs1_latest_value: 0x%8x",
               64,(0x3e8ULL * (QData)(VL_TIME_UNITED_Q(1000))),
               32,vlTOPp->core__DOT__rs1_data_id_o,
               32,vlTOPp->core__DOT__rd_value_mem_ro,
               32,vlTOPp->core__DOT__rd_value_mem_wo,
               2,(IData)(vlTOPp->core__DOT__ex_u__DOT__forwardA),
               32,vlTOPp->core__DOT__ex_u__DOT__rs1_latest_value);
    VL_FWRITEF(__Vtask_core__DOT__ex_u__DOT__alu_op_trace__3__file,"\nTime: %1t rs2_latest_value_selector Mux, time, in0_i: 0x%8x, in1_i: 0x%8x, in2_i: 0x%8x, ForwardB: %0b, rs2_latest_value: 0x%8x",
               64,(0x3e8ULL * (QData)(VL_TIME_UNITED_Q(1000))),
               32,vlTOPp->core__DOT__rs2_data_id_o,
               32,vlTOPp->core__DOT__rd_value_mem_ro,
               32,vlTOPp->core__DOT__rd_value_mem_wo,
               2,(IData)(vlTOPp->core__DOT__ex_u__DOT__forwardB),
               32,vlTOPp->core__DOT__ex_u__DOT__rs2_latest_value);
    __Vtask_core__DOT__ex_u__DOT__ALU_u__DOT__alu_trace_log__4__file 
        = __Vtask_core__DOT__ex_u__DOT__alu_op_trace__3__file;
    VL_FWRITEF(__Vtask_core__DOT__ex_u__DOT__ALU_u__DOT__alu_trace_log__4__file,"\nTime: %1t ALU, alu1_i: 0x%8x, alu2_i: 0x%8x, alu_op_i: %0b,  result_o: 0x%8x",
               64,(0x3e8ULL * (QData)(VL_TIME_UNITED_Q(1000))),
               32,vlTOPp->core__DOT__ex_u__DOT__alu1_input,
               32,vlTOPp->core__DOT__ex_u__DOT__alu2_input,
               4,(IData)(vlTOPp->core__DOT__alu_op_id_o),
               32,vlTOPp->core__DOT__ex_u__DOT__ALU_u__DOT__result_r);
    __Vtask_core__DOT__ex_u__DOT__branch_op_trace__5__file 
        = __Vtask_core__DOT__ex_u__DOT__ex_trace_log__2__file;
    VL_FWRITEF(__Vtask_core__DOT__ex_u__DOT__branch_op_trace__5__file,"\nTime: %1t Branching, branch_is_taken: %0b, wrong_prediction_NT_T: %0b, branching_ex_o: %0b, branch_address_ex_o: %0x ",
               64,(0x3e8ULL * (QData)(VL_TIME_UNITED_Q(1000))),
               1,(IData)(vlTOPp->core__DOT__ex_u__DOT__branch_is_taken),
               1,vlTOPp->core__DOT__ex_u__DOT__wrong_prediction_NT_T,
               1,(IData)(vlTOPp->core__DOT__branching_ex_o),
               32,vlTOPp->core__DOT__branch_address_ex_o);
    __Vtask_core__DOT__mem_u__DOT__mem_trace_log__6__file 
        = vlTOPp->core__DOT__trace_file;
    VL_FWRITEF(__Vtask_core__DOT__mem_u__DOT__mem_trace_log__6__file,"\n***********Memory Stage****************:");
    VL_FWRITEF(__Vtask_core__DOT__mem_u__DOT__mem_trace_log__6__file,"\nTime: %1t, Instruction: 0x%8x, Program Counter: 0x%8x",
               64,(0x3e8ULL * (QData)(VL_TIME_UNITED_Q(1000))),
               32,vlTOPp->core__DOT__fetched_instruction_ex_o,
               32,vlTOPp->core__DOT__pc_ex_o);
    __Vtask_core__DOT__mem_u__DOT__mem_op_trace__7__file 
        = __Vtask_core__DOT__mem_u__DOT__mem_trace_log__6__file;
    VL_FWRITEF(__Vtask_core__DOT__mem_u__DOT__mem_op_trace__7__file,"\nTime: %1t, address_i: %8x, write_data_i: %8x, is_load_instr: %0b, is_store_instr: %0b, funct3_i: %0b, read_data_o: %8x",
               64,(0x3e8ULL * (QData)(VL_TIME_UNITED_Q(1000))),
               32,vlTOPp->core__DOT__alu_result_ex_o,
               32,vlTOPp->core__DOT__mem_u__DOT__forwarded_store_value,
               1,(IData)(vlTOPp->core__DOT__is_load_instr_ex_o),
               1,vlTOPp->core__DOT__is_store_instr_ex_o,
               3,(IData)(vlTOPp->core__DOT__funct3_ex_o),
               32,vlTOPp->core__DOT__mem_u__DOT__data_read_from_mem);
}

VL_INLINE_OPT void Vcore::_sequent__TOP__6(Vcore__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcore::_sequent__TOP__6\n"); );
    Vcore* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->core__DOT__mem_u__DOT__forwarded_store_value 
        = ((IData)(vlTOPp->core__DOT__load_store_forward_sel_ex_o)
            ? vlTOPp->core__DOT__load_value_mem_o : vlTOPp->core__DOT__latest_rs2_value_ex_o);
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__alu_op_id_o = 0U;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)))) {
            vlTOPp->core__DOT__alu_op_id_o = vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__alu_op;
        }
    }
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__fetched_instruction_ex_o = 0x13U;
        vlTOPp->core__DOT__pc_ex_o = 0U;
    } else {
        vlTOPp->core__DOT__fetched_instruction_ex_o 
            = vlTOPp->core__DOT__fetched_instruction_id_o;
        vlTOPp->core__DOT__pc_ex_o = vlTOPp->core__DOT__pc_id_o;
    }
    vlTOPp->core__DOT__is_load_instr_ex_o = ((~ (IData)(vlTOPp->rst_i)) 
                                             & (IData)(vlTOPp->core__DOT__is_load_instr_id_o));
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__rs1_data_id_o = 0U;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)))) {
            vlTOPp->core__DOT__rs1_data_id_o = ((0U 
                                                 == 
                                                 (0x1fU 
                                                  & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                     >> 0xfU)))
                                                 ? 0U
                                                 : 
                                                ((((0x1fU 
                                                    & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                       >> 0xfU)) 
                                                   == (IData)(vlTOPp->core__DOT__rd_label_mem_o)) 
                                                  & (IData)(vlTOPp->core__DOT__reg_write_en_mem_o))
                                                  ? vlTOPp->core__DOT__rd_value_mem_ro
                                                  : 
                                                 vlTOPp->core__DOT__id_u__DOT__register_file_u__DOT__registers
                                                 [(0x1fU 
                                                   & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                      >> 0xfU))]));
        }
    }
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__rs2_data_id_o = 0U;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)))) {
            vlTOPp->core__DOT__rs2_data_id_o = ((0U 
                                                 == 
                                                 (0x1fU 
                                                  & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                     >> 0x14U)))
                                                 ? 0U
                                                 : 
                                                ((((0x1fU 
                                                    & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                       >> 0x14U)) 
                                                   == (IData)(vlTOPp->core__DOT__rd_label_mem_o)) 
                                                  & (IData)(vlTOPp->core__DOT__reg_write_en_mem_o))
                                                  ? vlTOPp->core__DOT__rd_value_mem_ro
                                                  : 
                                                 vlTOPp->core__DOT__id_u__DOT__register_file_u__DOT__registers
                                                 [(0x1fU 
                                                   & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                      >> 0x14U))]));
        }
    }
    vlTOPp->core__DOT__is_store_instr_ex_o = ((~ (IData)(vlTOPp->rst_i)) 
                                              & (IData)(vlTOPp->core__DOT__is_store_instr_id_o));
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__funct3_ex_o = 0U;
        vlTOPp->core__DOT__alu_result_ex_o = 0U;
    } else {
        vlTOPp->core__DOT__funct3_ex_o = vlTOPp->core__DOT__funct3_id_o;
        vlTOPp->core__DOT__alu_result_ex_o = vlTOPp->core__DOT__ex_u__DOT__ALU_u__DOT__result_r;
    }
    if (vlTOPp->__Vdlyvset__core__DOT__id_u__DOT__register_file_u__DOT__registers__v0) {
        vlTOPp->core__DOT__id_u__DOT__register_file_u__DOT__registers[0U] = 0U;
    }
    if (vlTOPp->__Vdlyvset__core__DOT__id_u__DOT__register_file_u__DOT__registers__v1) {
        vlTOPp->core__DOT__id_u__DOT__register_file_u__DOT__registers[vlTOPp->__Vdlyvdim0__core__DOT__id_u__DOT__register_file_u__DOT__registers__v1] 
            = vlTOPp->__Vdlyvval__core__DOT__id_u__DOT__register_file_u__DOT__registers__v1;
    }
    vlTOPp->core__DOT__fetched_instruction_id_o = ((IData)(vlTOPp->rst_i)
                                                    ? 0x13U
                                                    : 
                                                   ((IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)
                                                     ? 0x13U
                                                     : vlTOPp->core__DOT__fetched_instruction_if_o));
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__pc_id_o = 0xfffffffcU;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)))) {
            vlTOPp->core__DOT__pc_id_o = vlTOPp->core__DOT__pc_incremented_if_o;
        }
    }
    vlTOPp->core__DOT__is_load_instr_id_o = ((~ (IData)(vlTOPp->rst_i)) 
                                             & ((~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)) 
                                                & (IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__is_load_instr)));
    vlTOPp->core__DOT__rd_value_mem_ro = ((IData)(vlTOPp->rst_i)
                                           ? 0U : vlTOPp->core__DOT__rd_value_mem_wo);
    vlTOPp->core__DOT__reg_write_en_mem_o = ((~ (IData)(vlTOPp->rst_i)) 
                                             & (IData)(vlTOPp->core__DOT__reg_write_en_ex_o));
    vlTOPp->core__DOT__rd_label_mem_o = ((IData)(vlTOPp->rst_i)
                                          ? 0U : (IData)(vlTOPp->core__DOT__rd_label_ex_o));
    vlTOPp->core__DOT__is_store_instr_id_o = ((~ (IData)(vlTOPp->rst_i)) 
                                              & ((~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)) 
                                                 & (IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__is_store_instr)));
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__funct3_id_o = 0U;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)))) {
            vlTOPp->core__DOT__funct3_id_o = (7U & 
                                              (vlTOPp->core__DOT__fetched_instruction_if_o 
                                               >> 0xcU));
        }
    }
    vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_byte 
        = vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r
        [(0x1fffffU & vlTOPp->core__DOT__alu_result_ex_o)];
    vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_half 
        = ((vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r
            [(0x1fffffU & ((IData)(1U) + vlTOPp->core__DOT__alu_result_ex_o))] 
            << 8U) | vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r
           [(0x1fffffU & vlTOPp->core__DOT__alu_result_ex_o)]);
    vlTOPp->core__DOT__mem_u__DOT__data_read_from_mem 
        = ((IData)(vlTOPp->core__DOT__is_load_instr_ex_o)
            ? ((4U & (IData)(vlTOPp->core__DOT__funct3_ex_o))
                ? ((2U & (IData)(vlTOPp->core__DOT__funct3_ex_o))
                    ? 0xa5b5c5d5U : ((1U & (IData)(vlTOPp->core__DOT__funct3_ex_o))
                                      ? (IData)(vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_half)
                                      : (IData)(vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_byte)))
                : ((2U & (IData)(vlTOPp->core__DOT__funct3_ex_o))
                    ? ((1U & (IData)(vlTOPp->core__DOT__funct3_ex_o))
                        ? 0xa5b5c5d5U : ((vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r
                                          [(0x1fffffU 
                                            & ((IData)(3U) 
                                               + vlTOPp->core__DOT__alu_result_ex_o))] 
                                          << 0x18U) 
                                         | ((vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r
                                             [(0x1fffffU 
                                               & ((IData)(2U) 
                                                  + vlTOPp->core__DOT__alu_result_ex_o))] 
                                             << 0x10U) 
                                            | ((vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r
                                                [(0x1fffffU 
                                                  & ((IData)(1U) 
                                                     + vlTOPp->core__DOT__alu_result_ex_o))] 
                                                << 8U) 
                                               | vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r
                                               [(0x1fffffU 
                                                 & vlTOPp->core__DOT__alu_result_ex_o)]))))
                    : ((1U & (IData)(vlTOPp->core__DOT__funct3_ex_o))
                        ? ((0xffff0000U & ((- (IData)(
                                                      (1U 
                                                       & ((IData)(vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_half) 
                                                          >> 0xfU)))) 
                                           << 0x10U)) 
                           | (IData)(vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_half))
                        : ((0xffffff00U & ((- (IData)(
                                                      (1U 
                                                       & ((IData)(vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_byte) 
                                                          >> 7U)))) 
                                           << 8U)) 
                           | (IData)(vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_byte)))))
            : 0xb1b1b1b1U);
    vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__ex_pc_2bit_counter 
        = vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer
        [(0x1ffU & (vlTOPp->core__DOT__pc_id_o >> 2U))];
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__pc_incremented_if_o = 0x80000000U;
    } else {
        if (vlTOPp->core__DOT__branching_ex_o) {
            vlTOPp->core__DOT__pc_incremented_if_o = 0xdeadc0deU;
        } else {
            if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__load_stall)))) {
                vlTOPp->core__DOT__pc_incremented_if_o 
                    = vlTOPp->core__DOT__if_u__DOT__pc_reg;
            }
        }
    }
    vlTOPp->core__DOT__reg_write_en_ex_o = ((~ (IData)(vlTOPp->rst_i)) 
                                            & (IData)(vlTOPp->core__DOT__reg_write_en_id_o));
    vlTOPp->core__DOT__rd_label_ex_o = ((IData)(vlTOPp->rst_i)
                                         ? 0U : (IData)(vlTOPp->core__DOT__rd_label_id_o));
    vlTOPp->core__DOT__mem_u__DOT__loaded_data = ((IData)(vlTOPp->core__DOT__mem_u__DOT__o_wbs_ack)
                                                   ? vlTOPp->core__DOT__mem_u__DOT__o_wbs_data
                                                   : vlTOPp->core__DOT__mem_u__DOT__data_read_from_mem);
    vlTOPp->core__DOT__rd_value_mem_wo = ((2U & (IData)(vlTOPp->core__DOT__wb_sel_ex_o))
                                           ? ((1U & (IData)(vlTOPp->core__DOT__wb_sel_ex_o))
                                               ? 0xa9a9a9a9U
                                               : ((IData)(4U) 
                                                  + vlTOPp->core__DOT__pc_ex_o))
                                           : ((1U & (IData)(vlTOPp->core__DOT__wb_sel_ex_o))
                                               ? vlTOPp->core__DOT__mem_u__DOT__loaded_data
                                               : vlTOPp->core__DOT__alu_result_ex_o));
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__if_u__DOT__pc_reg = 0x80000000U;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__load_stall)))) {
            vlTOPp->core__DOT__if_u__DOT__pc_reg = vlTOPp->core__DOT__if_u__DOT__pc_next;
        }
    }
    vlTOPp->core__DOT__reg_write_en_id_o = (1U & ((~ (IData)(vlTOPp->rst_i)) 
                                                  & ((~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)) 
                                                     & ((IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__control_signals) 
                                                        >> 7U))));
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__rd_label_id_o = 0U;
    } else {
        if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__id_flush)))) {
            vlTOPp->core__DOT__rd_label_id_o = (0x1fU 
                                                & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                   >> 7U));
        }
    }
    vlTOPp->core__DOT__ex_u__DOT__forwarding_unit_u__DOT__rs1_mem_match 
        = (((0U != (IData)(vlTOPp->core__DOT__rd_label_ex_o)) 
            & (IData)(vlTOPp->core__DOT__reg_write_en_ex_o)) 
           & ((IData)(vlTOPp->core__DOT__rd_label_ex_o) 
              == (IData)(vlTOPp->core__DOT__rs1_label_id_o)));
    vlTOPp->core__DOT__ex_u__DOT__forwarding_unit_u__DOT__rs2_mem_match 
        = (((0U != (IData)(vlTOPp->core__DOT__rd_label_ex_o)) 
            & (IData)(vlTOPp->core__DOT__reg_write_en_ex_o)) 
           & ((IData)(vlTOPp->core__DOT__rd_label_ex_o) 
              == (IData)(vlTOPp->core__DOT__rs2_label_id_o)));
    vlTOPp->core__DOT__ex_u__DOT__forwardA = ((IData)(vlTOPp->core__DOT__ex_u__DOT__forwarding_unit_u__DOT__rs1_mem_match)
                                               ? 2U
                                               : ((
                                                   (((0U 
                                                      != (IData)(vlTOPp->core__DOT__rd_label_mem_o)) 
                                                     & (IData)(vlTOPp->core__DOT__reg_write_en_mem_o)) 
                                                    & ((IData)(vlTOPp->core__DOT__rd_label_mem_o) 
                                                       == (IData)(vlTOPp->core__DOT__rs1_label_id_o))) 
                                                   & (~ (IData)(vlTOPp->core__DOT__ex_u__DOT__forwarding_unit_u__DOT__rs1_mem_match)))
                                                   ? 1U
                                                   : 0U));
    vlTOPp->core__DOT__ex_u__DOT__forwardB = ((IData)(vlTOPp->core__DOT__ex_u__DOT__forwarding_unit_u__DOT__rs2_mem_match)
                                               ? 2U
                                               : ((
                                                   (((0U 
                                                      != (IData)(vlTOPp->core__DOT__rd_label_mem_o)) 
                                                     & (IData)(vlTOPp->core__DOT__reg_write_en_mem_o)) 
                                                    & ((IData)(vlTOPp->core__DOT__rd_label_mem_o) 
                                                       == (IData)(vlTOPp->core__DOT__rs2_label_id_o))) 
                                                   & (~ (IData)(vlTOPp->core__DOT__ex_u__DOT__forwarding_unit_u__DOT__rs2_mem_match)))
                                                   ? 1U
                                                   : 0U));
    vlTOPp->core__DOT__if_u__DOT__btb_predicted_pc 
        = vlTOPp->core__DOT__if_u__DOT__BTB__DOT__BTB
        [(0x1ffU & (vlTOPp->core__DOT__if_u__DOT__pc_reg 
                    >> 2U))];
    vlTOPp->core__DOT__if_u__DOT__branch_is_taken_prediction 
        = ((0x400U > vlTOPp->core__DOT__if_u__DOT__pc_reg) 
           & (vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer
              [(0x1ffU & (vlTOPp->core__DOT__if_u__DOT__pc_reg 
                          >> 2U))] >> 1U));
    if (vlTOPp->rst_i) {
        vlTOPp->core__DOT__fetched_instruction_if_o = 0U;
    } else {
        if (vlTOPp->core__DOT__branching_ex_o) {
            vlTOPp->core__DOT__fetched_instruction_if_o = 0x13U;
        } else {
            if ((1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__load_stall)))) {
                vlTOPp->core__DOT__fetched_instruction_if_o 
                    = vlTOPp->core__DOT__if_u__DOT__fetched_instruction;
            }
        }
    }
    vlTOPp->core__DOT__ex_u__DOT__rs1_latest_value 
        = ((2U & (IData)(vlTOPp->core__DOT__ex_u__DOT__forwardA))
            ? ((1U & (IData)(vlTOPp->core__DOT__ex_u__DOT__forwardA))
                ? 0xa1a1a1a1U : vlTOPp->core__DOT__rd_value_mem_wo)
            : ((1U & (IData)(vlTOPp->core__DOT__ex_u__DOT__forwardA))
                ? vlTOPp->core__DOT__rd_value_mem_ro
                : vlTOPp->core__DOT__rs1_data_id_o));
    vlTOPp->core__DOT__ex_u__DOT__rs2_latest_value 
        = ((2U & (IData)(vlTOPp->core__DOT__ex_u__DOT__forwardB))
            ? ((1U & (IData)(vlTOPp->core__DOT__ex_u__DOT__forwardB))
                ? 0xa2a2a2a2U : vlTOPp->core__DOT__rd_value_mem_wo)
            : ((1U & (IData)(vlTOPp->core__DOT__ex_u__DOT__forwardB))
                ? vlTOPp->core__DOT__rd_value_mem_ro
                : vlTOPp->core__DOT__rs2_data_id_o));
    vlTOPp->core__DOT__if_u__DOT__fetched_instruction 
        = ((vlTOPp->core__DOT__if_u__DOT__instr_cache_u__DOT__instructions
            [(0x1ffffffU & ((IData)(3U) + vlTOPp->core__DOT__if_u__DOT__pc_reg))] 
            << 0x18U) | ((vlTOPp->core__DOT__if_u__DOT__instr_cache_u__DOT__instructions
                          [(0x1ffffffU & ((IData)(2U) 
                                          + vlTOPp->core__DOT__if_u__DOT__pc_reg))] 
                          << 0x10U) | ((vlTOPp->core__DOT__if_u__DOT__instr_cache_u__DOT__instructions
                                        [(0x1ffffffU 
                                          & ((IData)(1U) 
                                             + vlTOPp->core__DOT__if_u__DOT__pc_reg))] 
                                        << 8U) | vlTOPp->core__DOT__if_u__DOT__instr_cache_u__DOT__instructions
                                       [(0x1ffffffU 
                                         & vlTOPp->core__DOT__if_u__DOT__pc_reg)])));
    vlTOPp->core__DOT__ex_u__DOT__alu1_input = ((IData)(vlTOPp->core__DOT__rs1_pc_sel_id_o)
                                                 ? 
                                                ((IData)(vlTOPp->core__DOT__rs1_pc_sel_id_o)
                                                  ? vlTOPp->core__DOT__pc_id_o
                                                  : 0U)
                                                 : vlTOPp->core__DOT__ex_u__DOT__rs1_latest_value);
    vlTOPp->core__DOT__ex_u__DOT__alu2_input = ((IData)(vlTOPp->core__DOT__rs2_imm_sel_id_o)
                                                 ? 
                                                ((IData)(vlTOPp->core__DOT__rs2_imm_sel_id_o)
                                                  ? vlTOPp->core__DOT__imm_value_id_o
                                                  : 0U)
                                                 : vlTOPp->core__DOT__ex_u__DOT__rs2_latest_value);
    vlTOPp->__Vtableidx1 = (((VL_LTS_III(1,32,32, vlTOPp->core__DOT__ex_u__DOT__rs1_latest_value, vlTOPp->core__DOT__ex_u__DOT__rs2_latest_value)
                               ? 1U : 0U) << 5U) | 
                            ((((vlTOPp->core__DOT__ex_u__DOT__rs1_latest_value 
                                < vlTOPp->core__DOT__ex_u__DOT__rs2_latest_value)
                                ? 1U : 0U) << 4U) | 
                             ((((vlTOPp->core__DOT__ex_u__DOT__rs1_latest_value 
                                 == vlTOPp->core__DOT__ex_u__DOT__rs2_latest_value)
                                 ? 1U : 0U) << 3U) 
                              | (IData)(vlTOPp->core__DOT__funct3_id_o))));
    vlTOPp->core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r 
        = vlTOPp->__Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r
        [vlTOPp->__Vtableidx1];
    vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__unconditional_branch = 0U;
    if ((0x40U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
        if ((0x20U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
            if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                          >> 4U)))) {
                if ((8U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
                    if ((4U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
                        vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__unconditional_branch = 1U;
                    }
                } else {
                    if ((4U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
                        vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__unconditional_branch = 1U;
                    }
                }
            }
        }
    }
    vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__alu_op = 0U;
    if ((0x40U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
        if ((0x20U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
            if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                          >> 4U)))) {
                if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                              >> 3U)))) {
                    if ((4U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
                        vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__alu_op = 0xbU;
                    }
                }
            }
        }
    } else {
        if ((0x20U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
            if ((0x10U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
                if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                              >> 3U)))) {
                    vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__alu_op 
                        = ((4U & vlTOPp->core__DOT__fetched_instruction_if_o)
                            ? 0xaU : ((0U == (0x7fU 
                                              & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                 >> 0x19U)))
                                       ? ((0x4000U 
                                           & vlTOPp->core__DOT__fetched_instruction_if_o)
                                           ? ((0x2000U 
                                               & vlTOPp->core__DOT__fetched_instruction_if_o)
                                               ? ((0x1000U 
                                                   & vlTOPp->core__DOT__fetched_instruction_if_o)
                                                   ? 9U
                                                   : 8U)
                                               : ((0x1000U 
                                                   & vlTOPp->core__DOT__fetched_instruction_if_o)
                                                   ? 6U
                                                   : 5U))
                                           : ((0x2000U 
                                               & vlTOPp->core__DOT__fetched_instruction_if_o)
                                               ? ((0x1000U 
                                                   & vlTOPp->core__DOT__fetched_instruction_if_o)
                                                   ? 4U
                                                   : 3U)
                                               : ((0x1000U 
                                                   & vlTOPp->core__DOT__fetched_instruction_if_o)
                                                   ? 2U
                                                   : 0U)))
                                       : ((0x20U == 
                                           (0x7fU & 
                                            (vlTOPp->core__DOT__fetched_instruction_if_o 
                                             >> 0x19U)))
                                           ? ((0U == 
                                               (7U 
                                                & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                   >> 0xcU)))
                                               ? 1U
                                               : ((5U 
                                                   == 
                                                   (7U 
                                                    & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                       >> 0xcU)))
                                                   ? 7U
                                                   : 0xfU))
                                           : 0xfU)));
                }
            }
        } else {
            if ((0x10U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
                if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                              >> 3U)))) {
                    if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                                  >> 2U)))) {
                        vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__alu_op 
                            = ((5U == (7U & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                             >> 0xcU)))
                                ? ((0U == (0x7fU & 
                                           (vlTOPp->core__DOT__fetched_instruction_if_o 
                                            >> 0x19U)))
                                    ? 6U : ((0x20U 
                                             == (0x7fU 
                                                 & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                    >> 0x19U)))
                                             ? 7U : 0xfU))
                                : ((0x4000U & vlTOPp->core__DOT__fetched_instruction_if_o)
                                    ? ((0x2000U & vlTOPp->core__DOT__fetched_instruction_if_o)
                                        ? ((0x1000U 
                                            & vlTOPp->core__DOT__fetched_instruction_if_o)
                                            ? 9U : 8U)
                                        : ((0x1000U 
                                            & vlTOPp->core__DOT__fetched_instruction_if_o)
                                            ? 0xfU : 5U))
                                    : ((0x2000U & vlTOPp->core__DOT__fetched_instruction_if_o)
                                        ? ((0x1000U 
                                            & vlTOPp->core__DOT__fetched_instruction_if_o)
                                            ? 4U : 3U)
                                        : ((0x1000U 
                                            & vlTOPp->core__DOT__fetched_instruction_if_o)
                                            ? 2U : 0U))));
                    }
                }
            }
        }
    }
    vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__is_branch_instr = 0U;
    if ((0x40U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
        if ((0x20U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
            if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                          >> 4U)))) {
                if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                              >> 3U)))) {
                    if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                                  >> 2U)))) {
                        vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__is_branch_instr = 1U;
                    }
                }
            }
        }
    }
    vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__is_load_instr = 0U;
    if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                  >> 6U)))) {
        if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                      >> 5U)))) {
            if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                          >> 4U)))) {
                if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                              >> 3U)))) {
                    if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                                  >> 2U)))) {
                        vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__is_load_instr = 1U;
                    }
                }
            }
        }
    }
    vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__control_signals 
        = ((0x40U & vlTOPp->core__DOT__fetched_instruction_if_o)
            ? ((0x20U & vlTOPp->core__DOT__fetched_instruction_if_o)
                ? ((0x10U & vlTOPp->core__DOT__fetched_instruction_if_o)
                    ? 0U : ((8U & vlTOPp->core__DOT__fetched_instruction_if_o)
                             ? ((4U & vlTOPp->core__DOT__fetched_instruction_if_o)
                                 ? 0xd9U : 0U) : ((4U 
                                                   & vlTOPp->core__DOT__fetched_instruction_if_o)
                                                   ? 0xccU
                                                   : 0x1bU)))
                : 0U) : ((0x20U & vlTOPp->core__DOT__fetched_instruction_if_o)
                          ? ((0x10U & vlTOPp->core__DOT__fetched_instruction_if_o)
                              ? ((8U & vlTOPp->core__DOT__fetched_instruction_if_o)
                                  ? 0U : ((4U & vlTOPp->core__DOT__fetched_instruction_if_o)
                                           ? 0x88U : 0x80U))
                              : ((8U & vlTOPp->core__DOT__fetched_instruction_if_o)
                                  ? 0U : ((4U & vlTOPp->core__DOT__fetched_instruction_if_o)
                                           ? 0U : 0xaU)))
                          : ((0x10U & vlTOPp->core__DOT__fetched_instruction_if_o)
                              ? ((8U & vlTOPp->core__DOT__fetched_instruction_if_o)
                                  ? 0U : ((4U & vlTOPp->core__DOT__fetched_instruction_if_o)
                                           ? 0x98U : 0x8cU))
                              : ((8U & vlTOPp->core__DOT__fetched_instruction_if_o)
                                  ? 0U : ((4U & vlTOPp->core__DOT__fetched_instruction_if_o)
                                           ? 0U : 0xacU)))));
    vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__is_store_instr = 0U;
    if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                  >> 6U)))) {
        if ((0x20U & vlTOPp->core__DOT__fetched_instruction_if_o)) {
            if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                          >> 4U)))) {
                if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                              >> 3U)))) {
                    if ((1U & (~ (vlTOPp->core__DOT__fetched_instruction_if_o 
                                  >> 2U)))) {
                        vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__is_store_instr = 1U;
                    }
                }
            }
        }
    }
    vlTOPp->core__DOT__ex_u__DOT__ALU_u__DOT__result_r 
        = ((8U & (IData)(vlTOPp->core__DOT__alu_op_id_o))
            ? ((4U & (IData)(vlTOPp->core__DOT__alu_op_id_o))
                ? 0xdeadbeefU : ((2U & (IData)(vlTOPp->core__DOT__alu_op_id_o))
                                  ? ((1U & (IData)(vlTOPp->core__DOT__alu_op_id_o))
                                      ? (0xfffffffeU 
                                         & (vlTOPp->core__DOT__ex_u__DOT__alu1_input 
                                            + vlTOPp->core__DOT__ex_u__DOT__alu2_input))
                                      : vlTOPp->core__DOT__ex_u__DOT__alu2_input)
                                  : ((1U & (IData)(vlTOPp->core__DOT__alu_op_id_o))
                                      ? (vlTOPp->core__DOT__ex_u__DOT__alu1_input 
                                         & vlTOPp->core__DOT__ex_u__DOT__alu2_input)
                                      : (vlTOPp->core__DOT__ex_u__DOT__alu1_input 
                                         | vlTOPp->core__DOT__ex_u__DOT__alu2_input))))
            : ((4U & (IData)(vlTOPp->core__DOT__alu_op_id_o))
                ? ((2U & (IData)(vlTOPp->core__DOT__alu_op_id_o))
                    ? ((1U & (IData)(vlTOPp->core__DOT__alu_op_id_o))
                        ? VL_SHIFTRS_III(32,32,5, vlTOPp->core__DOT__ex_u__DOT__alu1_input, 
                                         (0x1fU & vlTOPp->core__DOT__ex_u__DOT__alu2_input))
                        : (vlTOPp->core__DOT__ex_u__DOT__alu1_input 
                           >> (0x1fU & vlTOPp->core__DOT__ex_u__DOT__alu2_input)))
                    : ((1U & (IData)(vlTOPp->core__DOT__alu_op_id_o))
                        ? (vlTOPp->core__DOT__ex_u__DOT__alu1_input 
                           ^ vlTOPp->core__DOT__ex_u__DOT__alu2_input)
                        : ((vlTOPp->core__DOT__ex_u__DOT__alu1_input 
                            < vlTOPp->core__DOT__ex_u__DOT__alu2_input)
                            ? 1U : 0U))) : ((2U & (IData)(vlTOPp->core__DOT__alu_op_id_o))
                                             ? ((1U 
                                                 & (IData)(vlTOPp->core__DOT__alu_op_id_o))
                                                 ? 
                                                (VL_LTS_III(1,32,32, vlTOPp->core__DOT__ex_u__DOT__alu1_input, vlTOPp->core__DOT__ex_u__DOT__alu2_input)
                                                  ? 1U
                                                  : 0U)
                                                 : 
                                                (vlTOPp->core__DOT__ex_u__DOT__alu1_input 
                                                 << 
                                                 (0x1fU 
                                                  & vlTOPp->core__DOT__ex_u__DOT__alu2_input)))
                                             : ((1U 
                                                 & (IData)(vlTOPp->core__DOT__alu_op_id_o))
                                                 ? 
                                                (vlTOPp->core__DOT__ex_u__DOT__alu1_input 
                                                 - vlTOPp->core__DOT__ex_u__DOT__alu2_input)
                                                 : 
                                                (vlTOPp->core__DOT__ex_u__DOT__alu1_input 
                                                 + vlTOPp->core__DOT__ex_u__DOT__alu2_input)))));
    vlTOPp->core__DOT__ex_u__DOT__branch_is_taken = 
        (((IData)(vlTOPp->core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r) 
          & (IData)(vlTOPp->core__DOT__is_branch_instr_id_o)) 
         | (IData)(vlTOPp->core__DOT__unconditional_branch_id_o));
    vlTOPp->core__DOT__id_u__DOT__imm_gen_u__DOT__imm_r 
        = ((4U & (IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__control_signals))
            ? ((2U & (IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__control_signals))
                ? 0U : ((1U & (IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__control_signals))
                         ? 0U : ((0xfffff000U & ((- (IData)(
                                                            (1U 
                                                             & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                                >> 0x1fU)))) 
                                                 << 0xcU)) 
                                 | (0xfffU & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                              >> 0x14U)))))
            : ((2U & (IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__control_signals))
                ? ((1U & (IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__control_signals))
                    ? ((0xfffff000U & ((- (IData)((1U 
                                                   & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                      >> 0x1fU)))) 
                                       << 0xcU)) | 
                       ((0x800U & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                   << 4U)) | ((0x7e0U 
                                               & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                  >> 0x14U)) 
                                              | (0x1eU 
                                                 & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                    >> 7U)))))
                    : ((0xfffff800U & ((- (IData)((1U 
                                                   & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                      >> 0x1fU)))) 
                                       << 0xbU)) | 
                       ((0x7e0U & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                   >> 0x14U)) | (0x1fU 
                                                 & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                    >> 7U)))))
                : ((1U & (IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__control_signals))
                    ? ((0xfff00000U & ((- (IData)((1U 
                                                   & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                      >> 0x1fU)))) 
                                       << 0x14U)) | 
                       ((0xff000U & vlTOPp->core__DOT__fetched_instruction_if_o) 
                        | ((0x800U & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                      >> 9U)) | (0x7feU 
                                                 & (vlTOPp->core__DOT__fetched_instruction_if_o 
                                                    >> 0x14U)))))
                    : (0xfffff000U & vlTOPp->core__DOT__fetched_instruction_if_o))));
    vlTOPp->core__DOT__id_u__DOT__load_store_forward_sel = 0U;
    if (vlTOPp->core__DOT__is_load_instr_id_o) {
        if ((0U != (IData)(vlTOPp->core__DOT__rd_label_id_o))) {
            if ((((0x1fU & (vlTOPp->core__DOT__fetched_instruction_if_o 
                            >> 0xfU)) == (IData)(vlTOPp->core__DOT__rd_label_id_o)) 
                 | ((0x1fU & (vlTOPp->core__DOT__fetched_instruction_if_o 
                              >> 0x14U)) == (IData)(vlTOPp->core__DOT__rd_label_id_o)))) {
                vlTOPp->core__DOT__id_u__DOT__load_store_forward_sel 
                    = vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__is_store_instr;
            }
        }
    }
    vlTOPp->core__DOT__id_u__DOT__load_stall = 0U;
    if (vlTOPp->core__DOT__is_load_instr_id_o) {
        if ((0U != (IData)(vlTOPp->core__DOT__rd_label_id_o))) {
            if ((((0x1fU & (vlTOPp->core__DOT__fetched_instruction_if_o 
                            >> 0xfU)) == (IData)(vlTOPp->core__DOT__rd_label_id_o)) 
                 | ((0x1fU & (vlTOPp->core__DOT__fetched_instruction_if_o 
                              >> 0x14U)) == (IData)(vlTOPp->core__DOT__rd_label_id_o)))) {
                vlTOPp->core__DOT__id_u__DOT__load_stall 
                    = (1U & (~ (IData)(vlTOPp->core__DOT__id_u__DOT__control_unit_u__DOT__is_store_instr)));
            }
        }
    }
    vlTOPp->core__DOT__branching_ex_o = ((IData)(vlTOPp->core__DOT__ex_u__DOT__branch_is_taken) 
                                         ^ (IData)(vlTOPp->core__DOT__branch_is_taken_prediction_id_o));
    vlTOPp->core__DOT__ex_u__DOT__wrong_prediction_NT_T 
        = ((IData)(vlTOPp->core__DOT__ex_u__DOT__branch_is_taken) 
           & (~ (IData)(vlTOPp->core__DOT__branch_is_taken_prediction_id_o)));
    vlTOPp->core__DOT__id_u__DOT__id_flush = ((IData)(vlTOPp->core__DOT__id_u__DOT__load_stall) 
                                              | (IData)(vlTOPp->core__DOT__branching_ex_o));
    vlTOPp->core__DOT__branch_address_ex_o = ((IData)(vlTOPp->core__DOT__ex_u__DOT__wrong_prediction_NT_T)
                                               ? vlTOPp->core__DOT__ex_u__DOT__ALU_u__DOT__result_r
                                               : ((IData)(4U) 
                                                  + vlTOPp->core__DOT__pc_id_o));
    vlTOPp->core__DOT__if_u__DOT__pc_next = ((IData)(vlTOPp->core__DOT__branching_ex_o)
                                              ? vlTOPp->core__DOT__branch_address_ex_o
                                              : (((IData)(vlTOPp->core__DOT__if_u__DOT__branch_is_taken_prediction) 
                                                  & (0U 
                                                     != 
                                                     vlTOPp->core__DOT__if_u__DOT__BTB__DOT__BTB
                                                     [
                                                     (0x1ffU 
                                                      & (vlTOPp->core__DOT__if_u__DOT__pc_reg 
                                                         >> 2U))]))
                                                  ? vlTOPp->core__DOT__if_u__DOT__btb_predicted_pc
                                                  : 
                                                 ((IData)(4U) 
                                                  + vlTOPp->core__DOT__if_u__DOT__pc_reg)));
}

void Vcore::_eval(Vcore__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcore::_eval\n"); );
    Vcore* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    if ((((IData)(vlTOPp->clk_i) & (~ (IData)(vlTOPp->__Vclklast__TOP__clk_i))) 
         | ((IData)(vlTOPp->rst_i) & (~ (IData)(vlTOPp->__Vclklast__TOP__rst_i))))) {
        vlTOPp->_sequent__TOP__3(vlSymsp);
    }
    if (((~ (IData)(vlTOPp->clk_i)) & (IData)(vlTOPp->__Vclklast__TOP__clk_i))) {
        vlTOPp->_sequent__TOP__4(vlSymsp);
    }
    if ((((IData)(vlTOPp->clk_i) & (~ (IData)(vlTOPp->__Vclklast__TOP__clk_i))) 
         | ((IData)(vlTOPp->rst_i) & (~ (IData)(vlTOPp->__Vclklast__TOP__rst_i))))) {
        vlTOPp->_sequent__TOP__6(vlSymsp);
    }
    // Final
    vlTOPp->__Vclklast__TOP__clk_i = vlTOPp->clk_i;
    vlTOPp->__Vclklast__TOP__rst_i = vlTOPp->rst_i;
}

VL_INLINE_OPT QData Vcore::_change_request(Vcore__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcore::_change_request\n"); );
    Vcore* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    return (vlTOPp->_change_request_1(vlSymsp));
}

VL_INLINE_OPT QData Vcore::_change_request_1(Vcore__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcore::_change_request_1\n"); );
    Vcore* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    // Change detection
    QData __req = false;  // Logically a bool
    return __req;
}

#ifdef VL_DEBUG
void Vcore::_eval_debug_assertions() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcore::_eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((clk_i & 0xfeU))) {
        Verilated::overWidthError("clk_i");}
    if (VL_UNLIKELY((rst_i & 0xfeU))) {
        Verilated::overWidthError("rst_i");}
}
#endif  // VL_DEBUG
