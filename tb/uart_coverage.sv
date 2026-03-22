`ifndef UART_COVERAGE_SV
`define UART_COVERAGE_SV

class uart_coverage extends uvm_subscriber#(uart_seq_item);
    `uvm_component_utils(uart_coverage)

    uart_seq_item item;

    covergroup uart_cg;
        option.per_instance = 1;
        option.comment = "UART Functional Coverage";

        cp_direction: coverpoint item.direction {
            bins tx = {UART_DIR_TX};
            bins rx = {UART_DIR_RX};
        }

        cp_data: coverpoint item.data {
            bins zero   = {8'h00};
            bins low    = {[8'h01 : 8'h3F]};
            bins mid    = {[8'h40 : 8'hBF]};
            bins high   = {[8'hC0 : 8'hFE]};
            bins all_1s = {8'hFF};
        }

        cp_packet_width: coverpoint item.packet_width {
            bins width_5bit = {2'b00};
            bins width_6bit = {2'b01};
            bins width_7bit = {2'b10};
            bins width_8bit = {2'b11};
        }

        cp_parity_en: coverpoint item.parity_en {
            bins disabled = {0};
            bins enabled  = {1};
        }

        cp_parity_error: coverpoint item.parity_error {
            bins no_error = {0};
            bins error    = {1};
        }

        cp_frame_error: coverpoint item.frame_error {
            bins no_error = {0};
            bins error    = {1};
        }

        cross_dir_data: cross cp_direction, cp_data;
        cross_width_parity: cross cp_packet_width, cp_parity_en;
        cross_parity_error: cross cp_parity_en, cp_parity_error {
            ignore_bins no_parity_err = binsof(cp_parity_en.disabled) && binsof(cp_parity_error.error);
        }
    endgroup

    function new(string name = "uart_coverage", uvm_component parent = null);
        super.new(name, parent);
        uart_cg = new();
    endfunction

    virtual function void write(uart_seq_item t);
        item = t;
        uart_cg.sample();
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info("UART_COV", $sformatf("%s Functional Coverage: %0.2f%%", get_name(), uart_cg.get_inst_coverage()), UVM_LOW)
    endfunction

endclass

`endif // UART_COVERAGE_SV
