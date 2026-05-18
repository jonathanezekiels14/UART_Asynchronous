module uart_transmitter #(parameter WIDTH = 8) (
	input baud_clk,sys_rst,
	input xmitH,
	input [WIDTH-1:0] xmit_dataH,
	output reg xmit_doneH,xmit_active,
	output reg uart_XMIT_dataH
);
	parameter S_IDLE = 2'd0;
	parameter S_START = 2'd1;
	parameter S_SAMPLE = 2'd2;
	parameter S_STOP = 2'd3;
	
	reg tx_en;
	reg [1:0] curr_state,next_state;
	reg [3:0] count_tx;
	reg [2:0] count_word;
	reg [WIDTH-1:0] tx_data;
	always @(posedge baud_clk or posedge sys_rst) begin
		if(sys_rst) begin
			count_tx <= 0;
			tx_en <= 0;
		end

		else if (curr_state == S_IDLE) begin
			tx_en <= 0;
			count_tx <= 0;
		end

		else begin
			count_tx <= count_tx + 1;
			tx_en <= 1;
		end
	end
	
	always @(posedge baud_clk or posedge sys_rst) begin
		if(sys_rst)
			curr_state <= S_IDLE;
		else
			curr_state <= next_state;
	end

	always @(*) begin
		case( curr_state)
			S_IDLE: next_state <= xmitH ? S_START : S_IDLE;
			S_START: next_state <= tx_en ? S_SAMPLE : S_START;
			S_SAMPLE: next_state <= tx_en ? (count_word < (WIDTH-1)) ? S_SAMPLE : S_STOP : S_SAMPLE;
			S_STOP: next_state <= tx_en ? S_IDLE : S_STOP;
			default: next_state <= S_IDLE;
		endcase
	end

	always @(posedge baud_clk or posedge sys_rst) begin
		if(sys_rst) begin
			uart_XMIT_dataH <= 1;
			xmit_doneH <= 0;
			xmit_active <= 0;
			count_word <= 0;
		end

		else begin
			case(curr_state)
				S_IDLE: begin
					uart_XMIT_dataH <= 1;
					xmit_doneH <= 1;
					xmit_active <= 0;
					count_word <= 0;
					tx_data <= xmitH? xmit_dataH : 0;
				end
				S_START: begin
					uart_XMIT_dataH <= 0;
					xmit_doneH <= 0;
					xmit_active <= 1;
					count_word <= 0;
					tx_data <= tx_data;
				end
				S_SAMPLE: begin
					xmit_doneH <= 0;
					xmit_active <= 1;
					if(tx_en) begin
						uart_XMIT_dataH <= tx_data [0];
						tx_data <= tx_data >> 1;
						count_word <= count_word + 1;
					end
				end
				S_STOP: begin
					if(tx_en)
						xmit_doneH <= 1;
					xmit_active <= 1;
					uart_XMIT_dataH <= 1;
					count_word <= 0;
					tx_data <= tx_data;
				end
			endcase
		end
	end
endmodule
