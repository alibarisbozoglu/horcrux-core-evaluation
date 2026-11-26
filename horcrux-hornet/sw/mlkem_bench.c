/* ML-KEM-768 KAT + cycle test with / without HORCRUX (same file in horcrux-ibex/sw and horcrux-hornet/sw).
 * Same flow and test vectors as the HORCRUX repository's main.c (sw/applications/pqc/.../ml-kem-768), with the
 * X-HEEP counter code replaced by mcycle / minstret (bench_counters.h). Output lines:
 *   cycles <op> <cycles> <instret>     op = keygen | encaps | decaps
 *   check <name> ok|MISMATCH
 *   result PASS|FAIL                   main returns the number of mismatches */
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "kem.h"
#include "randombytes.h"
#include "test_vectors_768.h"
#include "bench_counters.h"

static uint8_t pk[KYBER_PUBLICKEYBYTES], sk[KYBER_SECRETKEYBYTES], ct[KYBER_CIPHERTEXTBYTES];
static uint8_t key_a[KYBER_SSBYTES], key_b[KYBER_SSBYTES];
static int fails;

/* only the derandomised API is used; kem.c still references randombytes for crypto_kem_keypair/enc */
void randombytes(uint8_t *out, size_t outlen) { memset(out, 0, outlen); fails++; }

static void check(const char *name, const uint8_t *a, const uint8_t *b, size_t n)
{
    int bad = memcmp(a, b, n) != 0;
    fails += bad;
    printf("check %s %s\n", name, bad ? "MISMATCH" : "ok");
}

#define MEASURE(name, call) do {                                            \
    uint64_t c0 = bench_cycles(), i0 = bench_instret();                     \
    call;                                                                   \
    uint64_t c1 = bench_cycles(), i1 = bench_instret();                     \
    /* newlib-nano printf has no %llu; every count here is < 2^32 */        \
    printf("cycles %s %lu %lu\n", name, (unsigned long)(c1 - c0),          \
           (unsigned long)(i1 - i0));                                       \
} while (0)

int main(void)
{
    printf("ML-KEM-768 %s\n", HX_VARIANT);
    MEASURE("keygen", crypto_kem_keypair_derand(pk, sk, TVEC_IN_KEM_KEYPAIR[0]));
    check("pk", pk, TVEC_OUT_PK[0], sizeof pk);
    check("sk", sk, TVEC_OUT_SK[0], sizeof sk);
    MEASURE("encaps", crypto_kem_enc_derand(ct, key_b, pk, TVEC_IN_KEM_ENC[0]));
    check("ct", ct, TVEC_OUT_CT[0], sizeof ct);
    check("ss_enc", key_b, TVEC_OUT_SS[0], sizeof key_b);
    MEASURE("decaps", crypto_kem_dec(key_a, ct, sk));
    check("ss_dec", key_a, TVEC_OUT_SS[0], sizeof key_a);
    printf("result %s\n", fails ? "FAIL" : "PASS");
    return fails;
}
