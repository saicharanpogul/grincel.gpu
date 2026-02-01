
void test_invert() {
    fe a, inv, res;
    fe_1(a); a[0] = 2; // 2
    fe_invert(inv, a);
    fe_mul(res, a, inv);
    
    uint8_t bytes[32];
    fe_tobytes(bytes, res);
    printf("2 * inv(2) = "); for(int i=0;i<32;i++) printf("%02x", bytes[i]); printf("\n");
}

void test_neg_mul() {
    fe zero, two, neg2, res;
    fe_0(zero);
    fe_1(two); two[0] = 2;
    fe_sub(neg2, zero, two);
    
    // neg2 represents -2 mod p = p-2.
    // (-2)^2 = 4.
    fe_sq(res, neg2);
    
    uint8_t bytes[32];
    fe_tobytes(bytes, res);
    printf("(-2)^2 = "); for(int i=0;i<32;i++) printf("%02x", bytes[i]); printf("\n");
}

int main() {
    test_neg_mul();
    test_invert();

    // Test Vector: Seed 0..0
    uint8_t seed[32] = {0};
    uint8_t public_key[32];
    uint8_t private_key[64];

    ed25519_create_keypair(seed, public_key, private_key);

    printf("Metal Logic Public Key (Seed 0..0): ");
    for(int i=0; i<32; i++) printf("%02x", public_key[i]);
    printf("\n");

    return 0;
}
