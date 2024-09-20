/*
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2_0 (the "License");
 * you may not use this file except in compliance with the License_
 * You may obtain a copy of the License at
 *
 *      http://www_apache_org/licenses/LICENSE-2_0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied_
 * See the License for the specific language governing permissions and
 * limitations under the License_
 */


`DEFINE_FP_INSTR(FCVT_D_H ,I_FORMAT, ARITHMETIC, RV64FH)
`DEFINE_FP_INSTR(FCVT_H_D ,I_FORMAT, ARITHMETIC, RV64FH)

`DEFINE_FP_INSTR(FCVT_L_H, I_FORMAT, ARITHMETIC, RV64FH)

`DEFINE_FP_INSTR(FCVT_LU_H, I_FORMAT, ARITHMETIC, RV64FH)
`DEFINE_FP_INSTR(FCVT_H_L, I_FORMAT, ARITHMETIC, RV64FH)
`DEFINE_FP_INSTR(FCVT_H_LU, I_FORMAT, ARITHMETIC, RV64FH)

