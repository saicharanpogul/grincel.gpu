const std = @import("std");

pub const PatternMode = enum {
    startsWith,
    endsWith,
    startsAndEndsWith,
};

pub const PatternOptions = struct {
    ignore_case: bool = false,
};

pub const Pattern = struct {
    mode: PatternMode,
    prefix: []const u8,
    suffix: ?[]const u8 = null,
    target_count: usize = 1,
    found_count: usize = 0,
    options: PatternOptions,
    allocator: std.mem.Allocator,

    pub fn init(
        allocator: std.mem.Allocator,
        mode: PatternMode,
        prefix: []const u8,
        suffix: ?[]const u8,
        target_count: usize,
        options: PatternOptions,
    ) !Pattern {
        return Pattern{
            .mode = mode,
            .prefix = try allocator.dupe(u8, prefix),
            .suffix = if (suffix) |s| try allocator.dupe(u8, s) else null,
            .target_count = target_count,
            .found_count = 0,
            .options = options,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Pattern) void {
        self.allocator.free(self.prefix);
        if (self.suffix) |s| self.allocator.free(s);
    }

    pub fn matches(self: Pattern, address: []const u8) bool {
        return switch (self.mode) {
            .startsWith => self.checkMatch(address, self.prefix, 0),
            .endsWith => if (address.len < self.prefix.len) false else self.checkMatch(address, self.prefix, address.len - self.prefix.len),
            .startsAndEndsWith => blk: {
                const s = self.suffix orelse break :blk false;
                if (address.len < self.prefix.len + s.len) break :blk false;
                break :blk self.checkMatch(address, self.prefix, 0) and
                    self.checkMatch(address, s, address.len - s.len);
            },
        };
    }

    fn checkMatch(self: Pattern, address: []const u8, pattern: []const u8, offset: usize) bool {
        if (address.len < offset + pattern.len) return false;

        for (pattern, 0..) |p_char, i| {
            const a_char = address[offset + i];
            if (self.options.ignore_case) {
                if (std.ascii.toLower(a_char) != std.ascii.toLower(p_char)) return false;
            } else {
                if (a_char != p_char) return false;
            }
        }
        return true;
    }
};
