#include "Vvirtus_soc.h"
#include "Vvirtus_soc_virtus_soc.h"
#include "Vvirtus_soc_virtus_core.h"
#include "Vvirtus_soc_regfile.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <map>
#include <sstream>
#include <yaml-cpp/yaml.h>  // requires yaml-cpp

namespace fs = std::filesystem;

#define TESTNAME_LENGTH 25
#define MAX_SIM_CYCLES 50000 // Timeout to prevent infinite loops
#define ROMS_DIR "roms"
#define FW_DIR "../../sw/build"
#define FIRMWARE_HEX "firmware.hex"
#define ASSEMBLER_CMD "riscv32-unknown-elf-as -march=rv32i_zicsr -mabi=ilp32 "
#define LINKER_CMD "riscv32-unknown-elf-ld -Ttext 0x80000000 -e 0x80000000 "

// ANSI colors helpers
#define RESET   "\033[0m"
#define RED     "\033[31m"
#define GREEN   "\033[32m"
#define YELLOW  "\033[33m"

// Convert firmware from binary into HEX
int bin_to_hex(const fs::path& bin_file, const fs::path& hex_file) {
    std::ifstream ifs(bin_file, std::ios::binary);
    if (!ifs) throw std::runtime_error("Cannot open " + bin_file.string());

    std::ofstream ofs(hex_file);
    if (!ofs) throw std::runtime_error("Cannot open " + hex_file.string());

    int n_instructions = 0;
    uint8_t buf[4];
    while (ifs.read(reinterpret_cast<char*>(buf), 4) || ifs.gcount() > 0) {
        // pad with zeros if less than 4 bytes at the end
        uint32_t word = 0;
        for (size_t i = 0; i < ifs.gcount(); ++i) {
            word |= buf[i] << (8 * i); // little-endian
        }
        ofs << std::hex << std::setw(8) << std::setfill('0') << word << "\n";
        n_instructions++;
    }
    return n_instructions;
}

// Assemble RISC-V assembly file into firmaware.hex
int assemble_to_hex(const fs::path& asm_file, const fs::path& hex_file) {
    std::string obj_file = asm_file.stem().string() + ".o";
    std::string elf_file = asm_file.stem().string() + ".elf";
    std::string bin_file = asm_file.stem().string() + ".bin";

    // Assemble to object file
    if (std::system((ASSEMBLER_CMD + asm_file.string() + " -o " + obj_file).c_str()) != 0)
        throw std::runtime_error("Assembler failed");

    // Link
    if (std::system((LINKER_CMD + obj_file + " -o " + elf_file).c_str()) != 0)
        throw std::runtime_error("Linker failed");

    // Objcopy to raw binary
    if (std::system(("riscv32-unknown-elf-objcopy -O binary " + elf_file
                    + " " + bin_file).c_str()) != 0)
        throw std::runtime_error("Objcopy failed");

    // Convert binary to hex
    int n_instructions = bin_to_hex(bin_file, hex_file);

    // Cleanup
    fs::remove(obj_file);
    fs::remove(elf_file);
    fs::remove(bin_file);

    return n_instructions;
}

void run_test(const fs::path& asm_file, const fs::path& yaml_file) {
    // 1) assemble program
    fs::path hex_file = fs::path(ROMS_DIR) / FIRMWARE_HEX;
    int n_instructions = assemble_to_hex(asm_file, hex_file);

    // 2) load expected register values from YAML file
    YAML::Node exp = YAML::LoadFile(yaml_file.string());
    std::map<int, uint32_t> expected;
    for (auto it = exp.begin(); it != exp.end(); ++it) {
        std::string reg = it->first.as<std::string>();
        int idx = std::stoi(reg.substr(1));
        uint32_t val = it->second.as<uint32_t>();
        expected[idx] = val;
    }

    // 3) set up simulation
    VerilatedContext* contextp = new VerilatedContext;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    Vvirtus_soc* dut = new Vvirtus_soc{contextp};

    contextp->traceEverOn(true);
    dut->trace(tfp, 99);
    tfp->open(("logs/waves/" + asm_file.stem().string() + ".vcd").c_str());

    int time = 0;
    dut->clk = 0;
    dut->rst = 1;
    dut->eval();
    tfp->dump(time++);

    // reset
    for (int i = 0; i < 2; i++) {
        dut->clk = 1; dut->eval(); tfp->dump(time++);
        dut->clk = 0; dut->eval(); tfp->dump(time++);
    }
    dut->rst = 0;

    // 4) run
    int cycle = 0;
    bool timeout = true;

    while (cycle < MAX_SIM_CYCLES) {
        dut->clk = 1; dut->eval(); tfp->dump(time++);
        dut->clk = 0; dut->eval(); tfp->dump(time++);
        cycle++;

        // Snoop for EBREAK
        if (dut->virtus_soc->core->is_sync_exception_W && dut->virtus_soc->core->csr_addr_W == 0x001) {
            timeout = false;
            break;
        }
    }

    // 5) check registers
    bool isPassing = true;
    std::stringstream log_buffer; // Buffer for register dump

    for (auto& [idx, exp_val] : expected) {
        uint32_t got = dut->virtus_soc->core->regfile_i->get_reg(idx);

        log_buffer << "   x" << std::dec << idx << "=0x" << std::hex << got;

        if (got != exp_val) {
            isPassing = false;
            log_buffer << " != 0x" << exp_val;
        }
        log_buffer << "\n";
    }

    // Print Test Name
    std::cout << std::left << std::setw(TESTNAME_LENGTH) << asm_file.stem().string();

    if (timeout) {
        std::cout << RED << "[TIMEOUT]" << RESET << std::endl;
        std::cout << log_buffer.str();
    } else if (isPassing) {
        std::cout << GREEN << "[PASS]" << RESET << std::endl;
    } else {
        std::cout << RED << "[FAIL]" << RESET << std::endl;
        std::cout << log_buffer.str(); // Dump all regs only on failure
    }

    // cleanup
    tfp->flush();
    tfp->close();
    delete tfp;
    delete dut;
    delete contextp;
}

