#include <metal_stdlib>
using namespace metal;

// ============================================================================
// SHA-512 Implementation
// ============================================================================

constant uint64_t K[80] = {
    0x428a2f98d728ae22ULL, 0x7137449123ef65cdULL, 0xb5c0fbcfec4d3b2fULL, 0xe9b5dba58189dbbcULL,
    0x3956c25bf348b538ULL, 0x59f111f1b605d019ULL, 0x923f82a4af194f9bULL, 0xab1c5ed5da6d8118ULL,
    0xd807aa98a3030242ULL, 0x12835b0145706fbeULL, 0x243185be4ee4b28cULL, 0x550c7dc3d5ffb4e2ULL,
    0x72be5d74f27b896fULL, 0x80deb1fe3b1696b1ULL, 0x9bdc06a725c71235ULL, 0xc19bf174cf692694ULL,
    0xe49b69c19ef14ad2ULL, 0xefbe4786384f25e3ULL, 0x0fc19dc68b8cd5b5ULL, 0x240ca1cc77ac9c65ULL,
    0x2de92c6f592b0275ULL, 0x4a7484aa6ea6e483ULL, 0x5cb0a9dcbd41fbd4ULL, 0x76f988da831153b5ULL,
    0x983e5152ee66dfabULL, 0xa831c66d2db43210ULL, 0xb00327c898fb213fULL, 0xbf597fc7beef0ee4ULL,
    0xc6e00bf33da88fc2ULL, 0xd5a79147930aa725ULL, 0x06ca6351e003826fULL, 0x142929670a0e6e70ULL,
    0x27b70a8546d22ffcULL, 0x2e1b21385c26c926ULL, 0x4d2c6dfc5ac42aedULL, 0x53380d139d95b3dfULL,
    0x650a73548baf63deULL, 0x766a0abb3c77b2a8ULL, 0x81c2c92e47edaee6ULL, 0x92722c851482353bULL,
    0xa2bfe8a14cf10364ULL, 0xa81a664bbc423001ULL, 0xc24b8b70d0f89791ULL, 0xc76c51a30654be30ULL,
    0xd192e819d6ef5218ULL, 0xd69906245565a910ULL, 0xf40e35855771202aULL, 0x106aa07032bbd1b8ULL,
    0x19a4c116b8d2d0c8ULL, 0x1e376c085141ab53ULL, 0x2748774cdf8eeb99ULL, 0x34b0bcb5e19b48a8ULL,
    0x391c0cb3c5c95a63ULL, 0x4ed8aa4ae3418acbULL, 0x5b9cca4f7763e373ULL, 0x682e6ff3d6b2b8a3ULL,
    0x748f82ee5defb2fcULL, 0x78a5636f43172f60ULL, 0x84c87814a1f0ab72ULL, 0x8cc702081a6439ecULL,
    0x90befffa23631e28ULL, 0xa4506cebde82bde9ULL, 0xbef9a3f7b2c67915ULL, 0xc67178f2e372532bULL,
    0xca273eceea26619cULL, 0xd186b8c721c0c207ULL, 0xeada7dd6cde0eb1eULL, 0xf57d4f7fee6ed178ULL,
    0x06f067aa72176fbaULL, 0x0a637dc5a2c898a6ULL, 0x113f9804bef90daeULL, 0x1b710b35131c471bULL,
    0x28db77f523047d84ULL, 0x32caab7b40c72493ULL, 0x3c9ebe0a15c9bebcULL, 0x431d67c49c100d4cULL,
    0x4cc5d4becb3e42b6ULL, 0x597f299cfc657e2aULL, 0x5fcb6fab3ad6faecULL, 0x6c44198c4a475817ULL
};

#define ROR64(x, n) (((x) >> (n)) | ((x) << (64 - (n))))
#define SHR64(x, n) ((x) >> (n))

