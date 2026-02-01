const std = @import("std");
const GpuManager = @import("gpu.zig").GpuManager;
const Ed25519 = @import("ed25519.zig").Ed25519;
const Benchmark = @import("benchmark.zig").Benchmark;
const Pattern = @import("pattern.zig").Pattern;
const PatternOptions = @import("pattern.zig").PatternOptions;
const SearchState = @import("search_state.zig").SearchState;

const MAX_DEVICES = 8;
const WORKGROUP_SIZE = 256;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 1) {
        printUsage();
        return;
    }

    var patterns = std.ArrayList(Pattern).empty;
    defer {
        for (patterns.items) |*p| p.deinit();
        patterns.deinit(allocator);
    }

    var ignore_case = false;
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--ignore-case")) {
            ignore_case = true;
        } else if (std.mem.eql(u8, arg, "--starts-with")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            try parseAndAddPattern(allocator, &patterns, .startsWith, args[i], ignore_case);
        } else if (std.mem.eql(u8, arg, "--ends-with")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            try parseAndAddPattern(allocator, &patterns, .endsWith, args[i], ignore_case);
        } else if (std.mem.eql(u8, arg, "--starts-and-ends-with")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            try parseAndAddPattern(allocator, &patterns, .startsAndEndsWith, args[i], ignore_case);
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            printUsage();
            return;
        }
    }

    if (patterns.items.len == 0) {
        std.debug.print("Error: No patterns specified.\n", .{});
        printUsage();
        return;
    }

    // Initialize GPU backend
    var gpu = try GpuManager.init(allocator);
    defer gpu.deinit();


    std.debug.print("Using GPU backend: {s}\n", .{@tagName(gpu.backend)});
    std.debug.print("Patterns current: {d}\n", .{patterns.items.len});
    std.debug.print("Case-sensitive: {}\n", .{!ignore_case});

    // Normal vanity address search
    std.debug.print("Searching for Solana addresses matching patterns...\n", .{});

    // Initialize compute resources
    var search_state = try SearchState.init(allocator, patterns.items);
    defer search_state.deinit();

    // Main search loop
    while (!search_state.all_done) {
        try gpu.dispatchCompute(&search_state, WORKGROUP_SIZE);
        try search_state.checkResults();
    }

    std.debug.print("\nAll target matches found!\n", .{});
}

fn printUsage() void {
    std.debug.print(
        \\Usage: grincel [options]
        \\Options:
        \\  --starts-with <PREFIX>[:COUNT]              Find addresses starting with PREFIX
        \\  --ends-with <SUFFIX>[:COUNT]                Find addresses ending with SUFFIX
        \\  --starts-and-ends-with <PRE>:<SUF>[:COUNT]  Find addresses starting with PRE and ending with SUF
        \\  --ignore-case                               Case-insensitive matching
        \\  --help, -h                                  Show this help
        \\
    , .{});
}

fn parseAndAddPattern(
    allocator: std.mem.Allocator,
    patterns: *std.ArrayList(Pattern),
    mode: @import("pattern.zig").PatternMode,
    raw_arg: []const u8,
    ignore_case: bool,
) !void {
    var parts = std.mem.splitScalar(u8, raw_arg, ':');
    const part1 = parts.next() orelse return error.InvalidFormat;

    if (mode == .startsAndEndsWith) {
        const part2 = parts.next() orelse return error.InvalidFormat;
        const count_str = parts.next();
        const count = if (count_str) |s| try std.fmt.parseInt(usize, s, 10) else 1;
        try patterns.append(allocator, try Pattern.init(allocator, mode, part1, part2, count, .{ .ignore_case = ignore_case }));
    } else {
        const count_str = parts.next();
        const count = if (count_str) |s| try std.fmt.parseInt(usize, s, 10) else 1;
        try patterns.append(allocator, try Pattern.init(allocator, mode, part1, null, count, .{ .ignore_case = ignore_case }));
    }
}
