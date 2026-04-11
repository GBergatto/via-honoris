#include "Vhp_soc.h"
#include "Vhp_soc_hp_soc.h"
#include "Vhp_soc_dmem.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>

namespace fs = std::filesystem;

#define TESTNAME_LENGTH 30
#define MAX_SIM_CYCLES 50000 // Timeout to prevent infinite loops
#define TEST_DIR "riscv-tests/isa/build"

// ANSI colors
#define RESET   "\033[0m"
#define RED     "\033[31m"
#define GREEN   "\033[32m"
#define YELLOW  "\033[33m"

int bin_to_hex(const fs::path& bin_file, const fs::path& hex_file) {
    std::ifstream ifs(bin_file, std::ios::binary);
    if (!ifs) throw std::runtime_error("Cannot open " + bin_file.string());

    std::ofstream ofs(hex_file);
    if (!ofs) throw std::runtime_error("Cannot open " + hex_file.string());

    int n_instructions = 0;
    uint8_t buf[4];
    while (ifs.read(reinterpret_cast<char*>(buf), 4) || ifs.gcount() > 0) {
        uint32_t word = 0;
        for (size_t i = 0; i < ifs.gcount(); ++i) {
            word |= buf[i] << (8 * i);
        }
        ofs << std::hex << std::setw(8) << std::setfill('0') << word << "\n";
        n_instructions++;
    }
    return n_instructions;
}

// Function to extract the tohost address from an ELF file using 'nm'
uint32_t get_tohost_addr(const fs::path& elf_file) {
    std::string cmd = "riscv32-unknown-elf-nm " + elf_file.string() + " | grep tohost";
    FILE* pipe = popen(cmd.c_str(), "r");
    if (!pipe) throw std::runtime_error("popen() failed!");

    char buffer[128];
    std::string result = "";
    while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
        result += buffer;
    }
    pclose(pipe);

    if (result.empty()) {
        throw std::runtime_error("Could not find 'tohost' in " + elf_file.string());
    }

    // nm output looks like: "80001000 D tohost"
    uint32_t tohost_addr;
    std::stringstream ss(result);
    ss >> std::hex >> tohost_addr;
    return tohost_addr;
}

void run_riscv_test(const fs::path& elf_file) {
    std::string bin_file = elf_file.stem().string() + ".bin";
    fs::path hex_file = "roms/firmware.hex";

    // 1) Extract tohost address
    uint32_t tohost_addr = 0;
    try {
        tohost_addr = get_tohost_addr(elf_file);
    } catch (const std::exception& e) {
        std::cout << std::left << std::setw(TESTNAME_LENGTH) << elf_file.stem().string() 
            << YELLOW << "[SKIP] " << RESET << e.what() << std::endl;
        return;
    }

    // 2) Objcopy ELF to BIN, then BIN to HEX
    if (std::system(("riscv32-unknown-elf-objcopy -O binary " + elf_file.string() + " " + bin_file).c_str()) != 0)
        throw std::runtime_error("Objcopy failed");

    bin_to_hex(bin_file, hex_file);
    fs::remove(bin_file); // Cleanup

    // 3) Set up simulation
    VerilatedContext* contextp = new VerilatedContext;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    Vhp_soc* dut = new Vhp_soc{contextp};

    contextp->traceEverOn(true);
    dut->trace(tfp, 99);
    tfp->open(("logs/waves/" + elf_file.stem().string() + ".vcd").c_str());

    int time = 0;
    dut->clk = 0; dut->rst = 1; dut->eval(); tfp->dump(time++);

    // Reset sequence
    for (int i = 0; i < 2; i++) {
        dut->clk = 1; dut->eval(); tfp->dump(time++);
        dut->clk = 0; dut->eval(); tfp->dump(time++);
    }
    dut->rst = 0;

    // 4) Run simulation until tohost is written or timeout occurs
    bool test_done = false;
    bool isPassing = false;
    uint32_t failing_test_num = 0;
    int cycle = 0;

    while (!test_done && cycle < MAX_SIM_CYCLES) {
        dut->clk = 1; dut->eval(); tfp->dump(time++);

        // Snooping the memory bus for 'tohost' writes
        if (dut->hp_soc->data_mem->get_we() != 0) {
            if (dut->hp_soc->data_mem->get_addr() == tohost_addr) {
                uint32_t tohost_val = dut->hp_soc->data_mem->get_wdata();

                if (tohost_val == 1) {
                    isPassing = true;
                    test_done = true;
                } else if (tohost_val > 1) {
                    isPassing = false;
                    test_done = true;
                    failing_test_num = tohost_val >> 1;
                }
            }
        }

        dut->clk = 0; dut->eval(); tfp->dump(time++);
        cycle++;
    }

    // 5) Print Results
    std::cout << std::left << std::setw(TESTNAME_LENGTH) << elf_file.stem().string();

    if (isPassing) {
        std::cout << GREEN << "[PASS]" << RESET << std::endl;
    } else if (!test_done) {
        std::cout << RED << "[TIMEOUT]" << RESET << " Exceeded " << MAX_SIM_CYCLES << " cycles." << std::endl;
    } else {
        std::cout << RED << "[FAIL]" << RESET << " Failed at sub-test: " << failing_test_num << std::endl;
    }

    // Cleanup
    tfp->flush(); tfp->close();
    delete tfp; delete dut; delete contextp;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    std::vector<fs::path> test_files;
    fs::path target_isa_dir = fs::path(TEST_DIR);

    if (fs::exists(target_isa_dir) && fs::is_directory(target_isa_dir)) {
        for (auto& entry : fs::recursive_directory_iterator(target_isa_dir)) {
            if (entry.is_regular_file()) {
                std::string filename = entry.path().filename().string();
                
                // 1. Must have no extension (ELF file)
                // 2. Must start with "rv32ui-p-" (the actual test payloads)
                if (entry.path().extension().empty() && filename.find("rv32ui-p-") == 0) {
                    test_files.push_back(entry.path());
                }
            }
        }
    } else {
        std::cerr << "Error: '" << target_isa_dir.string() << "' directory not found.\n";
        return 1;
    }

    std::sort(test_files.begin(), test_files.end());

    std::cout << "\n--- Running RISC-V Official Tests ---\n";
    for (const auto& elf_file : test_files) {
        run_riscv_test(elf_file);
    }

    return 0;
}
