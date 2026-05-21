
// Code your testbench here
// or browse Examples


class riscv_mmu_gen extends uvm_object;
riscv_instr_gen_config cfg;
  `define PC_GVA cfg.PC_GVA
  `define DATA_GVA cfg.DATA_GVA 
  `define VSATP_PPN 'h81010101010
  riscv_instr        mmu_instr[$];
  
  bit en_hv_inst,is_sup,is_user,is_virtualization_on,inst_trans,data_trans,
  		enable_g_load_page_fault=0,enable_g_store_page_fault=0,enable_g_inst_access_page_fault=0,stage_2_g_fault,
  		enable_load_page_fault=0,enable_store_page_fault=0,enable_inst_access_page_fault=0,stage_1_fault;
  int num_g_load_page_fault=0,num_g_store_page_fault=0,num_g_inst_access_page_fault=0;
  page_size_t init_page_size = P4KB;
  page_size_t guest_page_size = P1GB;
  atp_mode hgatp_m = BAREM;
  atp_mode vsatp_m = BAREM;
  atp_mode satp_m = SV48M;
  riscv_reg_t rd,rd_reg;
  string str[$];
  bit [63:0] satp,vsatp,hgatp,v_mode_on=0;
  longint unsigned real_satp;
  logic[49:0] GPA_3,GPA_2, GPA_1,GPA_0,set_size,g_set_size,tmp;
  logic [63:0] satp_ppn,vsatp_ppn,hgatp_ppn;
  logic [9:0] num_pages,nxt;
  logic[63:0] gva,GVA_3,GVA_2,GVA_1,GVA_0,GVA_3_VPN_3,GVA_3_VPN_2,GVA_3_VPN_1,GVA_3_VPN_0,
  GVA_2_VPN_3,GVA_2_VPN_2,GVA_2_VPN_1,GVA_2_VPN_0,
  GVA_1_VPN_3,GVA_1_VPN_2,GVA_1_VPN_1,GVA_1_VPN_0,
  GVA_0_VPN_3,GVA_0_VPN_2,GVA_0_VPN_1,GVA_0_VPN_0,
  G3_PTE_ADDR_3,G3_PTE_ADDR_2,G3_PTE_ADDR_1,G3_PTE_ADDR_0,
  G2_PTE_ADDR_3,G2_PTE_ADDR_2,G2_PTE_ADDR_1,G2_PTE_ADDR_0,
  G1_PTE_ADDR_3,G1_PTE_ADDR_2,G1_PTE_ADDR_1,G1_PTE_ADDR_0,
  G0_PTE_ADDR_3,G0_PTE_ADDR_2,G0_PTE_ADDR_1,G0_PTE_ADDR_0,
  G3_PTE_3,G3_PTE_2,G3_PTE_1,G3_PTE_0,
  G2_PTE_3,G2_PTE_2,G2_PTE_1,G2_PTE_0,
  G1_PTE_3,G1_PTE_2,G1_PTE_1,G1_PTE_0,
  G0_PTE_3,G0_PTE_2,G0_PTE_1,G0_PTE_0,
  PA_3,PA_2,PA_1,PA_0,
  PTE_3,PTE_2,PTE_1,PTE_0,
  GPA_PTE_ADDR_3,GPA_PTE_ADDR_2,GPA_PTE_ADDR_1,GPA_PTE_ADDR_0,
  GVA_DEAD,GVA_VPN_DEAD,
  G00_PTE_ADDR_3,G00_PTE_ADDR_2,G00_PTE_ADDR_1,G00_PTE_ADDR_0,
  G00_PTE_3,G00_PTE_2,G00_PTE_1,G00_PTE_0,
  GVA_00_VPN_3,GVA_00_VPN_2,GVA_00_VPN_1,GVA_00_VPN_0,
  PTE_00,PA_00,
  GVA_00,GVA_VPN_00,SPA,
  VPN_3,VPN_2,VPN_1,VPN_0,VPN_OFFSET;
  
  logic[63:0] GVA_VPN_3,GVA_VPN_2,GVA_VPN_1,GVA_VPN_0;
   
  logic[39:0] GVA_3_OFFSET,GVA_2_OFFSET,GVA_1_OFFSET,GVA_0_OFFSET,GVA_00_OFFSET;
  logic[63:0] PTE_ADDR_3,PTE_ADDR_2,PTE_ADDR_1,PTE_ADDR_0,PA,PTE;
  logic[11:0] GVA_VPN_OFFSET;
  
  `uvm_object_utils(riscv_mmu_gen)
  
  function new (string name = "");
    super.new(name);
  endfunction

  function void mmu_gen(ref string instr_st[$],riscv_instr_gen_config cfg);
    enable_g_load_page_fault = cfg.enable_g_load_page_fault;
    enable_g_store_page_fault = enable_g_store_page_fault;
    enable_g_inst_access_page_fault = enable_g_inst_access_page_fault;
    stage_2_g_fault = cfg.stage_2_g_fault;
    enable_load_page_fault = cfg.enable_load_page_fault;
    enable_store_page_fault = cfg.enable_store_page_fault;
    enable_inst_access_page_fault = cfg.enable_inst_access_page_fault;
    stage_1_fault = cfg.stage_1_fault;
    num_g_load_page_fault = cfg.num_g_load_page_fault;
    num_g_store_page_fault = cfg.num_g_store_page_fault;
    num_g_inst_access_page_fault = cfg.num_g_inst_access_page_fault;

    en_hv_inst = cfg.en_hv_inst;
    is_sup = cfg.is_sup ;
    is_user = cfg.is_user;
    inst_trans = cfg.inst_trans;
    data_trans = cfg.data_trans;
    is_virtualization_on = cfg.is_virtualization_on;
    hgatp_m = cfg.hgatp_m[0];   
    vsatp_m = cfg.vsatp_m[0];
    satp_m =  cfg.satp_m[0]; 
    // Setting *atp, Todo: pass inline argument
    `uvm_info(get_full_name(), $sformatf(
                "out satp value is - %016h", cfg.satp), UVM_NONE)
    satp =  {satp_m,$unsigned(cfg.satp[59:0])};
    vsatp = {vsatp_m,cfg.vsatp[59:0]};
    hgatp = {hgatp_m,cfg.hgatp[59:0]};
    
    satp_ppn = satp[43:0];
    satp_ppn = (satp_ppn <<2)>>2; //vsatp_ppn[43:42] = 'h0
    vsatp_ppn = vsatp[43:0];
    vsatp_ppn = (vsatp_ppn <<2)>>2; //vsatp_ppn[43:42] = 'h0
    hgatp_ppn = (hgatp[43:0]>>2)<<2;
    rd_reg = riscv_reg_t'($random());
    //rd = $cast(rd,rd_reg.name().tolower());
    rd = riscv_reg_t'(rd_reg.name().tolower());
    // Gen_fault logic
    enable_g_load_page_fault=0;
    enable_load_page_fault=1;
    enable_g_store_page_fault=0;
    enable_g_inst_access_page_fault=1;
    stage_2_g_fault = enable_g_load_page_fault | enable_g_store_page_fault | enable_g_inst_access_page_fault;
    stage_1_fault = enable_load_page_fault | enable_store_page_fault | enable_inst_access_page_fault;
    stage_1_fault=1;
    //str.push_back($sformatf("pmp_perm_setup_tor:\n"));
    //str.push_back($sformatf($sformatf("\t li %0s, 0xF\n",rd.name()));
    //str.push_back($sformatf($sformatf("\t csrw pmpcfg0, %0s \n",rd.name())));
    //str.push_back($sformatf($sformatf("\t li %0s, 0xEFFFFFFFFF \n",rd.name())));
    //str.push_back($sformatf($sformatf("\t csrw pmpaddr0, %0s \n",rd.name())));
	
    if(is_sup & is_user)
      $fatal("SUP and USER both can't be enabled at same time, look for is_sup and is_user signals");
    if(inst_trans & data_trans)
      $fatal("Address translation and Data translation both can't be enabled at same time, look for inst_trans and data_trans signals");
    
    if(satp[(9*(init_page_size))+:9]==0)begin
      $fatal("ERROR : satp_ppn[%0d:%0d] can't be 0 for %0s page translation, please provide value >> 0,satp_ppn = %0b",(9*(init_page_size+1)),(9*init_page_size),init_page_size,satp[(9*(init_page_size+1))+:9]);
    end
    
    
    if(vsatp_m==SV39M)
      assert(vsatp[36:27]==0);
    
    if(hgatp_m==SV39M)
      assert(hgatp[36:27]==0);
    
    if((vsatp_m!=SV48M & satp_m!=SV48M) && (init_page_size==P512GB))
      $fatal("Can Generate 512gb page in SV39M is less satp mode");
    
    instr_st.push_back($sformatf("\n\n#define PC_GVA 0x%0h",`PC_GVA));
    instr_st.push_back($sformatf("#define DATA_GVA 0x%0h\n\n",`DATA_GVA));
    pmp_setup(instr_st);
    mstatus_setup(instr_st);
    pte_calculation(`PC_GVA,instr_st);
    inst_trans = 0;
    data_trans = 1;
    pte_calculation(`DATA_GVA,instr_st);
    instr_st.push_back($sformatf("atp_setup:"));

    if(is_virtualization_on || en_hv_inst)begin
    	if(vsatp[(9*(init_page_size))+:9]==0)begin
      		$fatal("ERROR : vsatp_ppn[%0d:%0d] can't be 0 for %0s page translation, please provide value >> 0,vsatp_ppn = %0b",(9*(init_page_size+1)),(9*init_page_size),init_page_size,vsatp[(9*(init_page_size+1))+:9]);
    	end
    	if(hgatp[(9*(guest_page_size))+:9]==0)begin
    		$fatal("ERROR : hgatp[%0d:%0d] can't be 0 for %0s page translation, please provide value >> 0,hgatp_ppn = %0b",(9*(guest_page_size+1))+12,(9*guest_page_size)+12,guest_page_size,hgatp[(9*(guest_page_size+1))+12+:9]);
    	end
    instr_st.push_back($sformatf("li x10, 0x%0h",vsatp));
    instr_st.push_back($sformatf("li x11, 0x%0h",hgatp));
    instr_st.push_back($sformatf("csrw vsatp,x10")); 
    instr_st.push_back($sformatf("csrw hgatp,x11"));
    end
    if(satp_m!=BAREM || !en_hv_inst)begin
	instr_st.push_back($sformatf("li x9, 0x%0h",satp));
	instr_st.push_back($sformatf("csrw satp,x9")); 
    end
    /*instr_st.push_back($sformatf("la x10, main"));
    instr_st.push_back($sformatf("csrw mepc,x10"));
    instr_st.push_back($sformatf("mret"));
    instr_st.push_back($sformatf("main:	\
    		\n\tli x10, DATA_GVA	\
    	        \n\tli x20, 0xDEADDEAD	\
        	\n\tli x21, 0xFADE	\
             	\n\tsd x20,(x10)	\
             	\n\tsd x20,8(x10)	\
		\n\tsh x21,8(x10)	\
		\n\tld x15,8(x10)		"));
*/
    if(en_hv_inst)begin
    	instr_st.push_back($sformatf("\n\thsv.d x20,(x10)	\
             \n\thlvx.wu x21,(x10)	\
             \n\tli x25,1<<48		\
			 \n\txor x10,x10,x25	\
			 \n\thlvx.wu x15,(x10)"));
    end
  //return string'(instr_st);
  endfunction

    /*if(stage_2_g_fault)begin
      gen_guest_page_fault();
    end
    if(stage_1_fault)begin
      gen_page_fault();
    end*/

    function void pmp_setup(ref string instr_st[$]);
      instr_st.push_back($sformatf("pmp_setup:"));
      instr_st.push_back($sformatf("csrwi pmpcfg0,0xf"));
      instr_st.push_back($sformatf("li x5,-1"));
      instr_st.push_back($sformatf("csrw pmpaddr0,x5"));
  endfunction
    
  function void mstatus_setup(ref string instr_st[$]);
    if(en_hv_inst)begin
      	instr_st.push_back($sformatf("mstatus_setup:"));
      instr_st.push_back($sformatf("\tli x16, 0x80001EE00"));
      instr_st.push_back($sformatf("\tcsrw 0x300, x16 # MSTATUS"));
      instr_st.push_back($sformatf("\tcsrs mstatus,x30	// setting MPP=01(sup)"));
      instr_st.push_back($sformatf("\tli x16,0x200000180"));
      instr_st.push_back($sformatf("\tcsrw hstatus,x16"));
    end
    else begin
    instr_st.push_back($sformatf("mstatus_setup:"));  
    instr_st.push_back($sformatf("\tli x16, 0x80005EE00"));  
    instr_st.push_back($sformatf("\tcsrw 0x300, x16 # MSTATUS"));
    end
    if(is_sup)begin
      instr_st.push_back($sformatf("\tli x30,0x%0h",'b11<<11));
      instr_st.push_back($sformatf("\tcsrc mstatus,x30",));
      instr_st.push_back($sformatf("\tli x30,0x%0h",'b01<<11));
      instr_st.push_back($sformatf("\tcsrs mstatus,x30	// setting MPP=01(sup)"));
    end
    if(is_user)begin
      instr_st.push_back($sformatf("\tli x30,0x%0h",'b11<<11));
      instr_st.push_back($sformatf("\tcsrc mstatus,x30	// setting MPP=00(user)"));

    end
    
    if(is_virtualization_on)begin
    	v_mode_on = (is_virtualization_on<<39);
      instr_st.push_back($sformatf("\tli x30,0x%0h",v_mode_on));
      instr_st.push_back($sformatf("\tcsrs mstatus,x30 	// setting MPRV = 1\n"));
    end
    else begin
      v_mode_on = 'b1<<39;
      instr_st.push_back($sformatf("\tli x30,0x%0h",v_mode_on));
      instr_st.push_back($sformatf("\tcsrc mstatus,x30 	// setting MPRV = 0\n"));
    end
  endfunction
    
  function void pte_calculation(input[63:0] input_gva, ref string instr_st[$]);
    
      
    set_size = 48;
    gva = input_gva;
    GVA_VPN_3 = gva[47:39]; 
    GVA_VPN_2 = gva[38:30]; 
    GVA_VPN_1 = gva[29:21]; 
    GVA_VPN_0 = gva[20:12];
    GVA_VPN_OFFSET = gva[11:0];
    if(init_page_size==P4KB)
      GVA_3_OFFSET = GVA_3[11:0];
    else if(init_page_size==P2MB)
      GVA_3_OFFSET = GVA_3[20:0];
    else if(init_page_size==P1GB)
      GVA_3_OFFSET = GVA_3[29:0];
    else if(init_page_size==P512GB)
      GVA_3_OFFSET = GVA_3[38:0];

    if(vsatp_m!=BAREM)begin
    instr_st.push_back($sformatf("// VSATP(Virtual) MODE = %0s, HGATP(Guest) mode : %0s, Virtual Page Size = %0s, Guest Page Size = %0s ",vsatp_m,hgatp_m, init_page_size, guest_page_size));

    casez(vsatp_m) 
      BAREM: instr_st.push_back($sformatf("// VSATP in BAREM mode, No translation Available"));
      SV48M:begin
		 
	// Guest Physical Address calculation for level 2 translation
        GPA_PTE_ADDR_3 = (vsatp_ppn << 12) + (GVA_VPN_3 << 'h3);
        
        GPA_PTE_ADDR_3 = {6'b0,GPA_PTE_ADDR_3[49:0]};
        GVA_3 = GPA_PTE_ADDR_3[49:0];
        GVA_3_VPN_3 = GVA_3[49:39];
        GVA_3_VPN_2 = GVA_3[38:30];
        GVA_3_VPN_1 = GVA_3[29:21];
        GVA_3_VPN_0 = GVA_3[20:12];
        GVA_3_OFFSET = GVA_3[11:0];
        instr_st.push_back($sformatf("// Vitual mode - SV48M  //"));
        casez(hgatp_m)
          	BAREM:begin
              instr_st.push_back($sformatf("// HGATP in BAREM mode, No translation Available"));
              `V_PTE_G_BAREM(3,init_page_size,vsatp_m,inst_trans,0)
              `V_PTE_G_BAREM(2,init_page_size,vsatp_m,inst_trans,3)
              `V_PTE_G_BAREM(1,init_page_size,vsatp_m,inst_trans,2)
              `V_PTE_G_BAREM(0,init_page_size,vsatp_m,inst_trans,1)
            end
            SV48M:begin
              instr_st.push_back($sformatf("// Guest mode - SV48M  //"));

        		hgatp_ppn = hgatp_ppn & 'hfff_ffff_fffc;
        		g_set_size = 30;
              	
				GVA_3 = GPA_PTE_ADDR_3;

               `GVAX_VPNX__CALC(3,guest_page_size,hgatp_m)
              	// Guest level 3 PTE 3 calculation
               `GX_PTE_3_cal(3,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,2)
               `GX_PTE_2_cal(3,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,2)
               `GX_PTE_1_cal(3,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,2)
               `GX_PTE_0_cal(3,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,2)
               
              `GVAX_VPNX__CALC(2,guest_page_size,hgatp_m)
               `GX_PTE_3_cal(2,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
               `GX_PTE_2_cal(2,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
               `GX_PTE_1_cal(2,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
               `GX_PTE_0_cal(2,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
              
              `GVAX_VPNX__CALC(1,guest_page_size,hgatp_m)
               `GX_PTE_3_cal(1,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)
               `GX_PTE_2_cal(1,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)
               `GX_PTE_1_cal(1,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)
               `GX_PTE_0_cal(1,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)

              `GVAX_VPNX__CALC(0,guest_page_size,hgatp_m)
               `GX_PTE_3_cal(0,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)
               `GX_PTE_2_cal(0,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)
               `GX_PTE_1_cal(0,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)
               `GX_PTE_0_cal(0,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)
              
              `GVAX_VPNX__CALC(00,guest_page_size,hgatp_m)
               `G00_PTE_3_cal(00,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
               `G00_PTE_2_cal(00,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
               `G00_PTE_1_cal(00,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
               `G00_PTE_0_cal(00,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,inst_trans,tmp)

                            	GPA_PTE_ADDR_3 = GVA_3;
              					GPA_PTE_ADDR_2 = GVA_2;
              					GPA_PTE_ADDR_1 = GVA_1;
              					GPA_PTE_ADDR_0 = GVA_0;


            end
      		SV39M:begin
              instr_st.push_back($sformatf("// Guest mode - SV39M  //"));

        		g_set_size = 30;
        		hgatp_ppn = hgatp_ppn & 'h1ff_ffff_fffc;

              	GPA_PTE_ADDR_3 = (vsatp_ppn << 12) + (GVA_VPN_3 << 'h3);

				GVA_3 = GPA_PTE_ADDR_3;
               `GVAX_VPNX__CALC(3,guest_page_size,hgatp_m)

              	// Guest level 3 PTE 3 calculation
               `GX_PTE_2_cal(3,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,2)
               `GX_PTE_1_cal(3,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,2)
               `GX_PTE_0_cal(3,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,2)
              
               //PA_3 = ((G3_PTE_3>>10)<<12) + GVA_3_OFFSET;
              `GVAX_VPNX__CALC(2,guest_page_size,hgatp_m)
               `GX_PTE_2_cal(2,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
               `GX_PTE_1_cal(2,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
               `GX_PTE_0_cal(2,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
                            
              `GVAX_VPNX__CALC(1,guest_page_size,hgatp_m)
               `GX_PTE_2_cal(1,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)
               `GX_PTE_1_cal(1,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)
               `GX_PTE_0_cal(1,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)
                            
              `GVAX_VPNX__CALC(0,guest_page_size,hgatp_m)
               `GX_PTE_2_cal(0,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)
               `GX_PTE_1_cal(0,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)
               `GX_PTE_0_cal(0,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)
              
                `GVAX_VPNX__CALC(00,guest_page_size,hgatp_m)
              	`G00_PTE_2_cal(00,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
              	`G00_PTE_1_cal(00,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
              	`G00_PTE_0_cal(00,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,inst_trans,tmp)

                            	GPA_PTE_ADDR_3 = GVA_3;
              					GPA_PTE_ADDR_2 = GVA_2;
              					GPA_PTE_ADDR_1 = GVA_1;
            end
        endcase
        end
 
		SV39M:begin        
			// Guest Physical Address calculation for level 2 translation
            instr_st.push_back($sformatf("// Vitual mode - SV39M  //"));

          	GPA_PTE_ADDR_2 = (vsatp_ppn << 12) + (GVA_VPN_2 << 'h3);
          	GPA_PTE_ADDR_2 = {9'b0,GPA_PTE_ADDR_2[40:0]};

        	GVA_2 = GPA_PTE_ADDR_2;
        	GVA_2_VPN_3 = GVA_2[49:39]; 
        	GVA_2_VPN_2 = GVA_2[38:30]; 
        	GVA_2_VPN_1 = GVA_2[29:21]; 
        	GVA_2_VPN_0 = GVA_2[20:12];
           	GVA_2_OFFSET = GVA_2[11:0];

        	casez(hgatp_m)
              BAREM: begin
                instr_st.push_back($sformatf("// HGATP in BAREM mode, No translation Available"));
              //`V_PTE_G_BAREM(3,init_page_size,vsatp_m,inst_trans,0)
                `V_PTE_G_BAREM(2,init_page_size,vsatp_m,inst_trans,0)
                `V_PTE_G_BAREM(1,init_page_size,vsatp_m,inst_trans,2)
                `V_PTE_G_BAREM(0,init_page_size,vsatp_m,inst_trans,1)
              end
          		SV48M:begin
                  instr_st.push_back($sformatf("// Guest mode - SV48M  //"));

        			g_set_size = 30; 
                  	hgatp_ppn = hgatp_ppn & 'hfff_ffff_fffc;

               		`GX_PTE_3_cal(2,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
               		`GX_PTE_2_cal(2,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
               		`GX_PTE_1_cal(2,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
               		`GX_PTE_0_cal(2,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
                                    

                    `GVAX_VPNX__CALC(1,guest_page_size,hgatp_m)
               		`GX_PTE_3_cal(1,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)
               		`GX_PTE_2_cal(1,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)
               		`GX_PTE_1_cal(1,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)
               		`GX_PTE_0_cal(1,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)
                  
                  `GVAX_VPNX__CALC(0,guest_page_size,hgatp_m)
               		`GX_PTE_3_cal(0,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)
               		`GX_PTE_2_cal(0,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)
               		`GX_PTE_1_cal(0,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)
                  	`GX_PTE_0_cal(0,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)

                  `GVAX_VPNX__CALC(00,guest_page_size,hgatp_m)
                    `G00_PTE_3_cal(00,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
              		`G00_PTE_2_cal(00,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
              		`G00_PTE_1_cal(00,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
                  	`G00_PTE_0_cal(00,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,inst_trans,tmp)
                                
                  				GPA_PTE_ADDR_3 = GVA_3;
              					GPA_PTE_ADDR_2 = GVA_2;
              					GPA_PTE_ADDR_1 = GVA_1;
              					GPA_PTE_ADDR_0 = GVA_0;
                
            	end
      			SV39M:begin
                  instr_st.push_back($sformatf("// Guest mode - SV39M  //"));
					GVA_2 = GPA_PTE_ADDR_2;
                  `GVAX_VPNX__CALC(2,guest_page_size,hgatp_m)
                  
               		//`GX_PTE_3_cal(2,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
               		`GX_PTE_2_cal(2,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
               		`GX_PTE_1_cal(2,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
               		`GX_PTE_0_cal(2,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,1)
                	//GVA_1_VPN_3 = GVA_1[49:39]; 
                  `GVAX_VPNX__CALC(1,guest_page_size,hgatp_m)

               		//`GX_PTE_3_cal(1,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
               		`GX_PTE_2_cal(1,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)
               		`GX_PTE_1_cal(1,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)
               		`GX_PTE_0_cal(1,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,0)
                  
                  
              		//GVA_0_VPN_3 = GVA_0[49:39]; 
                  `GVAX_VPNX__CALC(0,guest_page_size,hgatp_m)

               		//`GX_PTE_3_cal(0,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
               		`GX_PTE_2_cal(0,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)
               		`GX_PTE_1_cal(0,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)
                  	`GX_PTE_0_cal(0,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,00)
                  	instr_st.push_back($sformatf("// SV39M : SV39M-G mode : GPA_3 = %0h,vsatp_ppm = %0h, hgatp_ppn = %0h",GPA_3, vsatp_ppn, hgatp_ppn));

                  `GVAX_VPNX__CALC(00,guest_page_size,hgatp_m)

                   //`G00_PTE_3_cal(00,3,hgatp_ppn,guest_page_size,init_page_size)
              	   `G00_PTE_2_cal(00,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
              	   `G00_PTE_1_cal(00,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
                   `G00_PTE_0_cal(00,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,inst_trans,tmp)
                  
                                GPA_PTE_ADDR_3 = GVA_3;
              					GPA_PTE_ADDR_2 = GVA_2;
              					GPA_PTE_ADDR_1 = GVA_1;
              					GPA_PTE_ADDR_0 = GVA_0;

            	end
        endcase
	  end

    endcase
    end
    else if(satp_m != BAREM)begin
      	set_size = 48;
    	gva = input_gva;
      	VPN_3 = gva[47:39]; 
    	VPN_2 = gva[38:30]; 
    	VPN_1 = gva[29:21]; 
    	VPN_0 = gva[20:12];
    	VPN_OFFSET = gva[11:0];
      	satp_ppn = satp[43:0];
    	casez(satp_m)
      		BAREM: instr_st.push_back($sformatf("// SATP in BAREM mode, No translation Available"));
      		SV48M:begin
		 		`S_MODE_PTE_cal(pt_entry,sapt_ppn,guest_page_size,init_page_size,satp_m)
        		
              	instr_st.push_back($sformatf("// Vitual mode - SV48M  //"));
        	end
 
	  		SV39M:begin        
				// Guest Physical Address calculation for level 2 translation
            	`S_MODE_PTE_cal(pt_entry,sapt_ppn,guest_page_size,init_page_size,satp_m)

	  end

    endcase
    end
    
    instr_st.push_back($sformatf("/************************************************************************************"));
    instr_st.push_back($sformatf("csrw vsatp, 0x%0h",vsatp));
    instr_st.push_back($sformatf("csrw hgatp, 0x%0h",hgatp));
        
    /*instr_st.push_back($sformatf("PA_3 = 0x%0h",PA_3));
    instr_st.push_back($sformatf("PTE_3 = 0x%0h",PTE_3));
    
    instr_st.push_back($sformatf("PA_2 = 0x%0h",PA_2));
    instr_st.push_back($sformatf("PTE_2 = 0x%0h",PTE_2));
    
    instr_st.push_back($sformatf("PA_1 = 0x%0h",PA_1));
    instr_st.push_back($sformatf("PTE_1 = 0x%0h",PTE_1));
    
    instr_st.push_back($sformatf("PA_0 = 0x%0h",PA_0));
    instr_st.push_back($sformatf("PTE_0 = 0x%0h",PTE_0));*/
     
    //Guest PTE_ADDR and PTE calc
    if(hgatp_m!=BAREM)begin
    instr_st.push_back($sformatf("\n\tG_PTE3 calculation"));

    instr_st.push_back($sformatf("GVA_3 = 0x%0h",GVA_3));
    instr_st.push_back($sformatf("GVA_3_VPN_3 <<3 = 0x%0h",GVA_3_VPN_3 <<3));
    instr_st.push_back($sformatf("GVA_3_VPN_2 <<3 = 0x%0h",GVA_3_VPN_2 <<3));
    instr_st.push_back($sformatf("GVA_3_VPN_1 <<3 = 0x%0h",GVA_3_VPN_1 <<3));
    instr_st.push_back($sformatf("GVA_3_VPN_0 <<3 = 0x%0h",GVA_3_VPN_0 <<3));
    
    instr_st.push_back($sformatf("\nG3_PTE_ADDR_3 = 0x%0h",G3_PTE_ADDR_3));
    instr_st.push_back($sformatf("G3_PTE_3 = 0x%0h",G3_PTE_3));
    
    instr_st.push_back($sformatf("G3_PTE_ADDR_2 = 0x%0h",G3_PTE_ADDR_2));
    instr_st.push_back($sformatf("G3_PTE_2 = 0x%0h",G3_PTE_2));
    
    instr_st.push_back($sformatf("G3_PTE_ADDR_1 = 0x%0h",G3_PTE_ADDR_1));
    instr_st.push_back($sformatf("G3_PTE_1 = 0x%0h",G3_PTE_1));
    
    instr_st.push_back($sformatf("G3_PTE_ADDR_0 = 0x%0h",G3_PTE_ADDR_0));
    instr_st.push_back($sformatf("G3_PTE_0 = 0x%0h",G3_PTE_0));
    
    instr_st.push_back($sformatf("\nPA_3 = 0x%0h",PA_3));
    instr_st.push_back($sformatf("PTE_3 = 0x%0h\n",PTE_3));
    
    
    instr_st.push_back($sformatf("\n\tG_PTE2 calculation"));
    
    instr_st.push_back($sformatf("GVA_2 = 0x%0h",GVA_2));
    instr_st.push_back($sformatf("GVA_2_VPN_3 <<3 = 0x%0h",GVA_2_VPN_3 <<3));
    instr_st.push_back($sformatf("GVA_2_VPN_2 <<3 = 0x%0h",GVA_2_VPN_2 <<3));
    instr_st.push_back($sformatf("GVA_2_VPN_1 <<3 = 0x%0h",GVA_2_VPN_1 <<3));
    instr_st.push_back($sformatf("GVA_2_VPN_0 <<3 = 0x%0h",GVA_2_VPN_0 <<3));
    
    instr_st.push_back($sformatf("\nG2_PTE_ADDR_3 0x%0h",G2_PTE_ADDR_3));
    instr_st.push_back($sformatf("G2_PTE_3 = 0x%0h",G2_PTE_3));
    
    instr_st.push_back($sformatf("G2_PTE_ADDR_2 = 0x%0h",G2_PTE_ADDR_2));
    instr_st.push_back($sformatf("G2_PTE_2 = 0x%0h",G2_PTE_2));

    instr_st.push_back($sformatf("G2_PTE_ADDR_1 = 0x%0h",G2_PTE_ADDR_1));
    instr_st.push_back($sformatf("G2_PTE_1 = 0x%0h",G2_PTE_1));
    
    instr_st.push_back($sformatf("G2_PTE_ADDR_0 = 0x%0h",G2_PTE_ADDR_0));
    instr_st.push_back($sformatf("G2_PTE_0 = 0x%0h",G2_PTE_0));
    
    instr_st.push_back($sformatf("\nPA_2 = 0x%0h",PA_2));
    instr_st.push_back($sformatf("PTE_2 = 0x%0h\n",PTE_2));
    
    instr_st.push_back($sformatf("\n\tG_PTE1 calculation"));
    instr_st.push_back($sformatf("GVA_1 = 0x%0h",GVA_1));
    instr_st.push_back($sformatf("GVA_1_VPN_3 <<3 = 0x%0h",GVA_1_VPN_3 <<3));
    instr_st.push_back($sformatf("GVA_1_VPN_2 <<3 = 0x%0h",GVA_1_VPN_2 <<3));
    instr_st.push_back($sformatf("GVA_1_VPN_1 <<3 = 0x%0h",GVA_1_VPN_1 <<3));
    instr_st.push_back($sformatf("GVA_1_VPN_0 <<3 = 0x%0h",GVA_1_VPN_0 <<3));

    instr_st.push_back($sformatf("\nG1_PTE_ADDR_3 0x%0h",G1_PTE_ADDR_3));
    instr_st.push_back($sformatf("G1_PTE_3 0x%0h",G1_PTE_3));
    
    instr_st.push_back($sformatf("G1_PTE_ADDR_2 = 0x%0h",G1_PTE_ADDR_2));
    instr_st.push_back($sformatf("G1_PTE_2 = 0x%0h",G1_PTE_2));
    
    instr_st.push_back($sformatf("G1_PTE_ADDR_1 = 0x%0h",G1_PTE_ADDR_1));
    instr_st.push_back($sformatf("G1_PTE_1 = 0x%0h",G1_PTE_1));
    
    instr_st.push_back($sformatf("G1_PTE_ADDR_0 = 0x%0h",G1_PTE_ADDR_0));
    instr_st.push_back($sformatf("G1_PTE_0 = 0x%0h",G1_PTE_0));
    
    instr_st.push_back($sformatf("\nPA_1 = 0x%0h",PA_1));
    instr_st.push_back($sformatf("PTE_1 = 0x%0h\n",PTE_1));
    
    instr_st.push_back($sformatf("\n\tG_PTE0 calculation"));
    instr_st.push_back($sformatf("GVA_0 = 0x%0h",GVA_0));
    instr_st.push_back($sformatf("GVA_0_VPN_3 <<3 = 0x%0h",GVA_0_VPN_3 <<3));
    instr_st.push_back($sformatf("GVA_0_VPN_2 <<3 = 0x%0h",GVA_0_VPN_2 <<3));
    instr_st.push_back($sformatf("GVA_0_VPN_1 <<3 = 0x%0h",GVA_0_VPN_1 <<3));
    instr_st.push_back($sformatf("GVA_0_VPN_0 <<3 = 0x%0h",GVA_0_VPN_0 <<3));

    instr_st.push_back($sformatf("\nG0_PTE_ADDR_3 = 0x%0h",G0_PTE_ADDR_3));
    instr_st.push_back($sformatf("G0_PTE_3 = 0x%0h",G0_PTE_3));
    
    instr_st.push_back($sformatf("G0_PTE_ADDR_2 = 0x%0h",G0_PTE_ADDR_2));
    instr_st.push_back($sformatf("G0_PTE_2 = 0x%0h",G0_PTE_2));
    
    instr_st.push_back($sformatf("G0_PTE_ADDR_1 = 0x%0h",G0_PTE_ADDR_1));
    instr_st.push_back($sformatf("G0_PTE_1 = 0x%0h",G0_PTE_1));
    
    instr_st.push_back($sformatf("G0_PTE_ADDR_0 = 0x%0h",G0_PTE_ADDR_0));
    instr_st.push_back($sformatf("G0_PTE_0 = 0x%0h",G0_PTE_0));
    
    instr_st.push_back($sformatf("\nPA_0 = 0x%0h",PA_0));
    instr_st.push_back($sformatf("PTE_0 = 0x%0h\n",PTE_0));
    
    instr_st.push_back($sformatf("GVA_00 = 0x%0h",GVA_00));
    instr_st.push_back($sformatf("GVA_00_VPN_3 <<3 = 0x%0h",GVA_00_VPN_3 <<3));
    instr_st.push_back($sformatf("GVA_00_VPN_2 <<3 = 0x%0h",GVA_00_VPN_2 <<3));
    instr_st.push_back($sformatf("GVA_00_VPN_1 <<3 = 0x%0h",GVA_00_VPN_1 <<3));
    instr_st.push_back($sformatf("GVA_00_VPN_0 <<3 = 0x%0h",GVA_00_VPN_0 <<3));

    instr_st.push_back($sformatf("\nG00_PTE_ADDR_3 = 0x%0h",G00_PTE_ADDR_3));
    instr_st.push_back($sformatf("G00_PTE_3 = 0x%0h",G00_PTE_3));
    
    instr_st.push_back($sformatf("G00_PTE_ADDR_2 = 0x%0h",G00_PTE_ADDR_2));
    instr_st.push_back($sformatf("G00_PTE_2 = 0x%0h",G00_PTE_2));
    
    instr_st.push_back($sformatf("G00_PTE_ADDR_1 = 0x%0h",G00_PTE_ADDR_1));
    instr_st.push_back($sformatf("G00_PTE_1 = 0x%0h",G00_PTE_1));
    
    instr_st.push_back($sformatf("G00_PTE_ADDR_0 = 0x%0h",G00_PTE_ADDR_0));
    instr_st.push_back($sformatf("G00_PTE_0 = 0x%0h",G00_PTE_0));
    
     instr_st.push_back($sformatf("spa = 0x%0h",SPA));
     instr_st.push_back($sformatf("************************************************************************************/"));

    
    // Normal PTE_ADDR and PTE calc      
    //Guest PTE_ADDR and PTE calc
    // Level G3
    if(vsatp_m inside {SV48M,SV39M})begin
      if(vsatp_m == SV48M)begin
        instr_st.push_back($sformatf("li x5, 0x%0h  //G3_PTE_ADDR_3",G3_PTE_ADDR_3));
        instr_st.push_back($sformatf("li x6, 0x%0h	//G3_PTE_3",G3_PTE_3));
        instr_st.push_back($sformatf("sd x6, (x5)"));
      end
      if(guest_page_size != P512GB)begin
        instr_st.push_back($sformatf("li x5, 0x%0h	//G3_PTE_ADDR_2",G3_PTE_ADDR_2));
        instr_st.push_back($sformatf("li x6, 0x%0h	//G3_PTE_2",G3_PTE_2));
      	instr_st.push_back($sformatf("sd x6, (x5)"));
      	if(guest_page_size != P1GB)begin
        	instr_st.push_back($sformatf("li x5, 0x%0h	//G3_PTE_ADDR_1",G3_PTE_ADDR_1));
        	instr_st.push_back($sformatf("li x6, 0x%0h	//G3_PTE_1",G3_PTE_1));
        	instr_st.push_back($sformatf("sd x6, (x5)"));
      		if(guest_page_size != P2MB)begin
        		instr_st.push_back($sformatf("li x5, 0x%0h	//G3_PTE_ADDR_0",G3_PTE_ADDR_0));
        		instr_st.push_back($sformatf("li x6, 0x%0h	//G3_PTE_0",G3_PTE_0));
        		instr_st.push_back($sformatf("sd x6, (x5)\n"));
        	end
        end
      end
      	instr_st.push_back($sformatf("li x5, 0x%0h	//PA_3",PA_3));
      	instr_st.push_back($sformatf("li x6, 0x%0h	//PTE_3",PTE_3));
        instr_st.push_back($sformatf("sd x6, (x5)\n\n"));
    end
      
      // Level G2
      if(guest_page_size inside {P512GB,P1GB,P2MB,P4KB})begin

      if(vsatp_m == SV48M)begin
        instr_st.push_back($sformatf("li x5, 0x%0h	//G2_PTE_ADDR_3",G2_PTE_ADDR_3));
        instr_st.push_back($sformatf("li x6, 0x%0h	//G2_PTE_3",G2_PTE_3));
        instr_st.push_back($sformatf("sd x6, (x5)"));
      end
        if(guest_page_size != P512GB)begin
      instr_st.push_back($sformatf("li x5, 0x%0h	//G2_PTE_ADDR_2",G2_PTE_ADDR_2));
      instr_st.push_back($sformatf("li x6, 0x%0h	//G2_PTE_2",G2_PTE_2));
      instr_st.push_back($sformatf("sd x6, (x5)"));
        if(guest_page_size != P1GB)begin
      instr_st.push_back($sformatf("li x5, 0x%0h	//G2_PTE_ADDR_1",G2_PTE_ADDR_1));
      instr_st.push_back($sformatf("li x6, 0x%0h	//G2_PTE_1",G2_PTE_1));
      instr_st.push_back($sformatf("sd x6, (x5)"));
        if(guest_page_size != P2MB)begin
      instr_st.push_back($sformatf("li x5, 0x%0h	//G2_PTE_ADDR_0",G2_PTE_ADDR_0));
      instr_st.push_back($sformatf("li x6, 0x%0h	//G2_PTE_0",G2_PTE_0));
      instr_st.push_back($sformatf("sd x6, (x5)\n"));
        end
        end
      instr_st.push_back($sformatf("li x5, 0x%0h	//PA_2",PA_2));
      instr_st.push_back($sformatf("li x6, 0x%0h	//PTE_2",PTE_2));
      instr_st.push_back($sformatf("sd x6, (x5)\n\n"));
        end
      end
      
        //level G1
      if(guest_page_size inside {P1GB,P2MB,P4KB})begin
   	  if(vsatp_m == SV48M)begin
        instr_st.push_back($sformatf("li x5, 0x%0h	//G1_PTE_ADDR_3",G1_PTE_ADDR_3));
        instr_st.push_back($sformatf("li x6, 0x%0h	//G1_PTE_3",G1_PTE_3));
        instr_st.push_back($sformatf("sd x6, (x5)"));
      end
    
      instr_st.push_back($sformatf("li x5, 0x%0h	//G1_PTE_ADDR_2",G1_PTE_ADDR_2));
      instr_st.push_back($sformatf("li x6, 0x%0h	//G1_PTE_2",G1_PTE_2));
      instr_st.push_back($sformatf("sd x6, (x5)"));
    
        if(guest_page_size != P1GB)begin
      instr_st.push_back($sformatf("li x5, 0x%0h	//G1_PTE_ADDR_1",G1_PTE_ADDR_1));
      instr_st.push_back($sformatf("li x6, 0x%0h	//G1_PTE_1",G1_PTE_1));
      instr_st.push_back($sformatf("sd x6, (x5)"));
        if(guest_page_size != P2MB)begin
      instr_st.push_back($sformatf("li x5, 0x%0h	//G1_PTE_ADDR_0",G1_PTE_ADDR_0));
      instr_st.push_back($sformatf("li x6, 0x%0h	//G1_PTE_0",G1_PTE_0));
      instr_st.push_back($sformatf("sd x6, (x5)\n"));
      	end
      instr_st.push_back($sformatf("li x5, 0x%0h	//PA_1",PA_1));
      instr_st.push_back($sformatf("li x6, 0x%0h	//PTE_1",PTE_1));
      instr_st.push_back($sformatf("sd x6, (x5)\n\n"));
       	end
     end
      
      //level G0
      if(guest_page_size inside {P2MB,P4KB})begin
      if(vsatp_m == SV48M)begin
        instr_st.push_back($sformatf("li x5, 0x%0h	//G0_PTE_ADDR_3",G0_PTE_ADDR_3));
        instr_st.push_back($sformatf("li x6, 0x%0h	//G0_PTE_3",G0_PTE_3));
        instr_st.push_back($sformatf("sd x6, (x5)"));
      end
    
      instr_st.push_back($sformatf("li x5, 0x%0h	//G0_PTE_ADDR_2",G0_PTE_ADDR_2));
      instr_st.push_back($sformatf("li x6, 0x%0h	//G0_PTE_2",G0_PTE_2));
      instr_st.push_back($sformatf("sd x6, (x5)"));
    
      
      instr_st.push_back($sformatf("li x5, 0x%0h	//G0_PTE_ADDR_1",G0_PTE_ADDR_1));
      instr_st.push_back($sformatf("li x6, 0x%0h	//G0_PTE_1",G0_PTE_1));
      instr_st.push_back($sformatf("sd x6, (x5)"));
    
        if(guest_page_size == P4KB)begin
      instr_st.push_back($sformatf("li x5, 0x%0h	//G0_PTE_ADDR_0",G0_PTE_ADDR_0));
      instr_st.push_back($sformatf("li x6, 0x%0h	//G0_PTE_0",G0_PTE_0));
      instr_st.push_back($sformatf("sd x6, (x5)\n"));
    
      instr_st.push_back($sformatf("li x5, 0x%0h	//PA_0",PA_0));
      instr_st.push_back($sformatf("li x6, 0x%0h	//PTE_0",PTE_0));
      instr_st.push_back($sformatf("sd x6, (x5)\n\n"));
        end
      end
      
      //level G00
      if(guest_page_size==P4KB)begin
      if(vsatp_m == SV48M)begin
        instr_st.push_back($sformatf("li x5, 0x%0h	//G00_PTE_ADDR_3",G00_PTE_ADDR_3));
        instr_st.push_back($sformatf("li x6, 0x%0h	//G00_PTE_3",G00_PTE_3));
        instr_st.push_back($sformatf("sd x6, (x5)"));
      end
    
      instr_st.push_back($sformatf("li x5, 0x%0h	//G00_PTE_ADDR_2",G00_PTE_ADDR_2));
      instr_st.push_back($sformatf("li x6, 0x%0h	//G00_PTE_2",G00_PTE_2));
      instr_st.push_back($sformatf("sd x6, (x5)"));
    
      instr_st.push_back($sformatf("li x5, 0x%0h	//G00_PTE_ADDR_1",G00_PTE_ADDR_1));
      instr_st.push_back($sformatf("li x6, 0x%0h	//G00_PTE_1",G00_PTE_1));
      instr_st.push_back($sformatf("sd x6, (x5)"));
    
      instr_st.push_back($sformatf("li x5, 0x%0h	//G00_PTE_ADDR_0",G00_PTE_ADDR_0));
      instr_st.push_back($sformatf("li x6, 0x%0h	//G00_PTE_0",G00_PTE_0));
      instr_st.push_back($sformatf("sd x6, (x5)"));
    
      instr_st.push_back($sformatf("// spa = 0x%0h",SPA));
      instr_st.push_back($sformatf("// csrw vsatp, 0x%0h",vsatp));
      instr_st.push_back($sformatf("// csrw hgatp, 0x%0h",hgatp));
      end
    end
    else begin
      instr_st.push_back($sformatf("\n\tPTE calculation"));

      instr_st.push_back($sformatf("VA_3 = 0x%0h",gva));
      instr_st.push_back($sformatf("VPN_3 << 3 = 0x%0h",VPN_3 <<3));
      instr_st.push_back($sformatf("VPN_2 << 3 = 0x%0h",VPN_2 <<3));
      instr_st.push_back($sformatf("VPN_1 << 3 = 0x%0h",VPN_1 <<3));
      instr_st.push_back($sformatf("VPN_0 << 3 = 0x%0h",VPN_0 <<3));
      
      instr_st.push_back($sformatf("\nPTE_ADDR_3 = 0x%0h",PTE_ADDR_3));
      instr_st.push_back($sformatf("PTE_3 = 0x%0h",PTE_3));
    
      instr_st.push_back($sformatf("PTE_ADDR_2 = 0x%0h",PTE_ADDR_2));
      instr_st.push_back($sformatf("PTE_2 = 0x%0h",PTE_2));
    
      instr_st.push_back($sformatf("PTE_ADDR_1 = 0x%0h",PTE_ADDR_1));
      instr_st.push_back($sformatf("PTE_1 = 0x%0h",PTE_1));
    
      instr_st.push_back($sformatf("PTE_ADDR_0 = 0x%0h",PTE_ADDR_0));
      instr_st.push_back($sformatf("PTE_0 = 0x%0h",PTE_0));
    
      instr_st.push_back($sformatf("\nPA = 0x%0h",PA));
      instr_st.push_back($sformatf("PTE = 0x%0h\n",PTE));
      instr_st.push_back($sformatf("************************************************************************************/"));
      if(satp_m == SV48M)begin
      instr_st.push_back($sformatf("li x5, 0x%0h	//PTE_ADDR_3",PTE_ADDR_3));
      instr_st.push_back($sformatf("li x6, 0x%0h	//PTE_3",PTE_3));
      instr_st.push_back($sformatf("sd x6, (x5)"));
      end
      if(init_page_size < P512GB)begin
      	instr_st.push_back($sformatf("li x5, 0x%0h	//PTE_ADDR_2",PTE_ADDR_2));
      	instr_st.push_back($sformatf("li x6, 0x%0h	//PTE_2",PTE_2));
      	instr_st.push_back($sformatf("sd x6, (x5)"));
              
        if(init_page_size < P1GB)begin
      		instr_st.push_back($sformatf("li x5, 0x%0h	//PTE_ADDR_1",PTE_ADDR_1));
      		instr_st.push_back($sformatf("li x6, 0x%0h	//PTE_1",PTE_1));
      		instr_st.push_back($sformatf("sd x6, (x5)"));
            if(init_page_size < P2MB)begin
      			instr_st.push_back($sformatf("li x5, 0x%0h	//PTE_ADDR_0",PTE_ADDR_0));
      			instr_st.push_back($sformatf("li x6, 0x%0h	//PTE_0",PTE_0));
      			instr_st.push_back($sformatf("sd x6, (x5)"));
            end
        end
      end
    end
    
   			 

      
      endfunction
  
  function void gen_guest_page_fault(ref string instr_st[$]);
	// 512GB fault
    
    instr_st.push_back($sformatf("////BEFORE//// \nli x6, 0x%0h",G3_PTE_0));
    instr_st.push_back($sformatf("li x6, 0x%0h",G2_PTE_0));
    instr_st.push_back($sformatf("li x6, 0x%0h",G1_PTE_0));
    instr_st.push_back($sformatf("li x6, 0x%0h",G0_PTE_0));
    instr_st.push_back($sformatf("li x6, 0x%0h",G00_PTE_0));
    
    case(guest_page_size)
      P512GB:begin
        if(vsatp_m == SV48M)begin
          if(hgatp_m==SV48M)begin
      	    `GX_PTE_3_gen_fault(3,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
    	  end
      	`GX_PTE_3_gen_fault(2,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
      	`GX_PTE_3_gen_fault(1,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
      	`GX_PTE_3_gen_fault(0,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
      	`G00_PTE_3_gen_fault(00,3,hgatp_ppn,guest_page_size,init_page_size,vsa0p_m,hgatp_m)
          
        end
      	if(vsatp_m == SV39M)begin
          if(hgatp_m==SV48M)begin
            `GX_PTE_3_gen_fault(2,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          end
      `GX_PTE_3_gen_fault(1,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
      `GX_PTE_3_gen_fault(0,3,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
      `G00_PTE_3_gen_fault(00,3,hgatp_ppn,guest_page_size,init_page_size,vsa0p_m,hgatp_m)
          
        end
      end
      P1GB:
        begin
        if(vsatp_m == SV48M)begin
          if(hgatp_m==SV48M)begin
            `GX_PTE_2_gen_fault(3,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
    	  end
      		`GX_PTE_2_gen_fault(2,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
      		`GX_PTE_2_gen_fault(1,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
      		`GX_PTE_2_gen_fault(0,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
      		`G00_PTE_2_gen_fault(00,2,hgatp_ppn,guest_page_size,init_page_size,vsa0p_m,hgatp_m)
          
        end

		if(vsatp_m == SV39M)begin
          if(hgatp_m==SV48M)begin
            `GX_PTE_2_gen_fault(2,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          end
           `GX_PTE_2_gen_fault(1,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
           `GX_PTE_2_gen_fault(0,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
           `G00_PTE_2_gen_fault(00,2,hgatp_ppn,guest_page_size,init_page_size,vsa0p_m,hgatp_m)
          
        end
      	if(vsatp_m == SV39M)begin
          if(hgatp_m==SV39M)begin
            `GX_PTE_2_gen_fault(2,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          end
          `GX_PTE_2_gen_fault(1,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `GX_PTE_2_gen_fault(0,2,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `G00_PTE_2_gen_fault(00,2,hgatp_ppn,guest_page_size,init_page_size,vsa0p_m,hgatp_m)
        end
        end
      P2MB:begin
         if(vsatp_m == SV48M)begin
          if(hgatp_m==SV48M)begin
            `GX_PTE_1_gen_fault(3,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
    	  end
           `GX_PTE_1_gen_fault(2,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
           `GX_PTE_1_gen_fault(1,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
           `GX_PTE_1_gen_fault(0,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
           `G00_PTE_1_gen_fault(00,1,hgatp_ppn,guest_page_size,init_page_size,vsa0p_m,hgatp_m)
           
        end

		if(vsatp_m == SV39M)begin
          if(hgatp_m==SV48M)begin
            `GX_PTE_2_gen_fault(2,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          end
          `GX_PTE_1_gen_fault(1,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `GX_PTE_1_gen_fault(0,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `G00_PTE_1_gen_fault(00,1,hgatp_ppn,guest_page_size,init_page_size,vsa0p_m,hgatp_m)
        end
      	if(vsatp_m == SV39M)begin
          if(hgatp_m==SV39M)begin
            `GX_PTE_1_gen_fault(2,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          end
          `GX_PTE_1_gen_fault(1,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `GX_PTE_1_gen_fault(0,1,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `G00_PTE_1_gen_fault(00,1,hgatp_ppn,guest_page_size,init_page_size,vsa0p_m,hgatp_m)
          
        end
      end
      P4KB:begin
        if(vsatp_m == SV48M)begin
          if(hgatp_m==SV48M)begin
            `GX_PTE_0_gen_fault(3,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
    	  end
          `GX_PTE_0_gen_fault(2,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `GX_PTE_0_gen_fault(1,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `GX_PTE_0_gen_fault(0,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `G00_PTE_0_gen_fault(00,0,hgatp_ppn,guest_page_size,init_page_size,vsa0p_m,hgatp_m)
          
        end

		if(vsatp_m == SV39M)begin
          if(hgatp_m==SV48M)begin
            `GX_PTE_0_gen_fault(3,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          end
          `GX_PTE_0_gen_fault(2,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `GX_PTE_0_gen_fault(1,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `GX_PTE_0_gen_fault(0,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `G00_PTE_0_gen_fault(00,0,hgatp_ppn,guest_page_size,init_page_size,vsa0p_m,hgatp_m)
          
        end
      	if(vsatp_m == SV39M)begin
          if(hgatp_m==SV39M)begin
            `GX_PTE_0_gen_fault(2,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          end
          `GX_PTE_0_gen_fault(1,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `GX_PTE_0_gen_fault(0,0,hgatp_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)
          `G00_PTE_0_gen_fault(00,0,hgatp_ppn,guest_page_size,init_page_size,vsa0p_m,hgatp_m)
          
        end
      end
    endcase
        
    instr_st.push_back($sformatf("///////AFTER//////// \nli x6, 0x%0h",G3_PTE_0));
    instr_st.push_back($sformatf("li x6, 0x%0h",G2_PTE_0));
    instr_st.push_back($sformatf("li x6, 0x%0h",G1_PTE_0));
    instr_st.push_back($sformatf("li x6, 0x%0h",G0_PTE_0));
    instr_st.push_back($sformatf("li x6, 0x%0h",G00_PTE_0));

   
  endfunction
function void gen_page_fault(ref string instr_st[$]);
  case(init_page_size)
  P512GB:begin
    if(vsatp_m == SV48M)begin
      `PTE_3_gen_fault(3,init_page_size,vsatp_m)
      `PTE_3_gen_fault(2,init_page_size,vsatp_m)
      `PTE_3_gen_fault(1,init_page_size,vsatp_m)
      `PTE_3_gen_fault(0,init_page_size,vsatp_m)
    end
    if(vsatp_m == SV39M)begin
      `PTE_3_gen_fault(2,init_page_size,vsatp_m)
      `PTE_3_gen_fault(1,init_page_size,vsatp_m)
      `PTE_3_gen_fault(0,init_page_size,vsatp_m)
    end
  end

      P1GB:begin
        if(vsatp_m == SV48M)begin
          `PTE_2_gen_fault(3,init_page_size,vsatp_m)
          `PTE_2_gen_fault(2,init_page_size,vsatp_m)
          `PTE_2_gen_fault(1,init_page_size,vsatp_m)
          `PTE_2_gen_fault(0,init_page_size,vsatp_m)
        end
        if(vsatp_m == SV39M)begin
          `PTE_2_gen_fault(2,init_page_size,vsatp_m)
          `PTE_2_gen_fault(1,init_page_size,vsatp_m)
          `PTE_2_gen_fault(0,init_page_size,vsatp_m)
        end
      end
  P2MB:begin
    if(vsatp_m == SV48M)begin
      `PTE_1_gen_fault(3,init_page_size,vsatp_m)
      `PTE_1_gen_fault(2,init_page_size,vsatp_m)
      `PTE_1_gen_fault(1,init_page_size,vsatp_m)
      `PTE_1_gen_fault(0,init_page_size,vsatp_m)
    end
    if(vsatp_m == SV39M)begin
      `PTE_1_gen_fault(2,init_page_size,vsatp_m)
      `PTE_1_gen_fault(1,init_page_size,vsatp_m)
      `PTE_1_gen_fault(0,init_page_size,vsatp_m)
    end
  end
  P4KB:begin
    if(vsatp_m == SV48M)begin
      `PTE_0_gen_fault(3,init_page_size,vsatp_m)
      `PTE_0_gen_fault(2,init_page_size,vsatp_m)
      `PTE_0_gen_fault(1,init_page_size,vsatp_m)
      `PTE_0_gen_fault(0,init_page_size,vsatp_m)
        end
        if(vsatp_m == SV39M)begin
          `PTE_0_gen_fault(2,init_page_size,vsatp_m)
          `PTE_0_gen_fault(1,init_page_size,vsatp_m)
          `PTE_0_gen_fault(0,init_page_size,vsatp_m)
        end
      end
    endcase
  instr_st.push_back($sformatf("///////AFTER//////// \nli x6, 0x%0h",PTE_0));
  instr_st.push_back($sformatf("li x6, 0x%0h",PTE_3));
  instr_st.push_back($sformatf("li x7, 0x%0h",PA_3));
  instr_st.push_back($sformatf("sd x6, (x7)"));
  instr_st.push_back($sformatf("li x6, 0x%0h",PTE_2));
  instr_st.push_back($sformatf("li x7, 0x%0h",PA_2));
  instr_st.push_back($sformatf("sd x6, (x7)"));
  instr_st.push_back($sformatf("li x6, 0x%0h",PTE_1));
  instr_st.push_back($sformatf("li x7, 0x%0h",PA_1));
  instr_st.push_back($sformatf("sd x6, (x7)"));
  instr_st.push_back($sformatf("li x6, 0x%0h",PTE_0));
  instr_st.push_back($sformatf("li x7, 0x%0h",PA_0));
  instr_st.push_back($sformatf("sd x6, (x7)"));
  endfunction

endclass
