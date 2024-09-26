// Copyright 2018 Robert Balas <balasr@student.ethz.ch>
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Wrapper for a CV32E40P testbench, containing CV32E40P, Memory and stdout peripheral
// Contributor: Robert Balas <balasr@student.ethz.ch>
// Module renamed from riscv_wrapper to cv32e40p_tb_wrapper because (1) the
// name of the core changed, and (2) the design has a cv32e40p_wrapper module.
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-0.51

// most of the connection changed
// Bus delay should be set but error occurs

module cv32e40p_tb_wrapper
    #(parameter // Parameters used by TB
                INSTR_RDATA_WIDTH = 32,
                RAM_ADDR_WIDTH    = 20,
                BOOT_ADDR         = 'h80,
                DM_HALTADDRESS    = 32'h1A11_0800,
                HART_ID           = 32'h0000_0000,
                // Parameters used by DUT
                PULP_XPULP        = 0,
                PULP_CLUSTER      = 0,
                FPU               = 0,
                PULP_ZFINX        = 0,
                NUM_MHPMCOUNTERS  = 1
    )(input logic         clk_i,
     input logic         rst_ni,

     input logic         fetch_enable_i,
     output logic        tests_passed_o,
     output logic        tests_failed_o,
     output logic [31:0] exit_value_o,
     output logic        exit_valid_o
    );
   //---------------------------------------------------------------------------
    localparam NUM_MST=2
             , NUM_SLV=1;
    //---------------------------------------------------------------------------
    localparam  P_HSEL0_START=32'h0,P_HSEL0_SIZE=32'h20000;
    //---------------------------------------------------------------------------
    logic               `BUS_DELAY M_HBUSREQ0;
    logic               `BUS_DELAY M_HBUSREQ1;
    logic [NUM_MST-1:0] `BUS_DELAY M_HGRANT  ;
    logic [31:0]        `BUS_DELAY M_HADDR0  ;
    logic [ 3:0]        `BUS_DELAY M_HPROT0  ;
    logic               `BUS_DELAY M_HLOCK0  ;  //0
    logic [ 1:0]        `BUS_DELAY M_HTRANS0 ;
    logic               `BUS_DELAY M_HWRITE0 ;
    logic [ 2:0]        `BUS_DELAY M_HSIZE0  ;
    logic [ 2:0]        `BUS_DELAY M_HBURST0 ;  //0
    logic [31:0]        `BUS_DELAY M_HWDATA0 ;
    logic [31:0]        `BUS_DELAY M_HADDR1  ;
    logic [ 3:0]        `BUS_DELAY M_HPROT1  ;
    logic               `BUS_DELAY M_HLOCK1  ;  //0
    logic [ 1:0]        `BUS_DELAY M_HTRANS1 ;
    logic               `BUS_DELAY M_HWRITE1 ;
    logic [ 2:0]        `BUS_DELAY M_HSIZE1  ;
    logic [ 2:0]        `BUS_DELAY M_HBURST1 ;  //0
    logic [31:0]        `BUS_DELAY M_HWDATA1 ;
    logic [31:0]        `BUS_DELAY M_HRDATA  ;
    logic [ 1:0]        `BUS_DELAY M_HRESP   ;
    logic               `BUS_DELAY M_HREADY  ;  //1
    //---------------------------------------------------------------------------
    logic [31:0]        `BUS_DELAY S_HADDR      ;
    logic [ 3:0]        `BUS_DELAY S_HPROT      ;
    logic [ 1:0]        `BUS_DELAY S_HTRANS     ;
    logic               `BUS_DELAY S_HWRITE     ;
    logic [ 2:0]        `BUS_DELAY S_HSIZE      ;
    logic [ 2:0]        `BUS_DELAY S_HBURST     ;  //0
    logic [31:0]        `BUS_DELAY S_HWDATA     ;
    logic [31:0]        `BUS_DELAY S_HRDATA0    ;
    logic [ 1:0]        `BUS_DELAY S_HRESP0     ;
    logic               `BUS_DELAY S_HREADY     ;   //1
    logic               `BUS_DELAY S_HREADYout0 ;   //1
    logic [15:0]        `BUS_DELAY S_HSPLIT0    ;   //0000
    logic [NUM_SLV-1:0] `BUS_DELAY S_HSEL       ;   // 1
    logic [ 3:0]        `BUS_DELAY S_HMASTER    ;
    logic               `BUS_DELAY S_HMASTLOCK  ;   //0
    //---------------------------------------------------------------------------

    // signals connecting core to memory
    logic                         instr_req;
    logic                         instr_gnt;
    logic                         instr_rvalid;
    logic [31:0]                  instr_addr;
    logic [INSTR_RDATA_WIDTH-1:0] instr_rdata;
    logic                         instr_err;

    logic                         data_req;
    logic                         data_gnt;
    logic                         data_rvalid;
    logic [31:0]                  data_addr;
    logic                         data_we;
    logic [3:0]                   data_be;
    logic [31:0]                  data_rdata;
    logic [31:0]                  data_wdata;
    logic                         data_err;

    // signals to debug unit
    logic                         debug_req;

    // irq signals (not used)
    logic [0:31]                  irq;
    logic [0:4]                   irq_id_in;
    logic                         irq_ack;
    logic [0:4]                   irq_id_out;
    logic                         irq_sec;

    // pending signal related to data_gnt
    // if pending signal is 1, data_gnt becomes 0
    logic                         pending_dbus_xfer_i = 1'b0;
    logic                         pending_dbus_xfer_d = 1'b0;


    // interrupts (only timer for now)
    assign irq_sec     = '0;

    // instantiate the core
    cv32e40p_core #(
                 .PULP_XPULP       (PULP_XPULP),
                 .PULP_CLUSTER     (PULP_CLUSTER),
                 .FPU              (FPU),
                 .PULP_ZFINX       (PULP_ZFINX),
                 .NUM_MHPMCOUNTERS (NUM_MHPMCOUNTERS)
    ) cv32e40p_core_i (
         .clk_i                  ( clk_i                 ),
         .rst_ni                 ( rst_ni                ),

         .pulp_clock_en_i        ( '1                    ),
         .scan_cg_en_i           ( '0                    ),

         .boot_addr_i            ( BOOT_ADDR             ),
         .dm_halt_addr_i         ( DM_HALTADDRESS        ),
         .hart_id_i              ( HART_ID               ),

         .instr_req_o            ( instr_req             ),
         .instr_gnt_i            ( instr_gnt             ),
         .instr_rvalid_i         ( instr_rvalid          ),
         .instr_addr_o           ( instr_addr            ),
         .instr_rdata_i          ( instr_rdata           ),

         .data_req_o             ( data_req              ),
         .data_gnt_i             ( data_gnt              ),
         .data_rvalid_i          ( data_rvalid           ),
         .data_we_o              ( data_we               ),
         .data_be_o              ( data_be               ),
         .data_addr_o            ( data_addr             ),
         .data_wdata_o           ( data_wdata            ),
         .data_rdata_i           ( data_rdata            ),

         .apu_req_o              (                       ),
         .apu_gnt_i              ( 1'b0                  ),
         .apu_operands_o         (                       ),
         .apu_op_o               (                       ),
         .apu_flags_o            (                       ),
         .apu_rvalid_i           ( 1'b0                  ),
         .apu_result_i           ( {32{1'b0}}            ),
         .apu_flags_i            ( {5{1'b0}}             ), // APU_NUSFLAGS_CPU

         // Interrupts verified in UVM environment
         .irq_i                  ( {32{1'b0}}            ),
         .irq_ack_o              ( irq_ack               ),
         .irq_id_o               ( irq_id_out            ),

         .debug_req_i            ( debug_req             ),

         .fetch_enable_i         ( fetch_enable_i        ),
         .core_sleep_o           ( core_sleep_o          )
    );

    //---------------------------------------------------------------------------

    obi2ahbm_adapter_data u_obi_ahb_bridge_data
    (
        .hclk_i        (clk_i),                // (I) AHB clock
        .hresetn_i     (rst_ni),            // (I) AHB reset, active LOW
    
    // AHB master interface
        .haddr_o       (M_HADDR0    ),        // (O) 32-bit AHB system address bus
        .hburst_o      (M_HBURST0   ),       // (O) Burst type 
        .hmastlock_o   (M_HLOCK0    ),    // (O) Sequence lock
        .hprot_o       (M_HPROT0    ),        // (O) Protection control
        .hsize_o       (M_HSIZE0    ),        // (O) Transfer size
        .htrans_o      (M_HTRANS0   ),       // (O) Transfer type
        .hwdata_o      (M_HWDATA0   ),       // (O) 32-bit AHB write data bus
        .hwrite_o      (M_HWRITE0   ),       // (O) Transfer direction
        .hrdata_i      (M_HRDATA    ),       // (I) 32-bit AHB read data bus
        .hready_i      (M_HREADY    ),       // (I) Status of transfer
        .hresp_i       (M_HRESP     ),        // (I) Transfer response
        //bus request signal added for arbiter
        .hbusreqd_o    (M_HBUSREQ0  ),        // (O) bus request
    
    // Data interface from core
        .data_req_i    (data_req),     // (I) Request ready
        .data_gnt_o    (data_gnt),     // (O) The other side accepted the request
        .data_addr_i   (data_addr),    // (I) Address
        .data_we_i     (data_we),      // (I) Write enable (active HIGH)
        .data_be_i     (data_be),      // (I) Byte enable
        .data_wdata_i  (data_wdata),   // (I) Write data
        .data_rdata_o  (data_rdata),   // (O) Read data
        .data_rvalid_o (data_rvalid),  // (O) Read data valid when high
        .data_err_o    (data_err),     // (O) Error
        .pending_dbus_xfer_i(pending_dbus_xfer_d), // (I) Asserted if data bus is busy from other transactions

    // Miscellaneous
        .priv_mode_i()       // (I) Privilege mode (from core. 1=machine mode, 0=user mode)
    );

    //---------------------------------------------------------------------------
    
    obi2ahbm_adapter_inst u_obi_ahb_bridge_inst
    (
        .hclk_i        (clk_i),                // (I) AHB clock
        .hresetn_i     (rst_ni),            // (I) AHB reset, active LOW
    
    // AHB master interface
        .haddr_o       (M_HADDR1    ),        // (O) 32-bit AHB system address bus
        .hburst_o      (M_HBURST1   ),       // (O) Burst type 
        .hmastlock_o   (M_HLOCK1    ),    // (O) Sequence lock
        .hprot_o       (M_HPROT1    ),        // (O) Protection control
        .hsize_o       (M_HSIZE1    ),        // (O) Transfer size
        .htrans_o      (M_HTRANS1   ),       // (O) Transfer type
        .hwdata_o      (M_HWDATA1   ),       // (O) 32-bit AHB write data bus
        .hwrite_o      (M_HWRITE1   ),       // (O) Transfer direction
        .hrdata_i      (M_HRDATA    ),       // (I) 32-bit AHB read data bus
        .hready_i      (M_HREADY    ),       // (I) Status of transfer
        .hresp_i       (M_HRESP     ),        // (I) Transfer response
        //bus request signal added for arbiter
        .hbusreqi_o    (M_HBUSREQ1  ),        // (O) bus request

    //found that it doesn't need tied signal

    // Data interface from core
        .data_req_i    (instr_req),     // (I) Request ready
        .data_gnt_o    (instr_gnt),     // (O) The other side accepted the request
        .data_addr_i   (instr_addr),    // (I) Address
        .data_we_i     ('0),      // (I) Write enable (active HIGH)
        .data_be_i     (4'b1111),      // (I) Byte enable
        .data_wdata_i  ('0),   // (I) Write data
        .data_rdata_o  (instr_rdata),   // (O) Read data
        .data_rvalid_o (instr_rvalid),  // (O) Read data valid when high
        .data_err_o    (instr_err),     // (O) Error
        .pending_dbus_xfer_i(pending_dbus_xfer_i), // (I) Asserted if data bus is busy from other transactions

    // Miscellaneous
        .priv_mode_i('0)       // (I) Privilege mode (from core. 1=machine mode, 0=user mode)
    );
    //---------------------------------------------------------------------------
    amba_ahb_m2s1 #(.P_NUMM(NUM_MST) // num of masters
                    ,.P_NUMS(NUM_SLV) // num of slaves
                    ,.P_HSEL0_START(P_HSEL0_START),.P_HSEL0_SIZE(P_HSEL0_SIZE)
    ) u_amba_ahb  (
        .HCLK         (clk_i        )
        , .HRESETn      (rst_ni     )
        , .M0_HBUSREQ  (M_HBUSREQ0  )
        , .M0_HGRANT   (M_HGRANT0   )
        , .M0_HADDR    (M_HADDR0    )
        , .M0_HTRANS   (M_HTRANS0   )
        , .M0_HSIZE    (M_HSIZE0    )
        , .M0_HBURST   (M_HBURST0   )
        , .M0_HPROT    (M_HPROT0    )
        , .M0_HLOCK    (M_HLOCK0    )
        , .M0_HWRITE   (M_HWRITE0   )
        , .M0_HWDATA   (M_HWDATA0   )
        , .M1_HBUSREQ  (M_HBUSREQ1  )
        , .M1_HGRANT   (M_HGRANT1   )
        , .M1_HADDR    (M_HADDR1    )
        , .M1_HTRANS   (M_HTRANS1   )
        , .M1_HSIZE    (M_HSIZE1    )
        , .M1_HBURST   (M_HBURST1   )
        , .M1_HPROT    (M_HPROT1    )
        , .M1_HLOCK    (M_HLOCK1    )
        , .M1_HWRITE   (M_HWRITE1   )
        , .M1_HWDATA   (M_HWDATA1   )
        , .M_HRDATA    (M_HRDATA    )
        , .M_HRESP     (M_HRESP     )
        , .M_HREADY    (M_HREADY    )
        , .S_HADDR     (S_HADDR     )
        , .S_HWRITE    (S_HWRITE    )
        , .S_HTRANS    (S_HTRANS    )
        , .S_HSIZE     (S_HSIZE     )
        , .S_HBURST    (S_HBURST    )
        , .S_HWDATA    (S_HWDATA    )
        , .S_HPROT     (S_HPROT     )
        , .S_HREADY    (S_HREADY    )
        , .S_HMASTER   (S_HMASTER   )
        , .S_HMASTLOCK (S_HMASTLOCK )
        , .S0_HSEL     (S_HSEL0     )
        , .S0_HREADY   (S_HREADYout0)
        , .S0_HRESP    (S_HRESP0    )
        , .S0_HRDATA   (S_HRDATA0   )
        , .S0_HSPLIT   (32'h0       )
        , .REMAP       (1'b0        )
    );
    
    //---------------------------------------------------------------------------
    mem_ahb #(.P_SLV_ID(0)
        ,.P_SIZE_IN_BYTES(`SIZE_IN_BYTES)
        ,.P_DELAY(`MEM_DELAY)
    ) u_mem_ahb (
        .HRESETn   (rst_ni  )
        , .HCLK      (clk_i     )
        , .HADDR     (S_HADDR  )
        , .HTRANS    (S_HTRANS )
        , .HWRITE    (S_HWRITE )
        , .HSIZE     (S_HSIZE  )
        , .HBURST    (S_HBURST )
        , .HWDATA    (S_HWDATA )
        , .HSEL      (S_HSEL0       )
        , .HRDATA    (S_HRDATA0     )
        , .HRESP     (S_HRESP0      )
        , .HREADYin  (S_HREADY      )
        , .HREADYout (S_HREADYout0  )
    );


endmodule // cv32e40p_tb_wrapper