void sha512_transform(thread uint64_t state[8], const thread uint8_t block[128]) {
    uint64_t W[80];
    
    for (int i = 0; i < 16; i++) {
        W[i] = ((uint64_t)block[i*8] << 56) | ((uint64_t)block[i*8+1] << 48) |
               ((uint64_t)block[i*8+2] << 40) | ((uint64_t)block[i*8+3] << 32) |
               ((uint64_t)block[i*8+4] << 24) | ((uint64_t)block[i*8+5] << 16) |
               ((uint64_t)block[i*8+6] << 8) | ((uint64_t)block[i*8+7]);
    }
    
    for (int i = 16; i < 80; i++) {
        uint64_t s0 = ROR64(W[i-15], 1) ^ ROR64(W[i-15], 8) ^ SHR64(W[i-15], 7);
        uint64_t s1 = ROR64(W[i-2], 19) ^ ROR64(W[i-2], 61) ^ SHR64(W[i-2], 6);
        W[i] = W[i-16] + s0 + W[i-7] + s1;
    }
    
    uint64_t a = state[0], b = state[1], c = state[2], d = state[3];
    uint64_t e = state[4], f = state[5], g = state[6], h = state[7];
    
    for (int i = 0; i < 80; i++) {
        uint64_t S1 = ROR64(e, 14) ^ ROR64(e, 18) ^ ROR64(e, 41);
        uint64_t ch = (e & f) ^ ((~e) & g);
        uint64_t temp1 = h + S1 + ch + K[i] + W[i];
        uint64_t S0 = ROR64(a, 28) ^ ROR64(a, 34) ^ ROR64(a, 39);
        uint64_t maj = (a & b) ^ (a & c) ^ (b & c);
        uint64_t temp2 = S0 + maj;
        
        h = g; g = f; f = e; e = d + temp1;
        d = c; c = b; b = a; a = temp1 + temp2;
    }
    
    state[0] += a; state[1] += b; state[2] += c; state[3] += d;
    state[4] += e; state[5] += f; state[6] += g; state[7] += h;
}

void sha512(const thread uint8_t *data, uint32_t len, thread uint8_t output[64]) {
    uint64_t state[8] = {
        0x6a09e667f3bcc908ULL, 0xbb67ae8584caa73bULL, 0x3c6ef372fe94f82bULL, 0xa54ff53a5f1d36f1ULL,
        0x510e527fade682d1ULL, 0x9b05688c2b3e6c1fULL, 0x1f83d9abfb41bd6bULL, 0x5be0cd19137e2179ULL
    };
    
    uint8_t block[128];
    uint32_t i = 0;
    
    while (i + 128 <= len) {
        for (int j = 0; j < 128; j++) block[j] = data[i + j];
        sha512_transform(state, block);
        i += 128;
    }
    
    uint32_t remaining = len - i;
    for (uint32_t j = 0; j < remaining; j++) block[j] = data[i + j];
    block[remaining] = 0x80;
    
    if (remaining >= 112) {
        for (uint32_t j = remaining + 1; j < 128; j++) block[j] = 0;
        sha512_transform(state, block);
        for (int j = 0; j < 112; j++) block[j] = 0;
    } else {
        for (uint32_t j = remaining + 1; j < 112; j++) block[j] = 0;
    }
    
    uint64_t bit_len = (uint64_t)len * 8;
    for (int j = 0; j < 8; j++) block[120 + j] = (bit_len >> (56 - j * 8)) & 0xFF;
    sha512_transform(state, block);
    
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            output[i * 8 + j] = (state[i] >> (56 - j * 8)) & 0xFF;
        }
    }
}

// ============================================================================
// Field Arithmetic for GF(2^255-19) - Curve25519 (5-limb 64-bit radix-2^51)
// ============================================================================

typedef uint64_t fe[5];

constant uint64_t ge_base_x[5] = {
    1738742601995546ULL, 1146398526822698ULL, 2070867633025821ULL, 562264141797630ULL, 587772402128613ULL
};

constant uint64_t ge_base_y[5] = {
    1801439850948184ULL, 1351079888211148ULL, 450359962737049ULL, 900719925474099ULL, 1801439850948198ULL
};

constant uint64_t ge_d[5] = {
    929955233495203ULL, 466365720129213ULL, 1662059464998953ULL, 2033849074728123ULL, 1442794654840575ULL
};

constant uint64_t ge_d2[5] = {
    1859910466990425ULL, 932731440258426ULL, 1072319116312658ULL, 1815898335770999ULL, 633789495995903ULL
};

void fe_0(thread fe h) {
    for (int i = 0; i < 5; i++) h[i] = 0;
}

void fe_1(thread fe h) {
    h[0] = 1;
    for (int i = 1; i < 5; i++) h[i] = 0;
}

void fe_copy(thread fe h, const thread fe f) {
    for (int i = 0; i < 5; i++) h[i] = f[i];
}

