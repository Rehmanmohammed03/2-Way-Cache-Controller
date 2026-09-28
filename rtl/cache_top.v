// cache_top.v
// board wrapper for the Arty A7. there aren't enough switches to
// drive a full tag and 32-bit data word, so two buttons pick between
// a couple of hardcoded values instead.
//
// the cache is stepped by hand with btn0. the button goes through a
// debouncer running off the 100MHz oscillator, so one press is one
// clean clock edge.

module cache_top(
	input sys_clk,          // 100MHz board oscillator
	input step_btn,         // btn0, press to step the cache one clock
	input reset,            // btn1
	input tag_sel,          // btn2: 0 -> tag 3, 1 -> tag 7
	input data_sel,         // btn3: 0 -> AAAA5555, 1 -> 12345678
	input chip_enable,      // sw0
	input write_enable,     // sw1
	input way_select,       // sw2
	input set,              // sw3
	output hit,             // led4
	output miss,            // led5
	output valid,           // led6
	output dout_led         // led7
);

wire clk;
wire [3:0] tag;
wire [31:0] data_in;
wire [31:0] data_out;

// debounced button becomes the cache clock
debounce step_db (
	.clk(sys_clk),
	.btn_in(step_btn),
	.btn_out(clk)
);

// fixed test patterns
assign tag = tag_sel ? 4'h7 : 4'h3;
assign data_in = data_sel ? 32'h12345678 : 32'hAAAA5555;

cache_controller core (
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

// only one LED left, so show bit 0 of the output.
// 12345678 -> LED off, AAAA5555 -> LED on, so you can still tell
// which word came back
assign dout_led = data_out[0];

endmodule
