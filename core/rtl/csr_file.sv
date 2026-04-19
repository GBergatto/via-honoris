/* verilator lint_off IMPORTSTAR */
import core_types_pkg::*;

module csr_file (
   input  logic clk,
   input  logic rst,
   input  csr_addr_e   read_addr,
   output logic [31:0] read_data,
   input  logic        write_enable,
   input  csr_addr_e   write_addr,
   input  logic [31:0] write_data,

   // Trap handling
   input  logic        trap,
   input  logic [31:0] trap_pc,
   input  logic [31:0] trap_cause,
   input  logic        mret,

   // Interrupts
   input  logic        mtip,
   output logic        irq_pending,

   // Continuous outputs for PC redirection
   output logic [31:0] mtvec_out,
   output logic [31:0] mepc_out
);

   logic [31:0] csr_mstatus;
   logic [31:0] csr_mie;
   logic [31:0] csr_mtvec;
   logic [31:0] csr_mscratch;
   logic [31:0] csr_mepc;
   logic [31:0] csr_mcause;
   logic [31:0] csr_medeleg;
   logic [31:0] csr_mideleg;
   logic [31:0] csr_satp;
   logic [31:0] csr_pmpcfg0;
   logic [31:0] csr_pmpaddr0;
   logic [31:0] csr_mnstatus;
   logic [31:0] csr_stvec;
   logic [31:0] csr_fcsr;
   logic [31:0] csr_vcsr;

   assign mtvec_out = csr_mtvec;
   assign mepc_out = csr_mepc;
   assign irq_pending = mtip && csr_mie[7] && csr_mstatus[3];

   always_comb begin
      case (read_addr)
         CSR_MSTATUS:  read_data = csr_mstatus;
         CSR_MIE:      read_data = csr_mie;
         CSR_MIP:      read_data = {24'b0, mtip, 7'b0};
         CSR_MTVEC:    read_data = csr_mtvec;
         CSR_MSCRATCH: read_data = csr_mscratch;
         CSR_MEPC:     read_data = csr_mepc;
         CSR_MCAUSE:   read_data = csr_mcause;
         CSR_MEDELEG:  read_data = csr_medeleg;
         CSR_MIDELEG:  read_data = csr_mideleg;
         CSR_SATP:     read_data = csr_satp;
         CSR_PMPCFG0:  read_data = csr_pmpcfg0;
         CSR_PMPADDR0: read_data = csr_pmpaddr0;
         CSR_MNSTATUS: read_data = csr_mnstatus;
         CSR_STVEC:    read_data = csr_stvec;
         CSR_FCSR:     read_data = csr_fcsr;
         CSR_VCSR:     read_data = csr_vcsr;
         CSR_MHARTID:  read_data = 32'b0; // mhartid
         default:      read_data = 32'b0;
      endcase
   end

    always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         csr_mstatus <= 32'h0000_1800; // MPP (bits 12:11) hardwired to 2'b11 (M-mode)
         csr_mie <= 32'b0;
         csr_mtvec <= 32'b0;
         csr_mscratch <= 32'b0;
         csr_mepc <= 32'b0;
         csr_mcause <= 32'b0;
         csr_medeleg <= 32'b0;
         csr_mideleg <= 32'b0;
         csr_satp <= 32'b0;
         csr_pmpcfg0 <= 32'b0;
         csr_pmpaddr0 <= 32'b0;
         csr_mnstatus <= 32'b0;
         csr_stvec <= 32'b0;
         csr_fcsr <= 32'b0;
         csr_vcsr <= 32'b0;
      end else begin
         if (trap) begin
            csr_mepc <= trap_pc;
            csr_mcause <= trap_cause;
            // Push MIE to MPIE, then clear MIE
            csr_mstatus[7] <= csr_mstatus[3];
            csr_mstatus[3] <= 1'b0;
         end else if (mret) begin
            // Pop MPIE to MIE, then set MPIE to 1
            csr_mstatus[3] <= csr_mstatus[7];
            csr_mstatus[7] <= 1'b1;
          end else if (write_enable) begin
            case (write_addr)
               CSR_MSTATUS:  csr_mstatus <= {write_data[31:13], 2'b11, write_data[10:0]}; // Preserve MPP = 2'b11
               CSR_MIE:      csr_mie <= write_data;
               CSR_MTVEC:    csr_mtvec <= write_data;
               CSR_MSCRATCH: csr_mscratch <= write_data;
               CSR_MEPC:     csr_mepc <= write_data;
               CSR_MCAUSE:   csr_mcause <= write_data;
               CSR_MEDELEG:  csr_medeleg <= write_data;
               CSR_MIDELEG:  csr_mideleg <= write_data;
               CSR_SATP:     csr_satp <= write_data;
               CSR_PMPCFG0:  csr_pmpcfg0 <= write_data;
               CSR_PMPADDR0: csr_pmpaddr0 <= write_data;
               CSR_MNSTATUS: csr_mnstatus <= write_data;
               CSR_STVEC:    csr_stvec <= write_data;
               CSR_FCSR:     csr_fcsr <= write_data;
               CSR_VCSR:     csr_vcsr <= write_data;
               default: ;
            endcase
         end
      end
   end

endmodule
