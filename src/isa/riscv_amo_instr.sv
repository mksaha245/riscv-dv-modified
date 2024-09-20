/*
 * Copyright 2020 Google LLC
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

class riscv_amo_instr extends riscv_instr;

  rand bit aq;
  rand bit rl;

  constraint aq_rl_c {
    (aq && rl) == 0;
  }

  `uvm_object_utils(riscv_amo_instr)

  function new(string name = "");
    super.new(name);
  endfunction

  virtual function string get_instr_name();
    get_instr_name = instr_name.name();
    if (group == RV32A) begin
      get_instr_name = {get_instr_name.substr(0, get_instr_name.len() - 3), ".w"};
      get_instr_name = aq ? {get_instr_name, ".aq"} :
                       rl ? {get_instr_name, ".rl"} : get_instr_name;
    end else if (group == RV64A) begin
      get_instr_name = {get_instr_name.substr(0, get_instr_name.len() - 3), ".d"};
      get_instr_name = aq ? {get_instr_name, ".aq"} :
                       rl ? {get_instr_name, ".rl"} : get_instr_name;
    end else begin
      `uvm_fatal(`gfn, $sformatf("Unexpected amo instr group: %0s / %0s",
                                 group.name(), instr_name.name()))
    end
    return get_instr_name;
  endfunction : get_instr_name

  // Convert the instruction to assembly code
  virtual function string convert2asm(string prefix = "");
    string asm_str;
    asm_str = format_string(get_instr_name(), MAX_INSTR_STR_LEN);
    if (group inside {RV32A, RV64A}) begin
      if (instr_name inside {LR_W, LR_D}) begin
        asm_str = $sformatf("%0s %0s, (%0s)", asm_str, rd.name(), rs1.name());
      end else begin
        asm_str = $sformatf("%0s %0s, %0s, (%0s)", asm_str, rd.name(), rs2.name(), rs1.name());
      end
    end else begin
      `uvm_fatal(`gfn, $sformatf("Unexpected amo instr group: %0s / %0s",
                                 group.name(), instr_name.name()))
    end
    if(comment != "")
      asm_str = {asm_str, " #",comment};
    return asm_str.tolower();
  endfunction : convert2asm

  virtual function void do_copy(uvm_object rhs);
    riscv_amo_instr rhs_;
    super.copy(rhs);
    assert($cast(rhs_, rhs));
    this.aq = rhs_.aq;
    this.rl = rhs_.rl;
  endfunction : do_copy

   virtual function bit [6:0] get_opcode();
    case (instr_name) inside
      ///////////// RV32A instruction added //////////////
  //amo_cov_change      
      LR_W,     		
      SC_W    		, 
      AMOSWAP_W		, 
      AMOADD_W		, 
      AMOAND_W		, 
      AMOOR_W 		, 
      AMOXOR_W		, 
      AMOMIN_W		, 
      AMOMAX_W		, 
      AMOMINU_W		, 
  ///////////// RV64A instruction added //////////////
	LR_D			,     		
	SC_D    		, 
	AMOSWAP_D		, 
	AMOADD_D		, 
	AMOAND_D		, 
	AMOOR_D 		, 
	AMOXOR_D		, 
	AMOMIN_D		, 
	AMOMAX_D		, 
	AMOMINU_D		, 
	AMOMAXU_D		: get_opcode = 7'b0101111; 

      default : `uvm_fatal(`gfn, $sformatf("Unsupported instruction %0s", instr_name.name()))
    endcase
  endfunction

virtual function bit [2:0] get_func3();
    case (instr_name) inside
    ///////////// RV32A instruction added //////////////
      LR_W     , 
      SC_W    ,
      AMOSWAP_W,
      AMOADD_W,
      AMOAND_W,
      AMOOR_W ,
      AMOXOR_W,
      AMOMIN_W,
      AMOMAX_W,
      AMOMINU_W,
      AMOMAXU_W: get_func3 = 3'b010;
  ///////////// RV64A instruction added //////////////
	LR_D			,     		
	SC_D    		,                           	
	AMOSWAP_D		, 
	AMOADD_D		, 
	AMOAND_D		, 
	AMOOR_D 		, 
	AMOXOR_D		, 
	AMOMIN_D		, 
	AMOMAX_D		, 
	AMOMINU_D		, 
	AMOMAXU_D		: get_func3 = 3'b011; 
      
      ECALL, EBREAK, URET, SRET, MRET, DRET, WFI, SFENCE_VMA : get_func3 = 3'b000;
      default : `uvm_fatal(`gfn, $sformatf("Unsupported instruction %0s", instr_name.name()))
    endcase
  endfunction
function bit [6:0] get_func7();
    case (instr_name)
  ///////////// RV32A & RV64A instruction added //////////////
	    LR_W     ,LR_D					:get_func7 = {5'b00010,aq,rl};
            SC_W     ,SC_D    					:get_func7 = {5'b00011,aq,rl};      
            AMOSWAP_W,AMOSWAP_D					:get_func7 = {5'b00001,aq,rl};
            AMOADD_W ,AMOADD_D					:get_func7 = {5'b00000,aq,rl};
            AMOAND_W ,AMOAND_D					:get_func7 = {5'b01100,aq,rl};
            AMOOR_W  ,AMOOR_D 					:get_func7 = {5'b01000,aq,rl};
            AMOXOR_W ,AMOXOR_D					:get_func7 = {5'b00100,aq,rl};
            AMOMIN_W ,AMOMIN_D					:get_func7 = {5'b10000,aq,rl};
            AMOMAX_W ,AMOMAX_D					:get_func7 = {5'b10100,aq,rl};
            AMOMINU_W,AMOMINU_D					:get_func7 = {5'b11000,aq,rl};
            AMOMAXU_W,AMOMAXU_D					:get_func7 = {5'b11100,aq,rl};

      default : `uvm_fatal(`gfn, $sformatf("Unsupported instruction %0s", instr_name.name()))
    endcase
  endfunction



endclass
