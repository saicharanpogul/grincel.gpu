import sys

# Ed25519 constants
P = 2**255 - 19
D = -121665 * pow(121666, -1, P) % P
I = pow(2, (P - 1) // 4, P)
By = 4 * pow(5, -1, P) % P
Bx = 15112221349535400772501151409588531511454012693041857206046113283949847762202

def edwards_add(P1, P2):
    x1, y1 = P1
    x2, y2 = P2
    x3 = (x1 * y2 + y1 * x2) * pow(1 + D * x1 * x2 * y1 * y2, -1, P) % P
    y3 = (y1 * y2 + x1 * x2) * pow(1 - D * x1 * x2 * y1 * y2, -1, P) % P
    return (x3, y3)

def edwards_double(P1):
    x1, y1 = P1
    x3 = (x1 * y1 + x1 * y1) * pow(1 + D * x1 * x1 * y1 * y1, -1, P) % P
    y3 = (y1 * y1 + x1 * x1) * pow(1 - D * x1 * x1 * y1 * y1, -1, P) % P
    return (x3, y3)

def scalarmult(P1, e):
    if e == 0: return (0, 1)
    Q = scalarmult(P1, e // 2)
    Q = edwards_double(Q)
    if e & 1:
        Q = edwards_add(Q, P1)
    return Q

# Generate 4-bit window table
# We process 4 bits at a time. Total 256 bits / 4 = 64 groups.
# For each group i (0..63), we precompute P_i[v] = v * 2^(4*i) * B
# where v is in [1..15]. However, usually we precompute 
# B_table[i][j] = (j+1) * 2^(4*i) * Base
#
# Optimization: We can store points in Extended Coordinates (X, Y, Z, T)
# But to save space/bandwidth, we can stick to Affine or Projective.
# Let's generate Affine (x, y) first and convert to Extended on GPU if needed.

# Actually, standard comb method precomputes:
# Base * 2^0, Base * 2^1, ... Base * 2^255
#
# But simple 4-bit window usually means:
# table[i][j] = (j) * 2^(4*i) * Base, for j=0..15, i=0..63
#
# Wait, typically we just need `16 * 32 = 512` entries if we do Comb.
# Or `8 * 32` for 8-bit window.
#
# Let's do a simple 4-bit window (radix-16).
# Outer loop: 64 iterations (256/4).
# Inner loop: look up table[digit * 64 + iter].
# Table size: 16 (digits) * 64 (positions) = 1024 points.
# Each point is (X, Y) = 64 bytes. Total 64KB. This fits in constant memory (usually 64KB limit).

B = (Bx, By)

def to_hex(val):
    # Little endian 32-byte hex array
    bytes_val = [(val >> (8 * i)) & 0xFF for i in range(32)]
    return "{" + ", ".join([f"0x{b:02x}" for b in bytes_val]) + "}"

def main():
    print("// Precomputed Ed25519 Base Point Table")
    print("// 4-bit window, 64 positions. Table[pos][digit]")
    print("// Stored as Affine coordinates (x, y) to save space. Z=1, T=x*y")
    print("#include <metal_stdlib>")
    print("using namespace metal;")
    print("")
    print("constant uint8_t base_table_x[64][16][32] = {")
    
    # Debug: Print 16*Base (i=0, nibble=0 is 0. Wait. Table[0][1] is 1*Base. Table[1][1] is 16*Base)
    # Actually 16 is "16 * 1".
    # 16 = 0x10.
    # a[0]=0x10.
    # i=0 (bits 0-3): nibble = 0.
    # i=1 (bits 4-7): nibble = 1.
    # So we want Table[1][1].
    P16 = scalarmult(B, 16)
    val16 = P16[1] | ((P16[0] & 1) << 255)
    print("// Debug 16*Base Hex: " + "".join([f"{b:02x} " for b in val16.to_bytes(32, 'little')]))
    
    table_x = []
    table_y = []

    # Iterate over 64 positions (4-bit chunks)
    for pos in range(64):
        shift = pos * 4
        # Base for this position: 2^(shift) * B
        BasePos = scalarmult(B, 1 << shift)
        
        row_x = []
        row_y = []
        
        # Iterate over 16 digit values
        for digit in range(16):
            # Point = digit * BasePos = digit * 2^(4*pos) * B
            P_val = scalarmult(BasePos, digit)
            row_x.append(to_hex(P_val[0]))
            row_y.append(to_hex(P_val[1]))
            
        print("  { // Position " + str(pos))
        print("    " + ",\n    ".join(row_x))
        print("  },")
        
        table_x.append(row_x)
        table_y.append(row_y)
        
    print("};")
    print("")
    print("constant uint8_t base_table_y[64][16][32] = {")
    for pos in range(64):
        print("  { // Position " + str(pos))
        print("    " + ",\n    ".join(table_y[pos]))
        print("  },")
    print("};")

if __name__ == "__main__":
    main()
