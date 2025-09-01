// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vcore.h for the primary calling header

#include "Vcore.h"
#include "Vcore__Syms.h"

//==========
CData/*0:0*/ Vcore::__Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[64];

VL_CTOR_IMP(Vcore) {
    Vcore__Syms* __restrict vlSymsp = __VlSymsp = new Vcore__Syms(this, name());
    Vcore* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Reset internal values
    
    // Reset structure values
    _ctor_var_reset();
}

void Vcore::__Vconfigure(Vcore__Syms* vlSymsp, bool first) {
    if (false && first) {}  // Prevent unused
    this->__VlSymsp = vlSymsp;
    if (false && this->__VlSymsp) {}  // Prevent unused
    Verilated::timeunit(-9);
    Verilated::timeprecision(-12);
}

Vcore::~Vcore() {
    VL_DO_CLEAR(delete __VlSymsp, __VlSymsp = NULL);
}

void Vcore::_initial__TOP__1(Vcore__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcore::_initial__TOP__1\n"); );
    Vcore* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Variables
    WData/*223:0*/ __Vtemp1[7];
    WData/*127:0*/ __Vtemp2[4];
    // Body
    __Vtemp1[0U] = 0x2e686578U;
    __Vtemp1[1U] = 0x74657374U;
    __Vtemp1[2U] = 0x72616d5fU;
    __Vtemp1[3U] = 0x70726f67U;
    __Vtemp1[4U] = 0x6374732fU;
    __Vtemp1[5U] = 0x74696661U;
    __Vtemp1[6U] = 0x6172U;
    VL_READMEM_N(true, 8, 33554432, 0, VL_CVT_PACK_STR_NW(7, __Vtemp1)
                 , vlTOPp->core__DOT__if_u__DOT__instr_cache_u__DOT__instructions
                 , 0, ~0ULL);
    __Vtemp2[0U] = 0x2e6c6f67U;
    __Vtemp2[1U] = 0x72616365U;
    __Vtemp2[2U] = 0x72655f74U;
    __Vtemp2[3U] = 0x636fU;
    vlTOPp->core__DOT__trace_file = VL_FOPEN_NN(VL_CVT_PACK_STR_NW(4, __Vtemp2)
                                                , std::string("w"));
}

void Vcore::_settle__TOP__5(Vcore__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcore::_settle__TOP__5\n"); );
    Vcore* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->core__DOT__mem_u__DOT__forwarded_store_value 
        = ((IData)(vlTOPp->core__DOT__load_store_forward_sel_ex_o)
            ? vlTOPp->core__DOT__load_value_mem_o : vlTOPp->core__DOT__latest_rs2_value_ex_o);
    vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_byte 
        = vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r
        [(0x1fffffU & vlTOPp->core__DOT__alu_result_ex_o)];
    vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_half 
        = ((vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r
            [(0x1fffffU & ((IData)(1U) + vlTOPp->core__DOT__alu_result_ex_o))] 
            << 8U) | vlTOPp->core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r
           [(0x1fffffU & vlTOPp->core__DOT__alu_result_ex_o)]);
    vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__ex_pc_2bit_counter 
        = vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer
        [(0x1ffU & (vlTOPp->core__DOT__pc_id_o >> 2U))];
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
    vlTOPp->core__DOT__if_u__DOT__btb_predicted_pc 
        = vlTOPp->core__DOT__if_u__DOT__BTB__DOT__BTB
        [(0x1ffU & (vlTOPp->core__DOT__if_u__DOT__pc_reg 
                    >> 2U))];
    vlTOPp->core__DOT__if_u__DOT__branch_is_taken_prediction 
        = ((0x400U > vlTOPp->core__DOT__if_u__DOT__pc_reg) 
           & (vlTOPp->core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer
              [(0x1ffU & (vlTOPp->core__DOT__if_u__DOT__pc_reg 
                          >> 2U))] >> 1U));
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

void Vcore::_eval_initial(Vcore__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcore::_eval_initial\n"); );
    Vcore* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_initial__TOP__1(vlSymsp);
    vlTOPp->__Vclklast__TOP__clk_i = vlTOPp->clk_i;
    vlTOPp->__Vclklast__TOP__rst_i = vlTOPp->rst_i;
}

void Vcore::final() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcore::final\n"); );
    // Variables
    Vcore__Syms* __restrict vlSymsp = this->__VlSymsp;
    Vcore* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
}

void Vcore::_eval_settle(Vcore__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcore::_eval_settle\n"); );
    Vcore* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_settle__TOP__5(vlSymsp);
}

