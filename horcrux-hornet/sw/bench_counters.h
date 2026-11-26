// mcycle/minstret readers (RV32: high halves re-read until stable). Same code as horcrux-boom/sw/bench_chipyard.h.


#ifndef BENCH_COUNTERS_H
#define BENCH_COUNTERS_H
#include <stdint.h>
#if __riscv_xlen == 32
#define BENCH_CSR64(lo, hi) ({ uint32_t h_, l_, h2_;                       \
    do { __asm__ volatile ("csrr %0, " #hi : "=r"(h_));                       \
         __asm__ volatile ("csrr %0, " #lo : "=r"(l_));                       \
         __asm__ volatile ("csrr %0, " #hi : "=r"(h2_)); } while (h_ != h2_); \
    ((uint64_t)h_ << 32) | l_; })
static inline uint64_t bench_cycles(void) { return BENCH_CSR64(mcycle, mcycleh); }
static inline uint64_t bench_instret(void) { return BENCH_CSR64(minstret, minstreth); }
#else
static inline uint64_t bench_cycles(void) { uint64_t v; __asm__ volatile ("csrr %0, mcycle" : "=r"(v)); return v; }
static inline uint64_t bench_instret(void) { uint64_t v; __asm__ volatile ("csrr %0, minstret" : "=r"(v)); return v; }
#endif
static inline uint32_t bench_clk_hz(void) { return 0; }  // simulation: cycles only
#endif
