// debounce.v
// cleans up a push button. the input has to sit at the same level for
// STABLE_COUNT cycles of clk before the output follows it.
// default is 1,000,000 cycles = 10ms at 100MHz, plenty for the arty buttons.

module debounce #(
	parameter STABLE_COUNT = 1000000
)(
	input clk,
	input btn_in,
	output reg btn_out
);

// button is async to clk, so run it through two flops first
reg sync0, sync1;
always @(posedge clk) begin
	sync0 <= btn_in;
	sync1 <= sync0;
end

// wide enough for STABLE_COUNT
reg [$clog2(STABLE_COUNT+1)-1:0] count;

initial begin
	sync0 = 0;
	sync1 = 0;
	btn_out = 0;
	count = 0;
end

always @(posedge clk) begin
	if (sync1 == btn_out) begin
		// nothing changed, keep the counter at 0
		count <= 0;
	end
	else if (count == STABLE_COUNT - 1) begin
		// held long enough, accept the new level
		btn_out <= sync1;
		count <= 0;
	end
	else begin
		count <= count + 1;
	end
end

endmodule