void fe_add(thread fe h, const thread fe f, const thread fe g) {
    for (int i = 0; i < 5; i++) h[i] = f[i] + g[i];
}

void fe_sub(thread fe h, const thread fe f, const thread fe g) {
    // f - g + 2p to avoid underflow
    // 2^51 bits of 2p:
    // L0: 2^51 - 38 = 0x7FFFFFFFFFFDA
    // L1..L4: 2^51 - 2 (since 2*2^255 = 2^256, so 2p = 2^256-38? No. 
    // 2p = 2^256 - 38.
    // Limbs of 2^256: L0=... L4=2^51? No.
    // L4 bit 51 is 2^255 * 2 = 2^256.
    // So 2p = 2^256 - 38.
    // 2^256 = (2^51)^5 * 2 => bit 0 of limb 5.
    // Representation:
    // L0 = 0x7FFFFFFFFFFDA
    // L1 = 0x7FFFFFFFFFFFF
    // L2 = 0x7FFFFFFFFFFFF
    // L3 = 0x7FFFFFFFFFFFF
    // L4 = 0x7FFFFFFFFFFFF
    // This adds 2^256 - 38.
    
    h[0] = f[0] - g[0] + 0x7FFFFFFFFFFDAULL;
    h[1] = f[1] - g[1] + 0x7FFFFFFFFFFFFULL;
    h[2] = f[2] - g[2] + 0x7FFFFFFFFFFFFULL;
    h[3] = f[3] - g[3] + 0x7FFFFFFFFFFFFULL;
    h[4] = f[4] - g[4] + 0xFFFFFFFFFFFFFULL;
}

// 128-bit accumulation helper
struct uint128 {
    uint64_t lo;
    uint64_t hi;
};

void add128(thread uint128 &acc, uint64_t lo, uint64_t hi) {
    uint64_t old_lo = acc.lo;
    acc.lo += lo;
    acc.hi += hi + (acc.lo < old_lo ? 1 : 0);
}

void mul_add(thread uint128 &acc, uint64_t a, uint64_t b) {
    add128(acc, a * b, mulhi(a, b));
}

void fe_mul(thread fe h, const thread fe f, const thread fe g) {
    uint128 t0 = {0,0}, t1 = {0,0}, t2 = {0,0}, t3 = {0,0}, t4 = {0,0};
    
    uint64_t f0 = f[0], f1 = f[1], f2 = f[2], f3 = f[3], f4 = f[4];
    uint64_t g0 = g[0], g1 = g[1], g2 = g[2], g3 = g[3], g4 = g[4];
    
    // t0 = f0g0 + 19(f1g4 + f2g3 + f3g2 + f4g1)
    mul_add(t0, f0, g0);
    mul_add(t0, f1 * 19, g4);
    mul_add(t0, f2 * 19, g3);
    mul_add(t0, f3 * 19, g2);
    mul_add(t0, f4 * 19, g1);
    
    // t1 = f0g1 + f1g0 + 19(f2g4 + f3g3 + f4g2)
    mul_add(t1, f0, g1);
    mul_add(t1, f1, g0);
    mul_add(t1, f2 * 19, g4);
    mul_add(t1, f3 * 19, g3);
    mul_add(t1, f4 * 19, g2);
    
    // t2 = f0g2 + f1g1 + f2g0 + 19(f3g4 + f4g3)
    mul_add(t2, f0, g2);
    mul_add(t2, f1, g1);
    mul_add(t2, f2, g0);
    mul_add(t2, f3 * 19, g4);
    mul_add(t2, f4 * 19, g3);
    
    // t3 = f0g3 + f1g2 + f2g1 + f3g0 + 19(f4g4)
    mul_add(t3, f0, g3);
    mul_add(t3, f1, g2);
    mul_add(t3, f2, g1);
    mul_add(t3, f3, g0);
    mul_add(t3, f4 * 19, g4);
    
    // t4 = f0g4 + f1g3 + f2g2 + f3g1 + f4g0
    mul_add(t4, f0, g4);
    mul_add(t4, f1, g3);
    mul_add(t4, f2, g2);
    mul_add(t4, f3, g1);
    mul_add(t4, f4, g0);
    
    // Reduction
    uint64_t c0 = t0.lo & 0x7FFFFFFFFFFFFULL;
    uint64_t r0 = t0.lo >> 51 | t0.hi << 13;
    add128(t1, r0, t0.hi >> 51);
    
    uint64_t c1 = t1.lo & 0x7FFFFFFFFFFFFULL;
    uint64_t r1 = t1.lo >> 51 | t1.hi << 13;
    add128(t2, r1, t1.hi >> 51);
    
    uint64_t c2 = t2.lo & 0x7FFFFFFFFFFFFULL;
    uint64_t r2 = t2.lo >> 51 | t2.hi << 13;
    add128(t3, r2, t2.hi >> 51);
    
    uint64_t c3 = t3.lo & 0x7FFFFFFFFFFFFULL;
    uint64_t r3 = t3.lo >> 51 | t3.hi << 13;
    add128(t4, r3, t3.hi >> 51);
    
    uint64_t c4 = t4.lo & 0x7FFFFFFFFFFFFULL;
    uint64_t r4 = t4.lo >> 51 | t4.hi << 13;
    
    // r4 * 19 -> c0
    // Use uint128 to be safe against large inputs
    uint128 c4_carry_128 = {0,0};
    mul_add(c4_carry_128, r4, 19);
    
    // Add to c0
    uint128 c0_sum = {c0, 0};
    add128(c0_sum, c4_carry_128.lo, c4_carry_128.hi);
    
    // Reduce c0
    c0 = c0_sum.lo & 0x7FFFFFFFFFFFFULL;
    uint64_t c0_carry = (c0_sum.lo >> 51) | (c0_sum.hi << 13);
    
    // c1 += c0_carry
    c1 += c0_carry;
    
    h[0] = c0; h[1] = c1; h[2] = c2; h[3] = c3; h[4] = c4;
}

