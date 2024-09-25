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

class riscv_z_instr extends riscv_b_instr;

  rand riscv_reg_t rs3;
  bit has_rs3 = 1'b0;
  rand bit[3:0] rnum;
  rand bit[1:0] bs;
  bit vm;

  `uvm_object_utils(riscv_z_instr)

constraint vm_c{
	vm == imm[0];
}

constraint rd_c{
	rd != 0;
}
  function new(string name = "");
    super.new(name);
    `uvm_info(`gfn, $sformatf("creating riscv_z_inst class"), UVM_LOW)
  endfunction



  virtual function void set_rand_mode();
    super.set_rand_mode();
    has_rs3 = 1'b0;
    `uvm_info(`gfn, $sformatf("line 44 Imm rand_mode Mukess -> instr name - %0p, group - %p, format - %p", instr_name,group,format), UVM_LOW)
    case (format) inside
      R_FORMAT: begin
        if (instr_name inside {MOP_R_N,MOP_RR_N
                               }) begin
          has_rs2 = 1'b0;
        end
        else if (instr_name inside {FLI_S, FLI_D, FLI_H, FROUND_S, FROUNDNX_S,
				    FROUND_D, FROUNDNX_D, FROUND_H, FROUNDNX_H, 
				    FCVTMOD_W_D, FMVH_X_D, FMVP_D_X
                               }) begin
          has_rs2 = 1'b0;
	end
        else if (instr_name inside {CBO_CLEAN,CBO_FLUSH,CBO_INVAL,CBO_ZERO, WRS_NTO, WRS_STO}) begin
          has_rs2 = 1'b0;
          has_rd = 1'b0;
          has_imm = 1'b0;
        end
      end
      R4_FORMAT: begin
        has_imm = 1'b0;
        has_rs3 = 1'b1;
      end
      I_FORMAT: begin
        has_rs2 = 1'b0;
          `uvm_info(`gfn, $sformatf("line 68 Imm rand_mode Mukess -> instr name - %0p, group - %p, format - %p", instr_name,group,format), UVM_LOW)
        if (instr_name inside {PAUSE}) begin
          `uvm_info(`gfn, $sformatf("PAUSE git Imm rand_mode Mukess -> instr name - %0p, group - %p, format - %p", instr_name,group,format), UVM_LOW)
          has_rs2 = 1'b0;
          has_rs1 = 1'b0;
          has_imm = 1'b0;
        end
      end
      S_FORMAT: begin
	has_rs2 = 0;
      end
      CR_FORMAT: begin
        if(instr_name inside {C_ZEXT_B,C_SEXT_B,C_ZEXT_H,C_SEXT_H,C_ZEXT_W} ) begin // Use psuedo instruction format
	  has_rs2 = 0;
	  has_rs1 = 0;
	  has_imm = 0;
	end
      end
    endcase

  endfunction

  function void pre_randomize();
    super.pre_randomize();
	rnum = imm[3:0];
	bs   = imm[1:0];
      if (instr_name inside {PREFETCH_I,PREFETCH_R,PREFETCH_W}) begin
        imm = {imm[11:5],5'b00000};
      end
    rs3.rand_mode(has_rs3);
  endfunction


  virtual function void set_imm_len();
        `uvm_info(`gfn, $sformatf("immlen func instr name - %0p", instr_name), UVM_LOW)

    if (format inside {I_FORMAT,S_FORMAT,CL_FORMAT,CS_FORMAT}) begin
      if (category inside {SHIFT, LOGICAL}) begin
        imm_len = $clog2(XLEN);
      end
      if (instr_name inside {C_LBU, C_LHU, C_LH, C_SB, C_SH}) begin
        imm_len = 2;
      end
      // ARITHMETIC RV32B
      if (instr_name inside {PREFETCH_I,PREFETCH_R,PREFETCH_W}) begin
        imm_len = 12;
      end
    end

    imm_mask = imm_mask << imm_len;
  endfunction

  // Convert the instruction to assembly code
  virtual function string convert2asm(string prefix = "");
    string asm_str_final, asm_str;
    asm_str = format_string(get_instr_name(), MAX_INSTR_STR_LEN);

        `uvm_info(`gfn, $sformatf("2> 2asm -> instr name - %0p", instr_name), UVM_LOW)

    case (format)
      I_FORMAT: begin
        if (instr_name inside { PAUSE, NTL_P1, NTL_PALL,NTL_S1, NTL_ALL, C_MOP_1, C_MOP_3, C_MOP_5, C_MOP_7, C_MOP_9, C_MOP_11,C_MOP_13, C_MOP_15, WRS_NTO, WRS_STO}) begin  // instr 
          asm_str_final = $sformatf("%0s", asm_str);
        end
        else if (instr_name inside {CBO_CLEAN,CBO_FLUSH,CBO_INVAL,CBO_ZERO}) begin  // instr (rs1)
          asm_str_final = $sformatf("%0s (%0s)", asm_str, rs1.name());
        end
	// Inst present in vectore ext
        /*else if (instr_name inside {VFNCVT_F_F_W,VFWCVT_F_F_V}) begin  // instr vd,vs2,imm
          asm_str_final = $sformatf("%0s%0s, %0s, %0s, %0s", asm_str, vd.name(), vs2.name(),imm[0]);
        end*/
        else if (instr_name inside {PREFETCH_I,PREFETCH_R,PREFETCH_W}) begin  // instr offset(rs1)
          asm_str_final = $sformatf("%0s 0x%h(%0s)", asm_str, {imm[11:5],5'b00000},rs1.name());
        end
      end
      CL_FORMAT:begin
        if(category == LOAD) begin // Use psuedo instruction format
            asm_str = $sformatf("%0s%0s, %0s(%0s)", asm_str, rd.name(), get_imm(), rs1.name());
        end
      end
      S_FORMAT: begin
	if(category == STORE) // Use psuedo instruction format
            asm_str = $sformatf("%0s%0s, %0s(%0s)", asm_str, rs2.name(), get_imm(), rs1.name());
	end
      CR_FORMAT: begin  
        if (!has_rs2) begin //instr rd rs1
          asm_str_final = $sformatf("%0s%0s, %0s", asm_str, rd.name(), rs1.name());
        end
        else if(instr_name inside {C_ZEXT_B,C_SEXT_B,C_ZEXT_H,C_SEXT_H,C_ZEXT_W} ) begin // Use psuedo instruction format
          asm_str_final = $sformatf("%0s%0s", asm_str, rd.name());
	  
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
      default: `uvm_info(`gfn, $sformatf("Unsupported format %0s", format.name()), UVM_LOW)
    endcase

    if (asm_str_final == "") begin
      //return super.convert2asm(prefix);
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
        if ((category inside {ARITHMETIC}) && (group == RV32B)) begin
          if (instr_name inside {CRC32_B, CRC32_H, CRC32_W, CRC32C_B, CRC32C_H, CRC32C_W}) begin
            binary =
                $sformatf("%8h", {get_func7(), get_func5(), rs1, get_func3(), rd, get_opcode()});
          end
        end

        if ((category inside {ARITHMETIC}) && (group == RV64B)) begin
          if (instr_name inside {CRC32_D, CRC32C_D, BMATFLIP}) begin
            binary =
                $sformatf("%8h", {get_func7(), get_func5(), rs1, get_func3(), rd, get_opcode()});
          end
        end
        if ((category inside {ARITHMETIC}) && (group inside {RV64ZBKX,RV64ZBKC,RV64ZBKB,RV64ZKND,RV64ZKNE,RV64ZKNH,RV64ZKSED,RV64ZKSH})) begin
          if (instr_name inside {AES64IM}) begin
            binary =
                $sformatf("%8h", {get_func7(), get_func5(), rs1, get_func3(), rd, get_opcode()});
	  end
	  else
            binary = $sformatf("%8h", {get_func7(), get_func5(), rs2, rs1, get_func3(), rd, get_opcode()});
		
        end
      end

      I_FORMAT: begin
        if ((category inside {SHIFT, LOGICAL}) && (group == RV32B)) begin
          binary = $sformatf("%8h", {get_func5(), imm[6:0], rs1, get_func3(), rd, get_opcode()});
        end else if ((category inside {SHIFT, LOGICAL}) && (group == RV64B)) begin
          binary = $sformatf("%8h", {get_func7(), imm[4:0], rs1, get_func3(), rd, get_opcode()});
        end

        if (instr_name inside {FSRI}) begin
          binary = $sformatf("%8h", {rs3, 1'b1, imm[5:0], rs1, get_func3(), rd, get_opcode()});
        end

        if ((category inside {ARITHMETIC}) && (group == RV32B)) begin
          binary = $sformatf("%8h", {6'b00_0010, imm[5:0], rs1, get_func3(), rd, get_opcode()});
        end

        if ((category inside {ARITHMETIC}) && (group == RV64B)) begin
          binary = $sformatf("%8h", {imm[11:0], rs1, get_func3(), rd, get_opcode()});
        end

	// SM4ED,SM4KS
        if ((category inside {ARITHMETIC}) && (group inside {RV64ZBKX,RV64ZBKC,RV64ZBKB,RV64ZKND,RV64ZKNE,RV64ZKNH,RV64ZKSED,RV64ZKSH})) begin
          if (instr_name inside {SM4ED,SM4KS}) begin
            binary = $sformatf("%8h", {imm[1:0], get_func5(), rs2, rs1, get_func3(), rd, get_opcode()});
          end
	  // AES64KS1I
          else if (instr_name inside {AES64KS1I}) begin
            binary = $sformatf("%8h", {get_func7(), 1'b1,rnum, rs1, get_func3(), rd, get_opcode()});
          end
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
    riscv_z_instr rhs_;
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





