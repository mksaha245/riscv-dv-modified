// Guest level 3 PTE 3 calculation
`define GX_PTE_3_cal(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,nxt) 											\
  G``guest_level``_PTE_ADDR_``pt_entry`` = (hgatp_ppn[43:2] << 14) + (GVA_``guest_level``_VPN_``pt_entry`` << 'h3);									\
G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12)) + 3) << (9*(guest_page_size) + 10)) + 'h1;																\
/* P512GB condition */																																\
  if(guest_page_size == P512GB)begin																												\
    G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*guest_page_size + 12)) + ``guest_level``) << (9*guest_page_size + 10))+'hdf;																													 \
    PA_``guest_level`` = ((G``guest_level``_PTE_``pt_entry``>>10)<<12) + GVA_``guest_level``_OFFSET;												\
    if(inst_trans)begin																																	\
          G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*guest_page_size + 12)) + ``guest_level``) << (9*guest_page_size + 10))+'hdf;																													 \
          PA_``guest_level`` = ((G``guest_level``_PTE_``pt_entry``>>10)<<12) + GVA_``guest_level``_OFFSET;												\
      PTE_``guest_level`` = (((PA_``guest_level`` >>(9*(init_page_size) + 12)) + ``guest_level``) << (9*(init_page_size) + 10));					\
    end \
    if(data_trans)begin																																	\
          G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*guest_page_size + 12)) + ``guest_level``) << (9*guest_page_size + 10))+'hdf;																													 \
          PA_``guest_level`` = ((G``guest_level``_PTE_``pt_entry``>>10)<<12) + GVA_``guest_level``_OFFSET;												\
      PTE_``guest_level`` = (((PA_``guest_level`` >>(9*(init_page_size) + 12)) + ``guest_level``+1) << (9*(init_page_size) + 10));					\
    end \
    if(``nxt``>=0 || ``nxt`` == 00)begin																											\
      GVA_``nxt`` = ((PTE_``guest_level``[53:0] >> 10) <<12) + (GVA_VPN_``nxt``<<3);																\
    end																																				\
    if(inst_trans && (guest_level == 2) && (pt_entry==3))																							\
		G``guest_level``_PTE_``pt_entry`` = 'hdf;																									\
  end																																				\
  /* P1GB condition */																																\
  if(guest_page_size == P1GB)begin																													\
    G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12)) + 3) << (9*(guest_page_size) + 10)) + 'h1;																																				 \
  end																																				\
  `PTE_CALC_CASE(init_page_size,vsatp_m,guest_level)																								\