void fe_sq(thread fe h, const thread fe f) {
    fe_mul(h, f, f);
}

// Inversion using Fermat's little theorem: a^(p-2) mod p
void fe_invert(thread fe out, const thread fe z) {
    fe t0, t1, t2, t3;
    
    // 2
    fe_sq(t0, z);
    
    // 4
    fe_sq(t1, t0);
    
    // 8
    fe_sq(t1, t1);
    
    // 9
    fe_mul(t1, z, t1);
    
    // 11
    fe_mul(t0, t0, t1);
    
    // 22
    fe_sq(t2, t0);
    
    // 2^5 - 2^0 = 31
    fe_mul(t1, t1, t2);
    
    // 2^10 - 2^5
    fe_sq(t2, t1);
    for (int i = 1; i < 5; ++i) fe_sq(t2, t2);
    
    // 2^10 - 2^0
    fe_mul(t1, t2, t1);
    
    // 2^20 - 2^10
    fe_sq(t2, t1);
    for (int i = 1; i < 10; ++i) fe_sq(t2, t2);
    
    // 2^20 - 2^0
    fe_mul(t2, t2, t1);
    
    // 2^40 - 2^0
    fe_sq(t3, t2);
    for (int i = 1; i < 20; ++i) fe_sq(t3, t3);
    fe_mul(t2, t3, t2);
    
    // 2^50 - 2^0
    fe_sq(t2, t2);
    for (int i = 1; i < 10; ++i) fe_sq(t2, t2);
    fe_mul(t1, t2, t1);
    
    // 2^100 - 2^0
    fe_sq(t2, t1);
    for (int i = 1; i < 50; ++i) fe_sq(t2, t2);
    fe_mul(t2, t2, t1);
    
    // 2^200 - 2^0
    fe_sq(t3, t2);
    for (int i = 1; i < 100; ++i) fe_sq(t3, t3);
    fe_mul(t2, t3, t2);
    
    // 2^250 - 2^0
    fe_sq(t2, t2);
    for (int i = 1; i < 50; ++i) fe_sq(t2, t2);
    fe_mul(t1, t2, t1);
    
    // 2^255 - 2^5
    fe_sq(out, t1); // use out as scratch
    for (int i = 1; i < 5; ++i) fe_sq(out, out);
    
    // 2^255 - 21
    fe_mul(out, out, t0);
}

