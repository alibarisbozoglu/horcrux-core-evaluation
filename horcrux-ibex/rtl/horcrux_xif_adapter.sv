// horcrux_xif_adapter: plain-port shell around the unchanged HORCRUX coprocessor (horcrux_top), for Ibex's
// coprocessor port (XifEn, see ibex/rtl/ibex_id_stage.sv after patches/ibex-xif.patch).
//
// horcrux_top speaks CORE-V-XIF (if_xif, X_NUM_RS = 3). This shell owns the interface instance, ties off the
// channels HORCRUX does not use (compressed, memory, commit) and exposes the two it does:
//   issue : issue_valid / issue_ready (combinational from the HORCRUX decoder), 32-bit instruction word,
//           three 32-bit source operands
//   result: result_valid is a one-cycle pulse (HORCRUX has no result_ready), result_data = 32-bit result
// Ibex keeps one coprocessor instruction in flight, so no instruction ids are needed.
module horcrux_xif_adapter (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        issue_valid_i,
  output logic        issue_ready_o,
  input  logic [31:0] issue_instr_i,
  input  logic [31:0] issue_rs1_i,
  input  logic [31:0] issue_rs2_i,
  input  logic [31:0] issue_rs3_i,
  output logic        result_valid_o,
  output logic [31:0] result_data_o
);
  if_xif #(.X_NUM_RS(3)) xif ();

  // unused channels
  assign xif.compressed_valid = 1'b0;
  assign xif.compressed_req   = '0;
  assign xif.commit_valid     = 1'b0;
  assign xif.commit           = '0;
  assign xif.mem_ready        = 1'b0;
  assign xif.mem_resp         = '0;
  assign xif.mem_result_valid = 1'b0;
  assign xif.mem_result       = '0;

  // issue
  assign xif.issue_valid          = issue_valid_i;
  assign xif.issue_req.instr      = issue_instr_i;
  assign xif.issue_req.mode       = 2'b11;
  assign xif.issue_req.id         = '0;
  assign xif.issue_req.rs[0]      = issue_rs1_i;
  assign xif.issue_req.rs[1]      = issue_rs2_i;
  assign xif.issue_req.rs[2]      = issue_rs3_i;
  assign xif.issue_req.rs_valid   = '1;
  assign xif.issue_req.ecs        = '0;
  assign xif.issue_req.ecs_valid  = 1'b1;
  assign issue_ready_o            = xif.issue_ready;

  // result
  assign xif.result_ready = 1'b1;
  assign result_valid_o   = xif.result_valid;
  assign result_data_o    = xif.result.data;

  horcrux_top i_horcrux_top (
    .clk_i             (clk_i),
    .rst_ni            (rst_ni),
    .xif_compressed_if (xif),
    .xif_issue_if      (xif),
    .xif_commit_if     (xif),
    .xif_mem_if        (xif),
    .xif_mem_result_if (xif),
    .xif_result_if     (xif)
  );
endmodule
