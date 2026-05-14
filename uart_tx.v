module uart_transmitter #(parameter WIDTH = 8) (
	input baud_clk,sys_rst,
	input xmitH,
	input [WIDTH-1:0] xmit_dataH,
	output reg xmit_doneH,xmit_active,
	output reg uart_XMIT_dataH
);
	integer count,i;
	always @(posedge baud_clk) begin
		if (xmitH)
			count <= 1;
		else if (count > 0)
			count <= count + 1;
		else
			count <= 0;
	end
	always @(posedge baud_clk or posedge sys_rst) begin
		if (sys_rst) begin
			xmit_doneH <= 0;
			xmit_active <= 0;
			uart_XMIT_dataH <= 0;
			count <= 0;
			i <= WIDTH - 1;
		end
		else begin
				count <= count + 1;
				uart_XMIT_dataH <= xmit_dataH[i];
				if (count == 16 :w
	
