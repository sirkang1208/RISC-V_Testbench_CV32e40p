###############################################################################
#
# Copyright 2020 OpenHW Group
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://solderpad.org/licenses/
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###############################################################################
#
# Makefile for the CV_CORE "core" testbench.  Substantially modified from the
# Makefile original for the RI5CY testbench.
#
###############################################################################
#
# Copyright 2019 Claire Wolf
# Copyright 2019 Robert Balas
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#
# Original Author: Robert Balas (balasr@iis.ee.ethz.ch)
#
###############################################################################

# "Constants"
MAKE           = make
MAKE_DIR       = $(PWD)
MAKE_PATH     := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
COREV_PROJ     = cv32
CORE_V_VERIF   = $(abspath $(MAKE_PATH))
DATE           = $(shell date +%F)
WAVES          = 0

CV_CORE       ?= CV32E40P
CV_CORE_LC     = $(shell echo $(CV_CORE) | tr A-Z a-z)
CV_CORE_UC     = $(shell echo $(CV_CORE) | tr a-z A-Z)

SIMULATOR     ?= $(CV_SIMULATOR)

# Test-Program directores.
# Relative path is used for Verilator which cannot seem to handle loooong pathnames.
TEST_PROGRAM_PATH    = $(CORE_V_VERIF)/$(CV_CORE_LC)/tests/custom
TEST_PROGRAM_RELPATH = cv32e40p/tests/custom

# Common output directories
RUN_INDEX               ?= 0
SIM_RESULTS              = simulation_results
SIM_TEST_RESULTS         = $(SIM_RESULTS)/$(TEST)
SIM_RUN_RESULTS          = $(SIM_TEST_RESULTS)/$(RUN_INDEX)
SIM_TEST_PROGRAM_RESULTS = $(SIM_RUN_RESULTS)/test_program
SIM_BSP_RESULTS          = $(SIM_TEST_PROGRAM_RESULTS)/bsp

# Compile compile flags for all simulators
SV_CMP_FLAGS =

# Default "custom test-program"
CUSTOM_PROG  ?= requested_csr_por
TEST         ?= dhrystone

###############################################################################
# Generate and include TEST_FLAGS_MAKE, based on the YAML test description.
# An example of what is generated is below (not all of these flags are used):
#       TEST_DESCRIPTION=Simple hello-world sanity test
#       TEST_NAME=hello-world
#       TEST_PROGRAM=hello-world
#       TEST_TEST_DIR=/home/mike/GitHubRepos/MikeOpenHWGroup/core-v-verif/master/cv32e40p/tests/programs/custom/hello-world
#       TEST_UVM_TEST=uvmt_$(CV_CORE_LC)_firmware_test_c

YAML2MAKE = $(CORE_V_VERIF)/bin/yaml2make
TEST_FLAGS_MAKE := $(shell $(YAML2MAKE) --test=$(TEST) --yaml=test.yaml  $(YAML2MAKE_DEBUG) --run-index=$(u) --prefix=TEST --core=$(CV_CORE))
ifeq ($(TEST_FLAGS_MAKE),)
$(error ERROR Could not find test.yaml for test: $(TEST))
endif
include $(TEST_FLAGS_MAKE)

###############################################################################
# Common Makefiles:
#  -Variables for RTL and other dependencies (e.g. RISCV-DV)
include ExternalRepos.mk
#  -Core Firmware and the RISCV GCC Toolchain (SDK)
include $(CORE_V_VERIF)/mk/Common.mk

XRUN              = xrun
XRUN_FLAGS        = -gui -access +rwc -clean -smartorder -sv -top worklib.tb_top -timescale 1ns/1ps +define+CV32E40P_APU_TRACE -uvmhome CDNS-1.2-ML
XRUN_DIR          = xcelium.d

# verilator configuration
VERILATOR           = verilator
VERI_FLAGS         +=
VERI_COMPILE_FLAGS += -Wno-BLKANDNBLK $(SV_CMP_FLAGS) # hope this doesn't hurt us in the long run
VERI_TRACE         ?=
VERI_OBJ_DIR       ?= cobj_dir
#VERI_LOG_DIR       ?= cobj_dir/logs
VERI_LOG_DIR       ?= $(SIM_TEST_PROGRAM_RESULTS)
VERI_CFLAGS        += -O2

