module DSP(A,B,C,D,CARRYIN,M,P,CARRYOUT,CARRYOUTF,CLK,OPMODE,CEA,CEB,CEC,CED,CEM,CEOPMODE,CECARRYIN,CEP,RSTA,RSTB,RSTC,RSTD,RSTM,RSTOPMODE,RSTP,RSTCARRYIN,BCIN,BCOUT,PCIN,PCOUT);

//defining inputs, outputs, signals and parameters 
input [17:0] A,B,D,BCIN;
input [47:0] C,PCIN;
input CEA,CEB,CEC,CED,CEM,CEOPMODE,CEP,RSTA,RSTB,RSTC,RSTD,RSTM,RSTOPMODE,RSTP,RSTCARRYIN,CARRYIN,CLK,CECARRYIN;
input [7:0] OPMODE;
output CARRYOUT,CARRYOUTF;
output [17:0] BCOUT;
output [35:0] M;
output [47:0] P, PCOUT;
parameter A0REG=0, A1REG=1, B0REG=0, B1REG=1, CREG=1, DREG=1,
		  MREG=1, PREG=1, CARRYINREG=1, CARRYOUTREG=1, OPMODEREG=1,
		  CARRYINSEL="OPMODE5",B_INPUT="DIRECT",RSSTYPE="SYNC";
wire CYI_in,CYI_out,CYO_in,CYO_out;
wire [17:0] B0_in,A0_out,B0_out,D_out,Pre_adder_out,A1_out,B1_in,B1_out;
wire [47:0] C_out,D_A_B_conc,P_out,post_adder_out;
wire [7:0] OPMODE_out;
wire [35:0] Mul_out,M_out;
reg [47:0] Mux_X_out,Mux_Z_out;
//First stage (Inputs)
//A0_reg
Mux_register #(.No_of_bits(18),.RSTTYPE(RSSTYPE),.sel_en_reg(A0REG)) A0_reg(.Input(A),.Output(A0_out),.clk(CLK),.EN(CEA),.rst(RSTA));
//B0_reg
assign B0_in = (B_INPUT=="DIRECT")?B:(B_INPUT=="CASCADE")?BCIN:0;
Mux_register #(.No_of_bits(18),.RSTTYPE(RSSTYPE),.sel_en_reg(B0REG)) B0_reg(.Input(B0_in),.Output(B0_out),.clk(CLK),.EN(CEB),.rst(RSTB));
//D_reg
Mux_register #(.No_of_bits(18),.RSTTYPE(RSSTYPE),.sel_en_reg(DREG)) D0_reg(.Input(D),.Output(D_out),.clk(CLK),.EN(CED),.rst(RSTD));
//C_reg
Mux_register #(.No_of_bits(48),.RSTTYPE(RSSTYPE),.sel_en_reg(CREG)) C0_reg(.Input(C),.Output(C_out),.clk(CLK),.EN(CEC),.rst(RSTC));
//Opmode_reg
Mux_register #(.No_of_bits(8),.RSTTYPE(RSSTYPE),.sel_en_reg(OPMODEREG)) OP_reg(.Input(OPMODE),.Output(OPMODE_out),.clk(CLK),.EN(CEOPMODE),.rst(RSTOPMODE));

//Pre adder/subtractor
assign Pre_adder_out = OPMODE_out[6]?(D_out+B0_out):(D_out-B0_out);

//Second stage
//A1_reg
Mux_register #(.No_of_bits(18),.RSTTYPE(RSSTYPE),.sel_en_reg(A1REG)) A1_reg(.Input(A0_out),.Output(A1_out),.clk(CLK),.EN(CEA),.rst(RSTA));
//B1_reg
assign B1_in = OPMODE_out[4]?Pre_adder_out:B0_out;
Mux_register #(.No_of_bits(18),.RSTTYPE(RSSTYPE),.sel_en_reg(B1REG)) B1_reg(.Input(B1_in),.Output(B1_out),.clk(CLK),.EN(CEB),.rst(RSTB));
assign BCOUT = B1_out;

//Multiplier
assign Mul_out = B1_out*A1_out;

//Third stage
//M_reg
Mux_register #(.No_of_bits(36),.RSTTYPE(RSSTYPE),.sel_en_reg(MREG)) M_reg(.Input(Mul_out),.Output(M_out),.clk(CLK),.EN(CEM),.rst(RSTM));
assign M = M_out;
//CYI_reg
assign CYI_in = (CARRYINSEL=="OPMODE5")?OPMODE_out[5]:(CARRYINSEL=="CARRYIN")?CARRYIN:0;
Mux_register #(.No_of_bits(1),.RSTTYPE(RSSTYPE),.sel_en_reg(CARRYINREG)) CYI_reg(.Input(CYI_in),.Output(CYI_out),.clk(CLK),.EN(CECARRYIN),.rst(RSTCARRYIN));


//Fourth stage
assign D_A_B_conc ={D_out[11:0],A0_out,B0_out};
//X_Mux
always @(*) begin
	case(OPMODE_out[1:0])
		0:Mux_X_out=0;
		1:Mux_X_out=M_out;
		2:Mux_X_out=P_out;
		default:Mux_X_out=D_A_B_conc;
	endcase
end
//Z_Mux
always @(*) begin
	case(OPMODE_out[3:2])
		0:Mux_Z_out=0;
		1:Mux_Z_out=PCIN;
		2:Mux_Z_out=P_out;
		default:Mux_Z_out=C_out;
	endcase
end

//Fifth stage
//post_adder/subtractor
assign {CYO_in,post_adder_out}=OPMODE_out[7]?(Mux_Z_out-(Mux_X_out+CYI_out)):(Mux_Z_out+Mux_X_out+CYI_out);
//CYO_reg
Mux_register #(.No_of_bits(1),.RSTTYPE(RSSTYPE),.sel_en_reg(CARRYOUTREG)) CYO_reg(.Input(CYO_in),.Output(CYO_out),.clk(CLK),.EN(CECARRYIN),.rst(RSTCARRYIN));
assign CARRYOUT=CYO_out;
assign CARRYOUTF=CYO_out;
//P_reg
Mux_register #(.No_of_bits(48),.RSTTYPE(RSSTYPE),.sel_en_reg(PREG)) P_reg(.Input(post_adder_out),.Output(P_out),.clk(CLK),.EN(CEP),.rst(RSTP));
assign P = P_out;
assign PCOUT = P_out;
endmodule