// Guest level 3 PTE 2 calculation
`define GX_PTE_2_cal(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,nxt)												\
if(hgatp_m == SV48)	\
  G``guest_level``_PTE_ADDR_``pt_entry`` = ((G``guest_level``_PTE_3 >>10) << 12) + (GVA_``guest_level``_VPN_``pt_entry`` << 'h3);					\
else	\
  G``guest_level``_PTE_ADDR_``pt_entry`` = (hgatp_ppn[43:2] << 14) + (GVA_``guest_level``_VPN_``pt_entry`` << 'h3);									\
G``guest_level``_PTE_``pt_entry`` = ((((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12)) + 2) << (9*(guest_page_size) + 10))) + 'h1;																\
if(guest_page_size == P512GB)begin																													\
  G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12) + 2) << (9*(guest_page_size) + 10))) + 'h1;																\
end																																					\
if((guest_page_size == P1GB) && (guest_level == 1) && (pt_entry==2))begin																			\
  if(inst_trans)  																																	\
    G``guest_level``_PTE_``pt_entry`` = 'hDF;																										\
  if(data_trans)																																	\
    G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12) + 2) << (9*(guest_page_size) + 10))) + 'hdf;						\
end																																					\
if((guest_page_size == P1GB) && (guest_level == 3) && (pt_entry==2))begin																			\
    G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12) + 2) << (9*(guest_page_size) + 10))) + 'hdf;							\
  	PA_``guest_level`` = ((G``guest_level``_PTE_``pt_entry``>>10)<<12) + GVA_``guest_level``_OFFSET;												\
    PTE_``guest_level`` = (((PA_``guest_level`` >> 30) + ``guest_level``) << 28);																	\
    if(``nxt``>=0 || ``nxt`` == 00)begin																											\
      GVA_``nxt`` = ((PTE_``guest_level``[53:0] >> 10) <<12) + (GVA_VPN_``nxt``<<3);																\
    end																																				\
  end																																				\
if((guest_page_size == P1GB) && (guest_level == 2) && (pt_entry==2))begin																			\
    G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12)) + 2) << (9*(guest_page_size) + 10)) + 'hdf;							\
  	PA_``guest_level`` = ((G``guest_level``_PTE_``pt_entry``>>10)<<12) + GVA_``guest_level``_OFFSET;												\
    PTE_``guest_level`` = (((PA_``guest_level`` >> 30) + ``guest_level``) << 28);																	\
  if(inst_trans)																																	\
  PTE_``guest_level`` = (((PA_``guest_level`` >>(9*(init_page_size) + 12)) + ``guest_level``) << (9*(init_page_size) + 10));						\
  if(data_trans)																																	\
    PTE_``guest_level`` = (((PA_``guest_level`` >>(9*(init_page_size) + 12)) + ``guest_level``+10) << (9*(init_page_size) + 10));					\
  if(``nxt``>=0 || ``nxt`` == 00)begin																												\
      GVA_``nxt`` = ((PTE_``guest_level``[53:0] >> 10) <<12) + (GVA_VPN_``nxt``<<3);																\
    end																																				\
end																																					\
if(guest_page_size != P1GB)																															\
  `PTE_CALC_CASE(init_page_size,vsatp_m,guest_level)																						

// Guest level 3 PTE 1 calculation
`define GX_PTE_1_cal(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,nxt)												\
  G``guest_level``_PTE_ADDR_``pt_entry`` = ((G``guest_level``_PTE_2 >>10) << 12) + (GVA_``guest_level``_VPN_``pt_entry`` << 'h3);					\
  G``guest_level``_PTE_``pt_entry`` = ((((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12)) + 1) << (9*(guest_page_size) + 10))) + 'h1;																\
if(guest_page_size == P512GB)begin																													\
  G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12) + 1) << (9*(guest_page_size) + 10))) + 'h1;																\
end																																					\
if((guest_page_size == P1GB) && (hgatp_m == SV48) && (guest_level==2))																				\
    G``guest_level``_PTE_``pt_entry`` = 'hDF;																										\
if(guest_page_size == P2MB && (pt_entry==1))begin          																							\
  G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12)) + 1) << (9*(guest_page_size) + 10)) + 'hdf;								\
  `PTE_CALC_CASE(init_page_size,vsatp_m,guest_level)																							\
  if((``nxt`` >= 0) && (``nxt`` != 00))																											\
    GVA_``nxt`` = ((PTE_``guest_level``[53:0] >> 10) <<12) + (GVA_VPN_``nxt``<<3);																\
end																																				\
if(guest_page_size == P2MB && (guest_level inside {1,2,3}) && (pt_entry==1)) begin           													\
  G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12)) + ``guest_level``) << (9*(guest_page_size) + 10)) + 'hdf;								\
  PA_``guest_level`` = ((G``guest_level``_PTE_``pt_entry``>>10)<<12) + GVA_``guest_level``_OFFSET;												\
  if(inst_trans)																																\
  PTE_``guest_level`` = (((PA_``guest_level`` >>(9*(init_page_size) + 12)) + ``guest_level``) << (9*(init_page_size) + 10));																		\
  if(data_trans)																																\
    PTE_``guest_level`` = (((PA_``guest_level`` >>(9*(init_page_size) + 12)) + ``guest_level``+10) << (9*(init_page_size) + 10));				\
  `PTE_CALC_CASE(init_page_size,vsatp_m,guest_level)																							\
  /*if((``nxt`` >= 0) && (``nxt`` != 00))*/																										\
    GVA_``nxt`` = ((PTE_``guest_level``[53:0] >> 10) <<12) + (GVA_VPN_``nxt``<<3);																\
end																																				\
if(guest_page_size == P2MB && (guest_level==0) && (pt_entry==1) && inst_trans)																	\
  G``guest_level``_PTE_``pt_entry`` = 'hdf;																										\
