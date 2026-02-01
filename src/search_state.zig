const std = @import("std");
const Pattern = @import("pattern.zig").Pattern;

pub const Keypair = struct {
    public: []const u8,
    private: []const u8,
};

pub const SearchState = struct {
    allocator: std.mem.Allocator,
    patterns: []Pattern,
    all_done: bool,
    keypair: ?Keypair,

    pub fn init(allocator: std.mem.Allocator, patterns: []Pattern) !SearchState {
        return SearchState{
            .allocator = allocator,
            .patterns = patterns,
            .all_done = false,
            .keypair = null,
        };
    }

    pub fn deinit(self: *SearchState) void {
        if (self.keypair) |kp| {
            self.allocator.free(kp.public);
            self.allocator.free(kp.private);
        }
    }

    pub fn checkResults(self: *SearchState) !void {
        var done = true;
        for (self.patterns) |pattern| {
            if (pattern.found_count < pattern.target_count) {
                done = false;
                break;
            }
        }
        self.all_done = done;
    }

    pub fn getFoundKeypair(self: *SearchState) Keypair {
        return self.keypair orelse unreachable;
    }
};
