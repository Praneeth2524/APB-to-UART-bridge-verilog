# APB to UART Bridge in Verilog

## Overview
This project implements an AMBA APB (Advanced Peripheral Bus) to UART (Universal Asynchronous Receiver-Transmitter) bridge in Verilog. It allows a processor or master interface to send and receive serial data using standard 32-bit APB read and write transactions. For easy verification, the UART module is configured in an internal loopback mode where the transmitter output is connected directly to the receiver input.

## Features
* **AMBA APB Slave Interface:** Supports standard APB signals (`PADDR`, `PWDATA`, `PWRITE`, `PSEL`, `PENABLE`, `PRDATA`, `PREADY`) with single-cycle access completion.
* **UART Transmitter and Receiver:** Uses finite state machines (FSM) for 8-bit serial communication (1 start bit, 8 data bits LSB-first, 1 stop bit, no parity).
* **Configurable Baud Rate:** Uses the `CLKS_PER_BIT` parameter to control bit timing (set to 16 clocks per bit in simulation for fast execution).
* **Metastability Protection:** Includes a 2-stage flip-flop synchronizer on the asynchronous serial input (`serial_in`) in the receiver.
* **Sticky Status Flag:** Holds the `rx_ready` status bit high until the processor reads the RX data register, ensuring no received byte is missed.

## Register Map
The bridge uses the lower 8 bits of the address (`PADDR[7:0]`) to access three memory-mapped registers:

| Address Offset | Register Name | Access | Description |
| :--- | :--- | :--- | :--- |
| `0x00` | TX Data Register | Write-Only | Writes an 8-bit byte (`PWDATA[7:0]`) to the UART transmitter if `tx_busy` is 0. |
| `0x04` | RX Data Register | Read-Only | Reads the 8-bit received byte (`PRDATA[7:0]`) and clears the `rx_ready` flag. |
| `0x08` | Status Register | Read-Only | Bit 0: `rx_ready_flag` (1 = data ready to read). Bit 1: `tx_busy` (1 = transmitter busy). |

## Project File Structure
* `apb_uart_top.v`: Top-level wrapper module connecting the APB signals to the bridge.
* `apb_uart_bridge.v`: Handles APB protocol decoding, register read/write logic, and status flag management.
* `uart.v`: Instantiates the transmitter and receiver and connects them via an internal loopback wire (`serial_line`).
* `uart_transmitter.v`: Parallel-to-serial state machine that shifts out the start bit, 8 data bits, and stop bit.
* `uart_receiver.v`: Serial-to-parallel state machine that samples incoming bits at the middle of each bit period.
* `apb_uart_tb.v`: Testbench that runs APB write and read tasks at a 50 MHz clock to verify serial loopback transfers.

## How the Testbench Works
The testbench (`apb_uart_tb.v`) verifies the design using two serial transfers:
1. **Reset:** Initializes all signals and applies an active-low reset (`rst_n`).
2. **First Transfer (`0xA5`):** Writes `0xA5` to address `0x00` (TX register), waits 3500 ns for the serial loopback transfer to complete, reads address `0x08` (Status register) to verify `rx_ready` is `1`, and reads address `0x04` (RX register) to confirm `0xA5` was received.
3. **Second Transfer (`0x3C`):** Writes `0x3C` to address `0x00`, waits 3500 ns, checks the status register at `0x08`, and reads `0x3C` back from `0x04`.

## How to Run the Simulation
You can compile and simulate this project using Icarus Verilog (`iverilog`) and view the signals in GTKWave.

If all files are in separated `rtl/` and `tb/` folders:
```bash
iverilog -o apb_uart_sim rtl/*.v tb/apb_uart_tb.v
vvp apb_uart_sim
gtkwave apb_uart_dump.vcd