void run_firmware(const std::string& prog_name, int max_cycles = 2000) {
    VerilatedContext* contextp = new VerilatedContext;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    Vvirtus_soc* dut = new Vvirtus_soc{contextp};

    contextp->traceEverOn(true);
    dut->trace(tfp, 99);

    std::string wave_path = "logs/waves/" + prog_name + ".vcd";
    tfp->open(wave_path.c_str());

    int time = 0;
    dut->clk = 0; dut->rst = 1; dut->eval(); tfp->dump(time++);

    for (int i = 0; i < 2; i++) {
        dut->clk = 1; dut->eval(); tfp->dump(time++);
        dut->clk = 0; dut->eval(); tfp->dump(time++);
    }
    dut->rst = 0;

    std::cout << YELLOW << ">>> Simulating Firmware '" << prog_name
        << "' for " << max_cycles << " cycles..." << RESET << std::endl;

    for (int cycle = 0; cycle < max_cycles; ++cycle) {
        dut->clk = 1; dut->eval(); tfp->dump(time++);
        dut->clk = 0; dut->eval(); tfp->dump(time++);
    }

    std::cout << GREEN << ">>> Simulation complete. Waveform saved to " << wave_path << RESET << "\n";

    tfp->flush(); tfp->close();
    delete tfp; delete dut; delete contextp;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // Parse command line for the --fw flag
    std::string fw_prog = "";
    for (int i = 1; i < argc; ++i) {
        if (std::string(argv[i]) == "--fw" && i + 1 < argc) {
            fw_prog = argv[i+1];
            break;
        }
    }

    // MODE B: Firmware simulation
    if (!fw_prog.empty()) {
        // Copy the generated firmware into the directory Verilator expects
        fs::copy_file(fs::path(FW_DIR) / FIRMWARE_HEX, fs::path(ROMS_DIR) / FIRMWARE_HEX, fs::copy_options::overwrite_existing);
        run_firmware(fw_prog, 2000); // Simulate for 2000 cycles
        return 0;
    }

    // MODE A: Unit testing
    std::vector<fs::path> test_files;
    if (fs::exists(ROMS_DIR) && fs::is_directory(ROMS_DIR)) {
        for (auto& entry : fs::recursive_directory_iterator(ROMS_DIR)) {
            if (entry.is_regular_file() && entry.path().extension() == ".s") {
                test_files.push_back(entry.path());
            }
        }
    } else {
        std::cerr << "Error: '"<< ROMS_DIR << "' directory not found.\n";
        return 1;
    }

    std::sort(test_files.begin(), test_files.end());
    fs::path last_parent_dir = "";

    for (const auto& asm_file : test_files) {
        fs::path yaml_file = asm_file;
        yaml_file.replace_extension(".yaml");

        // Logic to print directory header centered in the line
        fs::path current_parent_dir = asm_file.parent_path().filename();
        if (current_parent_dir != last_parent_dir) {
            std::string dirname = current_parent_dir.string();

            int target_width = TESTNAME_LENGTH + 6;
            int padding = target_width - (int)dirname.length() - 2;
            if (padding < 4) padding = 4; // Ensure at least 2 dashes per side

            int left_pad = padding / 2;
            int right_pad = padding - left_pad;

            std::cout << "\n" << std::string(left_pad, '-') << " "
                << dirname << " " << std::string(right_pad, '-') << std::endl;

            last_parent_dir = current_parent_dir;
        }

        if (fs::exists(yaml_file)) {
            run_test(asm_file, yaml_file);
        }
    }

    return 0;
}

