#include "Vregfile.h"
#include "verilated.h"
#include "common.hpp"
#include <iostream>
#include <cstdint>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vregfile* top = new Vregfile;

    // Initialize
    top->clk      = 0;
    top->write    = 0;
    top->rs1      = 0;
    top->rs2      = 0;
    top->rd       = 0;
    top->rd_data  = 0;
    top->eval();

    // Test 1: x0 is always zero
    top->rs1 = 0; top->rs2 = 0; top->eval();
    check("x0 readback rs1", top->rs1_data, 0);
    check("x0 readback rs2", top->rs2_data, 0);

    // Test 2: write to x1, read back
    const uint32_t VAL1 = 0x12345678;
    top->rd      = 1;
    top->rd_data = VAL1;
    top->write   = 1;
    tick(top);
    top->write   = 0;
    top->rs1     = 1; top->rs2 = 0; top->eval();
    check("write x1 / read rs1", top->rs1_data, VAL1);
    check("write x1 / read rs2(x0)", top->rs2_data, 0);

    // Test 3: overwrite x1
    const uint32_t VAL2 = 0xDEADBEEF;
    top->rd      = 1;
    top->rd_data = VAL2;
    top->write   = 1;
    tick(top);
    top->write   = 0;
    top->rs1 = 1; top->eval();
    check("overwrite x1", top->rs1_data, VAL2);

    // Test 4: write to x2
    const uint32_t VAL3 = 0xCAFEBABE;
    top->rd      = 2;
    top->rd_data = VAL3;
    top->write   = 1;
    tick(top);
    top->write   = 0;
    top->rs2 = 2; top->eval();
    check("write x2 / read rs2", top->rs2_data, VAL3);

    // Test 5: attempt to write x0 (ignored)
    top->rd      = 0;
    top->rd_data = 0xFFFFFFFF;
    top->write   = 1;
    tick(top);
    top->write   = 0;
    top->rs1 = 0; top->eval();
    check("write-ignored x0", top->rs1_data, 0);

    // Summary
    if (failures) {
        std::cerr << "\n*** " << failures << " TEST(S) FAILED ***\n";
    } else {
        std::cout << "\nAll regfile tests passed!\n";
    }

    delete top;
    return failures ? 1 : 0;
}

