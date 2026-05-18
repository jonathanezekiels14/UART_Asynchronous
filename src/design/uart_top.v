`include "uart_baud.v"
`include "uart_rx.v"
`include "uart_tx.v"

module uart #(parameter XTAL_CLK = 50000000 , WIDTH = 8, BAUD = 9600)(
	input sys_clk, sys_rst,
	input xmitH,
	input [WIDTH-1:0] xmit_dataH,
	input uart_REC_dataH,
	output uart_XMIT_dataH, xmit_doneH, xmit_active,
	output [WIDTH-1:0] rec_dataH,
	output rec_readyH, rec_busy
);

	wire uart_clk;

	u_baud #(XTAL_CLK, BAUD)baud(
                .sys_clk(sys_clk),.sys_rst_(sys_rst),
                .baud_clk(baud_clk)
        );

	uart_transmitter #(WIDTH) xmit(
                .baud_clk(baud_clk),.sys_rst(sys_rst),.xmitH(xmitH),.xmit_dataH(xmit_dataH),
                .uart_XMIT_dataH(uart_XMIT_dataH),.xmit_doneH(xmit_doneH),.xmit_active(xmit_active)
        );

	u_receiver #(WIDTH) rec(
                .baud_clk(baud_clk),.sys_rst(sys_rst),.uart_REC_dataH(uart_REC_dataH),
                .rec_dataH(rec_dataH),.rec_readyH(rec_readyH),.rec_busy(rec_busy)
        );

endmodule