void fe_tobytes(thread uint8_t s[32], const thread fe h) {
    fe t;
    fe_copy(t, h);
    
    // First pass carry
    for (int i=0; i<4; i++) {
        t[i+1] += t[i] >> 51;
        t[i] &= 0x7FFFFFFFFFFFFULL;
    }
    t[0] += (t[4] >> 51) * 19;
    t[4] &= 0x7FFFFFFFFFFFFULL;

    // Second pass carry
    for (int i=0; i<4; i++) {
        t[i+1] += t[i] >> 51;
        t[i] &= 0x7FFFFFFFFFFFFULL;
    }
    t[0] += (t[4] >> 51) * 19;
    t[4] &= 0x7FFFFFFFFFFFFULL;
    
    // Check if >= p
    // p = 2^255 - 19
    // compute t + 19
    fe t_plus_19;
    fe_copy(t_plus_19, t);
    t_plus_19[0] += 19;
    
    for (int i=0; i<4; i++) {
        t_plus_19[i+1] += t_plus_19[i] >> 51;
        t_plus_19[i] &= 0x7FFFFFFFFFFFFULL;
    }
    
    // if t + 19 >= 2^255, then t >= p
    // 2^255 is bit 51 of limb 4.
    bool ge_p = (t_plus_19[4] >> 51) != 0;
    
    if (ge_p) {
        // result is t_plus_19 with cleared bit 255 (equivalent to subtracting p)
        t_plus_19[4] &= 0x7FFFFFFFFFFFFULL;
        fe_copy(t, t_plus_19);
    }
    
    // Pack to bytes
    s[0] = t[0];
    s[1] = t[0] >> 8;
    s[2] = t[0] >> 16;
    s[3] = t[0] >> 24;
    s[4] = t[0] >> 32;
    s[5] = t[0] >> 40;
    s[6] = (t[0] >> 48) | (t[1] << 3);
    s[7] = t[1] >> 5;
    s[8] = t[1] >> 13;
    s[9] = t[1] >> 21;
    s[10] = t[1] >> 29;
    s[11] = t[1] >> 37;
    s[12] = (t[1] >> 45) | (t[2] << 6);
    s[13] = t[2] >> 2;
    s[14] = t[2] >> 10;
    s[15] = t[2] >> 18;
    s[16] = t[2] >> 26;
    s[17] = t[2] >> 34;
    s[18] = t[2] >> 42;
    s[19] = (t[2] >> 50) | (t[3] << 1);
    s[20] = t[3] >> 7;
    s[21] = t[3] >> 15;
    s[22] = t[3] >> 23;
    s[23] = t[3] >> 31;
    s[24] = t[3] >> 39;
    s[25] = (t[3] >> 47) | (t[4] << 4);
    s[26] = t[4] >> 4;
    s[27] = t[4] >> 12;
    s[28] = t[4] >> 20;
    s[29] = t[4] >> 28;
    s[30] = t[4] >> 36;
    s[31] = t[4] >> 44;
}

void fe_frombytes(thread fe h, const thread uint8_t s[32]) {
    uint64_t v0 = ((uint64_t)s[0]) | ((uint64_t)s[1] << 8) | ((uint64_t)s[2] << 16) | ((uint64_t)s[3] << 24) | ((uint64_t)s[4] << 32) | ((uint64_t)s[5] << 40) | ((uint64_t)s[6] << 48);
    uint64_t v1 = ((uint64_t)s[6] >> 3) | ((uint64_t)s[7] << 5) | ((uint64_t)s[8] << 13) | ((uint64_t)s[9] << 21) | ((uint64_t)s[10] << 29) | ((uint64_t)s[11] << 37) | ((uint64_t)s[12] << 45);
    uint64_t v2 = ((uint64_t)s[12] >> 6) | ((uint64_t)s[13] << 2) | ((uint64_t)s[14] << 10) | ((uint64_t)s[15] << 18) | ((uint64_t)s[16] << 26) | ((uint64_t)s[17] << 34) | ((uint64_t)s[18] << 42) | ((uint64_t)s[19] << 50);
    uint64_t v3 = ((uint64_t)s[19] >> 1) | ((uint64_t)s[20] << 7) | ((uint64_t)s[21] << 15) | ((uint64_t)s[22] << 23) | ((uint64_t)s[23] << 31) | ((uint64_t)s[24] << 39) | ((uint64_t)s[25] << 47);
    uint64_t v4 = ((uint64_t)s[25] >> 4) | ((uint64_t)s[26] << 4) | ((uint64_t)s[27] << 12) | ((uint64_t)s[28] << 20) | ((uint64_t)s[29] << 28) | ((uint64_t)s[30] << 36) | ((uint64_t)s[31] << 44);
    
    h[0] = v0 & 0x7FFFFFFFFFFFFULL;
    h[1] = v1 & 0x7FFFFFFFFFFFFULL;
    h[2] = v2 & 0x7FFFFFFFFFFFFULL;
    h[3] = v3 & 0x7FFFFFFFFFFFFULL;
    h[4] = v4 & 0x7FFFFFFFFFFFFULL;
}

