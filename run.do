# =============================================================================
# run.do — Questa/ModelSim build and simulation script
# Usage:  vsim -do run.do
#         vsim -do run.do -g TEST=uart_parity_test
# =============================================================================

# Test name — override from command line with -g TEST=<name>
quietly set TEST "uart_base_test"

# Create and map work library
if {[file exists work]} { vdel -all }
vlib work
vmap work work

# =============================================================================
# Compile RTL
# =============================================================================
vlog -sv -timescale 1ns/1ps \
    +incdir+rtl              \
    rtl/rtl_inc.sv

# =============================================================================
# Compile Testbench (pulls in all TB files via `include)
# =============================================================================
vlog -sv -timescale 1ns/1ps \
    +incdir+tb               \
    +define+UVM_NO_DPI       \
    tb/testbench.sv

# =============================================================================
# Simulate
# =============================================================================
vsim -novopt work.tb_top \
    -sv_lib $env(UVM_HOME)/lib/uvm_dpi \
    +UVM_TESTNAME=$TEST     \
    +UVM_VERBOSITY=UVM_LOW  \
    +UVM_NO_RELNOTES

run -all
quit -f