# TB source files for the CV32E core
TBSRC_HOME  := $(CORE_V_VERIF)/$(CV_CORE_LC)/tb
TBSRC_TOP   := $(TBSRC_HOME)/core/tb_top.sv
TBSRC_CORE  := $(TBSRC_HOME)/core
TBSRC_PKG   := $(TBSRC_CORE)/tb_riscv/include/perturbation_defines.sv
TBSRC       := $(TBSRC_CORE)/tb_top.sv \
               $(TBSRC_CORE)/cv32e40p_tb_wrapper.sv \
               $(TBSRC_CORE)/mm_ram.sv \
               $(TBSRC_CORE)/dp_ram.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_random_stall.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_random_interrupt_generator.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_rvalid_stall.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_gnt_stall.sv

RTLSRC_VLOG_TB_TOP	:= $(basename $(notdir $(TBSRC_TOP)))
RTLSRC_VOPT_TB_TOP	:= $(addsuffix _vopt, $(RTLSRC_VLOG_TB_TOP))

TBSRC_VERI  := $(TBSRC_CORE)/tb_top_verilator.sv \
               $(TBSRC_CORE)/cv32e40p_tb_wrapper.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_rvalid_stall.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_gnt_stall.sv \
               $(TBSRC_CORE)/mm_ram.sv \
               $(TBSRC_CORE)/dp_ram.sv
SIM_LIBS    := $(CORE_V_VERIF)/lib/sim_libs

# RTL source files for the CV32E core
# DESIGN_RTL_DIR is used by CV_CORE_MANIFEST file
CV_CORE_PKG           := $(CV_CORE_LC)
CV_CORE_RTLSRC_INCDIR := $(CV_CORE_PKG)/rtl/include
CV_CORE_RTLSRC_PKG    := $(CV_CORE_PKG)/rtl/fpnew/src/fpnew_pkg.sv \
				$(addprefix $(CV_CORE_RTLSRC_INCDIR)/,\
				CV_CORE_apu_core_package.sv CV_CORE_defines.sv \
				CV_CORE_tracer_defines.sv)