SPA = ((G``guest_level``_PTE_``pt_entry`` >>10)<<12) + GVA_``guest_level``_OFFSET;																	

  
// Guest level 3 PTE 0 calculation	
`define GX_PTE_0_cal(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,nxt)												\
  G``guest_level``_PTE_ADDR_``pt_entry`` = ((G``guest_level``_PTE_1 >>10) << 12) + (GVA_``guest_level``_VPN_``pt_entry`` << 'h3);					\
  G``guest_level``_PTE_``pt_entry`` = ((((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12)) + 5) << (9*(guest_page_size) + 10))) + 'h1;																\
if(guest_page_size inside {P512GB,P1GB})begin																										\
  G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12) + 5) << (9*(guest_page_size) + 10))) + 'h1;																\
end																																					\
if(guest_page_size == P4KB) begin																													\
  G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> 12)+``guest_level``) << 10) + 'hDF;								\
  PA_``guest_level`` = ((G``guest_level``_PTE_``pt_entry``>>10)<<12) + GVA_``guest_level``_OFFSET;													\
  if(inst_trans)																																	\
  PTE_``guest_level`` = (((PA_``guest_level`` >>(9*(init_page_size) + 12)) + ``guest_level``) << (9*(init_page_size) + 10));																		\
  if(data_trans)																																	\
    PTE_``guest_level`` = (((PA_``guest_level`` >>(9*(init_page_size) + 12)) + ``guest_level``+10) << (9*(init_page_size) + 10));																		\
  if(``nxt``>=0 || ``nxt`` == 00)begin																												\
    GVA_``nxt`` = ((PTE_``guest_level``[53:0] >> 10) <<12) + (GVA_VPN_``nxt``<<3);																	\
  end																																				\
end 																																				\
`PTE_CALC_CASE(init_page_size,vsatp_m,guest_level)																									\
GVA_00 = ((PTE_0[53:0] >> 10) <<12) + (GVA_VPN_0<<3);																								\

  //////////////////////////////////////////////////////////////////////////////////////////////////////////
`define G00_PTE_3_cal(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m) 												\
if(hgatp_m == SV48)																																	\
  G``guest_level``_PTE_ADDR_``pt_entry`` = (hgapt_ppn[43:2]<<14) + (GVA_``guest_level``_VPN_``pt_entry``<< 3);										\
else																																				\
  G``guest_level``_PTE_ADDR_``pt_entry`` = ((G``guest_level``_PTE_3 >>10) << 12) + (GVA_``guest_level``_VPN_``pt_entry`` << 'h3);					\
G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> 12)+3) << 10) + 'h1;								\
if(guest_page_size == P512GB)begin																													\
  G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> 12)+1) << 10) + 'hDF;											\
    if(inst_trans)begin																																	\
      G``guest_level``_PTE_ADDR_``pt_entry`` += 8;										\
      tmp = G``guest_level``_PTE_ADDR_``pt_entry``;																									\
      G``guest_level``_PTE_``pt_entry`` = 'hDF;																										\
    end																																				\
    if(data_trans)begin																																	\
      if(tmp == G``guest_level``_PTE_ADDR_``pt_entry``)																									\
        G``guest_level``_PTE_ADDR_``pt_entry``+=8;																										\
    end																																				\
  end
              	
// Guest level 3 PTE 2 calculation
`define G00_PTE_2_cal(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)												\
if(hgatp_m == SV48)																																	\
  G``guest_level``_PTE_ADDR_``pt_entry`` = ((G``guest_level``_PTE_3 >>10) << 12) + (GVA_``guest_level``_VPN_``pt_entry`` << 'h3);					\
else																																				\
  G``guest_level``_PTE_ADDR_``pt_entry`` = (hgatp_ppn << 12) + (GVA_``guest_level``_VPN_``pt_entry`` << 'h3);										\
