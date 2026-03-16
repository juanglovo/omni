const std = @import("std");
const Filter = @import("interface.zig").Filter;

pub const DslAction = enum {
    keep,
    count,
};

pub const DslRule = struct {
    capture: []const u8,
    action: DslAction,
    as: ?[]const u8 = null,
};

pub const DslFilterConfig = struct {
    name: []const u8,
    trigger: []const u8,
    rules: []DslRule,
    output: []const u8,
};

pub const DslEngine = struct {
    allocator: std.mem.Allocator,
    filters: []DslFilterConfig,

    pub fn init(allocator: std.mem.Allocator, configs: []DslFilterConfig) !*DslEngine {
        const self = try allocator.create(DslEngine);
        self.* = .{
            .allocator = allocator,
            .filters = configs,
        };
        return self;
    }

    pub fn deinit(self: *DslEngine) void {
        self.allocator.destroy(self);
    }

    pub fn getFilters(self: *DslEngine, list: *std.ArrayList(Filter)) !void {
        for (self.filters) |*f| {
            try list.append(.{
                .name = f.name,
                .ptr = f,
                .matchFn = match,
                .processFn = process,
            });
        }
    }

    fn match(ptr: *anyopaque, input: []const u8) bool {
        const config: *DslFilterConfig = @ptrCast(@alignCast(ptr));
        return std.mem.indexOf(u8, input, config.trigger) != null;
    }

    fn process(ptr: *anyopaque, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        const config: *DslFilterConfig = @ptrCast(@alignCast(ptr));
        
        var vars = std.StringHashMap([]const u8).init(allocator);
        defer vars.deinit();
        
        var counters = std.StringHashMap(usize).init(allocator);
        defer counters.deinit();

        var it = std.mem.splitAny(u8, input, "\n\r");
        while (it.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t");
            if (trimmed.len == 0) continue;

            for (config.rules) |rule| {
                if (try captureVariables(allocator, trimmed, rule.capture, &vars)) {
                    if (rule.action == .count) {
                        const key = rule.as orelse rule.capture;
                        const entry = try counters.getOrPutValue(key, 0);
                        entry.value_ptr.* += 1;
                    }
                }
            }
        }

        return try formatOutput(allocator, config.output, &vars, &counters);
    }

    fn captureVariables(allocator: std.mem.Allocator, input: []const u8, pattern: []const u8, vars: *std.StringHashMap([]const u8)) !bool {
        _ = allocator;
        // Simplified capture: looks for {var} and tries to match literal parts around it
        // Example: "On branch {branch}" matches "On branch main" -> branch=main
        if (std.mem.indexOf(u8, pattern, "{")) |start_idx| {
            if (std.mem.indexOf(u8, pattern[start_idx..], "}")) |end_rel| {
                const end_idx = start_idx + end_rel;
                const prefix = pattern[0..start_idx];
                const var_name = pattern[start_idx + 1 .. end_idx];
                const suffix = pattern[end_idx + 1 ..];

                if (std.mem.startsWith(u8, input, prefix)) {
                    const remain = input[prefix.len..];
                    if (suffix.len == 0) {
                        try vars.put(var_name, remain);
                        return true;
                    } else if (std.mem.indexOf(u8, remain, suffix)) |s_idx| {
                        try vars.put(var_name, remain[0..s_idx]);
                        return true;
                    }
                }
            }
        }
        return false;
    }

    fn formatOutput(allocator: std.mem.Allocator, template: []const u8, vars: *std.StringHashMap([]const u8), counters: *std.StringHashMap(usize)) ![]u8 {
        var result = std.ArrayList(u8).init(allocator);
        errdefer result.deinit();

        var i: usize = 0;
        while (i < template.len) {
            if (template[i] == '{') {
                if (std.mem.indexOf(u8, template[i..], "}")) |end_rel| {
                    const end_idx = i + end_rel;
                    const key = template[i + 1 .. end_idx];
                    
                    if (vars.get(key)) |val| {
                        try result.appendSlice(val);
                    } else if (counters.get(key)) |count| {
                        var buf: [32]u8 = undefined;
                        const s = std.fmt.bufPrint(&buf, "{d}", .{count}) catch "???";
                        try result.appendSlice(s);
                    } else {
                        try result.appendSlice(template[i .. end_idx + 1]);
                    }
                    i = end_idx + 1;
                    continue;
                }
            }
            try result.append(template[i]);
            i += 1;
        }
        return try result.toOwnedSlice();
    }
};
