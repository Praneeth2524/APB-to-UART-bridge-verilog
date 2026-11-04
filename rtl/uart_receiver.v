`timescale 1ns/1ps

module uart_receiver #(
    parameter integer CLKS_PER_BIT = 217
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       serial_in,
    output reg  [7:0] data_out,
    output reg        data_ready
);

localparam IDLE  = 2'd0;
localparam START = 2'd1;
localparam RECV  = 2'd2;
localparam STOP  = 2'd3;

reg [1:0]  state;
reg [15:0] clk_count;
reg [2:0]  bit_index;
reg [7:0]  data_buf;

reg rx_meta;
reg rx_sync;

// 2-stage synchronizer to prevent metastability on async serial input
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_meta <= 1'b1; // Default to idle high on reset
        rx_sync <= 1'b1;
    end else begin
        rx_meta <= serial_in;
        rx_sync <= rx_meta;
    end
end

// UART Receiver FSM
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state      <= IDLE;
        clk_count  <= 16'd0;
        bit_index  <= 3'd0;
        data_buf   <= 8'd0;
        data_out   <= 8'd0;
        data_ready <= 1'b0;
    end else begin
        data_ready <= 1'b0; // Default to 0; pulses high for 1 cycle in STOP

        case (state)
            IDLE: begin
                clk_count <= 16'd0;
                bit_index <= 3'd0;

                // Detect falling edge of start bit
                if (rx_sync == 1'b0)
                    state <= START;
            end

            START: begin
                // Sample at the middle of the start bit to verify it isn't noise
                if (clk_count == (CLKS_PER_BIT >> 1)) begin
                    clk_count <= 16'd0;

                    if (rx_sync == 1'b0)
                        state <= RECV;
                    else
                        state <= IDLE;
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            RECV: begin
                // Wait one full bit period to sample the middle of the next data bit
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 16'd0;
                    data_buf[bit_index] <= rx_sync; // LSB first

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
                // Wait for the middle of the stop bit before flagging data_ready
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count  <= 16'd0;
                    data_out   <= data_buf;
                    data_ready <= 1'b1;
                    state      <= IDLE;
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule