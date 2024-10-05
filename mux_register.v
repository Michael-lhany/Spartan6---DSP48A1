module Mux_register(Input,Output,clk,EN,rst);
parameter No_of_bits=5, RSTTYPE="SYNC", sel_en_reg=1;
input [No_of_bits-1:0] Input;
output [No_of_bits-1:0] Output;
input clk, EN, rst;
reg [No_of_bits-1:0] Temp;
generate
if (RSTTYPE=="ASYNC") begin
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			Temp<=0;
		end
		else if (EN) begin
			Temp<=Input;
		end
	end
end 
else begin
	always @(posedge clk) begin
		if (rst) begin
			Temp<=0;
		end
		else if (EN) begin
			Temp<=Input;
		end
	end
end
endgenerate
assign Output=sel_en_reg?Temp:Input;
endmodule