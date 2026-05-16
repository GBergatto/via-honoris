#ifndef TB_COMMON_HPP
#define TB_COMMON_HPP

#include <iostream>
#include <cstdint>
#include <string>

/// Global failure count
static int failures = 0;

/// Assert-style checker (prints pass/fail but never aborts)
inline void check(const std::string &name, uint32_t got, uint32_t exp) {
    if (got != exp) {
        std::cerr << "× FAIL: " << name
                  << " | expected=0x" << std::hex << exp
                  << " got=0x"     << std::hex << got
                  << std::dec << "\n";
        ++failures;
    } else {
        std::cout << "✓ PASS: " << name
                  << " | value=0x" << std::hex << got
                  << std::dec << "\n";
    }
}

/// Clock‐tick helper: raise then lower
template<typename T>
inline void tick(T *top) {
    top->clk = 1;
    top->eval();
    top->clk = 0;
    top->eval();
}

#endif // TB_COMMON_HPP

