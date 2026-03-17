const std = @import("std");
const Filter = @import("interface.zig").Filter;

pub const Action = enum {
    remove,
    mask,
};

pub const Rule = struct {
    name: []const u8,
    match: []const u8,
    action: Action,
};

pub const Config = struct {
    rules: []Rule,
};

pub const CustomFilter = struct {
    allocator: std.mem.Allocator,
    rules: std.ArrayList(Rule),
    parsed_configs: std.ArrayList(std.json.Parsed(Config)),

    pub fn init(allocator: std.mem.Allocator) !*CustomFilter {
        const self = try allocator.create(CustomFilter);
        self.* = .{
            .allocator = allocator,
            .rules = std.ArrayList(Rule).empty,
            .parsed_configs = std.ArrayList(std.json.Parsed(Config)).empty,
        };
        return self;
    }

    pub fn loadFromFile(self: *CustomFilter, config_path: []const u8) !void {
        const file = std.fs.cwd().openFile(config_path, .{}) catch return;
        defer file.close();

        const content = try file.readToEndAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(content);
        
        try self.loadFromContent(content);
    }

    pub fn loadFromContent(self: *CustomFilter, content: []const u8) !void {
        const parsed = std.json.parseFromSlice(Config, self.allocator, content, .{ .ignore_unknown_fields = true }) catch return;
        errdefer parsed.deinit();

        try self.parsed_configs.append(self.allocator, parsed);
        for (parsed.value.rules) |rule| {
            try self.rules.append(self.allocator, rule);
        }
    }

    pub fn deinit(self: *CustomFilter) void {
        for (self.parsed_configs.items) |*pc| {
            pc.deinit();
        }
        self.parsed_configs.deinit(self.allocator);
        self.rules.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    pub fn filter(self: *CustomFilter) Filter {
        return .{
            .name = "custom",
            .ptr = self,
            .matchFn = match,
            .scoreFn = score,
            .processFn = process,
        };
    }

    fn score(_: *anyopaque, _: []const u8) f32 {
        return 1.0; // User-defined rules are high-signal
    }

    fn match(ptr: *anyopaque, input: []const u8) bool {
        const self: *CustomFilter = @ptrCast(@alignCast(ptr));
        for (self.rules.items) |rule| {
            if (std.mem.indexOf(u8, input, rule.match) != null) return true;
        }
        return false;
    }

    fn process(ptr: *anyopaque, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        const self: *CustomFilter = @ptrCast(@alignCast(ptr));
        var current_output = try allocator.dupe(u8, input);
        errdefer allocator.free(current_output);

        for (self.rules.items) |rule| {
            if (std.mem.indexOf(u8, current_output, rule.match)) |_| {
                const next_output = switch (rule.action) {
                    .remove => try removeAll(allocator, current_output, rule.match),
                    .mask => try maskAll(allocator, current_output, rule.match),
                };
                allocator.free(current_output);
                current_output = next_output;
            }
        }
        return current_output;
    }

    fn removeAll(allocator: std.mem.Allocator, input: []const u8, match_str: []const u8) ![]u8 {
        var result = std.ArrayList(u8).empty;
        errdefer result.deinit(allocator);

        var last_index: usize = 0;
        while (std.mem.indexOf(u8, input[last_index..], match_str)) |index| {
            const actual_index = last_index + index;
            try result.appendSlice(allocator, input[last_index..actual_index]);
            last_index = actual_index + match_str.len;
        }
        try result.appendSlice(allocator, input[last_index..]);
        return try result.toOwnedSlice(allocator);
    }

    fn maskAll(allocator: std.mem.Allocator, input: []const u8, match_str: []const u8) ![]u8 {
        var result = std.ArrayList(u8).empty;
        errdefer result.deinit(allocator);

        var last_index: usize = 0;
        while (std.mem.indexOf(u8, input[last_index..], match_str)) |index| {
            const actual_index = last_index + index;
            try result.appendSlice(allocator, input[last_index..actual_index]);
            try result.appendSlice(allocator, "[MASKED]");
            last_index = actual_index + match_str.len;
        }
        try result.appendSlice(allocator, input[last_index..]);
        return try result.toOwnedSlice(allocator);
    }
};