void fe_frombytes_constant(thread fe h, const constant uint8_t s[32]) {
    uint64_t v0 = ((uint64_t)s[0]) | ((uint64_t)s[1] << 8) | ((uint64_t)s[2] << 16) | ((uint64_t)s[3] << 24) | ((uint64_t)s[4] << 32) | ((uint64_t)s[5] << 40) | ((uint64_t)s[6] << 48);
    uint64_t v1 = ((uint64_t)s[6] >> 3) | ((uint64_t)s[7] << 5) | ((uint64_t)s[8] << 13) | ((uint64_t)s[9] << 21) | ((uint64_t)s[10] << 29) | ((uint64_t)s[11] << 37) | ((uint64_t)s[12] << 45);
    uint64_t v2 = ((uint64_t)s[12] >> 6) | ((uint64_t)s[13] << 2) | ((uint64_t)s[14] << 10) | ((uint64_t)s[15] << 18) | ((uint64_t)s[16] << 26) | ((uint64_t)s[17] << 34) | ((uint64_t)s[18] << 42) | ((uint64_t)s[19] << 50);
    uint64_t v3 = ((uint64_t)s[19] >> 1) | ((uint64_t)s[20] << 7) | ((uint64_t)s[21] << 15) | ((uint64_t)s[22] << 23) | ((uint64_t)s[23] << 31) | ((uint64_t)s[24] << 39) | ((uint64_t)s[25] << 47);
    uint64_t v4 = ((uint64_t)s[25] >> 4) | ((uint64_t)s[26] << 4) | ((uint64_t)s[27] << 12) | ((uint64_t)s[28] << 20) | ((uint64_t)s[29] << 28) | ((uint64_t)s[30] << 36) | ((uint64_t)s[31] << 44);
    
    h[0] = v0 & 0x7FFFFFFFFFFFFULL;
    h[1] = v1 & 0x7FFFFFFFFFFFFULL;
    h[2] = v2 & 0x7FFFFFFFFFFFFULL;
    h[3] = v3 & 0x7FFFFFFFFFFFFULL;
    h[4] = v4 & 0x7FFFFFFFFFFFFULL;
}

// ============================================================================
// Edwards Curve Point Operations (Continued in next part)
// ============================================================================

// Extended coordinates (X:Y:Z:T) where x=X/Z, y=Y/Z, xy=T/Z
struct ge_p3 {
    fe X, Y, Z, T;
};

struct ge_p2 {
    fe X, Y, Z;
};

struct ge_cached {
    fe YplusX, YminusX, Z, T2d;
};

// Base point (generator)


void ge_p3_0(thread ge_p3 *h) {
    fe_0(h->X);
    fe_1(h->Y);
    fe_1(h->Z);
    fe_0(h->T);
}

void ge_p3_to_p2(thread ge_p2 *r, const thread ge_p3 *p) {
    fe_copy(r->X, p->X);
    fe_copy(r->Y, p->Y);
    fe_copy(r->Z, p->Z);
}

void ge_p3_to_cached(thread ge_cached *r, const thread ge_p3 *p) {
    fe d2;
    for (int i = 0; i < 5; i++) d2[i] = ge_d2[i];
    
    fe_add(r->YplusX, p->Y, p->X);
    fe_sub(r->YminusX, p->Y, p->X);
    fe_copy(r->Z, p->Z);
    fe_mul(r->T2d, p->T, d2);
}

void ge_add(thread ge_p3 *r, const thread ge_p3 *p, const thread ge_cached *q) {
    fe t0, t1, t2, t3, t4, t5, t6, t7;
    
    fe_add(t0, p->Y, p->X);
    fe_mul(t1, t0, q->YplusX);
    fe_sub(t0, p->Y, p->X);
    fe_mul(t2, t0, q->YminusX);
    fe_mul(t3, q->T2d, p->T);
    fe_mul(t4, p->Z, q->Z);
    fe_add(t5, t4, t4);
    fe_sub(t6, t1, t2);
    fe_add(t7, t5, t3);
    fe_sub(t4, t5, t3);
    fe_add(t5, t1, t2);
    fe_mul(r->X, t6, t4);
    fe_mul(r->Y, t5, t7);
    fe_mul(r->Z, t4, t7);
    fe_mul(r->T, t6, t5);
}