void Vcore::_ctor_var_reset() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcore::_ctor_var_reset\n"); );
    // Body
    clk_i = VL_RAND_RESET_I(1);
    rst_i = VL_RAND_RESET_I(1);
    core__DOT__pc_incremented_if_o = VL_RAND_RESET_I(32);
    core__DOT__fetched_instruction_if_o = VL_RAND_RESET_I(32);
    core__DOT__branch_is_taken_prediction_if_o = VL_RAND_RESET_I(1);
    core__DOT__rs1_data_id_o = VL_RAND_RESET_I(32);
    core__DOT__rs2_data_id_o = VL_RAND_RESET_I(32);
    core__DOT__rd_label_id_o = VL_RAND_RESET_I(5);
    core__DOT__rs1_label_id_o = VL_RAND_RESET_I(5);
    core__DOT__rs2_label_id_o = VL_RAND_RESET_I(5);
    core__DOT__imm_value_id_o = VL_RAND_RESET_I(32);
    core__DOT__load_store_forward_sel_id_o = VL_RAND_RESET_I(1);
    core__DOT__reg_write_en_id_o = VL_RAND_RESET_I(1);
    core__DOT__rs1_pc_sel_id_o = VL_RAND_RESET_I(1);
    core__DOT__rs2_imm_sel_id_o = VL_RAND_RESET_I(1);
    core__DOT__is_branch_instr_id_o = VL_RAND_RESET_I(1);
    core__DOT__is_store_instr_id_o = VL_RAND_RESET_I(1);
    core__DOT__is_load_instr_id_o = VL_RAND_RESET_I(1);
    core__DOT__wb_sel_id_o = VL_RAND_RESET_I(2);
    core__DOT__alu_op_id_o = VL_RAND_RESET_I(4);
    core__DOT__pc_id_o = VL_RAND_RESET_I(32);
    core__DOT__fetched_instruction_id_o = VL_RAND_RESET_I(32);
    core__DOT__funct3_id_o = VL_RAND_RESET_I(3);
    core__DOT__unconditional_branch_id_o = VL_RAND_RESET_I(1);
    core__DOT__branch_is_taken_prediction_id_o = VL_RAND_RESET_I(1);
    core__DOT__alu_result_ex_o = VL_RAND_RESET_I(32);
    core__DOT__load_store_forward_sel_ex_o = VL_RAND_RESET_I(1);
    core__DOT__reg_write_en_ex_o = VL_RAND_RESET_I(1);
    core__DOT__is_load_instr_ex_o = VL_RAND_RESET_I(1);
    core__DOT__is_store_instr_ex_o = VL_RAND_RESET_I(1);
    core__DOT__rd_label_ex_o = VL_RAND_RESET_I(5);
    core__DOT__wb_sel_ex_o = VL_RAND_RESET_I(2);
    core__DOT__pc_ex_o = VL_RAND_RESET_I(32);
    core__DOT__latest_rs2_value_ex_o = VL_RAND_RESET_I(32);
    core__DOT__funct3_ex_o = VL_RAND_RESET_I(3);
    core__DOT__branching_ex_o = VL_RAND_RESET_I(1);
    core__DOT__branch_address_ex_o = VL_RAND_RESET_I(32);
    core__DOT__fetched_instruction_ex_o = VL_RAND_RESET_I(32);
    core__DOT__load_value_mem_o = VL_RAND_RESET_I(32);
    core__DOT__rd_label_mem_o = VL_RAND_RESET_I(5);
    core__DOT__reg_write_en_mem_o = VL_RAND_RESET_I(1);
    core__DOT__rd_value_mem_wo = VL_RAND_RESET_I(32);
    core__DOT__rd_value_mem_ro = VL_RAND_RESET_I(32);
    core__DOT__trace_file = 0;
    core__DOT__if_u__DOT__pc_next = VL_RAND_RESET_I(32);
    core__DOT__if_u__DOT__fetched_instruction = VL_RAND_RESET_I(32);
    core__DOT__if_u__DOT__btb_predicted_pc = VL_RAND_RESET_I(32);
    core__DOT__if_u__DOT__pc_reg = VL_RAND_RESET_I(32);
    core__DOT__if_u__DOT__branch_is_taken_prediction = VL_RAND_RESET_I(1);
    { int __Vi0=0; for (; __Vi0<33554432; ++__Vi0) {
            core__DOT__if_u__DOT__instr_cache_u__DOT__instructions[__Vi0] = VL_RAND_RESET_I(8);
    }}
    { int __Vi0=0; for (; __Vi0<1024; ++__Vi0) {
            core__DOT__if_u__DOT__BTB__DOT__BTB[__Vi0] = VL_RAND_RESET_I(32);
    }}
    core__DOT__if_u__DOT__BTB__DOT__i = VL_RAND_RESET_I(32);
    core__DOT__if_u__DOT__bimodal_predictor_u__DOT__ex_pc_2bit_counter = VL_RAND_RESET_I(2);
    { int __Vi0=0; for (; __Vi0<1024; ++__Vi0) {
            core__DOT__if_u__DOT__bimodal_predictor_u__DOT__branch_history_buffer[__Vi0] = VL_RAND_RESET_I(2);
    }}
    core__DOT__if_u__DOT__bimodal_predictor_u__DOT__i = VL_RAND_RESET_I(32);
    core__DOT__id_u__DOT__load_stall = VL_RAND_RESET_I(1);
    core__DOT__id_u__DOT__load_store_forward_sel = VL_RAND_RESET_I(1);
    core__DOT__id_u__DOT__id_flush = VL_RAND_RESET_I(1);
    { int __Vi0=0; for (; __Vi0<32; ++__Vi0) {
            core__DOT__id_u__DOT__register_file_u__DOT__registers[__Vi0] = VL_RAND_RESET_I(32);
    }}
    core__DOT__id_u__DOT__imm_gen_u__DOT__imm_r = VL_RAND_RESET_I(32);
    core__DOT__id_u__DOT__control_unit_u__DOT__control_signals = VL_RAND_RESET_I(8);
    core__DOT__id_u__DOT__control_unit_u__DOT__is_load_instr = VL_RAND_RESET_I(1);
    core__DOT__id_u__DOT__control_unit_u__DOT__is_store_instr = VL_RAND_RESET_I(1);
    core__DOT__id_u__DOT__control_unit_u__DOT__is_branch_instr = VL_RAND_RESET_I(1);
    core__DOT__id_u__DOT__control_unit_u__DOT__unconditional_branch = VL_RAND_RESET_I(1);
    core__DOT__id_u__DOT__control_unit_u__DOT__alu_op = VL_RAND_RESET_I(4);
    core__DOT__ex_u__DOT__branch_is_taken = VL_RAND_RESET_I(1);
    core__DOT__ex_u__DOT__wrong_prediction_NT_T = VL_RAND_RESET_I(1);
    core__DOT__ex_u__DOT__alu1_input = VL_RAND_RESET_I(32);
    core__DOT__ex_u__DOT__alu2_input = VL_RAND_RESET_I(32);
    core__DOT__ex_u__DOT__forwardA = VL_RAND_RESET_I(2);
    core__DOT__ex_u__DOT__forwardB = VL_RAND_RESET_I(2);
    core__DOT__ex_u__DOT__rs1_latest_value = VL_RAND_RESET_I(32);
    core__DOT__ex_u__DOT__rs2_latest_value = VL_RAND_RESET_I(32);
    core__DOT__ex_u__DOT__forwarding_unit_u__DOT__rs1_mem_match = VL_RAND_RESET_I(1);
    core__DOT__ex_u__DOT__forwarding_unit_u__DOT__rs2_mem_match = VL_RAND_RESET_I(1);
    core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r = VL_RAND_RESET_I(1);
    core__DOT__ex_u__DOT__ALU_u__DOT__result_r = VL_RAND_RESET_I(32);
    core__DOT__mem_u__DOT__forwarded_store_value = VL_RAND_RESET_I(32);
    core__DOT__mem_u__DOT__o_wbs_ack = VL_RAND_RESET_I(1);
    core__DOT__mem_u__DOT__o_wbs_data = VL_RAND_RESET_I(32);
    core__DOT__mem_u__DOT__loaded_data = VL_RAND_RESET_I(32);
    core__DOT__mem_u__DOT__data_read_from_mem = VL_RAND_RESET_I(32);
    { int __Vi0=0; for (; __Vi0<2097152; ++__Vi0) {
            core__DOT__mem_u__DOT__datum_cache_u__DOT__cache_r[__Vi0] = VL_RAND_RESET_I(8);
    }}
    core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_byte = VL_RAND_RESET_I(8);
    core__DOT__mem_u__DOT__datum_cache_u__DOT__datum_half = VL_RAND_RESET_I(16);
    core__DOT__mem_u__DOT__datum_cache_u__DOT__i = VL_RAND_RESET_I(32);
    __Vtableidx1 = 0;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[0] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[1] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[2] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[3] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[4] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[5] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[6] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[7] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[8] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[9] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[10] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[11] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[12] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[13] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[14] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[15] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[16] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[17] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[18] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[19] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[20] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[21] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[22] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[23] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[24] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[25] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[26] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[27] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[28] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[29] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[30] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[31] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[32] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[33] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[34] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[35] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[36] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[37] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[38] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[39] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[40] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[41] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[42] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[43] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[44] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[45] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[46] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[47] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[48] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[49] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[50] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[51] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[52] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[53] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[54] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[55] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[56] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[57] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[58] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[59] = 0U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[60] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[61] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[62] = 1U;
    __Vtable1_core__DOT__ex_u__DOT__branch_jump_u__DOT__out_sel_r[63] = 1U;
    __Vdlyvset__core__DOT__id_u__DOT__register_file_u__DOT__registers__v0 = 0;
    __Vdlyvdim0__core__DOT__id_u__DOT__register_file_u__DOT__registers__v1 = 0;
    __Vdlyvval__core__DOT__id_u__DOT__register_file_u__DOT__registers__v1 = VL_RAND_RESET_I(32);
    __Vdlyvset__core__DOT__id_u__DOT__register_file_u__DOT__registers__v1 = 0;
}
