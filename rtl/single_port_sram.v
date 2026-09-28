// single_port_sram.v
// tiny 2-entry memory used as one "way" of the cache.
// each entry is 37 bits wide: {tag[3:0], valid, data[31:0]}
// writes happen on the clock edge, reads are combinational so the
// controller can compare tags in the same cycle.

module single_port_sram(
	input clk,
	input reset,
	input chip_enable,
	input write_enable,
	input address,              // 1 bit -> picks set 0 or set 1
	input [36:0] data_in,
	output [36:0] data_out
);

// only two sets, so two rows
reg [36:0] memory [0:1];

always @(posedge clk) begin
	if (reset) begin
		// clearing everything also clears the valid bit (bit 32),
		// so after reset every lookup is a miss
		memory[0] <= 0;
		memory[1] <= 0;
	end
	else if (chip_enable && write_enable) begin
		memory[address] <= data_in;
	end
end

// async read. drive zeros when the chip isn't enabled
assign data_out = (chip_enable) ? memory[address] : 0;

endmodule
