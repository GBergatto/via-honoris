#include "Vimem.h"
#include "verilated.h"
#include "common.hpp"

#include <fstream>
#include <sstream>
#include <vector>
#include <string>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // 1) Read the hex file into a vector of expected values
    const std::string hex_path = "roms/firmware.hex";
    std::ifstream hexfile(hex_path);
    if (!hexfile.is_open()) {
        std::cerr << "× ERROR: Cannot open " << hex_path << "\n";
        return 1;
    }

    std::vector<uint32_t> expected;
    std::string line;
    while (std::getline(hexfile, line)) {
        // strip whitespace
        if (line.empty()) continue;
        std::istringstream iss(line);
        uint32_t value;
        iss >> std::hex >> value;
        expected.push_back(value);
    }
    hexfile.close();

    if (expected.empty()) {
        std::cerr << "× ERROR: No data read from " << hex_path << "\n";
        return 1;
    }

    // 2) Instantiate the DUT
    Vimem* top = new Vimem;
    top->clk = 0;
    top->pc = 0;
    top->eval();

    // 3) Test every address
    for (size_t i = 0; i < expected.size(); ++i) {
        top->pc = i;
        tick(top);
        check(("imem[" + std::to_string(i) + "]").c_str(),
              top->inst, expected[i]);
    }

    // 4) Summary & exit code
    if (failures) {
        std::cerr << "\n*** " << failures << " imem test(s) FAILED ***\n";
    } else {
        std::cout << "\nAll " << expected.size() << " imem entries matched!\n";
    }

    delete top;
    return failures ? 1 : 0;
}

