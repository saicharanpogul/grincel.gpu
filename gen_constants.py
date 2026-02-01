p = 2**255 - 19
d = -121665 * pow(121666, p-2, p) % p

def recover_x(y):
    # x^2 = (y^2 - 1) / (d*y^2 + 1)
    y2 = (y*y) % p
    num = (y2 - 1) % p
    den = (d * y2 + 1) % p
    x2 = (num * pow(den, p-2, p)) % p
    # x = x2^((p+3)/8)
    x = pow(x2, (p+3)//8, p)
    if (x*x) % p != x2:
        x = (x * pow(2, (p-1)//4, p)) % p
    if x % 2 == 1: # X base is odd? check ref
        # RFC8032: x is recovering x coordinate resulting in even X. 
        # But base point has x odd?
        # "The base point B is (x, 4/5) ... x is positive"
        # x calculated as ...
        pass
    # Base point x: 15112221349535400772501151409588531511454012693041857206046113283949847762202
    return x

y = (4 * pow(5, p-2, p)) % p
x = recover_x(y)
if x % 2 != 0: x = p - x # Force X to be EVEN (standard Ed25519 base point)

# Check against standard hex
# X: 216936d3cd6e53fec0a4e231fdd6dc5c692cc7609525a7b2c9562d608f25d51a
# Y: 6666666666666666666666666666666666666666666666666666666666666658

print(f"X: {x:x}")
print(f"Y: {y:x}")


def to_limbs(val):
    limbs = []
    for _ in range(5):
        limbs.append(val & ((1 << 51) - 1))
        val >>= 51
    return limbs

dx = to_limbs(d)
d2x = to_limbs((2 * d) % p)
bx = to_limbs(x)
by = to_limbs(y)

def print_limbs(name, limbs):
    print(f"constant uint64_t {name}[5] = {{")
    s = "    " + ", ".join(f"{v}ULL" for v in limbs)
    print(s)
    print("};")

print_limbs("ge_d", dx)
print_limbs("ge_d2", d2x)
print_limbs("ge_base_x", bx)
print_limbs("ge_base_y", by)

