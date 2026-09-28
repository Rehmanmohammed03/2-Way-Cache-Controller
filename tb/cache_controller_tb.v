// cache_controller_tb.v
// basic directed test: write a few lines, read them back with the
// right and wrong tags, and check what happens with chip_enable low.
// inputs change on the falling edge side (clk rises at 5, 15, 25...)
// so there's no race with the posedge logic.

module tb_cache_controller;
	reg clk;
	reg reset;
	reg chip_enable;
	reg write_enable;
	reg way_select;
	reg [3:0] tag;
	reg [31:0] data_in;
	reg set;
	wire [31:0] data_out;
	wire hit;
	wire miss;
	wire valid;

	cache_controller uut (
		.clk(clk),
		.reset(reset),
		.chip_enable(chip_enable),
		.write_enable(write_enable),
		.way_select(way_select),
		.tag(tag),
		.data_in(data_in),
		.set(set),
		.data_out(data_out),
		.hit(hit),
		.miss(miss),
		.valid(valid)
	);

	// 10ns clock
	always #5 clk = ~clk;

	initial begin
		clk = 0;
		reset = 1;
		chip_enable = 0;
		write_enable = 0;
		way_select = 0;
		tag = 0;
		data_in = 0;
		set = 0;
		// hold reset for two edges
		#20;
		reset = 0;
		chip_enable = 1;

		// nothing written yet, should miss
		#10;
		$display("Empty read set0    : hit=%b miss=%b valid=%b data=%h", hit, miss, valid, data_out);

		// putting values in way0 set0, tag 3
		write_enable = 1;
		way_select = 0;
		set = 0;
		tag = 4'h3;
		data_in = 32'h5AA9A645;
		#10;

		// read it back
		write_enable = 0;
		#10;
		$display("Way0 correct tag   : hit=%b miss=%b valid=%b data=%h", hit, miss, valid, data_out);

		// same set, tag that isn't stored anywhere
		tag = 4'h5;
		#10;
		$display("Way0 wrong tag     : hit=%b miss=%b valid=%b data=%h", hit, miss, valid, data_out);

		// filling way1 of same set with a different tag/data
		write_enable = 1;
		way_select = 1;
		tag = 4'h7;
		data_in = 32'h11978104;
		#10;
		write_enable = 0;
		#10;
		$display("Way1 correct tag   : hit=%b miss=%b valid=%b data=%h", hit, miss, valid, data_out);

		// way0, but in set 1 this time
		write_enable = 1;
		way_select = 0;
		set = 1;
		tag = 4'h1;
		data_in = 32'hFEDEFA7F;
		#10;
		write_enable = 0;
		#10;
		$display("Set1 Way0 hit      : hit=%b miss=%b valid=%b data=%h", hit, miss, valid, data_out);

		tag = 4'h2;
		#10;
		$display("Set1 wrong tag     : hit=%b miss=%b valid=%b data=%h", hit, miss, valid, data_out);

		// make sure the set1 write didn't clobber set0
		set = 0;
		tag = 4'h3;
		#10;
		$display("Set0 Way0 recheck  : hit=%b miss=%b valid=%b data=%h", hit, miss, valid, data_out);

		// flags should all drop
		chip_enable = 0;
		#10;
		$display("Chip disabled      : hit=%b miss=%b valid=%b", hit, miss, valid);
		$finish;
	end
endmodule