void ge_double(thread ge_p3 *r, const thread ge_p2 *p) {
    fe t0, t1, t2, t3, t4;
    
    fe_sq(t0, p->X);
    fe_sq(t1, p->Y);
    fe_sq(t2, p->Z);
    fe_add(t2, t2, t2);
    fe_add(t3, p->X, p->Y);
    fe_sq(t4, t3);
    fe_add(t3, t0, t1);
    fe_sub(t4, t4, t3); // E
    fe_sub(t1, t1, t0); // G
    fe_sub(t2, t2, t1); // F = C - G
    
    fe_mul(r->X, t4, t2); // X3 = E * F
    fe_mul(r->Y, t3, t1); // Y3 = H * G. H = X^2+Y^2
    fe_mul(r->Z, t1, t2); // Z3 = F * G
    fe_mul(r->T, t4, t3); // T3 = E * H
}

// Scalar multiplication: h = a * B where B is the base point
// Scalar multiplication: h = a * B where B is the base point
// Optimized using 4-bit window precomputed table
void ge_scalarmult_base(thread ge_p3 *h, const thread uint8_t a[32]) {
    ge_p3_0(h);
    
    ge_cached c;
    fe x, y, t, t2d;
    
    // Constant 2*d
    fe d2;
    for (int i = 0; i < 5; i++) d2[i] = ge_d2[i];
    
    // Z is always 1 for affine points from table
    fe_1(c.Z);
    
    for (int i = 0; i < 64; i++) {
        uint8_t byte = a[i >> 1];
        uint8_t nibble = (i & 1) ? (byte >> 4) : (byte & 0xF);
        
        if (nibble > 0) {
            fe_frombytes_constant(x, base_table_x[i][nibble]);
            fe_frombytes_constant(y, base_table_y[i][nibble]);
            
            // Convert Affine (x, y) to Cached (Y+X, Y-X, Z, 2dT)
            fe_add(c.YplusX, y, x);
            fe_sub(c.YminusX, y, x);
            fe_mul(t, x, y);
            fe_mul(c.T2d, t, d2);
            
            ge_add(h, h, &c);
        }
    }
}

// Check if f is negative (LSB is 1 after reduction)
int fe_isnegative(const thread fe f) {
    uint8_t s[32];
    fe_tobytes(s, f);
    return s[0] & 1;
}

void ge_tobytes(thread uint8_t s[32], const thread ge_p3 *h) {
    fe recip, x, y;
    
    fe_invert(recip, h->Z);
    fe_mul(x, h->X, recip);
    fe_mul(y, h->Y, recip);
    fe_tobytes(s, y);
    s[31] ^= fe_isnegative(x) << 7;
}

// ============================================================================
// Ed25519 Key Generation
// ============================================================================

void ed25519_create_keypair(const thread uint8_t seed[32], thread uint8_t public_key[32], thread uint8_t private_key[64]) {
    uint8_t hash[64];
    sha512(seed, 32, hash);
    
    // Clamp the scalar
    hash[0] &= 248;
    hash[31] &= 127;
    hash[31] |= 64;
    
    // Compute public key = hash * base_point
    ge_p3 A;
    ge_scalarmult_base(&A, hash);
    ge_tobytes(public_key, &A);
    
    // Store private key (seed + public key)
    for (int i = 0; i < 32; i++) {
        private_key[i] = seed[i];
        private_key[32 + i] = public_key[i];
    }
}

// ============================================================================
// Base58 Encoding
// ============================================================================

constant char BASE58_ALPHABET[] = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

