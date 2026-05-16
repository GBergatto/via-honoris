#include "Valu.h"
#include "verilated.h"
#include "common.hpp"
#include <cstdint>
#include <cassert>

void test_op(Valu* dut, uint32_t op1, uint32_t op2, uint8_t alu_op, uint32_t expected, const std::string& name) {
    dut->op1 = op1;
    dut->op2 = op2;
    dut->alu_op = alu_op;

    dut->eval();

    check(name, dut->out, expected);
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Valu* dut = new Valu;

    // Constants for ALU ops from the SystemVerilog enum
    enum {
        ALU_ADD = 0, ALU_SUB, ALU_SLL, ALU_SLT, ALU_SLTU,
        ALU_XOR, ALU_SRL, ALU_SRA, ALU_OR, ALU_AND
    };

    test_op(dut, 10, 5, ALU_ADD, 15, "ALU_ADD");
    test_op(dut, 10, 5, ALU_SUB, 5, "ALU_SUB");
    test_op(dut, 1, 2, ALU_SLL, 1 << 2, "ALU_SLL");

    test_op(dut, 4, 10, ALU_SLT, 1, "ALU_SLT true");
    test_op(dut, 10, 4, ALU_SLT, 0, "ALU_SLT false");

    test_op(dut, 0x00000001, 0xFFFFFFFF, ALU_SLTU, 1, "ALU_SLTU true");
    test_op(dut, 0xFFFFFFFF, 0x00000001, ALU_SLTU, 0, "ALU_SLTU false");

    test_op(dut, 0xAAAA5555, 0xFFFF0000, ALU_XOR, 0x55555555, "ALU_XOR");

    test_op(dut, 0xF000000F, 4, ALU_SRL, 0x0F000000, "ALU_SRL");
    test_op(dut, 0xF000000F, 4, ALU_SRA, 0xFF000000, "ALU_SRA");

    test_op(dut, 0x0F0F0F0F, 0x00FF00FF, ALU_OR,  0x0FFF0FFF, "ALU_OR");
    test_op(dut, 0x0F0F0F0F, 0x00FF00FF, ALU_AND, 0x000F000F, "ALU_AND");

    delete dut;
    return 0;
}

