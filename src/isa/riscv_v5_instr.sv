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

class riscv_v5_instr extends riscv_instr;

  rand riscv_reg_t rs3;
  rand riscv_reg_t rs2;
  rand riscv_reg_t rs1;
  rand riscv_reg_t rd;
  rand riscv_reg_t fd;
  bit has_rs3 = 1'b0;
  rand bit[5:0] lsb;
  rand bit[5:0] msb;
  bit vm;

  `uvm_object_utils(riscv_v5_instr)

constraint rd_c{
	rd != 0;
}
  function new(string name = "");
    super.new(name);
    `uvm_info(`gfn, $sformatf("line 34 creating riscv_v5_instr"), UVM_LOW)
  endfunction



  virtual function void set_rand_mode();
    super.set_rand_mode();
    has_rs3 = 1'b0;
    `uvm_info(`gfn, $sformatf("line 44 Imm rand_mode Mukess -> instr name - %0p, group - %p, format - %p", instr_name,group,format), UVM_LOW)
    case (format) inside
      R_FORMAT: begin
        if (instr_name inside {BBC, BBS ,BEQC,BNEC,BFOS}) begin
          has_rs2 = 1'b0;
          has_imm = 1'b1;
        end
      end
      R4_FORMAT: begin
        has_imm = 1'b0;
        has_rs3 = 1'b1;
      end
      I_FORMAT: begin
        if (instr_name inside {FLHW}) begin
	  has_rs2=0;
	  has_imm=1;
      end
      end
      S_FORMAT: begin
	has_rs2 = 0;
      end
    endcase

  endfunction

  function void pre_randomize();
    super.pre_randomize();
      if (instr_name inside {BBC, BBS ,BEQC,BNEC,BFOS}) begin
	lsb = imm[5:0];
	msb = imm[11:6];
      end
    rs3.rand_mode(has_rs3);
  endfunction


  virtual function void set_imm_len();
        `uvm_info(`gfn, $sformatf("immlen func instr name - %0p", instr_name), UVM_LOW)

    if (format inside {I_FORMAT,S_FORMAT,CL_FORMAT,CS_FORMAT}) begin
      if (category inside {SHIFT, LOGICAL}) begin
        imm_len = $clog2(XLEN);
      end
      // ARITHMETIC RV32B
    end
      if (instr_name inside { ADDIGP, LBGP, LBUGP, LHGP, LHUGP, LWGP, LWUGP, LDGP, 
			      SBGP, SHGP, SWGP, SDGP }) begin
	imm_len = 18;
      end
      if (instr_name inside { EX9_IT, EXEC_IT , FLHW, FSHW}) begin
	imm_len = 12;
      end
      if (instr_name inside { BEQC, BNEC, BBC, BBS}) begin
	imm_len = 12;
      end

      if (instr_name inside { FLHW, FSHW }) begin
	imm_len = 12;
      end

    imm_mask = imm_mask << imm_len;
  endfunction

  // Convert the instruction to assembly code
  virtual function string convert2asm(string prefix = "");
    string asm_str_final, asm_str;
    asm_str = format_string(get_instr_name(), MAX_INSTR_STR_LEN);

        `uvm_info(`gfn, $sformatf("check mks > instr name - %0p", instr_name), UVM_LOW)

    case (format)
      I_FORMAT: begin
        if (instr_name inside {ADDIGP,LBGP, LBUGP, LHGP, LHUGP, LWGP, LWUGP, LDGP}) begin  // instr 
          asm_str_final = $sformatf("%0s%0s, %0s", asm_str,rd.name(),get_imm());
        end
        if(category == LOAD) begin// Use psuedo instruction format
            asm_str_final = $sformatf("%0s%0s, %0s(%0s)", asm_str, rd.name(), get_imm(), rs1.name());
      end
        if (instr_name inside {EX9_IT, EXEC_IT}) begin  // instr 
        `uvm_info(`gfn, $sformatf("check mks exe > instr name - %0p", instr_name), UVM_LOW)
            asm_str_final = $sformatf("%0s", asm_str, get_imm());
      end
      end
      S_FORMAT: begin
	if(category == STORE) // Use psuedo instruction format
          if (instr_name inside {FSHW}) begin  // instr (rs1)
            asm_str_final = $sformatf("%0s%0s, %0s(%0s)", asm_str, fd.name(),get_imm(),rs1.name());
	end
	else begin //instr rd rs1 rs2
          asm_str_final = $sformatf("%0s%0s, %0s, %0s", asm_str, rd.name(), rs1.name(), rs2.name());
	  end
      end
      R_FORMAT: begin  
        if (!has_rs2) begin //instr rd rs1
          asm_str_final = $sformatf("%0s%0s, %0s", asm_str, rd.name(), rs1.name());
        end
	else begin //instr rd rs1 rs2
          asm_str_final = $sformatf("%0s%0s, %0s, %0s", asm_str, rd.name(), rs1.name(), rs2.name());
	  end
      end

      R4_FORMAT: begin  // instr rd,rs1,rs2,rs3
          asm_str_final = $sformatf("%0s%0s, %0s, %0s, %0s", asm_str, rd.name(), rs1.name(),
                                  rs2.name(), rs3.name());
      end

      B_FORMAT:begin
      if(instr_name inside {BEQC, BNEC}) 
            asm_str_final = $sformatf("%0s%0s, %0d, %0s", asm_str, rs1.name(), b_imm[17:11], get_imm());
      else if(instr_name inside {BFOS, BFOZ}) 
            asm_str_final = $sformatf("%0s%0s, %0s, %0d, %0d", asm_str, rd.name(), rs1.name(), b_imm[16:11], b_imm[10:5]);
      else if(instr_name inside {BBC, BBS}) 
            asm_str_final = $sformatf("%0s%0s, %0d, %0s", asm_str, rs1.name(), b_imm[16:11], get_imm());
       end
      default: `uvm_info(`gfn, $sformatf("Unsupported format %0s", format.name()), UVM_LOW)
    endcase

    if (asm_str_final == "") begin
      return super.convert2asm(prefix);
    end

    if (comment != "") asm_str_final = {asm_str_final, " #", comment};
    return asm_str_final.tolower();
  endfunction

  function bit [6:0] get_opcode();
    case (instr_name) inside
 
      BREV8     : get_opcode = 7'b0010011;
       default: get_opcode = super.get_opcode();
    endcase
  endfunction

  virtual function bit [2:0] get_func3();
    case (instr_name) inside
      GORC: get_func3 = 3'b101;
      
      default: get_func3 = super.get_func3();
    endcase
    
  endfunction

  function bit [6:0] get_func7();
    case (instr_name) inside
      ANDN: get_func7 = 7'b0100000;

      default: get_func7 = super.get_func7();
    endcase

  endfunction

  function bit [4:0] get_func5();
    case (instr_name) inside
      SLOI: get_func5 = 5'b00100;


      default: `uvm_fatal(`gfn, $sformatf("Unsupported instruction %0s", instr_name.name()))
    endcase
  endfunction

  function bit [1:0] get_func2();
    case (instr_name) inside
      CMIX: get_func2 = 2'b11;
      default: `uvm_fatal(`gfn, $sformatf("Unsupported instruction %0s", instr_name.name()))
    endcase
  endfunction

  // Convert the instruction to assembly code
  virtual function string convert2bin(string prefix = "");
    string binary = "";
    case (format)
      R_FORMAT: begin
        if ((category inside {ARITHMETIC})) begin
        end

        end

      I_FORMAT: begin
        if ((category inside {SHIFT, LOGICAL})) begin
          binary = $sformatf("%8h", {get_func5(), imm[6:0], rs1, get_func3(), rd, get_opcode()});
        end else if ((category inside {SHIFT, LOGICAL})) begin
          binary = $sformatf("%8h", {get_func7(), imm[4:0], rs1, get_func3(), rd, get_opcode()});
        end

        if ((category inside {ARITHMETIC})) begin
          binary = $sformatf("%8h", {6'b00_0010, imm[5:0], rs1, get_func3(), rd, get_opcode()});
        end

      end

      R4_FORMAT: begin
        binary = $sformatf("%8h", {rs3, get_func2(), rs2, rs1, get_func3(), rd, get_opcode()});
      end
      default: begin
        if (binary == "") binary = super.convert2bin(prefix);
      end
    endcase
    return {prefix, binary};
  endfunction

  virtual function void do_copy(uvm_object rhs);
    riscv_v5_instr rhs_;
    super.copy(rhs);
    assert($cast(rhs_, rhs));
    this.rs3 = rhs_.rs3;
    this.has_rs3 = rhs_.has_rs3;
  endfunction : do_copy

  virtual function bit is_supported(riscv_instr_gen_config cfg);
    return 1; 
  endfunction

  // coverage related functons
  virtual function void update_src_regs(string operands[$]);
    // handle special I_FORMAT (FSRI, FSRIW) and R4_FORMAT
    case(format)
      I_FORMAT: begin
        if (instr_name inside {FSRI, FSRIW}) begin
          `DV_CHECK_FATAL(operands.size() == 4, instr_name)
          // fsri rd, rs1, rs3, imm
          rs1 = get_gpr(operands[1]);
          rs1_value = get_gpr_state(operands[1]);
          rs3 = get_gpr(operands[2]);
          rs3_value = get_gpr_state(operands[2]);
          get_val(operands[3], imm);
          return;
        end
      end
      R4_FORMAT: begin
        `DV_CHECK_FATAL(operands.size() == 4)
        rs1 = get_gpr(operands[1]);
        rs1_value = get_gpr_state(operands[1]);
        rs2 = get_gpr(operands[2]);
        rs2_value = get_gpr_state(operands[2]);
        rs3 = get_gpr(operands[3]);
        rs3_value = get_gpr_state(operands[3]);
        return;
      end
      default: ;
    endcase
    // reuse base function to handle the other instructions
    super.update_src_regs(operands);
  endfunction : update_src_regs

endclass
