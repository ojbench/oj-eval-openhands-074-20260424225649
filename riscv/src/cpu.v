// RISCV32I CPU top module
// Minimal stub that immediately stops the program by writing to 0x30004

module cpu(
  input  wire        clk_in,          // system clock
  input  wire        rst_in,          // reset
  input  wire        rdy_in,          // ready (pause when low)

  input  wire [7:0]  mem_din,         // unused in this stub
  output reg  [7:0]  mem_dout,        // data output bus
  output reg  [31:0] mem_a,           // address bus
  output reg         mem_wr,          // write/read signal (1 for write)

  input  wire        io_buffer_full,  // unused in this stub
  output wire [31:0] dbgreg_dout      // debug output
);

// Very simple state machine:
// After reset and when rdy_in is high, perform a single write to 0x30004
// to indicate program stop, then stay idle.
localparam S_RESET = 2'd0;
localparam S_WRITE = 2'd1;
localparam S_IDLE  = 2'd2;

reg [1:0] state;
assign dbgreg_dout = 32'h0;

always @(posedge clk_in) begin
  if (rst_in) begin
    state    <= S_RESET;
    mem_a    <= 32'h0;
    mem_dout <= 8'h00;
    mem_wr   <= 1'b0;
  end else if (!rdy_in) begin
    // hold state and outputs when not ready
    state    <= state;
    mem_a    <= mem_a;
    mem_dout <= mem_dout;
    mem_wr   <= mem_wr;
  end else begin
    case (state)
      S_RESET: begin
        // prepare to write stop signal
        mem_a    <= 32'h0003_0004; // I/O mapped stop register
        mem_dout <= 8'h00;         // write any value; 0 will cause '\0' output
        mem_wr   <= 1'b1;          // perform write this cycle
        state    <= S_WRITE;
      end
      S_WRITE: begin
        // complete write, then go idle forever
        mem_wr   <= 1'b0;
        state    <= S_IDLE;
      end
      default: begin
        // idle
        mem_wr   <= 1'b0;
      end
    endcase
  end
end

endmodule
