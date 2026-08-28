// tt_um_pineapple_one.v -- Tiny Tapeout top level
//
// Pin mapping (v1, no external memory yet):
//   ui_in[7:0]  -> memory-mapped input register at address 0xF4 (switches)
//   uo_out[7:0] -> memory-mapped output register at address 0xF0 (LEDs)
//   uio[7:0]    -> reserved, unused in v1 (all inputs, driven low)
//                  Milestone 2: wire CS/MOSI/MISO/SCK here to talk to
//                  external SPI RAM/flash for real program+data memory,
//                  matching Tiny Tapeout's recommended SPI-RAM pinout.
//
// `ena` is ignored (always active) per TT convention for simple designs.

`default_nettype none

module tt_um_pineapple_one (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire [7:0]  mem_addr;
    wire [31:0] mem_wdata;
    wire [1:0]  mem_size;
    wire        mem_we;
    wire [31:0] mem_rdata;
    wire [7:0]  led_out;

    rv32i_core u_core (
        .clk       (clk),
        .rst_n     (rst_n),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_size  (mem_size),
        .mem_we    (mem_we),
        .mem_rdata (mem_rdata)
    );

    mem u_mem (
        .clk      (clk),
        .rst_n    (rst_n),
        .addr     (mem_addr),
        .wdata    (mem_wdata),
        .size     (mem_size),
        .we       (mem_we),
        .rdata    (mem_rdata),
        .gpio_in  (ui_in),
        .gpio_out (led_out)
    );

    assign uo_out  = led_out;
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;   // all uio pins are inputs (unused) in v1

    // Silence unused-signal lint warnings without affecting synthesis
    wire _unused = &{ena, uio_in, 1'b0};

endmodule
