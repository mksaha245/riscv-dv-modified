
// Code your testbench here
// or browse Examples

/*typedef enum bit [4:0] {
    ZERO = 5'b00000,
    RA, SP, GP, TP, T0, T1, T2, S0, S1, A0, A1, A2, A3, A4, A5, A6, A7,
    S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, T3, T4, T5, T6
  } riscv_reg_t;
*/
typedef enum bit [3:0] {
  	BAREM ='h0,
    SV32M ='h7,
  	SV39M ='h8,
  	SV48M ='h9,
  	SV57M ='ha
}atp_mode;

typedef enum bit [3:0] {
  	P4KB,
  	P2MB,
    P1GB,
  	P512GB
}page_size_t;

/*typedef enum bit [2:0] {
	BAREM ='h0,
  	SV39M ='h8,
  	SV48M ='h9,
  	SV57M ='ha
}hgatp_mode;
*/

class riscv_mmu_gen;
  `define PC_GVA 'h0
  `define DATA_GVA 'h8229989199a
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
  //vsatp_mode = vsatp[39:60]
  //hgatp_mode = hgatp[63:60]
  riscv_reg_t rd,rd_reg;
  string str[$];
  bit[63:0] satp,vsatp,hgatp,v_mode_on=0;
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
  function void mmu_gen(string instr_st[$]);
    instr_st.push_back($sformatf("I'm inside mmu gen"));
  //initial begin
    en_hv_inst=0;
    is_sup = 1;
    is_user = 0;
    inst_trans = 1;
    data_trans = 0;
    is_virtualization_on=0;
	satp = 'h0000100267070711;
	vsatp = 'h0000100199999911;
    hgatp = 'h00001001010810a4;
    satp[63:60] = satp_m;
    vsatp[63:60] = vsatp_m;
    hgatp[63:60] = hgatp_m;
    
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
    str.push_back("pmp_perm_setup_tor:\n");
    str.push_back($sformatf("\t li %0s, 0xF\n",rd.name()));
    str.push_back($sformatf("\t csrw pmpcfg0, %0s \n",rd.name()));
    str.push_back($sformatf("\t li %0s, 0xEFFFFFFFFF \n",rd.name()));
    str.push_back($sformatf("\t csrw pmpaddr0, %0s \n",rd.name()));
	
    if(is_sup & is_user)
      $fatal("SUP and USER both can't be enabled at same time, look for is_sup and is_user signals");
    if(inst_trans & data_trans)
      $fatal("Address translation and Data translation both can't be enabled at same time, look for inst_trans and data_trans signals");
    
    /*if(pc_trans & !data_trans)
    	pc_pte_calculation();
    else if(pc_trans & data_trans)
    	pc_pte_calculation();
    else if(!pc_trans & data_trans)
      $fatal("ERROR : Data Translation is possible without Inst Translation, pleae switch on pc_trans variable");*/
	if(satp[(9*(init_page_size))+:9]==0)begin
      $fatal("ERROR : satp_ppn[%0d:%0d] can't be 0 for %0s page translation, please provide value >> 0,satp_ppn = %0b",(9*(init_page_size+1)),(9*init_page_size),init_page_size,satp[(9*(init_page_size+1))+:9]);
    end
    
    if(vsatp[(9*(init_page_size))+:9]==0)begin
      $fatal("ERROR : vsatp_ppn[%0d:%0d] can't be 0 for %0s page translation, please provide value >> 0,vsatp_ppn = %0b",(9*(init_page_size+1)),(9*init_page_size),init_page_size,vsatp[(9*(init_page_size+1))+:9]);
    end
    if(hgatp[(9*(guest_page_size))+:9]==0)begin
      $fatal("ERROR : hgatp[%0d:%0d] can't be 0 for %0s page translation, please provide value >> 0,hgatp_ppn = %0b",(9*(guest_page_size+1))+12,(9*guest_page_size)+12,guest_page_size,hgatp[(9*(guest_page_size+1))+12+:9]);
    end
    
    if(vsatp_m==SV39M)
      assert(vsatp[36:27]==0);
    
    if(hgatp_m==SV39M)
      assert(hgatp[36:27]==0);
    
    if((vsatp_m!=SV48M & satp_m!=SV48M) && (init_page_size==P512GB))
      $fatal("Can Generate 512gb page in SV39M is less satp mode");
    
    $display("\n\n#define PC_GVA 0x%0h",`PC_GVA);
    $display("#define DATA_GVA 0x%0h\n\n",`DATA_GVA);
    pmp_setup();
    mstatus_setup();
    pte_calculation(`PC_GVA);
    inst_trans = 0;
    data_trans = 1;
    pte_calculation(`DATA_GVA);
    		 $display("atp_setup:");
    		 $display("li x9, 0x%0h",satp);
             $display("li x10, 0x%0h",vsatp);
             $display("li x11, 0x%0h",hgatp);
    	     $display("csrw satp,x9"); 
             $display("csrw vsatp,x10"); 
    		 $display("csrw hgatp,x11");
             $display("la x10, main");
             $display("csrw mepc,x10");
             $display("mret");
    $display("main:					\
    		 \n\tli x10, DATA_GVA	\
             \n\tli x20, 0xDEADDEAD	\
             \n\tli x21, 0xFADE		\
             \n\tsd x20,(x10)		\
             \n\tsd x20,8(x10)		\
			 \n\tsh x21,8(x10)		\
			 \n\tld x15,8(x10)		");
    if(en_hv_inst)begin
    	$display("\n\thsv.d x20,(x10)	\
             \n\thlvx.wu x21,(x10)	\
             \n\tli x25,1<<48		\
			 \n\txor x10,x10,x25	\
			 \n\thlvx.wu x15,(x10)");
    end
  endfunction
    /*if(stage_2_g_fault)begin
      gen_guest_page_fault();
    end
    if(stage_1_fault)begin
      gen_page_fault();
    end*/

    function void pmp_setup();
      $display("pmp_setup:");
      $display("csrwi pmpcfg0,0xf");
      $display("li x5,-1");
      $display("csrw pmpaddr0,x5");
  endfunction
    
  function void mstatus_setup();
    if(en_hv_inst)begin
      	$display("mstatus_setup:");
      $display("\tli x16, 0x80001EE00");
      $display("\tcsrw 0x300, x16 # MSTATUS");
      $display("\tcsrs mstatus,x30	// setting MPP=01(sup)");
      $display("\tli x16,0x200000180");
      $display("\tcsrw hstatus,x16");
    end
    else begin
    $display("mstatus_setup:");  
    $display("\tli x16, 0x80005EE00");  
    $display("\tcsrw 0x300, x16 # MSTATUS");
    end
    if(is_sup)begin
      $display("\tli x30,0x%0h",'b11<<11);
      $display("\tcsrc mstatus,x30",);
      $display("\tli x30,0x%0h",'b01<<11);
      $display("\tcsrs mstatus,x30	// setting MPP=01(sup)");
    end
    if(is_user)begin
      $display("\tli x30,0x%0h",'b11<<11);
      $display("\tcsrc mstatus,x30	// setting MPP=00(user)");

    end
    
    if(is_virtualization_on)begin
    	v_mode_on = (is_virtualization_on<<39);
      $display("\tli x30,0x%0h",v_mode_on);
      $display("\tcsrs mstatus,x30 	// setting MPRV = 1\n");
    end
    else begin
      v_mode_on = 'b1<<39;
      $display("\tli x30,0x%0h",v_mode_on);
      $display("\tcsrc mstatus,x30 	// setting MPRV = 0\n");
    end
  endfunction
    
  function void pte_calculation(input[63:0] input_gva);
    
      
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
    $display("// VSATP(Virtual) MODE = %0s, HGATP(Guest) mode : %0s, Virtual Page Size = %0s, Guest Page Size = %0s ",vsatp_m,hgatp_m, init_page_size, guest_page_size);

    casez(vsatp_m) 
      BAREM: $display("// VSATP in BAREM mode, No translation Available");
      SV48M:begin
		 
        //vsatp_ppn = vsatp_ppn & 'h3ffff_ffff_ffff;
		// Guest Physical Address calculation for level 2 translation
        GPA_PTE_ADDR_3 = (vsatp_ppn << 12) + (GVA_VPN_3 << 'h3);
        
        GPA_PTE_ADDR_3 = {6'b0,GPA_PTE_ADDR_3[49:0]};
        GVA_3 = GPA_PTE_ADDR_3[49:0];
        GVA_3_VPN_3 = GVA_3[49:39];
        GVA_3_VPN_2 = GVA_3[38:30];
        GVA_3_VPN_1 = GVA_3[29:21];
        GVA_3_VPN_0 = GVA_3[20:12];
        GVA_3_OFFSET = GVA_3[11:0];
        $display("// Vitual mode - SV48M  //");
        casez(hgatp_m)
          	BAREM:begin
              $display("// HGATP in BAREM mode, No translation Available");
              `V_PTE_G_BAREM(3,init_page_size,vsatp_m,inst_trans,0)
              `V_PTE_G_BAREM(2,init_page_size,vsatp_m,inst_trans,3)
              `V_PTE_G_BAREM(1,init_page_size,vsatp_m,inst_trans,2)
              `V_PTE_G_BAREM(0,init_page_size,vsatp_m,inst_trans,1)
            end
            SV48M:begin
              $display("// Guest mode - SV48M  //");

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
              $display("// Guest mode - SV39M  //");

        		g_set_size = 30;
        		hgatp_ppn = hgatp_ppn & 'h1ff_ffff_fffc;

              	GPA_PTE_ADDR_3 = (vsatp_ppn << 12) + (GVA_VPN_3 << 'h3);

				GVA_3 = GPA_PTE_ADDR_3;
               `GVAX_VPNX__CALC(3,guest_page_size,hgatp_m)

              	// Guest level 3 PTE 3 calculation
               //`GX_PTE_3_cal(3,3,hgatp_ppn,guest_page_size,init_page_size)
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
            $display("// Vitual mode - SV39M  //");

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
                $display("// HGATP in BAREM mode, No translation Available");
              //`V_PTE_G_BAREM(3,init_page_size,vsatp_m,inst_trans,0)
                `V_PTE_G_BAREM(2,init_page_size,vsatp_m,inst_trans,0)
                `V_PTE_G_BAREM(1,init_page_size,vsatp_m,inst_trans,2)
                `V_PTE_G_BAREM(0,init_page_size,vsatp_m,inst_trans,1)
              end
          		SV48M:begin
                  $display("// Guest mode - SV48M  //");

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
                  $display("// Guest mode - SV39M  //");
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
                  	$display("// SV39M : SV39M-G mode : GPA_3 = %0h,vsatp_ppm = %0h, hgatp_ppn = %0h",GPA_3, vsatp_ppn, hgatp_ppn);

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
      		BAREM: $display("// SATP in BAREM mode, No translation Available");
      		SV48M:begin
		 		`S_MODE_PTE_cal(pt_entry,sapt_ppn,guest_page_size,init_page_size,satp_m)
        		
              	$display("// Vitual mode - SV48M  //");
        	end
 
	  		SV39M:begin        
				// Guest Physical Address calculation for level 2 translation
            	`S_MODE_PTE_cal(pt_entry,sapt_ppn,guest_page_size,init_page_size,satp_m)

	  end

    endcase
    end
    
    $display("/************************************************************************************");
    $display("csrw vsatp, 0x%0h",vsatp);
    $display("csrw hgatp, 0x%0h",hgatp);
        
    /*$display("PA_3 = 0x%0h",PA_3);
    $display("PTE_3 = 0x%0h",PTE_3);
    
    $display("PA_2 = 0x%0h",PA_2);
    $display("PTE_2 = 0x%0h",PTE_2);
    
    $display("PA_1 = 0x%0h",PA_1);
    $display("PTE_1 = 0x%0h",PTE_1);
    
    $display("PA_0 = 0x%0h",PA_0);
    $display("PTE_0 = 0x%0h",PTE_0);*/
     
    //Guest PTE_ADDR and PTE calc
    if(hgatp_m!=BAREM)begin
    $display("\n\tG_PTE3 calculation");

    $display("GVA_3 = 0x%0h",GVA_3);
    $display("GVA_3_VPN_3 <<3 = 0x%0h",GVA_3_VPN_3 <<3);
    $display("GVA_3_VPN_2 <<3 = 0x%0h",GVA_3_VPN_2 <<3);
    $display("GVA_3_VPN_1 <<3 = 0x%0h",GVA_3_VPN_1 <<3);
    $display("GVA_3_VPN_0 <<3 = 0x%0h",GVA_3_VPN_0 <<3);
    
    $display("\nG3_PTE_ADDR_3 = 0x%0h",G3_PTE_ADDR_3);
    $display("G3_PTE_3 = 0x%0h",G3_PTE_3);
    
    $display("G3_PTE_ADDR_2 = 0x%0h",G3_PTE_ADDR_2);
    $display("G3_PTE_2 = 0x%0h",G3_PTE_2);
    
    $display("G3_PTE_ADDR_1 = 0x%0h",G3_PTE_ADDR_1);
    $display("G3_PTE_1 = 0x%0h",G3_PTE_1);
    
    $display("G3_PTE_ADDR_0 = 0x%0h",G3_PTE_ADDR_0);
    $display("G3_PTE_0 = 0x%0h",G3_PTE_0);
    
    $display("\nPA_3 = 0x%0h",PA_3);
    $display("PTE_3 = 0x%0h\n",PTE_3);
    
    
    $display("\n\tG_PTE2 calculation");
    
    $display("GVA_2 = 0x%0h",GVA_2);
    $display("GVA_2_VPN_3 <<3 = 0x%0h",GVA_2_VPN_3 <<3);
    $display("GVA_2_VPN_2 <<3 = 0x%0h",GVA_2_VPN_2 <<3);
    $display("GVA_2_VPN_1 <<3 = 0x%0h",GVA_2_VPN_1 <<3);
    $display("GVA_2_VPN_0 <<3 = 0x%0h",GVA_2_VPN_0 <<3);
    
    $display("\nG2_PTE_ADDR_3 0x%0h",G2_PTE_ADDR_3);
    $display("G2_PTE_3 = 0x%0h",G2_PTE_3);
    
    $display("G2_PTE_ADDR_2 = 0x%0h",G2_PTE_ADDR_2);
    $display("G2_PTE_2 = 0x%0h",G2_PTE_2);

    $display("G2_PTE_ADDR_1 = 0x%0h",G2_PTE_ADDR_1);
    $display("G2_PTE_1 = 0x%0h",G2_PTE_1);
    
    $display("G2_PTE_ADDR_0 = 0x%0h",G2_PTE_ADDR_0);
    $display("G2_PTE_0 = 0x%0h",G2_PTE_0);
    
    $display("\nPA_2 = 0x%0h",PA_2);
    $display("PTE_2 = 0x%0h\n",PTE_2);
    
    $display("\n\tG_PTE1 calculation");
    $display("GVA_1 = 0x%0h",GVA_1);
    $display("GVA_1_VPN_3 <<3 = 0x%0h",GVA_1_VPN_3 <<3);
    $display("GVA_1_VPN_2 <<3 = 0x%0h",GVA_1_VPN_2 <<3);
    $display("GVA_1_VPN_1 <<3 = 0x%0h",GVA_1_VPN_1 <<3);
    $display("GVA_1_VPN_0 <<3 = 0x%0h",GVA_1_VPN_0 <<3);

    $display("\nG1_PTE_ADDR_3 0x%0h",G1_PTE_ADDR_3);
    $display("G1_PTE_3 0x%0h",G1_PTE_3);
    
    $display("G1_PTE_ADDR_2 = 0x%0h",G1_PTE_ADDR_2);
    $display("G1_PTE_2 = 0x%0h",G1_PTE_2);
    
    $display("G1_PTE_ADDR_1 = 0x%0h",G1_PTE_ADDR_1);
    $display("G1_PTE_1 = 0x%0h",G1_PTE_1);
    
    $display("G1_PTE_ADDR_0 = 0x%0h",G1_PTE_ADDR_0);
    $display("G1_PTE_0 = 0x%0h",G1_PTE_0);
    
    $display("\nPA_1 = 0x%0h",PA_1);
    $display("PTE_1 = 0x%0h\n",PTE_1);
    
    $display("\n\tG_PTE0 calculation");
    $display("GVA_0 = 0x%0h",GVA_0);
    $display("GVA_0_VPN_3 <<3 = 0x%0h",GVA_0_VPN_3 <<3);
    $display("GVA_0_VPN_2 <<3 = 0x%0h",GVA_0_VPN_2 <<3);
    $display("GVA_0_VPN_1 <<3 = 0x%0h",GVA_0_VPN_1 <<3);
    $display("GVA_0_VPN_0 <<3 = 0x%0h",GVA_0_VPN_0 <<3);

    $display("\nG0_PTE_ADDR_3 = 0x%0h",G0_PTE_ADDR_3);
    $display("G0_PTE_3 = 0x%0h",G0_PTE_3);
    
    $display("G0_PTE_ADDR_2 = 0x%0h",G0_PTE_ADDR_2);
    $display("G0_PTE_2 = 0x%0h",G0_PTE_2);
    
    $display("G0_PTE_ADDR_1 = 0x%0h",G0_PTE_ADDR_1);
    $display("G0_PTE_1 = 0x%0h",G0_PTE_1);
    
    $display("G0_PTE_ADDR_0 = 0x%0h",G0_PTE_ADDR_0);
    $display("G0_PTE_0 = 0x%0h",G0_PTE_0);
    
    $display("\nPA_0 = 0x%0h",PA_0);
    $display("PTE_0 = 0x%0h\n",PTE_0);
    
    $display("GVA_00 = 0x%0h",GVA_00);
    $display("GVA_00_VPN_3 <<3 = 0x%0h",GVA_00_VPN_3 <<3);
    $display("GVA_00_VPN_2 <<3 = 0x%0h",GVA_00_VPN_2 <<3);
    $display("GVA_00_VPN_1 <<3 = 0x%0h",GVA_00_VPN_1 <<3);
    $display("GVA_00_VPN_0 <<3 = 0x%0h",GVA_00_VPN_0 <<3);

    $display("\nG00_PTE_ADDR_3 = 0x%0h",G00_PTE_ADDR_3);
    $display("G00_PTE_3 = 0x%0h",G00_PTE_3);
    
    $display("G00_PTE_ADDR_2 = 0x%0h",G00_PTE_ADDR_2);
    $display("G00_PTE_2 = 0x%0h",G00_PTE_2);
    
    $display("G00_PTE_ADDR_1 = 0x%0h",G00_PTE_ADDR_1);
    $display("G00_PTE_1 = 0x%0h",G00_PTE_1);
    
    $display("G00_PTE_ADDR_0 = 0x%0h",G00_PTE_ADDR_0);
    $display("G00_PTE_0 = 0x%0h",G00_PTE_0);
    
     $display("spa = 0x%0h",SPA);
     $display("************************************************************************************/");

    
    // Normal PTE_ADDR and PTE calc      
    //Guest PTE_ADDR and PTE calc
    // Level G3
    if(vsatp_m inside {SV48M,SV39M})begin
      if(vsatp_m == SV48M)begin
        $display("li x5, 0x%0h  //G3_PTE_ADDR_3",G3_PTE_ADDR_3);
        $display("li x6, 0x%0h	//G3_PTE_3",G3_PTE_3);
        $display("sd x6, (x5)");
      end
      if(guest_page_size != P512GB)begin
        $display("li x5, 0x%0h	//G3_PTE_ADDR_2",G3_PTE_ADDR_2);
        $display("li x6, 0x%0h	//G3_PTE_2",G3_PTE_2);
      	$display("sd x6, (x5)");
      	if(guest_page_size != P1GB)begin
        	$display("li x5, 0x%0h	//G3_PTE_ADDR_1",G3_PTE_ADDR_1);
        	$display("li x6, 0x%0h	//G3_PTE_1",G3_PTE_1);
        	$display("sd x6, (x5)");
      		if(guest_page_size != P2MB)begin
        		$display("li x5, 0x%0h	//G3_PTE_ADDR_0",G3_PTE_ADDR_0);
        		$display("li x6, 0x%0h	//G3_PTE_0",G3_PTE_0);
        		$display("sd x6, (x5)\n");
        	end
        end
      end
      	$display("li x5, 0x%0h	//PA_3",PA_3);
      	$display("li x6, 0x%0h	//PTE_3",PTE_3);
        $display("sd x6, (x5)\n\n");
    end
      
      // Level G2
      if(guest_page_size inside {P512GB,P1GB,P2MB,P4KB})begin

      if(vsatp_m == SV48M)begin
        $display("li x5, 0x%0h	//G2_PTE_ADDR_3",G2_PTE_ADDR_3);
        $display("li x6, 0x%0h	//G2_PTE_3",G2_PTE_3);
        $display("sd x6, (x5)");
      end
        if(guest_page_size != P512GB)begin
      $display("li x5, 0x%0h	//G2_PTE_ADDR_2",G2_PTE_ADDR_2);
      $display("li x6, 0x%0h	//G2_PTE_2",G2_PTE_2);
      $display("sd x6, (x5)");
        if(guest_page_size != P1GB)begin
      $display("li x5, 0x%0h	//G2_PTE_ADDR_1",G2_PTE_ADDR_1);
      $display("li x6, 0x%0h	//G2_PTE_1",G2_PTE_1);
      $display("sd x6, (x5)");
        if(guest_page_size != P2MB)begin
      $display("li x5, 0x%0h	//G2_PTE_ADDR_0",G2_PTE_ADDR_0);
      $display("li x6, 0x%0h	//G2_PTE_0",G2_PTE_0);
      $display("sd x6, (x5)\n");
        end
        end
      $display("li x5, 0x%0h	//PA_2",PA_2);
      $display("li x6, 0x%0h	//PTE_2",PTE_2);
      $display("sd x6, (x5)\n\n");
        end
      end
      
        //level G1
      if(guest_page_size inside {P1GB,P2MB,P4KB})begin
   	  if(vsatp_m == SV48M)begin
        $display("li x5, 0x%0h	//G1_PTE_ADDR_3",G1_PTE_ADDR_3);
        $display("li x6, 0x%0h	//G1_PTE_3",G1_PTE_3);
        $display("sd x6, (x5)");
      end
    
      $display("li x5, 0x%0h	//G1_PTE_ADDR_2",G1_PTE_ADDR_2);
      $display("li x6, 0x%0h	//G1_PTE_2",G1_PTE_2);
      $display("sd x6, (x5)");
    
        if(guest_page_size != P1GB)begin
      $display("li x5, 0x%0h	//G1_PTE_ADDR_1",G1_PTE_ADDR_1);
      $display("li x6, 0x%0h	//G1_PTE_1",G1_PTE_1);
      $display("sd x6, (x5)");
        if(guest_page_size != P2MB)begin
      $display("li x5, 0x%0h	//G1_PTE_ADDR_0",G1_PTE_ADDR_0);
      $display("li x6, 0x%0h	//G1_PTE_0",G1_PTE_0);
      $display("sd x6, (x5)\n");
      	end
      $display("li x5, 0x%0h	//PA_1",PA_1);
      $display("li x6, 0x%0h	//PTE_1",PTE_1);
      $display("sd x6, (x5)\n\n");
       	end
     end
      
      //level G0
      if(guest_page_size inside {P2MB,P4KB})begin
      if(vsatp_m == SV48M)begin
        $display("li x5, 0x%0h	//G0_PTE_ADDR_3",G0_PTE_ADDR_3);
        $display("li x6, 0x%0h	//G0_PTE_3",G0_PTE_3);
        $display("sd x6, (x5)");
      end
    
      $display("li x5, 0x%0h	//G0_PTE_ADDR_2",G0_PTE_ADDR_2);
      $display("li x6, 0x%0h	//G0_PTE_2",G0_PTE_2);
      $display("sd x6, (x5)");
    
      
      $display("li x5, 0x%0h	//G0_PTE_ADDR_1",G0_PTE_ADDR_1);
      $display("li x6, 0x%0h	//G0_PTE_1",G0_PTE_1);
      $display("sd x6, (x5)");
    
        if(guest_page_size == P4KB)begin
      $display("li x5, 0x%0h	//G0_PTE_ADDR_0",G0_PTE_ADDR_0);
      $display("li x6, 0x%0h	//G0_PTE_0",G0_PTE_0);
      $display("sd x6, (x5)\n");
    
      $display("li x5, 0x%0h	//PA_0",PA_0);
      $display("li x6, 0x%0h	//PTE_0",PTE_0);
      $display("sd x6, (x5)\n\n");
        end
      end
      
      //level G00
      if(guest_page_size==P4KB)begin
      if(vsatp_m == SV48M)begin
        $display("li x5, 0x%0h	//G00_PTE_ADDR_3",G00_PTE_ADDR_3);
        $display("li x6, 0x%0h	//G00_PTE_3",G00_PTE_3);
        $display("sd x6, (x5)");
      end
    
      $display("li x5, 0x%0h	//G00_PTE_ADDR_2",G00_PTE_ADDR_2);
      $display("li x6, 0x%0h	//G00_PTE_2",G00_PTE_2);
      $display("sd x6, (x5)");
    
      $display("li x5, 0x%0h	//G00_PTE_ADDR_1",G00_PTE_ADDR_1);
      $display("li x6, 0x%0h	//G00_PTE_1",G00_PTE_1);
      $display("sd x6, (x5)");
    
      $display("li x5, 0x%0h	//G00_PTE_ADDR_0",G00_PTE_ADDR_0);
      $display("li x6, 0x%0h	//G00_PTE_0",G00_PTE_0);
      $display("sd x6, (x5)");
    
      $display("// spa = 0x%0h",SPA);
      $display("// csrw vsatp, 0x%0h",vsatp);
      $display("// csrw hgatp, 0x%0h",hgatp);
      end
    end
    else begin
      $display("\n\tPTE calculation");

      $display("VA_3 = 0x%0h",gva);
      $display("VPN_3 << 3 = 0x%0h",VPN_3 <<3);
      $display("VPN_2 << 3 = 0x%0h",VPN_2 <<3);
      $display("VPN_1 << 3 = 0x%0h",VPN_1 <<3);
      $display("VPN_0 << 3 = 0x%0h",VPN_0 <<3);
      
      $display("\nPTE_ADDR_3 = 0x%0h",PTE_ADDR_3);
      $display("PTE_3 = 0x%0h",PTE_3);
    
      $display("PTE_ADDR_2 = 0x%0h",PTE_ADDR_2);
      $display("PTE_2 = 0x%0h",PTE_2);
    
      $display("PTE_ADDR_1 = 0x%0h",PTE_ADDR_1);
      $display("PTE_1 = 0x%0h",PTE_1);
    
      $display("PTE_ADDR_0 = 0x%0h",PTE_ADDR_0);
      $display("PTE_0 = 0x%0h",PTE_0);
    
      $display("\nPA = 0x%0h",PA);
      $display("PTE = 0x%0h\n",PTE);
      $display("************************************************************************************/");
      if(satp_m == SV48M)begin
      $display("li x5, 0x%0h	//PTE_ADDR_3",PTE_ADDR_3);
      $display("li x6, 0x%0h	//PTE_3",PTE_3);
      $display("sd x6, (x5)");
      end
      if(init_page_size < P512GB)begin
      	$display("li x5, 0x%0h	//PTE_ADDR_2",PTE_ADDR_2);
      	$display("li x6, 0x%0h	//PTE_2",PTE_2);
      	$display("sd x6, (x5)");
              
        if(init_page_size < P1GB)begin
      		$display("li x5, 0x%0h	//PTE_ADDR_1",PTE_ADDR_1);
      		$display("li x6, 0x%0h	//PTE_1",PTE_1);
      		$display("sd x6, (x5)");
            if(init_page_size < P2MB)begin
      			$display("li x5, 0x%0h	//PTE_ADDR_0",PTE_ADDR_0);
      			$display("li x6, 0x%0h	//PTE_0",PTE_0);
      			$display("sd x6, (x5)");
            end
        end
      end
    end
    
   			 

      
      endfunction
  
  function void gen_guest_page_fault();
	// 512GB fault
    
    $display("////BEFORE//// \nli x6, 0x%0h",G3_PTE_0);
    $display("li x6, 0x%0h",G2_PTE_0);
    $display("li x6, 0x%0h",G1_PTE_0);
    $display("li x6, 0x%0h",G0_PTE_0);
    $display("li x6, 0x%0h",G00_PTE_0);
    
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
        
    $display("///////AFTER//////// \nli x6, 0x%0h",G3_PTE_0);
    $display("li x6, 0x%0h",G2_PTE_0);
    $display("li x6, 0x%0h",G1_PTE_0);
    $display("li x6, 0x%0h",G0_PTE_0);
    $display("li x6, 0x%0h",G00_PTE_0);

   
  endfunction
function void gen_page_fault();
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
  $display("///////AFTER//////// \nli x6, 0x%0h",PTE_0);
  $display("li x6, 0x%0h",PTE_3);
  $display("li x7, 0x%0h",PA_3);
  $display("sd x6, (x7)");
  $display("li x6, 0x%0h",PTE_2);
  $display("li x7, 0x%0h",PA_2);
  $display("sd x6, (x7)");
  $display("li x6, 0x%0h",PTE_1);
  $display("li x7, 0x%0h",PA_1);
  $display("sd x6, (x7)");
  $display("li x6, 0x%0h",PTE_0);
  $display("li x7, 0x%0h",PA_0);
  $display("sd x6, (x7)");
  endfunction

endclass
