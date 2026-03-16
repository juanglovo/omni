const std = @import("std");
const compressor = @import("compressor.zig");
const Filter = @import("filters/interface.zig").Filter;
const GitFilter = @import("filters/git.zig").GitFilter;
const BuildFilter = @import("filters/build.zig").BuildFilter;
const DockerFilter = @import("filters/docker.zig").DockerFilter;
const SqlFilter = @import("filters/sql.zig").SqlFilter;
const NodeFilter = @import("filters/node.zig").NodeFilter;
const CustomFilter = @import("filters/custom.zig").CustomFilter;
const DslEngine = @import("filters/dsl_engine.zig").DslEngine;
const DslFilterConfig = @import("filters/dsl_engine.zig").DslFilterConfig;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

/// Result structure for Wasm interaction.
/// Must be extern for Wasm ABI compatibility.
pub const CompressResult = extern struct {
    ptr: [*]u8,
    len: usize,
};

var global_filters: ?std.ArrayList(Filter) = null;
var global_custom_filter: ?*CustomFilter = null;
var global_dsl_engine: ?*DslEngine = null;

export fn init_engine() bool {
    if (global_filters != null) return true;
    
    var filters = std.ArrayList(Filter).empty;
    filters.append(allocator, GitFilter.filter()) catch return false;
    filters.append(allocator, BuildFilter.filter()) catch return false;
    filters.append(allocator, DockerFilter.filter()) catch return false;
    filters.append(allocator, SqlFilter.filter()) catch return false;
    filters.append(allocator, NodeFilter.filter()) catch return false;

    // Optional: Load custom rules if config exists in Wasm environment (might need pre-opened file)
    // Optional: Load custom rules
    if (CustomFilter.init(allocator, "omni_config.json")) |custom| {
        global_custom_filter = custom;
        filters.append(allocator, custom.filter()) catch {};
        
        // Try to load DSL filters from the same config if present
        // In a real impl, we'd parse the full JSON once, but for simplicity:
        const FullConfig = struct { dsl_filters: []DslFilterConfig };
        const content = std.fs.cwd().readFileAlloc(allocator, "omni_config.json", 1024 * 64) catch null;
        if (content) |raw_json| {
            defer allocator.free(raw_json);
            if (std.json.parseFromSlice(FullConfig, allocator, raw_json, .{ .ignore_unknown_fields = true })) |parsed| {
                if (DslEngine.init(allocator, parsed.value.dsl_filters)) |engine| {
                    global_dsl_engine = engine;
                    engine.getFilters(&filters) catch {};
                } else |_| {}
                parsed.deinit();
            } else |_| {}
        }
    } else |_| {}

    global_filters = filters;
    return true;
}

export fn alloc(len: usize) ?[*]u8 {
    const slice = allocator.alloc(u8, len) catch return null;
    return slice.ptr;
}

export fn free(ptr: [*]u8, len: usize) void {
    allocator.free(ptr[0..len]);
}

export fn compress(ptr: [*]u8, len: usize) u64 {
    const input = ptr[0..len];
    _ = init_engine(); // Ensure it's init
    
    const filters = if (global_filters) |f| f.items else &[_]Filter{};
    const result = compressor.compress(allocator, input, filters) catch |err| {
        const err_msg = std.fmt.allocPrint(allocator, "Error: {any}", .{err}) catch "Critical Error";
        return @as(u64, err_msg.len) << 32 | @as(u32, @truncate(@intFromPtr(err_msg.ptr)));
    };

    return @as(u64, result.len) << 32 | @as(u32, @truncate(@intFromPtr(result.ptr)));
}
pub fn main() void {}
