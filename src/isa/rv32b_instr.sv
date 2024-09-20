/*
 * Copyright 2019 Google LLC
 * Copyright 2019 Mellanox Technologies Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Remaining bitmanip instructions of draft v.0.93 not ratified in v.1.00 (Zba, Zbb, Zbc, Zbs).

// LOGICAL instructions
`DEFINE_B_INSTR(GORC,     R_FORMAT, LOGICAL, RV32B)
`DEFINE_B_INSTR(GORCI,    I_FORMAT, LOGICAL, RV32B, UIMM)
`DEFINE_B_INSTR(CMIX,    R4_FORMAT, LOGICAL, RV32B)
`DEFINE_B_INSTR(CMOV,    R4_FORMAT, LOGICAL, RV32B)
//`DEFINE_B_INSTR(PACK,     R_FORMAT, LOGICAL, RV32B)
//`DEFINE_B_INSTR(PACKU,    R_FORMAT, LOGICAL, RV32B)
//`DEFINE_B_INSTR(PACKH,    R_FORMAT, LOGICAL, RV32B)
`DEFINE_B_INSTR(XPERM_N,  R_FORMAT, LOGICAL, RV32B)
`DEFINE_B_INSTR(XPERM_B,  R_FORMAT, LOGICAL, RV32B)
`DEFINE_B_INSTR(XPERM_H,  R_FORMAT, LOGICAL, RV32B)
// SHIFT intructions
`DEFINE_B_INSTR(SLO,    R_FORMAT, SHIFT, RV32B)
`DEFINE_B_INSTR(SRO,    R_FORMAT, SHIFT, RV32B)
`DEFINE_B_INSTR(SLOI,   I_FORMAT, SHIFT, RV32B, UIMM)
`DEFINE_B_INSTR(SROI,   I_FORMAT, SHIFT, RV32B, UIMM)
`DEFINE_B_INSTR(GREV,   R_FORMAT, SHIFT, RV32B)
`DEFINE_B_INSTR(GREVI,  I_FORMAT, SHIFT, RV32B, UIMM)
`DEFINE_B_INSTR(FSL,   R4_FORMAT, SHIFT, RV32B)
`DEFINE_B_INSTR(FSR,   R4_FORMAT, SHIFT, RV32B)
`DEFINE_B_INSTR(FSRI,   I_FORMAT, SHIFT, RV32B, UIMM)
// ARITHMETIC intructions
`DEFINE_B_INSTR(CRC32_B,     R_FORMAT, ARITHMETIC, RV32B)
`DEFINE_B_INSTR(CRC32_H,     R_FORMAT, ARITHMETIC, RV32B)
`DEFINE_B_INSTR(CRC32_W,     R_FORMAT, ARITHMETIC, RV32B)
`DEFINE_B_INSTR(CRC32C_B,    R_FORMAT, ARITHMETIC, RV32B)
`DEFINE_B_INSTR(CRC32C_H,    R_FORMAT, ARITHMETIC, RV32B)
`DEFINE_B_INSTR(CRC32C_W,    R_FORMAT, ARITHMETIC, RV32B)
`DEFINE_B_INSTR(SHFL,        R_FORMAT, ARITHMETIC, RV32B)
`DEFINE_B_INSTR(UNSHFL,      R_FORMAT, ARITHMETIC, RV32B)
`DEFINE_B_INSTR(SHFLI,       I_FORMAT, ARITHMETIC, RV32B, UIMM)
`DEFINE_B_INSTR(UNSHFLI,     I_FORMAT, ARITHMETIC, RV32B, UIMM)
`DEFINE_B_INSTR(BCOMPRESS,   R_FORMAT, ARITHMETIC, RV32B)
`DEFINE_B_INSTR(BDECOMPRESS, R_FORMAT, ARITHMETIC, RV32B)
`DEFINE_B_INSTR(BFP,         R_FORMAT, ARITHMETIC, RV32B)
