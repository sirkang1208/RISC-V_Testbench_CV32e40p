//------------------------------------------------------------------------------
// top.v generated by "gen_ahb_top.sh"
//------------------------------------------------------------------------------
`timescale 1ns/10ps
`ifndef CLK_FREQ
`define CLK_FREQ       50000000
`endif
`ifndef BUS_DELAY
`define BUS_DELAY #(1)
`endif
`ifndef MEM_DELAY
`define MEM_DELAY 0
`endif
`ifndef SIZE_IN_BYTES
`define SIZE_IN_BYTES 1024
`endif

module top(
   input logic HCLK,
   input logic HRESETn
);
   //---------------------------------------------------------------------------
   localparam NUM_MST=1
            , NUM_SLV=2;
   //---------------------------------------------------------------------------
   localparam  P_HSEL0_START=32'h0,P_HSEL0_SIZE=32'h400;
   localparam  P_HSEL1_START=32'h400,P_HSEL1_SIZE=32'h400;
   //---------------------------------------------------------------------------
   wire [NUM_MST-1:0] `BUS_DELAY M_HBUSREQ ;
   wire [NUM_MST-1:0] `BUS_DELAY M_HGRANT  ;
   wire [31:0]        `BUS_DELAY M_HADDR   ;
   wire [ 3:0]        `BUS_DELAY M_HPROT   ;
   wire               `BUS_DELAY M_HLOCK   ;
   wire [ 1:0]        `BUS_DELAY M_HTRANS  ;
   wire               `BUS_DELAY M_HWRITE  ;
   wire [ 2:0]        `BUS_DELAY M_HSIZE   ;
   wire [ 2:0]        `BUS_DELAY M_HBURST  ;
   wire [31:0]        `BUS_DELAY M_HWDATA  ;
   wire [31:0]        `BUS_DELAY M_HRDATA  ;
   wire [ 1:0]        `BUS_DELAY M_HRESP   ;
   wire               `BUS_DELAY M_HREADY  ;
   //---------------------------------------------------------------------------
   wire [31:0]        `BUS_DELAY S_HADDR    ;
   wire [ 3:0]        `BUS_DELAY S_HPROT    ;
   wire [ 1:0]        `BUS_DELAY S_HTRANS   ;
   wire               `BUS_DELAY S_HWRITE   ;
   wire [ 2:0]        `BUS_DELAY S_HSIZE    ;
   wire [ 2:0]        `BUS_DELAY S_HBURST   ;
   wire [31:0]        `BUS_DELAY S_HWDATA   ;
   wire [31:0]        `BUS_DELAY S_HRDATA [0:NUM_SLV-1];
   wire [ 1:0]        `BUS_DELAY S_HRESP  [0:NUM_SLV-1];
   wire               `BUS_DELAY S_HREADY   ;
   wire               `BUS_DELAY S_HREADYout[0:NUM_SLV-1];
   wire [15:0]        `BUS_DELAY S_HSPLIT   [0:NUM_SLV-1];
   wire [NUM_SLV-1:0] `BUS_DELAY S_HSEL     ;
   wire [ 3:0]        `BUS_DELAY S_HMASTER  ;
   wire               `BUS_DELAY S_HMASTLOCK;
   //---------------------------------------------------------------------------
   logic trans_valid;
   logic trans_ready;
   logic [31:0] trans_addr;
   logic trans_we;
   logic [3:0] trans_be;
   logic [31:0] trans_wdata;
   logic [5:0] trans_atop;

   logic resp_valid;
   logic [31:0] resp_rdata;
   logic resp_err;  // Unused for now

   logic data_req_o;
   logic data_gnt_i;
   logic data_addr_o;
   logic data_we_o;
   logic data_be_o;
   logic data_wdata_o;
   logic data_atop_o;/ Not (yet) defined in OBI 1.0 spec
   logic data_rdata_i;
   logic data_rvalid_i;
   logic data_err_i  // External bus error (validity defined by obi_rvalid_i)

   wire trace_valid;
   wire [35:0] trace_data;
	reg [31:0] irq = 0;


       // testbench result
   logic                   tests_passed;
   logic                   tests_failed;
   logic                   exit_valid;
   logic [31:0]            exit_value;

   // signals for ri5cy
   logic                   fetch_enable;

   // make the core start fetching instruction immediately
   assign fetch_enable = '1;
   //---------------------------------------------------------------------------

   cv32e40p_tb_wrapper #(
      .INSTR_RDATA_WIDTH (INSTR_RDATA_WIDTH),
      .RAM_ADDR_WIDTH    (RAM_ADDR_WIDTH),
      .BOOT_ADDR         (BOOT_ADDR)
   )
   cv32e40p_tb_wrapper_i(
      .clk_i          ( core_clk     ),
      .rst_ni         ( core_rst_n   ),
      .fetch_enable_i ( fetch_enable ),
      .tests_passed_o ( tests_passed ),
      .tests_failed_o ( tests_failed ),
      .exit_valid_o   ( exit_valid   ),
      .exit_value_o   ( exit_value   )
   );

   cv32e40p_obi_interface #(
      .TRANS_STABLE(1)
   ) u_obi_interface (
      .clk           (HCLK),
      .rst_n         (HRESETn),

      .trans_valid_i (trans_valid),
      .trans_ready_o (trans_ready),
      .trans_addr_i  (trans_addr),
      .trans_we_i    (trans_we),
      .trans_be_i    (trans_be),
      .trans_wdata_i (trans_wdata),
      .trans_atop_i  (trans_atop),

      .resp_valid_o  (resp_valid),
      .resp_rdata_o  (resp_rdata),
      .resp_err_o    (resp_err),  // Unused for now

      .obi_req_o     (data_req_o),
      .obi_gnt_i     (data_gnt_i),
      .obi_addr_o    (data_addr_o),
      .obi_we_o      (data_we_o),
      .obi_be_o      (data_be_o),
      .obi_wdata_o   (data_wdata_o),
      .obi_rdata_i   (data_rdata_i),
      .obi_rvalid_i  (data_rvalid_i),
      .obi_err_i     (data_err_i)  // External bus error (validity defined by obi_rvalid_i)
      .obi_atop_o    (data_atop_o),  // Not (yet) defined in OBI 1.0 spec
   );

   //---------------------------------------------------------------------------

   obi2ahbm_adapter u_obi_ahb_bridge
   (
      .hclk_i        (HCLK),                // (I) AHB clock
      .hresetn_i     (HRESETn),            // (I) AHB reset, active LOW
   
   // AHB master interface
      .haddr_o       (M_HADDR),        // (O) 32-bit AHB system address bus
      .hburst_o      (M_HBURST),       // (O) Burst type 
      .hmastlock_o   (M_HLOCK),    // (O) Sequence lock
      .hprot_o       (M_HPROT),        // (O) Protection control
      .hsize_o       (M_HSIZE),        // (O) Transfer size
      .htrans_o      (M_HTRANS),       // (O) Transfer type
      .hwdata_o      (M_HWDATA),       // (O) 32-bit AHB write data bus
      .hwrite_o      (M_HWRITE),       // (O) Transfer direction
      .hrdata_i      (M_HRDATA),       // (I) 32-bit AHB read data bus
      .hready_i      (M_HREADY),       // (I) Status of transfer
      .hresp_i       (M_HRESP),        // (I) Transfer response
   
   // Data interface from core
      .data_req_i    (data_req_o),     // (I) Request ready
      .data_gnt_o    (data_gnt_i),     // (O) The other side accepted the request
      .data_addr_i   (data_addr_o),    // (I) Address
      .data_we_i     (data_we_o),      // (I) Write enable (active HIGH)
      .data_be_i     (data_be_o),      // (I) Byte enable
      .data_wdata_i  (data_wdata_o),   // (I) Write data
      .data_rdata_o  (data_rdata_i),   // (O) Read data
      .data_rvalid_o (data_rvalid_i),  // (O) Read data valid when high
      .data_err_o    (data_err_i),     // (O) Error
      .pending_dbus_xfer_i(), // (I) Asserted if data bus is busy from other transactions

   // Miscellaneous
      .priv_mode_i()       // (I) Privilege mode (from core. 1=machine mode, 0=user mode)
   );
//---------------------------------------------------------------------------
   amba_ahb_m1s2 #(.P_NUMM(NUM_MST) // num of masters
                  ,.P_NUMS(NUM_SLV) // num of slaves
                  ,.P_HSEL0_START(P_HSEL0_START),.P_HSEL0_SIZE(P_HSEL0_SIZE)
                  ,.P_HSEL1_START(P_HSEL1_START),.P_HSEL1_SIZE(P_HSEL1_SIZE)
           )
   u_amba_ahb  (
        .HRESETn      (HRESETn     )
      , .HCLK         (HCLK        )
      , .M0_HBUSREQ  (M_HBUSREQ    )
      , .M0_HGRANT   (M_HGRANT     )
      , .M0_HADDR    (M_HADDR      )
      , .M0_HTRANS   (M_HTRANS     )
      , .M0_HSIZE    (M_HSIZE      )
      , .M0_HBURST   (M_HBURST     )
      , .M0_HPROT    (M_HPROT      )
      , .M0_HLOCK    (M_HLOCK      )
      , .M0_HWRITE   (M_HWRITE     )
      , .M0_HWDATA   (M_HWDATA     )
      , .M_HRDATA    (M_HRDATA     )
      , .M_HRESP     (M_HRESP      )
      , .M_HREADY    (M_HREADY     )
      , .S_HADDR     (S_HADDR      )
      , .S_HWRITE    (S_HWRITE     )
      , .S_HTRANS    (S_HTRANS     )
      , .S_HSIZE     (S_HSIZE      )
      , .S_HBURST    (S_HBURST     )
      , .S_HWDATA    (S_HWDATA     )
      , .S_HPROT     (S_HPROT      )
      , .S_HREADY    (S_HREADY     )
      , .S_HMASTER   (S_HMASTER    )
      , .S_HMASTLOCK (S_HMASTLOCK  )
      , .S0_HSEL     (S_HSEL     [0])
      , .S0_HREADY   (S_HREADYout[0])
      , .S0_HRESP    (S_HRESP    [0])
      , .S0_HRDATA   (S_HRDATA   [0])
      , .S0_HSPLIT   (S_HSPLIT   [0])
      , .S1_HSEL     (S_HSEL     [1])
      , .S1_HREADY   (S_HREADYout[1])
      , .S1_HRESP    (S_HRESP    [1])
      , .S1_HRDATA   (S_HRDATA   [1])
      , .S1_HSPLIT   (S_HSPLIT   [1])
      , .REMAP       (1'b0          )
   );
   //---------------------------------------------------------------------------
     // wire [NUM_SLV-1:0] done;
   //---------------------------------------------------------------------------
	mem_ahb #(.P_SLV_ID(0)
		 ,.P_SIZE_IN_BYTES(`SIZE_IN_BYTES)
		 ,.P_DELAY(`MEM_DELAY))
	u_mem_ahb (
	      .HRESETn   (HRESETn  )
	    , .HCLK      (HCLK     )
	    , .HADDR     (S_HADDR  )
	    , .HTRANS    (S_HTRANS )
	    , .HWRITE    (S_HWRITE )
	    , .HSIZE     (S_HSIZE  )
	    , .HBURST    (S_HBURST )
	    , .HWDATA    (S_HWDATA )
	    , .HSEL      (S_HSEL      [0])
	    , .HRDATA    (S_HRDATA    [0])
	    , .HRESP     (S_HRESP     [0])
	    , .HREADYin  (S_HREADY         )
	    , .HREADYout (S_HREADYout [0])
	);
	
     sub_mem_ahb #(.P_SLV_ID(1)
               ,.P_SIZE_IN_BYTES(`SIZE_IN_BYTES)
               ,.P_DELAY(`MEM_DELAY))
     u_sub_mem_ahb (
          .HRESETn   (HRESETn  )
          , .HCLK      (HCLK     )
          , .HADDR     (S_HADDR  )
          , .HTRANS    (S_HTRANS )
          , .HWRITE    (S_HWRITE )
          , .HSIZE     (S_HSIZE  )
          , .HBURST    (S_HBURST )
          , .HWDATA    (S_HWDATA )
          , .HSEL      (S_HSEL      [1])
          , .HRDATA    (S_HRDATA    [1])
          , .HRESP     (S_HRESP     [1])
          , .HREADYin  (S_HREADY         )
          , .HREADYout (S_HREADYout [1])
     );
   //---------------------------------------------------------------------------
//    integer idz;
//    initial begin
//        wait(HRESETn==1'b0);
//        wait(HRESETn==1'b1);
//        for (idz=0; idz<NUM_SLV; idz=idz+1) begin
//             wait(done[idz]==1'b1);
//        end
//        repeat (5) @ (posedge HCLK);
//        $finish(2);
//    end
   //---------------------------------------------------------------------------

	
   //---------------------------------------------------------------------------
   initial begin
      `ifdef VCD
          // use +define+VCD in 'vlog'
          $dumpfile("wave.vcd");
          $dumpvars(0);
      `else
           // use +VCD in 'vsim'
           if ($test$plusargs("VCD")) begin
               $dumpfile("wave.vcd");
               $dumpvars(5);
           end
      `endif
   end
   //---------------------------------------------------------------------------
	integer trace_file;

	initial begin
		if ($test$plusargs("trace")) begin
			trace_file = $fopen("testbench.trace", "w");
			repeat (10) @(posedge HCLK);
			while (!trap) begin
				@(posedge HCLK);
				if (trace_valid)
					$fwrite(trace_file, "%x\n", trace_data);
			end
			$fclose(trace_file);
			$display("Finished writing testbench.trace.");
		end
	end

   // we either load the provided firmware or execute a small test program that
   // doesn't do more than an infinite loop with some I/O
   initial begin: load_prog
      automatic string firmware;
      automatic int prog_size = 6;

      if($value$plusargs("firmware=%s", firmware)) begin
          if($test$plusargs("verbose"))
              $display("[TESTBENCH] @ t=%0t: loading firmware %0s",
                       $time, firmware);
          $readmemh(firmware, cv32e40p_tb_wrapper_i.ram_i.dp_ram_i.mem);
      end else begin
          $display("No firmware specified");
          $finish;
      end
   end

endmodule