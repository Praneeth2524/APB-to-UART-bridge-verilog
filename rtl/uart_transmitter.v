`timescale 1ns/1ps

module uart_transmitter #(
    parameter integer CLKS_PER_BIT = 217
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] tx_data,
    input  wire       tx_write,
    output reg        serial_out,
    output reg        tx_busy
);

localparam IDLE  = 2'd0;
localparam START = 2'd1;
localparam SEND  = 2'd2;
localparam STOP  = 2'd3;

reg [1:0]  state;
reg [15:0] clk_count; // 16-bit to support various baud rates safely
reg [2:0]  bit_index;
reg [7:0]  data_buf;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state      <= IDLE;
        clk_count  <= 16'd0;
        bit_index  <= 3'd0;
        data_buf   <= 8'd0;
        serial_out <= 1'b1; // UART line is pulled high when idle
        tx_busy    <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                serial_out <= 1'b1;
                clk_count  <= 16'd0;
                bit_index  <= 3'd0;

                // Latch input data and start transmission on write pulse
                if (tx_write) begin
                    data_buf <= tx_data;
                    tx_busy  <= 1'b1;
                    state    <= START;
                end else begin
                    tx_busy  <= 1'b0;
                end
            end

            START: begin
                // Pull line low for one bit period to signal start bit
                serial_out <= 1'b0;

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 16'd0;
                    state     <= SEND;
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            SEND: begin
                // Shift out data LSB first
                serial_out <= data_buf[bit_index];

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 16'd0;

                    if (bit_index == 3'd7) begin
                        bit_index <= 3'd0;
                        state     <= STOP;
                    end else begin
                        bit_index <= bit_index + 1'b1;
                    end
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            STOP: begin
                // Pull line high for stop bit
                serial_out <= 1'b1;

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 16'd0;
                    tx_busy   <= 1'b0; // Frame complete, ready for next byte
                    state     <= IDLE;
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule