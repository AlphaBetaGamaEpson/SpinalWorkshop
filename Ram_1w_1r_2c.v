// Generator : SpinalHDL v1.4.3    git head : adf552d8f500e7419fff395b7049228e4bc5de26
// Component : Ram_1w_1r_2c
// Git hash  : 8881c15f7ecf53f2d3302b3f3d7dfe4c90373a98



module Ram_1w_1r_2c (
  input               io_wr_en,
  input      [3:0]    io_wr_addr,
  input      [7:0]    io_wr_data,
  input               io_rd_en,
  input      [3:0]    io_rd_addr,
  output     [7:0]    io_rd_data,
  input               io_wr_clk,
  input               io_wr_reset,
  input               io_rd_clk,
  input               io_rd_reset
);
  reg        [7:0]    _zz_1;
  reg [7:0] mem [0:15];

  always @ (posedge io_wr_clk) begin
    if(io_wr_en) begin
      mem[io_wr_addr] <= io_wr_data;
    end
  end

  always @ (posedge io_rd_clk) begin
    if(io_rd_en) begin
      _zz_1 <= mem[io_rd_addr];
    end
  end

  assign io_rd_data = _zz_1;

endmodule
