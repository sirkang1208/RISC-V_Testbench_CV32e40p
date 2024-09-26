This folder is for Modified Testbench for CV32e40p

I use an OBI2AHB adapter(bridge) to connect with AHB Bus and CV32e40p

But, the Bridge is built for AHB-lite which has only 1 master

So, HBUSREQ signal for Arbiter must be implemented

Keep this in todo list


Modified parts between Original_CV32e40p_Testbench

- dhrystone.hex format modified
	AHB Mem format is different from CV32e40p mem format	
	can modify hexfile by executing modify.py

- OBI2AHB_adapter added for connecting bridge
	in cv32e40p/rtl, 2 obi2ahb_adapter exist
	one is for instruction, one is for data
	original obi2ahb_adapter.sv file is in obi2abh_adapter/

- 2 Master is needed for the Project
	adapter doesn't support instruction and data at the same time
	So, each adapter is needed
	Instruction adapter doesn't need write operation, so some signal tied to 0 or 1
