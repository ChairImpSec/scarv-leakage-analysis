
//
// Common core parameters, constants etc
// ------------------------------------------------------------------------
//

localparam  integer XLEN = 32        ; // Register word width (bits)
localparam  integer ILEN = 32        ; // Maximum instruction length (bits)

localparam integer XL   = XLEN-1    ; // Register signal high bit
localparam integer IL   = ILEN-1    ; // Instruction signal high bit

localparam integer REG_ZERO = 5'd0;
localparam integer REG_RA   = 5'd1;
localparam integer REG_SP   = 5'd2;

//
// Pipeline encoding fields
// ------------------------------------------------------------------------
//

localparam integer P_FU_ALU     = 0;    // Integer alu
localparam integer P_FU_MUL     = 1;    // Multiply/divide
localparam integer P_FU_LSU     = 2;    // Load store unit
localparam integer P_FU_CFU     = 3;    // Control flow unit
localparam integer P_FU_CSR     = 4;    // CSR accesses
localparam integer P_FU_BIT     = 5;    // Bitwise
localparam integer P_FU_ASI     = 6;    // Algorithm specific (AES/SHA2/SHA3)
localparam integer P_FU_RNG     = 7;    // Algorithm specific (AES/SHA2/SHA3)
localparam integer P_FU_MSK     = 8;    // Masking Instructions.

localparam integer FU           = 8;    // Width of functional unit specifier field
localparam integer OP           = 4;    // Width of micro-op specifier field.
localparam integer PW           = 2;    // Width of IALU pack width field.

localparam integer PW_32        = 3'b100;
localparam integer PW_16        = 3'b011;
localparam integer PW_8         = 3'b010;
localparam integer PW_4         = 3'b001;
localparam integer PW_2         = 3'b000;

localparam integer ALU_ADD      = {2'b00, 3'b001};
localparam integer ALU_SUB      = {2'b00, 3'b000};
localparam integer ALU_AND      = {2'b01, 3'b001};
localparam integer ALU_OR       = {2'b01, 3'b010};
localparam integer ALU_XOR      = {2'b01, 3'b100};
localparam integer ALU_PACK     = {2'b01, 3'b101};
localparam integer ALU_SLT      = {2'b10, 3'b001};
localparam integer ALU_SLTU     = {2'b10, 3'b010};
localparam integer ALU_SRA      = {2'b11, 3'b001};
localparam integer ALU_SRL      = {2'b11, 3'b010};
localparam integer ALU_SLL      = {2'b11, 3'b100};
localparam integer ALU_ROR      = {2'b11, 3'b110};
localparam integer ALU_ROL      = {2'b11, 3'b111};

localparam integer CFU_BEQ      = {2'b00, 3'b001};
localparam integer CFU_BGE      = {2'b00, 3'b010};
localparam integer CFU_BGEU     = {2'b00, 3'b011};
localparam integer CFU_BLT      = {2'b00, 3'b100};
localparam integer CFU_BLTU     = {2'b00, 3'b101};
localparam integer CFU_BNE      = {2'b00, 3'b110};
localparam integer CFU_EBREAK   = {2'b01, 3'b001};
localparam integer CFU_ECALL    = {2'b01, 3'b010};
localparam integer CFU_MRET     = {2'b01, 3'b100};
localparam integer CFU_JMP      = {2'b10, 3'b001};
localparam integer CFU_JALI     = {2'b10, 3'b010};
localparam integer CFU_JALR     = {2'b10, 3'b100};
localparam integer CFU_TAKEN    = {2'b11, 3'b001};
localparam integer CFU_NOT_TAKEN= {2'b11, 3'b000};

localparam integer LSU_SIGNED   = 0;
localparam integer LSU_LOAD     = 3;
localparam integer LSU_STORE    = 4;
localparam integer LSU_BYTE     = 2'b01;
localparam integer LSU_HALF     = 2'b10;
localparam integer LSU_WORD     = 2'b11;

localparam integer MUL_DIV      = {2'b11, 3'b000};
localparam integer MUL_DIVU     = {2'b11, 3'b001};
localparam integer MUL_REM      = {2'b11, 3'b100};
localparam integer MUL_REMU     = {2'b11, 3'b101};
localparam integer MUL_PMUL_L   = {2'b01, 3'b000};
localparam integer MUL_PMUL_H   = {2'b01, 3'b001};
localparam integer MUL_MUL      = {2'b01, 3'b100};
localparam integer MUL_MULH     = {2'b01, 3'b110};
localparam integer MUL_MULHSU   = {2'b01, 3'b111};
localparam integer MUL_MULHU    = {2'b01, 3'b101};
localparam integer MUL_MMUL     = {2'b10, 3'b000};
localparam integer MUL_MADD     = {2'b10, 3'b001};
localparam integer MUL_MSUB     = {2'b10, 3'b010};
localparam integer MUL_MACC     = {2'b10, 3'b100};
localparam integer MUL_CLMUL_L  = {2'b00, 3'b001};
localparam integer MUL_CLMUL_H  = {2'b00, 3'b010};
localparam integer MUL_CLMUL_R  = {2'b00, 3'b100};
localparam integer MUL_PCLMUL_L = {2'b00, 3'b101};
localparam integer MUL_PCLMUL_H = {2'b00, 3'b111};

localparam integer MSK_B_MASK   = {2'b10, 3'b001};
localparam integer MSK_B_UNMASK = {2'b10, 3'b010};
localparam integer MSK_B_REMASK = {2'b10, 3'b100};
localparam integer MSK_A_MASK   = {2'b11, 3'b101};
localparam integer MSK_A_UNMASK = {2'b11, 3'b110};
localparam integer MSK_A_REMASK = {2'b11, 3'b100};
localparam integer MSK_B2A      = {2'b11, 3'b001};
localparam integer MSK_A2B      = {2'b11, 3'b010};
localparam integer MSK_A_ADD    = {2'b11, 3'b011};
localparam integer MSK_A_SUB    = {2'b11, 3'b111};
localparam integer MSK_B_NOT    = {2'b00, 3'b001};
localparam integer MSK_B_AND    = {2'b00, 3'b010};
localparam integer MSK_B_IOR    = {2'b00, 3'b011};
localparam integer MSK_B_XOR    = {2'b00, 3'b100};
localparam integer MSK_B_ADD    = {2'b00, 3'b101};
localparam integer MSK_B_SUB    = {2'b00, 3'b110};
localparam integer MSK_B_SLLI   = {2'b01, 3'b001};
localparam integer MSK_B_SRLI   = {2'b01, 3'b010};
localparam integer MSK_B_RORI   = {2'b01, 3'b100};
localparam integer MSK_F_MUL    = {2'b01, 3'b101};
localparam integer MSK_F_AFF    = {2'b01, 3'b110};
localparam integer MSK_F_SQR    = {2'b01, 3'b111};

localparam integer CSR_READ     = 4;
localparam integer CSR_WRITE    = 3;
localparam integer CSR_SET      = 2;
localparam integer CSR_CLEAR    = 1;
localparam integer CSR_SWAP     = 0;

localparam integer BIT_BDEP          = {2'b01, 3'b000};
localparam integer BIT_BEXT          = {2'b01, 3'b001};
localparam integer BIT_GREV          = {2'b10, 3'b000};
localparam integer BIT_GREVI         = {2'b10, 3'b001};
localparam integer BIT_LUT           = {2'b11, 3'b000};
localparam integer BIT_BOP           = {2'b11, 3'b001};
localparam integer BIT_CMOV          = {2'b11, 3'b100};
localparam integer BIT_FSL           = {2'b00, 3'b000};
localparam integer BIT_FSR           = {2'b00, 3'b001};
localparam integer BIT_RORW          = {2'b00, 3'b011};

localparam integer ASI_AES  = 2'b01;
localparam integer ASI_SHA2 = 2'b10;
localparam integer ASI_SHA3 = 2'b11;

localparam integer ASI_AESSUB_ENC    = {ASI_AES , 3'b000};
localparam integer ASI_AESSUB_ENCROT = {ASI_AES , 3'b010};
localparam integer ASI_AESSUB_DEC    = {ASI_AES , 3'b001};
localparam integer ASI_AESSUB_DECROT = {ASI_AES , 3'b011};
localparam integer ASI_AESMIX_ENC    = {ASI_AES , 3'b100};
localparam integer ASI_AESMIX_DEC    = {ASI_AES , 3'b101};
localparam integer ASI_SHA3_XY       = {ASI_SHA3, 3'b000};
localparam integer ASI_SHA3_X1       = {ASI_SHA3, 3'b001};
localparam integer ASI_SHA3_X2       = {ASI_SHA3, 3'b010};
localparam integer ASI_SHA3_X4       = {ASI_SHA3, 3'b011};
localparam integer ASI_SHA3_YX       = {ASI_SHA3, 3'b100};
localparam integer ASI_SHA256_S0     = {ASI_SHA2, 3'b000};
localparam integer ASI_SHA256_S1     = {ASI_SHA2, 3'b001};
localparam integer ASI_SHA256_S2     = {ASI_SHA2, 3'b010};
localparam integer ASI_SHA256_S3     = {ASI_SHA2, 3'b011};

localparam integer RNG_RNGSEED       = {2'b00, 3'b001};
localparam integer RNG_RNGSAMP       = {2'b00, 3'b010};
localparam integer RNG_RNGTEST       = {2'b00, 3'b100};
localparam integer RNG_ALFENCE       = {2'b11, 3'b010};

localparam integer RNG_IF_SEED       = 3'b001;
localparam integer RNG_IF_SAMP       = 3'b010;
localparam integer RNG_IF_TEST       = 3'b100;

localparam integer RNG_IF_STAT_NO_INIT = 3'b000; // Un-initialised
localparam integer RNG_IF_INIT_NO_ENTR = 3'b100; // Initialised - not enough entropy.
localparam integer RNG_IF_INIT_HEALTHY = 3'b101; // Initialised - ready to be sampled.

localparam integer LEAK_CFG_S2_OPR_A  = 0 ; // Decode -> Execute operand A
localparam integer LEAK_CFG_S2_OPR_B  = 1 ; // Decode -> Execute operand B
localparam integer LEAK_CFG_S2_OPR_C  = 2 ; // Decode -> Execute operand C
localparam integer LEAK_CFG_S3_OPR_A  = 3 ; // Execute -> Memory result register A
localparam integer LEAK_CFG_S3_OPR_B  = 4 ; // Execute -> Memory result register B
localparam integer LEAK_CFG_FU_MULT   = 5 ; // Multiplier accumulate registers.
localparam integer LEAK_CFG_FU_AESSUB = 6 ; // AES sub-bytes registers.
localparam integer LEAK_CFG_FU_AESMIX = 7 ; // AES mix registers.
localparam integer LEAK_CFG_S4_OPR_A  = 8 ; // Memory -> Writeback result register A
localparam integer LEAK_CFG_S4_OPR_B  = 9 ; // Memory -> Writeback result register B
localparam integer LEAK_CFG_UNCORE_0  = 10; // Un-core resource 0
localparam integer LEAK_CFG_UNCORE_1  = 11; // Un-core resource 1
localparam integer LEAK_CFG_UNCORE_2  = 12; // Un-core resource 2

//
// Dispatch stage operand register sources

localparam integer DIS_OPRA_RS1 = 0;  // Operand A sources RS1
localparam integer DIS_OPRA_PCIM= 1;  // Operand A sources PC+immediate
localparam integer DIS_OPRA_CSRI= 2;  // Operand A sources CSR mask immediate

localparam integer DIS_OPRB_RS2 = 3;  // Operand B sources RS2
localparam integer DIS_OPRB_IMM = 4;  // Operand B sources immediate

localparam integer DIS_OPRC_RS2 = 5;  // Operand C sources RS2
localparam integer DIS_OPRC_CSRA= 6;  // Operand C sources CSR address immediate
localparam integer DIS_OPRC_PCIM= 7;  // Operand C sources PC+immediate
localparam integer DIS_OPRC_RS3 = 8;  // Operand C sources RS3

//
// Exception codes
// ------------------------------------------------------------------------
//

localparam integer TRAP_NONE    = 6'b111111;
localparam integer TRAP_IALIGN  = 6'd0 ;
localparam integer TRAP_IACCESS = 6'd1 ;
localparam integer TRAP_IOPCODE = 6'd2 ;
localparam integer TRAP_BREAKPT = 6'd3 ;
localparam integer TRAP_LDALIGN = 6'd4 ;
localparam integer TRAP_LDACCESS= 6'd5 ;
localparam integer TRAP_STALIGN = 6'd6 ;
localparam integer TRAP_STACCESS= 6'd7 ;
localparam integer TRAP_ECALLM  = 6'd11;

localparam integer TRAP_INT_MSI = 6'd3 ;
localparam integer TRAP_INT_MTI = 6'd7 ;
localparam integer TRAP_INT_MEI = 6'd11;
localparam integer TRAP_INT_NMI = 6'd16;

//
// Utility macros
// ------------------------------------------------------------------------

`define WORD_SHUFFLE(IN,OUT,EN,FWD) \
    frv_masked_shuffle i_``IN (     \
        .i  (IN             ),      \
        .en (EN             ),      \
        .fwd(FWD            ),      \
        .o  (OUT            )       \
    );

//
// Formal verification macros
// ------------------------------------------------------------------------


//
// RISC-V Formal flow macros and parameters.
`ifdef RVFI

//
// Maximum number of instructions retired per cycle.
localparam integer NRET = 1;

`endif


//
// Custom formal flow macros.
`ifdef FRV_FORMAL

//
// Cover
`define FRV_COVER(X) if(g_resetn) begin cover(X); end

`endif
