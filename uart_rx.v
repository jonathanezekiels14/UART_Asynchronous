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
	reg [2:0] bit_count;
	reg [WIDTH-1:0] shift_reg;
	reg rx_sync1,rx_sync2;

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
		case (curr_state)
			S_IDLE: next_state = rx_sync2 ? S_IDLE : S_START;
			S_START: begin
				if (baud_count == 7) begin
					next_state = S_SAMPLE;
				else
					next_state = S_IDLE;
			end
			S_SAMPLE: begin
				if (baud_count == 15 && bit_count == (WIDTH - 1))
					next_state = S_STOP;
			end
			S_STOP: begin
				if(baud_count == 15)
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
		end
		else begin
			
