<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This is a minimal, from-scratch 32-bit RISC-V (RV32I) CPU, inspired by
[Pineapple ONE](https://pineapple-one.github.io/) -- a RISC-V computer
originally built entirely out of discrete 7400-series logic chips
(no FPGA, no microcontroller). This project keeps that "just basic logic"
spirit but reimplements the CPU as synthesizable Verilog sized to fit a
single Tiny Tapeout tile.

It implements the full RV32I base integer instruction set (LUI, AUIPC,
JAL, JALR, all branches, all loads/stores, and all register-register /
register-immediate ALU operations). FENCE/ECALL/EBREAK decode but act
as no-ops -- there's no trap/exception handling in this version.

The core uses a 5-stage multi-cycle FSM (fetch -> decode -> execute ->
memory -> writeback), so every instruction takes 5 clock cycles. This
keeps the design small and easy to reason about, at the cost of speed --
which is fitting, since the original Pineapple ONE ran at 500 kHz too.

Because a Tiny Tapeout tile is far too small for the original design's
512 kB program memory + 512 kB RAM + VGA card, this version uses a much
smaller 256-byte address space:

- `0x00-0x7F`: 128-byte **ROM**, holding the boot program. This is
  implemented as pure combinational logic (a big case statement), not
  flip-flops -- flip-flops don't reliably power up to a known value on
  real silicon, but combinational logic becomes fixed gates at synthesis
  time, so the boot program is guaranteed to be there on every power-on.
- `0x80-0xEF`: 112-byte flip-flop-backed **RAM** for the stack/scratch
  data (contents are undefined until your program writes to them).
- `0xF0`: memory-mapped **LED output register**, wired to `uo_out`.
- `0xF4`: memory-mapped **switch input register**, wired to `ui_in`.

The default boot program is a simple demo: it increments a counter,
masks it to 4 bits, and stores it to the LED register in a loop --
so `uo_out` counts 0 through 15 on repeat.

## How to test

Power up the chip (or run the testbench) and watch `uo_out[3:0]`
(LED0-LED3) count from 0 to 15 and wrap back to 0, incrementing roughly
every 20 clock cycles. `uo_out[7:4]` stay at 0 since the counter is
masked to 4 bits. `ui_in` (the switches) isn't read by the default
program, but is wired up and available for your own programs via the
memory-mapped register at address `0xF4`.

To load a different program: hand-encode your RV32I instructions (see
`tools/asm_encode.py` in the project source for a small Python
encoder/checker -- or use a real RISC-V toolchain for anything longer
than a handful of instructions) and replace the `rom_byte` case
statement in `src/mem.v`.

## External hardware

None required. `uo_out[0:7]` can be connected to LEDs (with series
resistors) to watch the counter directly; `ui_in[0:7]` can be connected
to switches/DIP switches once a program that reads them is loaded.
`uio[0:7]` are currently unused and reserved for a future external SPI
memory interface (to give the core a much larger address space than
the 256 bytes available on-die).
