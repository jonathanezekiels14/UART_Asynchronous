module u_baud #(parameter XTAL_CLK = 50000000, BAUD = 9600)(
	input sys_clk, sys_rst,
	output reg baud_clk
);
	localparam CW = $clog2(XTAL_CLK / (BAUD * 16 * 2));
	reg [CW:0] count;
	
	always @(posedge sys_clk or posedge sys_rst) begin
		if(sys_rst) begin
			baud_clk <= 0;
			count <= 0;
		end

		else begin
			if(count == (XTAL_CLK / (BAUD * 16 * 2))) begin
				baud_clk <= ~baud_clk;
				count <= 0;
			end
			else begin
				count <= count + 1;
			end
		end
	end
endmodule
