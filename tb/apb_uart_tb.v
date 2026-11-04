`timescale 1ns/1ps

module apb_uart_tb;

reg         clk = 0;
reg         rst_n;
reg  [31:0] PADDR;
reg  [31:0] PWDATA;
reg         PWRITE;
reg         PSEL;
reg         PENABLE;
wire [31:0] PRDATA;
wire        PREADY;

apb_uart_top dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .PADDR   (PADDR),
    .PWDATA  (PWDATA),
    .PWRITE  (PWRITE),
    .PSEL    (PSEL),
    .PENABLE (PENABLE),
    .PRDATA  (PRDATA),
    .PREADY  (PREADY)
);

// Generate 50 MHz clock (20ns period)
always #10 clk = ~clk;

initial begin
    rst_n   = 0;
    PADDR   = 0;
    PWDATA  = 0;
    PWRITE  = 0;
    PSEL    = 0;
    PENABLE = 0;

    #100;
    rst_n = 1;

    // --- First Transfer ---
    // Write 0xA5 to TX register
    apb_write(32'h00, 32'hA5);

    // Wait for UART serial transmission to finish (~3200ns)
    #3500;

    // Check STATUS register (should show rx_ready = 1)
    apb_read(32'h08);

    // Read RX register (retrieves 0xA5 and clears rx_ready)
    apb_read(32'h04);


    // --- Second Transfer ---
    // Write 0x3C to TX register
    apb_write(32'h00, 32'h3C);

    // Wait for UART serial transmission to finish
    #3500;

    // Check STATUS register and read RX register
    apb_read(32'h08);
    apb_read(32'h04);

    #100;
    $finish;
end

// APB Write Task
task apb_write(input [31:0] addr, input [31:0] data);
begin
    @(posedge clk);
    PADDR   = addr;
    PWDATA  = data;
    PWRITE  = 1;
    PSEL    = 1;
    PENABLE = 0;

    @(posedge clk);
    PENABLE = 1;

    @(posedge clk);
    PSEL    = 0;
    PENABLE = 0;
    $display("APB WRITE : ADDR=%h DATA=%h", addr, data);
end
endtask

// APB Read Task
task apb_read(input [31:0] addr);
begin
    @(posedge clk);
    PADDR   = addr;
    PWRITE  = 0;
    PSEL    = 1;
    PENABLE = 0;

    @(posedge clk);
    PENABLE = 1;

    @(posedge clk);
    @(posedge clk);

    $display("APB READ  : ADDR=%h DATA=%h", addr, PRDATA);

    PSEL    = 0;
    PENABLE = 0;
end
endtask

initial begin
    $dumpfile("apb_uart_dump.vcd");
    $dumpvars();
end

endmodule