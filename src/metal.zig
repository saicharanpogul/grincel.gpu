const std = @import("std");
const SearchState = @import("search_state.zig").SearchState;
const Base58Module = @import("base58.zig");
const Base58 = Base58Module.Base58;
const Ed25519Module = @import("ed25519.zig");
const bindings = @import("metal_bindings.zig");

pub const Metal = struct {
    allocator: std.mem.Allocator,
    context: bindings.MetalContext,
    attempts: u64,
    start_time: i64,

    pub fn init(allocator: std.mem.Allocator) !Metal {
        // Read shader source
        // Embed shader sources
        const table_source = @embedFile("shaders/tables.h");
        const shader_src = @embedFile("shaders/vanity.metal");

        // Concatenate sources
        const full_source_len = table_source.len + shader_src.len + 1;
        const shader_source = try allocator.allocSentinel(u8, full_source_len, 0);
        @memcpy(shader_source[0..table_source.len], table_source);
        shader_source[table_source.len] = '\n';
        @memcpy(shader_source[table_source.len+1..full_source_len], shader_src);
        defer allocator.free(shader_source);

        const context = bindings.initMetal(shader_source);

        return Metal{
            .allocator = allocator,
            .context = context,
            .attempts = 0,
            .start_time = std.time.milliTimestamp(),
        };
    }

    pub fn deinit(self: *Metal) void {
        bindings.deinitMetal(self.context);
    }

    pub fn dispatchCompute(self: *Metal, state_ptr: *SearchState, workgroup_size: u32) !void {
        // Check if all patterns are done
        var all_done = true;
        for (state_ptr.patterns) |p| {
            if (p.found_count < p.target_count) {
                all_done = false;
                break;
            }
        }
        if (all_done) {
            state_ptr.all_done = true;
            return;
        }

        // Convert patterns to Metal format
        var metal_patterns = try self.allocator.alloc(bindings.MetalPattern, state_ptr.patterns.len);
        defer self.allocator.free(metal_patterns);

        for (state_ptr.patterns, 0..) |pattern, i| {
            var p_len: u32 = 0;
            var s_len: u32 = 0;
            
            if (pattern.mode == .endsWith) {
                s_len = @intCast(pattern.prefix.len);
                p_len = 0;
            } else {
                p_len = @intCast(pattern.prefix.len);
                if (pattern.suffix) |s| s_len = @intCast(s.len);
            }

            metal_patterns[i] = bindings.MetalPattern{
                .mode = switch (pattern.mode) {
                    .startsWith => 0,
                    .endsWith => 1,
                    .startsAndEndsWith => 2,
                },
                .prefix = undefined,
                .suffix = undefined,
                .prefix_len = p_len,
                .suffix_len = s_len,
                .ignore_case = if (pattern.options.ignore_case) 1 else 0,
            };
            @memset(&metal_patterns[i].prefix, 0);
            @memset(&metal_patterns[i].suffix, 0);
            
            if (pattern.mode == .endsWith) {
                @memcpy(metal_patterns[i].suffix[0..pattern.prefix.len], pattern.prefix);
            } else {
                @memcpy(metal_patterns[i].prefix[0..pattern.prefix.len], pattern.prefix);
                if (pattern.suffix) |s| {
                    @memcpy(metal_patterns[i].suffix[0..s.len], s);
                }
            }

        }

        const base_seed = @as(u64, @intCast(std.time.milliTimestamp())) + self.attempts;

        // Dispatch GPU work
        bindings.dispatchMetal(self.context, metal_patterns, base_seed, workgroup_size);

        // Check for results
        const result = bindings.checkResultsMetal(self.context);
        if (result.found != 0) {
            const p_idx = result.pattern_index;
            
            // If we've already found enough matches for this pattern, skip it
            if (state_ptr.patterns[p_idx].found_count >= state_ptr.patterns[p_idx].target_count) {
                // Continue searching for other patterns
            } else {
                // GPU found a pattern match! Now regenerate the keypair on CPU using correct Ed25519
                const keypair = Ed25519Module.Ed25519.generateKeypair(&result.seed);
                
                // Verify the address matches what GPU found
                var public_b58: [64]u8 = undefined;
                const pub_len = try Base58.encode(&public_b58, &keypair.public);
                const pub_str = public_b58[0..pub_len];

                // Verify the address actually matches the pattern (GPU insurance)
                if (state_ptr.patterns[p_idx].matches(pub_str)) {
                    state_ptr.patterns[p_idx].found_count += 1;
                    
                    if (state_ptr.patterns.len > 1) {
                        std.debug.print("\n[Pattern {d}: {s}] Found match {}/{}: {s}\n", .{
                            p_idx,
                            state_ptr.patterns[p_idx].prefix,
                            state_ptr.patterns[p_idx].found_count,
                            state_ptr.patterns[p_idx].target_count,
                            pub_str,
                        });
                    } else {
                        std.debug.print("\nFound match {}/{}: {s}\n", .{
                            state_ptr.patterns[p_idx].found_count,
                            state_ptr.patterns[p_idx].target_count,
                            pub_str,
                        });
                    }

                    // Save to file


                    // Save to file
                const filename = try std.fmt.allocPrint(self.allocator, "{s}.json", .{pub_str});
                defer self.allocator.free(filename);

                const file = try std.fs.cwd().createFile(filename, .{});
                defer file.close();

                // Write private key as byte array (Solana CLI format)
                try file.writeAll("[");
                for (keypair.private, 0..) |byte, i| {
                    if (i > 0) try file.writeAll(",");
                    const byte_str = try std.fmt.allocPrint(self.allocator, "{d}", .{byte});
                    defer self.allocator.free(byte_str);
                    try file.writeAll(byte_str);
                }
                try file.writeAll("]");

                // Update state
                if (state_ptr.keypair) |kp| {
                    self.allocator.free(kp.public);
                    self.allocator.free(kp.private);
                }
                
                // Convert private key to Base58 for state
                var priv_b58: [128]u8 = undefined;
                const priv_len = try Base58.encode(&priv_b58, &keypair.private);
                const priv_str = priv_b58[0..priv_len];
                
                state_ptr.keypair = .{
                    .public = try self.allocator.dupe(u8, pub_str),
                    .private = try self.allocator.dupe(u8, priv_str),
                };
            } // End of verification check
        }
    }

        self.attempts += workgroup_size * 256;

        // Log progress
        if (self.attempts % (1024 * 256) == 0) {
            const elapsed_ms = std.time.milliTimestamp() - self.start_time;
            const elapsed_secs = @as(f64, @floatFromInt(elapsed_ms)) / 1000.0;
            
            var total_matches: usize = 0;
            for (state_ptr.patterns) |p| {
                total_matches += p.found_count;
            }

            var num_buf: [32]u8 = undefined;
            var i: usize = 32;
            var v = self.attempts;
            var count: usize = 0;
            if (v == 0) {
                i -= 1;
                num_buf[i] = '0';
            } else {
                while (v > 0) {
                    if (count > 0 and count % 3 == 0) {
                        i -= 1;
                        num_buf[i] = '_';
                    }
                    i -= 1;
                    num_buf[i] = @intCast('0' + (v % 10));
                    v /= 10;
                    count += 1;
                }
            }
            const attempts_str = num_buf[i..];

            std.debug.print("Searched {s} keypairs in {d:.2}s. {d} matches found.\n", .{
                attempts_str,
                elapsed_secs,
                total_matches,
            });
        }
    }
};