CV_CORE_RTLSRC  := $(filter-out $(CV_CORE_PKG)/rtl/$(CV_CORE_LC)_register_file_latch.sv, \
                $(wildcard $(CV_CORE_PKG)/rtl/*.sv))
CV_CORE_MANIFEST    := cv32e40p_manifest.flist
export DESIGN_RTL_DIR = $(CV_CORE_PKG)/rtl

# Shorthand rules for convience
CV_CORE_pkg: $(CV_CORE_LC)

tbsrc_pkg: $(TBSRC_PKG)

tbsrc: $(TBSRC)

###############################################################################


.PHONY: hello-world
hello-world: $(SIMULATOR)-hello-world

.PHONY: cv32_riscv_tests
cv32_riscv_tests: $(SIMULATOR)-cv32_riscv_tests

.PHONY: cv32_riscv_tests-gui
cv32_riscv_tests-gui: $(SIMULATOR)-cv32_riscv_tests-gui

.PHONY: cv32_riscv_compliance_tests
cv32_riscv_compliance_tests: $(SIMULATOR)-cv32_riscv_compliance_tests

.PHONY: cv32_riscv_compliance_tests-gui
cv32_riscv_compliance_tests-gui: $(SIMULATOR)-cv32_riscv_compliance_tests-gui

.PHONY: firmware
firmware: $(SIMULATOR)-firmware

.PHONY: firmware-gui
firmware-gui: $(SIMULATOR)-firmware-gui

.PHONY: unit-test
unit-test: $(SIMULATOR)-unit-test

.PHONY: unit-test-gui
unit-test-gui: $(SIMULATOR)-unit-test-gui

# assume verilator if no target chosen
.DEFAULT_GOAL := sanity-veri-run

all: clean_all sanity-veri-run dsim-sanity

###############################################################################
# Cadence Xcelium xrun testbench compilation
.PHONY: xrun-all
xrun-all: $(CV_CORE_PKG) $(RTLSRC_PKG) $(RTLSRC) $(TBSRC_PKG) $(TBSRC)
	$(XRUN) \
		$(XRUN_FLAGS) \
		-f $(CV_CORE_MANIFEST) \
		$(TBSRC_PKG) $(TBSRC) \
		+firmware=$(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex

xrun-custom:
	@echo "This target is depreciated.  Please use 'make xrun-test TEST=<test-program>'"
	@echo "                             Example:   'make xrun-test TEST=fibonacci'"

.PHONY: xrun-test
xrun-test: xrun-all $(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
	$(XRUN) \
		$(XRUN_FLAGS) \
		-f $(CV_CORE_MANIFEST) \
		$(TBSRC_PKG) $(TBSRC) \

# Cadence Xcelium xrun cleanup
.PHONY: xrun-clean xrun-clean-all
xrun-clean:
	rm -vrf $(XRUN_DIR)
	rm -f xrun.history
	rm -f xrun.key
	rm -v xrun.log

xrun-clean-all: xrun-clean
	rm -vrf $(addprefix $(FIRMWARE)/firmware., elf bin hex map) \
		$(FIRMWARE_OBJS) $(FIRMWARE_TEST_OBJS) $(COMPLIANCE_TEST_OBJS)

###############################################################################
# Verilator

# We first test if the user wants to to vcd dumping. This hacky part is required
# because we need to conditionally compile the testbench (-DVCD_TRACE) and pass
# the --trace flags to the verilator call
#ifeq ($(findstring +vcd,$(VERI_FLAGS)),+vcd)

ifneq (${WAVES}, 0)
VERI_TRACE="--trace"
VERI_CFLAGS+="-DVCD_TRACE"
endif

verilate: testbench_verilator

sanity-veri-run:
	make veri-test TEST=$(TEST)

testbench_verilator: CV_CORE_pkg $(TBSRC_VERI) $(TBSRC_PKG)
	@echo "$(BANNER)"
	@echo "* Compiling CORE TB and CV32E40P with Verilator"
	@echo "$(BANNER)"
	$(VERILATOR) --cc --sv --exe \
		$(VERI_TRACE) \
		--Wno-lint --Wno-UNOPTFLAT --Wno-MULTIDRIVEN \
		--Wno-COMBDLY --Wno-MODDUP --top-module \
		tb_top_verilator $(TBSRC_VERI) \
		-f $(CV_CORE_MANIFEST) \
		$(CV_CORE_PKG)/bhv/$(CV_CORE_LC)_core_log.sv \
		$(TBSRC_CORE)/tb_top_verilator.cpp --Mdir $(VERI_OBJ_DIR) \
		-CFLAGS "-std=gnu++17 $(VERI_CFLAGS)" \
		$(VERI_COMPILE_FLAGS)
	$(MAKE) -C $(VERI_OBJ_DIR) -f Vtb_top_verilator.mk
	mkdir -p $(SIM_RESULTS)
	mkdir -p $(SIM_TEST_RESULTS)
	mv $(VERI_OBJ_DIR)/Vtb_top_verilator $(SIM_TEST_RESULTS)/verilator_executable

veri-test: verilate $(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
	@echo "$(BANNER)"
	@echo "* Running with Verilator: logfile in $(SIM_TEST_RESULTS)/$(TEST).log"
	@echo "$(BANNER)"
	mkdir -p $(VERI_LOG_DIR)
	$(SIM_TEST_RESULTS)/verilator_executable \
		$(VERI_FLAGS) \
		"+firmware=$(TEST_PROGRAM_RELPATH)/$(TEST)/$(TEST).hex" \
		| tee $(VERI_LOG_DIR)/$(TEST).log

# verilator specific cleanup
veri-clean: verilate-clean

verilate-clean: tc-clean
	if [ -d $(SIM_RESULTS) ]; then rm -r $(SIM_RESULTS); fi
	if [ -d $(VERI_OBJ_DIR) ]; then rm -r $(VERI_OBJ_DIR); fi
	rm -rf testbench_verilator
	if [ -e memory_dump.bin ]; then rm memory_dump.bin; fi

###############################################################################
# general targets
.PHONY: tc-clean

# clean up simulation results
clean-sim-results:
	rm -rf $(SIM_RESULTS)
	rm -rf cobj_dir

# clean up toolchain generated files
clean-test-programs:
	find $(CORE_V_VERIF)/$(CV_CORE_LC)/tests/ -name *.o       -exec rm {} \;
	find $(CORE_V_VERIF)/$(CV_CORE_LC)/tests/ -name *.hex     -exec rm {} \;
	find $(CORE_V_VERIF)/$(CV_CORE_LC)/tests/ -name *.elf     -exec rm {} \;
	find $(CORE_V_VERIF)/$(CV_CORE_LC)/tests/ -name *.map     -exec rm {} \;
	find $(CORE_V_VERIF)/$(CV_CORE_LC)/tests/ -name *.readelf -exec rm {} \;
	find $(CORE_V_VERIF)/$(CV_CORE_LC)/tests/ -name *.objdump -exec rm {} \;
	find $(CORE_V_VERIF)/$(CV_CORE_LC)/tests/ -name corev_*.S -exec rm {} \;

.PHONY: clean clean_all distclean
clean: clean-sim-results verilate-clean firmware-clean xrun-clean clean-test-programs

distclean: clean
	rm -rf riscv-fesvr riscv-isa-sim $(CV_CORE_PKG) work

clean_all: distclean
#endend