if(guest_page_size == P1GB) begin																													\
  G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> 12)+((guest_page_size==init_page_size)?2:20)) << 10) + 'hDF;											\
  if(inst_trans)begin																																\
    G``guest_level``_PTE_``pt_entry`` = 'hDF;																										\
  end																																				\
  if(data_trans)begin																																	\
    if(tmp == G``guest_level``_PTE_ADDR_``pt_entry``)																									\
      G``guest_level``_PTE_ADDR_``pt_entry``+=8;																										\
  end																																				\
end else begin																																	\
  G``guest_level``_PTE_``pt_entry`` = ((((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12)) + ((guest_page_size==init_page_size)?2:20)) << (9*(guest_page_size) + 10))) + 'h1;																\
end
// Guest level 3 PTE 1 calculation
`define G00_PTE_1_cal(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)												\
  G``guest_level``_PTE_ADDR_``pt_entry`` = ((G``guest_level``_PTE_2 >> 10) << 12) + (GVA_``guest_level``_VPN_``pt_entry`` << 'h3);					\
  if(guest_page_size == P2MB) begin           																										\
  G``guest_level``_PTE_``pt_entry`` = ((((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12)) + ((guest_page_size==init_page_size)?1:10)) << (9*(guest_page_size) + 10))) + 'hdf;																\
    if(inst_trans)begin																																\
      G``guest_level``_PTE_``pt_entry`` = 'hDF;																										\
    end																																				\
    if(data_trans)begin																																	\
      if(tmp == G``guest_level``_PTE_ADDR_``pt_entry``)																									\
        G``guest_level``_PTE_ADDR_``pt_entry``+=8;																										\
    end																																				\
  end else begin																																	\
    G``guest_level``_PTE_``pt_entry`` = ((((G``guest_level``_PTE_ADDR_``pt_entry`` >> 12)+((guest_page_size==init_page_size)?1:10))) << 10) + 'h1;											\
  end																																				\
  
// Guest level 3 PTE 0 calculation	
`define G00_PTE_0_cal(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m,inst_trans,tmp)									\
  G``guest_level``_PTE_ADDR_``pt_entry`` = ((G``guest_level``_PTE_1 >> 10) << 12) + (GVA_``guest_level``_VPN_``pt_entry`` << 'h3);					\
  if(guest_page_size == P4KB) begin																													\
    /*if(tmp == G``guest_level``_PTE_ADDR_``pt_entry``)																								\
      G``guest_level``_PTE_ADDR_``pt_entry``+=8;*/																									\
    if(inst_trans)begin																																\
      tmp = G``guest_level``_PTE_ADDR_``pt_entry``;																									\
      G``guest_level``_PTE_``pt_entry`` = 'hDF;																										\
    end																																				\
    if(data_trans)																																	\
      G``guest_level``_PTE_``pt_entry`` = (((G``guest_level``_PTE_ADDR_``pt_entry`` >> 12)+1) << 10) + 'hDF;											\
    $display("// G%0d_PTE_%0d= %0h",``guest_level``,``pt_entry``,G``guest_level``_PTE_``pt_entry``); 										\
  end																																					\
  else G``guest_level``_PTE_``pt_entry`` = ((((G``guest_level``_PTE_ADDR_``pt_entry`` >> (9*(guest_page_size) + 12)) + 5) << (9*(guest_page_size) + 10))) + 'h1;																\
  SPA = ((G``guest_level``_PTE_``pt_entry`` >>10)<<12) + GVA_``guest_level``_OFFSET;																	

`define V_PTE_G_BARE(pt_entry,init_page_size,vsatp_m,inst_trans,tmp)																				\
PTE_ADDR_``pt_entry`` = ((PTE_``tmp``>>10) << 12) + (GVA_VPN_``pt_entry`` << 'h3);																	\
if(vsatp_m==SV48 && pt_entry==3)																													\
	PTE_ADDR_``pt_entry`` = (vsatp_ppn << 12) + (GVA_VPN_``pt_entry`` << 'h3);																	\
if(vsatp_m==SV39 && pt_entry==2)																													\
	PTE_ADDR_``pt_entry`` = (vsatp_ppn << 12) + (GVA_VPN_``pt_entry`` << 'h3);																	\
PTE_``pt_entry`` = (((PTE_ADDR_``pt_entry`` >> (9*(init_page_size) + 12)) + ``pt_entry``) << (9*(init_page_size) + 10)) + 1;							\
$display("// PTE_ADDR_%0d = %0h, PTE_%0d = %0h, GVA_VPN_%0d = %0h",``pt_entry``,PTE_ADDR_``pt_entry``,``pt_entry``,PTE_``pt_entry``,``pt_entry``,GVA_VPN_``pt_entry``);																\
if(init_page_size==P512GB && pt_entry==3)																											\
  PTE_``pt_entry`` = inst_trans ? (is_sup?8'hcf:8'hdf) : {PTE_``pt_entry``[63:8],(is_sup?8'hcf:8'hdf)};																					\
if(init_page_size==P1GB && pt_entry==2)																												\
  PTE_``pt_entry`` = inst_trans ? (is_sup?8'hcf:8'hdf) :{PTE_``pt_entry``[63:8],(is_sup?8'hcf:8'hdf)};																					\
if(init_page_size==P2MB && pt_entry==1)																												\
  PTE_``pt_entry`` = inst_trans ? (is_sup?8'hcf:8'hdf) : {PTE_``pt_entry``[63:8],(is_sup?8'hcf:8'hdf)};																					\
if(init_page_size==P4KB && pt_entry==0)																												\
  PTE_``pt_entry`` = inst_trans ? (is_sup?8'hcf:8'hdf) : {PTE_``pt_entry``[63:8],(is_sup?8'hcf:8'hdf)};																					\
PA = ((PTE_``pt_entry``>> 10) << 12) + GVA_VPN_OFFSET ;



	/*if(init_page_size == P512GB && vsatp_m==SV48)																								\
      	PTE_``guest_level`` += 'hdf;																												\
	else 																																			\
		PTE_``guest_level`` += 'h1;																													\
	if(init_page_size == P1GB && vsatp_m==SV39)																									\
      	PTE_``guest_level`` += 'hdf;																												\
	if(init_page_size == P2MB && vsatp_m==SV48)																									\
      	PTE_``guest_level`` += 'hdf;																												\
	if(init_page_size == P4KB && vsatp_m==SV48)																									\
      	PTE_``guest_level`` += 'hdf;																												\

*/
  		//nxt = ``guest_level``-1;																													\


`define GX_PTE_3_gen_fault(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m) 											\
if(guest_page_size == P512GB)begin																													\
  G``guest_level``_PTE_``pt_entry`` = (G``guest_level``_PTE_``pt_entry``  & 'hFFFFFFFFFFFFFFF0) | (enable_g_load_page_fault ? 'hd : (enable_g_store_page_fault ? 'hb : (enable_g_inst_access_page_fault ? 'h7 : 'h0)));																											\
end	\

`define GX_PTE_2_gen_fault(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m) 											\
if(guest_page_size == P1GB) begin																													\
  G``guest_level``_PTE_``pt_entry`` = (G``guest_level``_PTE_``pt_entry``  & 'hFFFFFFFFFFFFFFF0) |( enable_g_load_page_fault ? 'hd : (enable_g_store_page_fault ? 'hb : (enable_g_inst_access_page_fault ? 'h7 : 'h0)));																											\
end	\

`define GX_PTE_1_gen_fault(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m) 											\
if(guest_page_size == P2MB) begin           																										\
  G``guest_level``_PTE_``pt_entry`` = (G``guest_level``_PTE_``pt_entry``  & 'hFFFFFFFFFFFFFFF0) | (enable_g_load_page_fault ? 'hd : (enable_g_store_page_fault ? 'hb : (enable_g_inst_access_page_fault ? 'h7 : 'h0)));																											\
end	\

`define GX_PTE_0_gen_fault(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m) 											\
G``guest_level``_PTE_``pt_entry`` = (G``guest_level``_PTE_``pt_entry``  & 'hFFFFFFFFFFFFFFF0) | (enable_g_load_page_fault ? 'hd : (enable_g_store_page_fault ? 'hb : (enable_g_inst_access_page_fault ? 'h7 : 'h0)));																											\

`define G00_PTE_3_gen_fault(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m) 											\
G``guest_level``_PTE_``pt_entry`` = (G``guest_level``_PTE_``pt_entry``  & 'hFFFFFFFFFFFFFFF0) | (enable_g_load_page_fault ? 'hd : (enable_g_store_page_fault ? 'hb : (enable_g_inst_access_page_fault ? 'h7 : 'h0)));																											\

`define G00_PTE_2_gen_fault(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m) 											\
G``guest_level``_PTE_``pt_entry`` = (G``guest_level``_PTE_``pt_entry``  & 'hFFFFFFFFFFFFFFF0) | (enable_g_load_page_fault ? 'hd : (enable_g_store_page_fault ? 'hb : (enable_g_inst_access_page_fault ? 'h7 : 'h0)));																											\

`define G00_PTE_1_gen_fault(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m) 												\
G``guest_level``_PTE_``pt_entry`` = (G``guest_level``_PTE_``pt_entry``  & 'hFFFFFFFFFFFFFFF0) | (enable_g_load_page_fault ? 'hd : (enable_g_store_page_fault ? 'hb : (enable_g_inst_access_page_fault ? 'h7 : 'h0)));																											\

`define G00_PTE_0_gen_fault(guest_level,pt_entry,hgapt_ppn,guest_page_size,init_page_size,vsatp_m,hgatp_m)	\
  if(inst_trans)																																	\
    G``guest_level``_PTE_``pt_entry`` = (G``guest_level``_PTE_``pt_entry``  & 'hFFFFFFFFFFFFFFF0) | (enable_g_load_page_fault ? 'hd : (enable_g_store_page_fault ? 'hb : (enable_g_inst_access_page_fault ? 'h7 : 'h0)));																											\
  if(data_trans)																																	\
    G``guest_level``_PTE_``pt_entry`` = (G``guest_level``_PTE_``pt_entry``  & 'hFFFFFFFFFFFFFFF0) | (enable_g_load_page_fault ? 'hd : (enable_g_store_page_fault ? 'hb : (enable_g_inst_access_page_fault ? 'h7 : 'h0)));																											\

`define PTE_3_gen_fault(pt_entry,init_page_size,vsatp_m)	\
if(init_page_size == P512GB)								\
  PTE_``pt_entry`` = (PTE_``pt_entry``  & 'hFFFFFFFFFFFFFFF0) | (enable_load_page_fault ? 'hd : (enable_store_page_fault ? 'hb : (enable_inst_access_page_fault ? 'h7 : 'h0)));							\

`define PTE_2_gen_fault(pt_entry,init_page_size,vsatp_m) 											\
if(init_page_size == P1GB)																												\
  PTE_``pt_entry`` = (PTE_``pt_entry``  & 'hFFFFFFFFFFFFFFF0) | (enable_load_page_fault ? 'hd : (enable_store_page_fault ? 'hb : (enable_inst_access_page_fault ? 'h7 : 'h0)));							\

`define PTE_1_gen_fault(pt_entry,init_page_size,vsatp_m) 																																				\
if(init_page_size == P2MB)           																																								\
  PTE_``pt_entry`` = (PTE_``pt_entry``  & 'hFFFFFFFFFFFFFFF0) | (enable_load_page_fault ? 'hd : (enable_store_page_fault ? 'hb : (enable_inst_access_page_fault ? 'h7 : 'h0)));							\

`define PTE_0_gen_fault(pt_entry,init_page_size,vsatp_m) 																																				\
if(init_page_size == P4KB)																																										\
  PTE_``pt_entry`` = (PTE_``pt_entry``  & 'hFFFFFFFFFFFFFFF0) | (enable_load_page_fault ? 'hd : (enable_store_page_fault ? 'hb : (enable_inst_access_page_fault ? 'h7 : 'h0)));



`define PTE_CALC_CASE(init_page_size,vsatp_m,guest_level) \
casez({init_page_size == P512GB,init_page_size == P1GB,init_page_size == P2MB,init_page_size == P4KB,vsatp_m==SV48,vsatp_m==SV39,``guest_level``==3,``guest_level``==2,``guest_level``==1,``guest_level``==0})									    		\
  10'b1000_10_1000 : PTE_``guest_level`` = {PTE_``guest_level``[63:8], (is_sup ? (is_user ? 8'hdf : 8'hcf) : (is_user ? 8'hdf : 8'h0))} ;					\
  10'b0100_10_0100 : PTE_``guest_level`` = {PTE_``guest_level``[63:8], (is_sup ? (is_user ? 8'hdf : 8'hcf) : (is_user ? 8'hdf : 8'h0))} ;					\
  10'b0010_10_0010 : PTE_``guest_level`` = {PTE_``guest_level``[63:8], (is_sup ? (is_user ? 8'hdf : 8'hcf) : (is_user ? 8'hdf : 8'h0))} ;					\
  10'b0001_10_0001 : PTE_``guest_level`` = {PTE_``guest_level``[63:8], (is_sup ? (is_user ? 8'hdf : 8'hcf) : (is_user ? 8'hdf : 8'h0))} ;					\
  10'b0100_01_0100 : PTE_``guest_level`` = {PTE_``guest_level``[63:8], (is_sup ? (is_user ? 8'hdf : 8'hcf) : (is_user ? 8'hdf : 8'h0))} ;					\
  10'b0010_01_0010 : PTE_``guest_level`` = {PTE_``guest_level``[63:8], (is_sup ? (is_user ? 8'hdf : 8'hcf) : (is_user ? 8'hdf : 8'h0))} ;					\
  10'b0001_01_0001 : PTE_``guest_level`` = {PTE_``guest_level``[63:8], (is_sup ? (is_user ? 8'hdf : 8'hcf) : (is_user ? 8'hdf : 8'h0))} ;					\
default : PTE_``guest_level`` = {PTE_``guest_level``[63:8], 8'h1};																							\
    endcase																																			

`define GVAX_VPNX__CALC(guest_level,guest_page_size,hgatp_m)			\
GVA_``guest_level``_VPN_3 = GVA_``guest_level``[49:39]; 				\
if(hgatp_m==SV48)														\
  GVA_``guest_level``_VPN_2 = GVA_``guest_level``[38:30]; 				\
else if(hgatp_m==SV39)													\
  GVA_``guest_level``_VPN_2 = GVA_``guest_level``[40:30]; 				\
GVA_``guest_level``_VPN_1 = GVA_``guest_level``[29:21]; 				\
GVA_``guest_level``_VPN_0 = GVA_``guest_level``[20:12];					\
if(guest_page_size==P4KB)												\
  GVA_``guest_level``_OFFSET = GVA_``guest_level``[11:0];				\
else if(guest_page_size==P2MB)											\
  GVA_``guest_level``_OFFSET = GVA_``guest_level``[20:0];				\
else if(guest_page_size==P1GB)											\
  GVA_``guest_level``_OFFSET = GVA_``guest_level``[29:0];				\
else if(guest_page_size==P512GB)										\
  GVA_``guest_level``_OFFSET = GVA_``guest_level``[38:0];				


  //////////////////////////////////////////////////////////////////////////////////////////////////////////
//(((PTE_ADDR_2 >> (9*(init_page_size) + 12)) + 3) << (9*(init_page_size) + 10)) + 'h1

`define S_MODE_PTE_cal(pt_entry,sapt_ppn,guest_page_size,init_page_size,satp_m) 												\
if(satp_m==SV48)																												\
PTE_ADDR_3 = (satp_ppn << 12) + (VPN_3 << 'h3);																					\
PTE_3 = inst_trans ? ((init_page_size==P512GB) ? (is_sup? 'hcf : (is_user ? 8'hdf : 0)) : (((PTE_ADDR_3 >> (9*(init_page_size) + 12)) + 3) << (9*(init_page_size) + 10)) + 1 ) :				\
data_trans ? (((PTE_ADDR_3 >> (9*(init_page_size) + 12)) + 3) << (9*(init_page_size) + 10)) + ((init_page_size==P512GB) ? (is_sup? 'hcf : (is_user ? 'hdf : 0)) : (((PTE_ADDR_0 >> (9*(init_page_size) + 12))) << (9*(init_page_size) + 10)) + 1 ) :	\
		0;							\
																																\
if(satp_m==SV39)																												\
PTE_ADDR_2 = (satp_ppn << 12) + (VPN_2 << 'h3);																					\
																																\
PTE_ADDR_2 = ((PTE_3 >> 10) << 12) + (VPN_3 << 'h3);																			\
PTE_2 = inst_trans ? ((init_page_size==P1GB) ? (is_sup?'hcf : (is_user ? 'hdf : 0)) : (((PTE_ADDR_2 >> (9*(init_page_size) + 12)) + 2) << (9*(init_page_size) + 10)) + 1) :					\
(data_trans ? (((PTE_ADDR_2 >> (9*(init_page_size) + 12)) + 2) << (9*(init_page_size) + 10)) +   (init_page_size==P1GB ? (is_sup ? 8'hcf : (is_user ? 'hdf : 0) )  : (((PTE_ADDR_0 >> (9*(init_page_size) + 12))) << (9*(init_page_size) + 10)) + 1) :	\
 0);							\
																																\
PTE_ADDR_1 = ((PTE_2 >> 10) << 12) + (VPN_3 << 'h3);																			\
PTE_1 = inst_trans ? ((init_page_size==P2MB) ? (is_sup?'hcf : (is_user ? 'hdf : 0)) : (((PTE_ADDR_1 >> (9*(init_page_size) + 12)) + 1) << (9*(init_page_size) + 10)) + 1 ) :					\
data_trans ? (((PTE_ADDR_1 >> (9*(init_page_size) + 12)) + 1) << (9*(init_page_size) + 10)) + ((init_page_size==P2MB) ? (is_sup?'hcf : (is_user ? 'hdf : 0)) : (((PTE_ADDR_0 >> (9*(init_page_size) + 12))) << (9*(init_page_size) + 10)) + 1 ) :	\
		0;							\
																																\
PTE_ADDR_0 = ((PTE_1 >> 10) << 12) + (VPN_3 << 'h3);																			\
PTE_0 = inst_trans ? ((init_page_size==P4KB) ? (is_sup?'hcf : (is_user ? 'hdf : 0)) : (((PTE_ADDR_0 >> (9*(init_page_size) + 12))) << (9*(init_page_size) + 10)) + 1 ) :					\
data_trans ? (((PTE_ADDR_0 >> (9*(init_page_size) + 12))) << (9*(init_page_size) + 10)) + ((init_page_size==P4KB) ? (is_sup?'hcf : (is_user ? 'hdf : 0)) : (((PTE_ADDR_0 >> (9*(init_page_size) + 12))) << (9*(init_page_size) + 10)) + 1 ) :	\
		0;							\