void base58_encode(const thread uint8_t *data, uint32_t len, thread char *output, thread uint32_t &out_len) {
    uint8_t digits[64] = {0};
    uint32_t digit_len = 1;
    
    for (uint32_t i = 0; i < len; i++) {
        uint32_t carry = data[i];
        for (uint32_t j = 0; j < digit_len; j++) {
            carry += (uint32_t)digits[j] << 8;
            digits[j] = carry % 58;
            carry /= 58;
        }
        while (carry > 0) {
            digits[digit_len++] = carry % 58;
            carry /= 58;
        }
    }
    
    uint32_t zeros = 0;
    while (zeros < len && data[zeros] == 0) zeros++;
    
    out_len = 0;
    for (uint32_t i = 0; i < zeros; i++) output[out_len++] = '1';
    for (int i = digit_len - 1; i >= 0; i--) output[out_len++] = BASE58_ALPHABET[digits[i]];
    output[out_len] = 0;
}

// ============================================================================
// Pattern Matching
// ============================================================================

bool matches_pattern(const thread char *address, uint32_t addr_len,
                    const constant char *pattern, uint32_t pattern_len,
                    uint32_t mode, bool ignore_case) {
    if (mode == 0) { // starts_with
        if (addr_len < pattern_len) return false;
        for (uint32_t i = 0; i < pattern_len; i++) {
            char a = address[i];
            char p = pattern[i];
            if (ignore_case) {
                if (a >= 'A' && a <= 'Z') a += 32;
                if (p >= 'A' && p <= 'Z') p += 32;
            }
            if (a != p) return false;
        }
        return true;
    } else if (mode == 1) { // ends_with
        if (addr_len < pattern_len) return false;
        uint32_t offset = addr_len - pattern_len;
        for (uint32_t i = 0; i < pattern_len; i++) {
            char a = address[offset + i];
            char p = pattern[i];
            if (ignore_case) {
                if (a >= 'A' && a <= 'Z') a += 32;
                if (p >= 'A' && p <= 'Z') p += 32;
            }
            if (a != p) return false;
        }
        return true;
    }
    return false;
}

// ============================================================================
// Kernel Entry Point
// ============================================================================

struct Pattern {
    uint32_t mode;
    char prefix[48];
    char suffix[48];
    uint32_t prefix_len;
    uint32_t suffix_len;
    uint32_t ignore_case;
};

struct Result {
    uint8_t seed[32];           // The 32-byte seed used to generate the keypair
    char address[48];           // Base58 encoded address (for display)
    uint32_t address_len;       // Length of address string
    uint32_t found;
    uint32_t pattern_index;
};

kernel void vanity_search(
    device Result *results [[buffer(0)]],
    constant Pattern *patterns [[buffer(1)]],
    constant uint32_t &num_patterns [[buffer(2)]],
    constant uint64_t &start_seed [[buffer(3)]],
    uint tid [[thread_position_in_grid]])
{
    // Generate 32-byte seed from 64-bit index
    // Generate 32-byte seed from 64-bit index
    uint8_t seed[32];
    uint64_t my_idx = start_seed + tid;
    
    for (int i = 0; i < 8; i++) {
        seed[i] = (my_idx >> (i * 8)) & 0xFF;
    }
    for (int i = 8; i < 32; i++) {
        seed[i] = 0;
    }
    
    // Generate keypair
    uint8_t public_key[32];
    uint8_t private_key[64];
    ed25519_create_keypair(seed, public_key, private_key);
    
    // Encode to Base58
    char b58[50];
    uint32_t len;
    base58_encode(public_key, 32, b58, len);
    
    // Check patterns
    for (uint32_t p = 0; p < num_patterns; p++) {
        bool match = true;
        
        if (patterns[p].mode == 0) { // starts_with
             if (len < patterns[p].prefix_len) { match = false; }
             else {
                 for (uint32_t k = 0; k < patterns[p].prefix_len; k++) {
                     if (b58[k] != patterns[p].prefix[k]) {
                         match = false;
                         break;
                     }
                 }
             }
        } else if (patterns[p].mode == 1) { // ends_with
             if (len < patterns[p].suffix_len) { match = false; }
             else {
                 for (uint32_t k = 0; k < patterns[p].suffix_len; k++) {
                     if (b58[len - patterns[p].suffix_len + k] != patterns[p].suffix[k]) {
                         match = false;
                         break;
                     }
                 }
             }
        }

        if (match) {
            results[0].found = 1;
            for(int k=0; k<32; k++) results[0].seed[k] = seed[k];
            for (int k=0; k<len; k++) results[0].address[k] = b58[k];
            results[0].address_len = len;
            results[0].pattern_index = p;
            return;
        }
    }

}
