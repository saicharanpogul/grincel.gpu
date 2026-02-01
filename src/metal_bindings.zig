const std = @import("std");

pub const MetalContext = extern struct {
    device: ?*anyopaque,
    commandQueue: ?*anyopaque,
    pipelineState: ?*anyopaque,
    resultsBuffer: ?*anyopaque,
    patternsBuffer: ?*anyopaque,
};

pub const MetalPattern = extern struct {
    mode: u32,
    prefix: [48]u8,
    suffix: [48]u8,
    prefix_len: u32,
    suffix_len: u32,
    ignore_case: u32,
};

pub const MetalResult = extern struct {
    seed: [32]u8,           // The 32-byte seed used to generate the keypair
    address: [48]u8,        // Base58 encoded address (for display)
    address_len: u32,       // Length of address string
    found: u32,
    pattern_index: u32,
};

extern fn init_metal(shader_source: [*:0]const u8) MetalContext;
extern fn dispatch_metal(ctx: MetalContext, patterns: [*]MetalPattern, num_patterns: u32, base_seed: u64, workgroup_size: u32) void;
extern fn check_results_metal(ctx: MetalContext) MetalResult;
extern fn deinit_metal(ctx: MetalContext) void;

pub fn initMetal(shader_source: [:0]const u8) MetalContext {
    return init_metal(shader_source.ptr);
}

pub fn dispatchMetal(ctx: MetalContext, patterns: []MetalPattern, base_seed: u64, workgroup_size: u32) void {
    dispatch_metal(ctx, patterns.ptr, @intCast(patterns.len), base_seed, workgroup_size);
}

pub fn checkResultsMetal(ctx: MetalContext) MetalResult {
    return check_results_metal(ctx);
}

pub fn deinitMetal(ctx: MetalContext) void {
    deinit_metal(ctx);
}
