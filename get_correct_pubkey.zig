const std = @import("std");
const Ed25519 = std.crypto.sign.Ed25519;

pub fn main() !void {
    const seed = [_]u8{0} ** 32;
    const keypair = try Ed25519.KeyPair.generateDeterministic(seed);
    std.debug.print("Correct Public Key (Seed 0..0): ", .{});
    for (keypair.public_key.bytes) |b| std.debug.print("{x:0>2}", .{b});
    std.debug.print("\n", .{});
}
