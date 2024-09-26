`timescale 1 ns / 1 ps

`ifndef VERILATOR
module testbench
    #(parameter INSTR_RDATA_WIDTH = 128,    //Memory setting, can be changed
      parameter RAM_ADDR_WIDTH = 22,        //Memory setting, can be changed
      parameter BOOT_ADDR  = 'h80           //Memory setting, can be changed
      parameter AXI_TEST = 0,               //AXI4 memory setting
      parameter VERBOSE = 0,
      parameter TAG = 1)                //AXI4 memory setting
    (
    input logic clk_i = 1,
    input logic rstn_i = 0,
	input logic tests_passed_o,
    input logic tests_failed_o
    );
    
    int unsigned            cycle_cnt_q;

    logic                   exit_valid;
    logic [31:0]            exit_value;


	always #5 clk_i = ~clk_i;

	initial begin
		repeat (100) @(posedge clk_i);
		rstn_i <= 1;
	end

    // logic counter;

    // always_ff@(posedge clk_i) begin
    //     counter = counter + 1;
    //     if(counter % 100 == 0) begin
    //         $display("time ++ ");
    //     end
    // end
    
    always_ff@(posedge clk_i, negedge rstn_i) begin
        automatic int maxcycle = 10000000;                  //can be modified
    
        if($value$plusargs("maxcycle =%d", maxcycle)) begin
            if(~rstn_i) begin
                cycle_cnt_q <= 0;
            end
            else begin
                cycle_cnt_q <= cycle_cnt_q+1;
                if(cycle_cnt_q >= maxcycle) begin
                    $finish("cycle exceed the limit, simuation aborted");
                end
            end
        end
    end

    top u_top (
		.HCLK(clk_i),
		.HRESETn(rstn_i),
	);
endmodule
`endif