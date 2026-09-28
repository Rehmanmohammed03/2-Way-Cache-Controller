// cache_controller.v
// 2-way set associative cache, 2 sets, 4-bit tag, 32-bit data.
// each way is its own single_port_sram. both ways get read at the
// same set index and the tags are compared in parallel.
//
// note: there's no replacement policy here, the way to write into
// is picked by the way_select input.

module cache_controller (
	input clk,
	input reset,
	input chip_enable,
	input write_enable,
	input way_select,          // 0 = write way0, 1 = write way1
	input [3:0] tag,
	input [31:0] data_in,
	input set,                 // set index (only 2 sets)
	output reg [31:0] data_out,
	output reg hit,
	output reg miss,
	output reg valid
);
	wire [36:0] way0_data;
	wire [36:0] way1_data;
	wire [36:0] wdata;
	wire w0_we;
	wire w1_we;

	// line format stored in sram: {tag, valid, data}
	// valid is always 1 on a write since we're writing real data
	assign wdata = {tag, 1'b1, data_in};

	// only one way gets the write enable
	assign w0_we = write_enable && (way_select == 1'b0);
	assign w1_we = write_enable && (way_select == 1'b1);

	// split the stored line back into tag / valid / data
	wire [3:0] tag0 = way0_data[36:33];
	wire v0 = way0_data[32];
	wire [31:0] dout0 = way0_data[31:0];

	wire [3:0] tag1 = way1_data[36:33];
	wire v1 = way1_data[32];
	wire [31:0] dout1 = way1_data[31:0];

	// way 0
	single_port_sram WAY0 (
		.clk(clk),
		.reset(reset),
		.chip_enable(chip_enable),
		.write_enable(w0_we),
		.address(set),
		.data_in(wdata),
		.data_out(way0_data)
	);
	// way 1 - same set index and write data, separate write enable
	single_port_sram WAY1 (
		.clk(clk),
		.reset(reset),
		.chip_enable(chip_enable),
		.write_enable(w1_we),
		.address(set),
		.data_in(wdata),
		.data_out(way1_data)
	);

	// lookup. outputs are registered so hit/miss show up one clock
	// after tag/set are applied
	always @(posedge clk) begin
		if (reset) begin
			hit <= 1'b0;
			miss <= 1'b0;
			valid <= 1'b0;
			data_out <= 0;
		end
		else if (chip_enable && !write_enable) begin
			// check way0 first. if both ways somehow hold the same
			// tag, way0 wins
			if (v0 && (tag0 == tag)) begin
				data_out <= dout0;
				hit <= 1'b1;
				miss <= 1'b0;
				valid <= 1'b1;
			end
			else if (v1 && (tag1 == tag)) begin
				data_out <= dout1;
				hit <= 1'b1;
				miss <= 1'b0;
				valid <= 1'b1;
			end
			else begin
				// neither way matched (or the line isn't valid yet)
				data_out <= 0;
				hit <= 1'b0;
				miss <= 1'b1;
				valid <= 1'b0;
			end
		end
		else if (!chip_enable) begin
			// chip off -> clear the flags. data_out keeps its last value
			hit <= 1'b0;
			miss <= 1'b0;
			valid <= 1'b0;
		end
		// during a write cycle the outputs just hold
	end
endmodule
