#include "Vdmem.h"
#include "verilated.h"
#include "common.hpp"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vdmem* top = new Vdmem;

    // Initialize
    top->clk   = 0;
    top->we    = 0;
    top->addr  = 0;
    top->wdata = 0;
    top->eval();

    // Write and read back a few locations
    struct { uint32_t addr, data; } tests[] = {
        {0, 0xAAAAAAAA},
        {1, 0x55555555},
        {5, 0xDEADBEEF},
        {8, 0xCAFEC0DE},
    };

    for (auto& t : tests) {
        top->addr  = t.addr;
        top->wdata = t.data;
        top->we    = 1;
        tick(top);            // write on rising edge
        top->we    = 0;

        // Next cycle read
        tick(top);
        check(("dmem read[" + std::to_string(t.addr) + "]").c_str(),
              top->rdata, t.data);
    }

    // Summary
    if (failures) {
        std::cerr << "\n*** " << failures << " dmem test(s) FAILED ***\n";
    } else {
        std::cout << "\nAll dmem tests passed!\n";
    }

    delete top;
    return failures ? 1 : 0;
}

