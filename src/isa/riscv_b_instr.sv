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

class riscv_b_instr extends riscv_instr;

  rand riscv_reg_t rs3;
  bit has_rs3 = 1'b0;
  rand bit[3:0] rnum;
  rand bit[1:0] bs;


  `uvm_object_utils(riscv_b_instr)

constraint rnum_c{
	rnum inside {[0:10]};
	bs inside {[0:3]};
}

constraint rd_c{
	rd != 0;
}
  function new(string name = "");
    super.new(name);
  endfunction

  virtual function void set_rand_mode();
    super.set_rand_mode();
    has_rs3 = 1'b0;
    case (format) inside
      R_FORMAT: begin
	
        if (instr_name inside {BMATFLIP,
                               CRC32_B, CRC32_H, CRC32_W, CRC32C_B, CRC32C_H, CRC32C_W, CRC32_D,
                               CRC32C_D, AES64IM, AES64KS1I, SHA256SIG0, SHA256SIG1, SHA256SUM0, SHA256SUM1, SHA512SIG0, SHA512SIG1, SHA512SUM0, SHA512SUM1, SM3P0, SM3P1}) begin
          has_rs2 = 1'b0;
        end
        else if (instr_name inside {SM4KS, SM4ED}) begin
          has_rs2 = 1'b1;
          has_imm = 1'b1;
        end
      end
      R4_FORMAT: begin
        has_imm = 1'b0;
        has_rs3 = 1'b1;
      end
      I_FORMAT: begin
        has_rs2 = 1'b0;
        if (instr_name inside {FSRI, FSRIW}) begin
          has_rs3 = 1'b1;
        end
      end
    endcase

  endfunction

  function void pre_randomize();
    super.pre_randomize();
	rnum = imm[3:0];
	bs   = imm[1:0];
    rs3.rand_mode(has_rs3);
  endfunction


  virtual function void set_imm_len();

    if (format inside {I_FORMAT}) begin
      if (category inside {SHIFT, LOGICAL}) begin
        imm_len = $clog2(XLEN);
      end
      // ARITHMETIC RV32B
      if (instr_name inside {SHFLI, UNSHFLI}) begin
        imm_len = $clog2(XLEN) - 1;
      end
      if (instr_name inside {SM4ED, SM4KS}) begin
        imm_len = 2;
      end
    end

    imm_mask = imm_mask << imm_len;
  endfunction

  // Convert the instruction to assembly code
  virtual function string convert2asm(string prefix = "");
    string asm_str_final, asm_str;
    asm_str = format_string(get_instr_name(), MAX_INSTR_STR_LEN);


    case (format)
      I_FORMAT: begin
        if (instr_name inside {FSRI, FSRIW}) begin  // instr rd,rs1,rs3,imm
          asm_str_final = $sformatf("%0s%0s, %0s, %0s, %0s", asm_str, rd.name(), rs1.name(),rs3.name(), get_imm());
        end
        //else if ((instr_name inside {AES64KS1I}) && (group == RV64ZBK)) begin  // instr rd,rs1,rnum
        else if ((instr_name inside {AES64KS1I}) && (group == RV64ZKND)) begin  // instr rd,rs1,rnum
          asm_str_final = $sformatf("%0s%0s, %0s, %0d", asm_str, rd.name(), rs1.name(),rnum);
	end
      end

      R_FORMAT: begin  //instr rd rs1
        if (!has_rs2) begin
          asm_str_final = $sformatf("%0s%0s, %0s", asm_str, rd.name(), rs1.name());
        end
	 else if((instr_name inside {SM4KS, SM4ED})&& (group == RV64ZKSED) && has_rs2 && (imm_type==UIMM))begin
            asm_str_final = $sformatf("%0s%0s, %0s, %0s, %0d ", asm_str, rd.name(), rs1.name(), rs3.name(), bs);
	  end
	else begin
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
      return super.convert2asm(prefix);
    end

    if (comment != "") asm_str_final = {asm_str_final, " #", comment};
    return asm_str_final.tolower();
  endfunction

  function bit [6:0] get_opcode();
    case (instr_name) inside
      GORC, SLO, SRO, GREV, XPERM_N, XPERM_B, XPERM_H, XPERM_W: get_opcode = 7'b0110011;
      GORCI, SLOI, SROI, GREVI, CMIX, CMOV, FSL: get_opcode = 7'b0010011;
      FSR, FSRI, BMATFLIP, CRC32_B, CRC32_H, CRC32_W, CRC32C_B, CRC32C_H: get_opcode = 7'b0010011;
      CRC32C_W, CRC32_D, CRC32C_D: get_opcode = 7'b0010011;
      SHFL, UNSHFL, BCOMPRESS, BDECOMPRESS, PACK, PACKU, BMATOR, BMATXOR, PACKH, BFP: get_opcode
          = 7'b0110011;
      SHFLI, UNSHFLI: get_opcode = 7'b0010011;
      SLOW, SROW, GORCW, GREVW: get_opcode = 7'b0111011;
      SLOIW, SROIW, GORCIW, GREVIW: get_opcode = 7'b0011011;
      FSLW, FSRW: get_opcode = 7'b0111011;
      FSRIW: get_opcode = 7'b0011011;
      SHFLW, UNSHFLW, BCOMPRESSW, BDECOMPRESSW, PACKW, PACKUW, BFPW: get_opcode = 7'b0111011;

      AES64DS,   
      AES64DSM, 
      AES64ES,  
      AES64ESM,
      AES64KS2 
		: get_opcode = 7'b0011011; 
      AES64IM,  
      AES64KS1I
		: get_opcode = 7'b0010011; 
     SHA512SIG0H,
     SHA512SIG0L,
     SHA512SIG1H,
     SHA512SIG1L,
     SHA512SUM0R,
     SHA512SUM1R
		: get_opcode = 7'b0110011; 

     SHA512SIG0,
     SHA512SIG1,
     SHA512SUM0,
     SHA512SUM1
		: get_opcode = 7'b0010011; 
  

                      
                
      SHA256SIG0,
      SHA256SIG1,
      SHA256SUM0,
      SHA256SUM1
		: get_opcode = 7'b0011011; 
      SM4ED,  
      SM4KS  
		: get_opcode = 7'b0010011; 
              
      SM3P0,  
      SM3P1  
		: get_opcode = 7'b0110011; 
      BREV8     : get_opcode = 7'b0010011;

      CLMUL,CLMULH      : get_opcode = 7'b0110011; 
       default: get_opcode = super.get_opcode();
    endcase
  endfunction

  virtual function bit [2:0] get_func3();
    case (instr_name) inside
      GORC: get_func3 = 3'b101;
      GORCI: get_func3 = 3'b101;
      SLO: get_func3 = 3'b001;
      SRO: get_func3 = 3'b101;
      SLOI: get_func3 = 3'b001;
      SROI: get_func3 = 3'b101;
      GREV: get_func3 = 3'b101;
      GREVI: get_func3 = 3'b101;
      CMIX: get_func3 = 3'b001;
      CMOV: get_func3 = 3'b101;
      FSL: get_func3 = 3'b001;
      FSR: get_func3 = 3'b101;
      FSRI: get_func3 = 3'b101;
      BMATFLIP: get_func3 = 3'b001;
      CRC32_B: get_func3 = 3'b001;
      CRC32_H: get_func3 = 3'b001;
      CRC32_W: get_func3 = 3'b001;
      CRC32C_B: get_func3 = 3'b001;
      CRC32C_H: get_func3 = 3'b001;
      CRC32C_W: get_func3 = 3'b001;
      CRC32_D: get_func3 = 3'b001;
      CRC32C_D: get_func3 = 3'b001;
      SHFL: get_func3 = 3'b001;
      UNSHFL: get_func3 = 3'b101;
      BCOMPRESS: get_func3 = 3'b110;
      BDECOMPRESS: get_func3 = 3'b110;
      PACK: get_func3 = 3'b100;
      PACKU: get_func3 = 3'b100;
      BMATOR: get_func3 = 3'b011;
      BMATXOR: get_func3 = 3'b011;
      PACKH: get_func3 = 3'b111;
      BFP: get_func3 = 3'b111;
      SHFLI: get_func3 = 3'b001;
      UNSHFLI: get_func3 = 3'b101;
      SLOW: get_func3 = 3'b001;
      SROW: get_func3 = 3'b101;
      ROLW: get_func3 = 3'b001;
      GORCW: get_func3 = 3'b101;
      GREVW: get_func3 = 3'b101;
      SLOIW: get_func3 = 3'b001;
      SROIW: get_func3 = 3'b101;
      RORIW: get_func3 = 3'b101;
      GORCIW: get_func3 = 3'b101;
      GREVIW: get_func3 = 3'b101;
      FSLW: get_func3 = 3'b001;
      FSRW: get_func3 = 3'b101;
      FSRIW: get_func3 = 3'b101;
      SHFLW: get_func3 = 3'b001;
      UNSHFLW: get_func3 = 3'b101;
      BCOMPRESSW: get_func3 = 3'b110;
      BDECOMPRESSW: get_func3 = 3'b110;
      PACKW: get_func3 = 3'b100;
      PACKUW: get_func3 = 3'b100;
      BFPW: get_func3 = 3'b111;
      XPERM_N: get_func3 = 3'b010;
      XPERM_B: get_func3 = 3'b100;
      XPERM_H: get_func3 = 3'b110;
      XPERM_W: get_func3 = 3'b000;
        
      AES64DS, 
      AES64DSM, 
      AES64ES,  
      AES64ESM,
      AES64KS2
               : get_func3 = 3'b000;
  
      AES64IM,  
      AES64KS1I
       	: get_func3 = 3'b001; 
                           
      SHA256SIG0, 
      SHA256SIG1,
      SHA256SUM0,
      SHA256SUM1
                  : get_func3 = 3'b001;
      SHA512SIG0H,
      SHA512SIG0L,
      SHA512SIG1H,
      SHA512SIG1L,
      SHA512SUM0R,
      SHA512SUM1R
	        : get_func3 = 3'b000;

      SHA512SIG0,
      SHA512SIG1,
      SHA512SUM0,
      SHA512SUM1
	        : get_func3 = 3'b001;

      SM4ED,  
      SM4KS  
	        : get_func3 = 3'b001;
              
      SM3P0,  
      SM3P1  
	        : get_func3 = 3'b000;

      BREV8     : get_func3 = 3'b101;
      CLMUL      : get_func3 = 3'b001;
      CLMULH     : get_func3 = 3'b011;

      default: get_func3 = super.get_func3();
    endcase
    
  endfunction

  function bit [6:0] get_func7();
    case (instr_name) inside
      ANDN: get_func7 = 7'b0100000;
      ORN: get_func7 = 7'b0100000;
      XNOR: get_func7 = 7'b0100000;
      GORC: get_func7 = 7'b0010100;
      SLO: get_func7 = 7'b0010000;
      SRO: get_func7 = 7'b0010000;
      ROL: get_func7 = 7'b0110000;
      ROR: get_func7 = 7'b0110000;
      GREV: get_func7 = 7'b0110100;
      BMATFLIP: get_func7 = 7'b0110000;
      CRC32_B: get_func7 = 7'b0110000;
      CRC32_H: get_func7 = 7'b0110000;
      CRC32_W: get_func7 = 7'b0110000;
      CRC32C_B: get_func7 = 7'b0110000;
      CRC32C_H: get_func7 = 7'b0110000;
      CRC32C_W: get_func7 = 7'b0110000;
      CRC32_D: get_func7 = 7'b0110000;
      CRC32C_D: get_func7 = 7'b0110000;
      SHFL: get_func7 = 7'b0000100;
      UNSHFL: get_func7 = 7'b0000100;
      BCOMPRESS: get_func7 = 7'b0000100;
      BDECOMPRESS: get_func7 = 7'b0100100;
      PACK: get_func7 = 7'b0000100;
      PACKU: get_func7 = 7'b0100100;
      BMATOR: get_func7 = 7'b0000100;
      BMATXOR: get_func7 = 7'b0100100;
      PACKH: get_func7 = 7'b0000100;
      BFP: get_func7 = 7'b0100100;
      SLOW: get_func7 = 7'b0010000;
      SROW: get_func7 = 7'b0010000;
      GORCW: get_func7 = 7'b0010100;
      GORCIW: get_func7 = 7'b0010100;
      GREVW: get_func7 = 7'b0110100;
      GREVIW: get_func7 = 7'b0110100;
      SLOIW: get_func7 = 7'b0010000;
      SROIW: get_func7 = 7'b0010000;
      SHFLW: get_func7 = 7'b0000100;
      UNSHFLW: get_func7 = 7'b0000100;
      BCOMPRESSW: get_func7 = 7'b0000100;
      BDECOMPRESSW: get_func7 = 7'b0100100;
      PACKW: get_func7 = 7'b0000100;
      PACKUW: get_func7 = 7'b0100100;
      BFPW: get_func7 = 7'b0100100;
      XPERM_N: get_func7 = 7'b0010100;
      XPERM_B: get_func7 = 7'b0010100;
      XPERM_H: get_func7 = 7'b0010100;
      XPERM_W: get_func7 = 7'b0010100;
      AES64DS 	  	:get_func7 = 7'b0011101;
      AES64DSM 		:get_func7 = 7'b0011111; 
      AES64ES		:get_func7 = 7'b0011001;   
      AES64ESM          :get_func7 = 7'b0011011;
      AES64KS2          :get_func7 = 7'b0111111; 
  
      AES64IM           :get_func7 = 7'b0011000;     
      AES64KS1I         :get_func7 = 7'b0011000;   
    
                           
      SHA256SIG0        :get_func7 = 7'b0001000;  
      SHA256SIG1       :get_func7 = 7'b0001000; 
      SHA256SUM0       :get_func7 = 7'b0001000;  
      SHA256SUM1        :get_func7 = 7'b0001000;

      SHA512SIG0H       :get_func7 = 7'b0101110;
      SHA512SIG0L       :get_func7 = 7'b0101010;
      SHA512SIG1H       :get_func7 = 7'b0101111;
      SHA512SIG1L       :get_func7 = 7'b0101011;
      SHA512SUM0R       :get_func7 = 7'b0101000;
      SHA512SUM1R       :get_func7 = 7'b0101001;

      SHA512SIG0        :get_func7 = 7'b0101111;
      SHA512SIG1        :get_func7 = 7'b0101011;
      SHA512SUM0        :get_func7 = 7'b0101000;
      SHA512SUM1        :get_func7 = 7'b0101001;

              
      SM3P0		:get_func7 = 7'b0001000; 
      SM3P1             :get_func7 = 7'b0001000; 

      BREV8	  	:get_func7 = 7'b0110100;	
      CLMUL,CLMULH	:get_func7 = 7'b0000101;	

      default: get_func7 = super.get_func7();
    endcase

  endfunction

  function bit [4:0] get_func5();
    case (instr_name) inside
      SLOI: get_func5 = 5'b00100;
      SROI: get_func5 = 5'b00100;
      RORI: get_func5 = 5'b01100;
      GORCI: get_func5 = 5'b00101;
      GREVI: get_func5 = 5'b01101;

      CRC32_B: get_func5 = 5'b10000;
      CRC32_H: get_func5 = 5'b10001;
      CRC32_W: get_func5 = 5'b10010;
      CRC32C_B: get_func5 = 5'b11000;
      CRC32C_H: get_func5 = 5'b11001;
      CRC32C_W: get_func5 = 5'b11010;
      CRC32_D: get_func5 = 5'b10011;
      CRC32C_D: get_func5 = 5'b11011;

      BMATFLIP: get_func5 = 5'b00011;

      SHA256SIG0       :get_func5 = 5'b00010;  
      SHA256SIG1       :get_func5 = 5'b00011; 
      SHA256SUM0       :get_func5 = 5'b00000;  
      SHA256SUM1       :get_func5 = 5'b00001;

      SHA512SIG0       :get_func5 = 5'b00110;
      SHA512SIG1       :get_func5 = 5'b00111;
      SHA512SUM0       :get_func5 = 5'b00100;
      SHA512SUM1       :get_func5 = 5'b01000;

      SM4ED            :get_func5 = 5'b01000;   
      SM4KS            :get_func5 = 5'b01000; 

      SM3P1            :get_func5 = 5'b01001;   
      SM3P0            :get_func5 = 5'b01000; 

      BREV8	       :get_func5 = 5'b00111;



      default: `uvm_fatal(`gfn, $sformatf("Unsupported instruction %0s", instr_name.name()))
    endcase
  endfunction

  function bit [1:0] get_func2();
    case (instr_name) inside
      CMIX: get_func2 = 2'b11;
      CMOV: get_func2 = 2'b11;
      FSL: get_func2 = 2'b10;
      FSR: get_func2 = 2'b10;
      FSLW: get_func2 = 2'b10;
      FSRW: get_func2 = 2'b10;
      FSRIW: get_func2 = 2'b10;
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
    riscv_b_instr rhs_;
    super.copy(rhs);
    assert($cast(rhs_, rhs));
    this.rs3 = rhs_.rs3;
    this.has_rs3 = rhs_.has_rs3;
  endfunction : do_copy

  virtual function bit is_supported(riscv_instr_gen_config cfg);
    return cfg.enable_b_extension && (
           (ZBP inside {cfg.enable_bitmanip_groups} && instr_name inside {
               GREV, GREVW, GREVI, GREVIW,
               GORC, GORCW, GORCI, GORCIW,
               SHFL, SHFLW, UNSHFL, UNSHFLW, SHFLI, UNSHFLI,
               XPERM_N, XPERM_B, XPERM_H, XPERM_W,
               SLO, SLOW, SLOI, SLOIW,
               SRO, SROW, SROI, SROIW
               }) ||
           (ZBE inside {cfg.enable_bitmanip_groups} && instr_name inside {
               BCOMPRESS, BCOMPRESSW,
               BDECOMPRESS, BDECOMPRESSW
               }) ||
           (ZBF inside {cfg.enable_bitmanip_groups} && instr_name inside {BFP, BFPW}) ||
           (ZBR inside {cfg.enable_bitmanip_groups} && instr_name inside {
               CRC32_B, CRC32_H, CRC32_W, CRC32_D,
               CRC32C_B, CRC32C_H, CRC32C_W, CRC32C_D
               }) ||
           (ZBM inside {cfg.enable_bitmanip_groups} && instr_name inside {
               BMATOR, BMATXOR, BMATFLIP
               }) ||
           (ZBT inside {cfg.enable_bitmanip_groups} && instr_name inside {
               CMOV, CMIX,
               FSL, FSLW, FSR, FSRW, FSRI, FSRIW}) ||
           (ZBK inside {cfg.enable_bitmanip_groups} && instr_name inside {
AES64DS, AES64DSM, AES64IM, AES64ES, AES64ESM, AES64KS1I, AES64KS2, SHA256SIG0, SHA256SIG1, SHA256SUM0, 
SHA256SUM1, SHA512SIG0H, SHA512SIG0L, SHA512SIG1H, SHA512SIG1L, SHA512SUM0R, SHA512SUM1R, SHA512SIG0,
SHA512SIG1, SHA512SUM0, SHA512SUM1, SM4ED, SM4KS, SM3P0, SM3P1 ,CLMUL,CLMULH,PACK,PACKU,PACKH,PACKW,PACKUW,BREV8})
           );
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




