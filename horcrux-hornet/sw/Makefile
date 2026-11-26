# ML-KEM-768 test for the HORNET SoC, built with HORNET's own rules (hornet/sw/common.mk: crt0, newlib
# syscalls on the UART, linker script, IMEM/DMEM images). Called by sw/build.sh.
#   VARIANT=baseline : HORCRUX repo's software-only sources, unchanged   -> runs on both systems
#   VARIANT=optimized: HORCRUX repo's accelerated sources, unchanged     -> needs the HORCRUX system
# rv32im, -O2, HORNET's default memories (64 KiB IMEM + 64 KiB DMEM), 32 KiB stack.
VARIANT ?= baseline
HORNET  ?= $(abspath ../hornet)
HORCRUX ?= $(abspath ../../HORCRUX)
SRC     := $(HORCRUX)/sw/applications/pqc/$(VARIANT)/KEM/ML-KEM/ml-kem-768

PROG       = mlkem768
SRCS       = mlkem_bench.c $(filter-out %/main.c %/randombytes.c,$(wildcard $(SRC)/*.c $(SRC)/*.S))
OUT       ?= $(abspath ../build/sw/$(VARIANT))
ISA       ?= rv32im
STACK_SIZE = 0x8000
USE_DOCKER = 0
CFLAGS    += -std=gnu11 -I$(SRC) -I$(CURDIR) -DHX_VARIANT=\"$(VARIANT)\"

include $(HORNET)/sw/common.mk
