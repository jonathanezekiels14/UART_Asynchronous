module uart_transmitter #(parameter WIDTH = 8) (
	input baud_clk,
	input sys_rst,
	input xmitH,
	input [WIDTH-1:0] xmit_dataH,
	output wire xmit_doneH,
	output wire xmit_active,
	output wire uart_XMIT_dataH
);
	parameter S_IDLE = 2'd0;
	parameter S_START = 2'd1;
	parameter S_SAMPLE = 2'd2;
	parameter S_STOP = 2'd3;
	
	reg [1:0] curr_state, next_state;
	reg [3:0] count_tx;
	reg [3:0] count_word;
	reg [WIDTH-1:0] tx_data;
	
	reg tx_line_reg;
	reg done_reg;
	reg active_reg;
	
	assign uart_XMIT_dataH = (curr_state == S_IDLE && xmitH) ? 1'b0 : tx_line_reg;
	assign xmit_active = (curr_state == S_IDLE && xmitH) ? 1'b1 : active_reg;
	assign xmit_doneH = (curr_state == S_IDLE && xmitH) ? 1'b0 : done_reg;
	
	wire tx_en = (count_tx == 4'd14);

	always @(posedge baud_clk or posedge sys_rst) begin
		if(sys_rst) begin
			count_tx <= 0;
		end
		else if (curr_state == S_IDLE) begin
			count_tx <= 0;
		end
		else begin
			count_tx <= count_tx + 1;
		end
	end

	always @(posedge baud_clk or posedge sys_rst) begin
		if(sys_rst)
			curr_state <= S_IDLE;
		else
			curr_state <= next_state;
	end

	always @(*) begin
		case(curr_state)
			S_IDLE: next_state = (xmitH) ? S_START : S_IDLE;
			S_START: next_state = (tx_en) ? S_SAMPLE : S_START;
			S_SAMPLE: next_state = (tx_en) ? ((count_word == WIDTH) ? S_STOP : S_SAMPLE) : S_SAMPLE;
			S_STOP: next_state = (tx_en) ? S_IDLE : S_STOP;
			default: next_state = S_IDLE;
		endcase
	end

	always @(posedge baud_clk or posedge sys_rst) begin
		if(sys_rst) begin
			tx_line_reg <= 1;
			done_reg <= 1;
			active_reg <= 0;
			count_word <= 0;
			tx_data <= 0;
		end
		else begin
			case(curr_state)
				S_IDLE: begin
					count_word <= 0;
					if (xmitH) begin
						tx_line_reg <= 0;
						done_reg <= 0;
						active_reg <= 1;
						tx_data <= xmit_dataH;
					end else begin
						tx_line_reg <= 1;
						done_reg <= 1;
						active_reg <= 0;
					end
				end
				S_START: begin
					if (tx_en) begin
						tx_line_reg <= tx_data[0];
						tx_data <= tx_data >> 1;
						count_word <= count_word + 1;
					end else begin
						tx_line_reg <= 0;
						done_reg <= 0;
						active_reg <= 1;
					end
				end
				S_SAMPLE: begin
					done_reg <= 0;
					active_reg <= 1;
					if (tx_en) begin
						if (count_word == WIDTH) begin
							tx_line_reg <= 1;
						end else begin
							tx_line_reg <= tx_data[0];
							tx_data <= tx_data >> 1;
							count_word <= count_word + 1;
						end
					end
				end
				S_STOP: begin
					tx_line_reg <= 1;
					if (tx_en) begin
						done_reg <= 1;
						active_reg <= 0;
					end
				end
			endcase
		end
	end
endmodule
