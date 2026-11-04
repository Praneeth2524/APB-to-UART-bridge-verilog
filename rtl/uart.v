`timescale 1ns/1ps

module uart #(
    parameter integer CLKS_PER_BIT = 16 // Set to 16 for fast simulation
)(
    input  wire       clk,
    input  wire       rst_n,

    input  wire [7:0] tx_data,
    input  wire       tx_write,

    output wire [7:0] rx_data,
    output wire       rx_ready,
    output wire       tx_busy
);

// Internal serial line connecting TX to RX for self-contained loopback testing
wire serial_line;

uart_transmitter #(
    .CLKS_PER_BIT(CLKS_PER_BIT)
) u_tx (
    .clk        (clk),
    .rst_n      (rst_n),
    .tx_data    (tx_data),
    .tx_write   (tx_write),
    .serial_out (serial_line),
    .tx_busy    (tx_busy)
);

uart_receiver #(
    .CLKS_PER_BIT(CLKS_PER_BIT)
) u_rx (
    .clk        (clk),
    .rst_n      (rst_n),
    .serial_in  (serial_line),
    .data_out   (rx_data),
    .data_ready (rx_ready)
);

endmodule