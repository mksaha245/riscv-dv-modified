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
//`DEFINE_B_INSTR(PACK,   R_FORMAT, LOGICAL, RV64B)
//`DEFINE_B_INSTR(PACKH,   R_FORMAT, LOGICAL, RV64B)
//`DEFINE_B_INSTR(PACKW,   R_FORMAT, LOGICAL, RV64B)
//`DEFINE_B_INSTR(PACKUW,  R_FORMAT, LOGICAL, RV64B)
//`DEFINE_B_INSTR(XPERM_W, R_FORMAT, LOGICAL, RV64B)
// LOGICAL instructions
`DEFINE_B_INSTR(PACK,   R_FORMAT, LOGICAL,  RV64ZBKB)
`DEFINE_B_INSTR(PACKU,   R_FORMAT, LOGICAL,  RV64ZBKB) // Not supported yeat in cuzco
`DEFINE_B_INSTR(PACKH,   R_FORMAT, LOGICAL, RV64ZBKB)
`DEFINE_B_INSTR(PACKW,   R_FORMAT, LOGICAL, RV64ZBKB)
`DEFINE_B_INSTR(PACKUW,  R_FORMAT, LOGICAL, RV64ZBKB) // Not supported yeat in cuzco
`DEFINE_B_INSTR(BREV8, R_FORMAT, LOGICAL, RV64ZBKB)

