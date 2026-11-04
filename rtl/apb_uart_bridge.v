`timescale 1ns/1ps

module apb_uart_bridge (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [31:0] PADDR,
    input  wire [31:0] PWDATA,
    input  wire        PWRITE,
    input  wire        PSEL,
    input  wire        PENABLE,

    output reg  [31:0] PRDATA,
    output reg         PREADY
);

reg  [7:0] tx_data;
reg        tx_write;

wire [7:0] rx_data;
wire       rx_ready_pulse;
wire       tx_busy;

// Sticky status bit to hold rx_ready until the CPU reads the RX register
reg        rx_ready_flag;

uart #(
    .CLKS_PER_BIT(16)
) uart_inst (
    .clk      (clk),
    .rst_n    (rst_n),
    .tx_data  (tx_data),
    .tx_write (tx_write),
    .rx_data  (rx_data),
    .rx_ready (rx_ready_pulse),
    .tx_busy  (tx_busy)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        PREADY        <= 1'b0;
        PRDATA        <= 32'h0;
        tx_data       <= 8'h00;
        tx_write      <= 1'b0;
        rx_ready_flag <= 1'b0;
    end else begin
        // Default single-cycle pulses to 0
        PREADY   <= 1'b0;
        tx_write <= 1'b0;

        // Latch the single-cycle pulse from the UART receiver
        if (rx_ready_pulse)
            rx_ready_flag <= 1'b1;

        // Handle APB access phase
        if (PSEL && PENABLE) begin
            PREADY <= 1'b1;

            if (PWRITE) begin
                case (PADDR[7:0])
                    8'h00: begin
                        // Only trigger a new write if transmitter is idle
                        if (!tx_busy) begin
                            tx_data  <= PWDATA[7:0];
                            tx_write <= 1'b1;
                        end
                    end
                endcase
            end else begin
                case (PADDR[7:0])
                    8'h04: begin
                        PRDATA        <= {24'h0, rx_data};
                        rx_ready_flag <= 1'b0; // Clear sticky flag once read
                    end
                    8'h08: begin
                        PRDATA <= {30'h0, tx_busy, rx_ready_flag};
                    end
                    default: PRDATA <= 32'h0;
                endcase
            end
        end
    end
end

endmodule