module uart_receiver #(parameter WIDTH = 8)(
	input baud_clk, sys_rst, uart_REC_dataH,
	output reg [WIDTH - 1:0] rec_dataH,
	output reg rec_readyH, rec_busy
);

	localparam S_IDLE = 2'd0;
	localparam S_START = 2'd1;
	localparam S_SAMPLE = 2'd2;
	localparam S_STOP = 2'd3;

	reg [1:0] curr_state, next_state;

	reg [3:0] baud_count;
	reg [3:0] bit_count; 
	reg [WIDTH-1:0] shift_reg;
	reg rx_sync1, rx_sync2;

	always @(posedge baud_clk or posedge sys_rst) begin
		if(sys_rst) begin
			rx_sync1 <= 1;
			rx_sync2 <= 1;
		end 
		else begin
			rx_sync1 <= uart_REC_dataH;
			rx_sync2 <= rx_sync1;
		end
	end

	always @(posedge baud_clk or posedge sys_rst) begin
		if(sys_rst)
			curr_state <= S_IDLE;
		else
			curr_state <= next_state;
	end

	always @(*) begin
		next_state = curr_state; 
		case (curr_state)
			S_IDLE: next_state = rx_sync2 ? S_IDLE : S_START;
			S_START: begin
				if (baud_count == 4'd5) 
					next_state = (rx_sync2 == 0) ? S_SAMPLE : S_IDLE; 
			end
			S_SAMPLE: begin
				if (baud_count == 4'd13 && bit_count == WIDTH)
					next_state = S_STOP;
			end
			S_STOP: begin
				if(baud_count == 4'd13)
					next_state = S_IDLE;
			end
			default: next_state = S_IDLE;
		endcase
	end

	always @(posedge baud_clk or posedge sys_rst) begin
		if (sys_rst) begin
			baud_count <= 0;
			bit_count <= 0;
			shift_reg <= {WIDTH{1'b0}};
			rec_dataH <= {WIDTH{1'b0}};
			rec_busy <= 0;
			rec_readyH <= 0;
		end
		else begin
			rec_readyH <= 0; 
			case(curr_state)
				S_IDLE: begin
					baud_count <= 0;
					bit_count <= 0;
					rec_busy <= 0;
				end
				S_START:begin
					baud_count <= baud_count + 1;
					rec_busy <= 1;
				end	
				S_SAMPLE: begin
					baud_count <= baud_count + 1;
					rec_busy <= 1;
					if(baud_count == 5) begin
						shift_reg <= {rx_sync2, shift_reg[WIDTH-1:1]};
						bit_count <= bit_count + 1;
					end
				end
				S_STOP: begin
					baud_count <= baud_count + 1;
					rec_busy <= 1;
					if(baud_count == 13) begin
						rec_readyH <= 1;
						rec_dataH <= shift_reg;	
					end
				end
			endcase
		end
	end
endmodule
