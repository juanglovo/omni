// OMNI Local Metrics Subsystem
// Tracks your session stats locally for 'omni report' — no data ever leaves your machine.

const std = @import("std");

pub const Record = struct {
    timestamp: i64,
    agent: []const u8,
    input_bytes: usize,
    output_bytes: usize,
    ms: u64,
};

pub const Stats = struct {
    cmds: usize = 0,
    input: usize = 0,
    output: usize = 0,
    saved: usize = 0,
    ms: u64 = 0,

    pub fn add(self: *Stats, rec: Record) void {
        self.cmds += 1;
        self.input += rec.input_bytes;
        self.output += rec.output_bytes;
        if (rec.input_bytes > rec.output_bytes) {
            self.saved += rec.input_bytes - rec.output_bytes;
        }
        self.ms += rec.ms;
    }
};

pub const GroupedStats = struct {
    label: []const u8,
    stats: Stats,
};

pub fn parseCsvLine(allocator: std.mem.Allocator, line: []const u8) !Record {
    var it = std.mem.splitSequence(u8, line, ",");
    
    const ts_str = it.next() orelse return error.InvalidFormat;
    const agent_str = it.next() orelse return error.InvalidFormat;
    const in_str = it.next() orelse return error.InvalidFormat;
    const out_str = it.next() orelse return error.InvalidFormat;
    const ms_str = it.next() orelse return error.InvalidFormat;

    return Record{
        .timestamp = try std.fmt.parseInt(i64, ts_str, 10),
        .agent = try allocator.dupe(u8, agent_str),
        .input_bytes = try std.fmt.parseInt(usize, in_str, 10),
        .output_bytes = try std.fmt.parseInt(usize, out_str, 10),
        .ms = try std.fmt.parseInt(u64, ms_str, 10),
    };
}

pub fn formatBytes(allocator: std.mem.Allocator, bytes: usize) ![]u8 {
    if (bytes < 1000) {
        return std.fmt.allocPrint(allocator, "{d}", .{bytes});
    } else if (bytes < 1_000_000) {
        const val = @as(f64, @floatFromInt(bytes)) / 1000.0;
        return std.fmt.allocPrint(allocator, "{d:.1}K", .{val});
    } else if (bytes < 1_000_000_000) {
        const val = @as(f64, @floatFromInt(bytes)) / 1_000_000.0;
        return std.fmt.allocPrint(allocator, "{d:.1}M", .{val});
    } else {
        const val = @as(f64, @floatFromInt(bytes)) / 1_000_000_000.0;
        return std.fmt.allocPrint(allocator, "{d:.1}G", .{val});
    }
}

pub fn formatMs(allocator: std.mem.Allocator, total_ms: u64, cmds: usize) ![]u8 {
    if (cmds == 0) return std.fmt.allocPrint(allocator, "0ms", .{});
    const avg = total_ms / cmds;
    if (avg < 1000) {
        return std.fmt.allocPrint(allocator, "{d}ms", .{avg});
    } else {
        const s = @as(f64, @floatFromInt(avg)) / 1000.0;
        return std.fmt.allocPrint(allocator, "{d:.1}s", .{s});
    }
}

// Convert timestamp to YYYY-MM-DD string
pub fn toDailyLabel(allocator: std.mem.Allocator, ts: i64) ![]u8 {
    const epoch_seconds = @as(u64, @intCast(ts));
    const epoch = std.time.epoch.EpochSeconds{ .secs = epoch_seconds };
    const day = epoch.getEpochDay();
    const year_day = day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    return std.fmt.allocPrint(allocator, "{d:0>4}-{d:0>2}-{d:0>2}", .{
        year_day.year,
        month_day.month.numeric(),
        month_day.day_index + 1,
    });
}

// Convert timestamp to YYYY-MM string
pub fn toMonthlyLabel(allocator: std.mem.Allocator, ts: i64) ![]u8 {
    const epoch_seconds = @as(u64, @intCast(ts));
    const epoch = std.time.epoch.EpochSeconds{ .secs = epoch_seconds };
    const day = epoch.getEpochDay();
    const year_day = day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    return std.fmt.allocPrint(allocator, "{d:0>4}-{d:0>2}", .{
        year_day.year,
        month_day.month.numeric(),
    });
}

// Returns the starting day of the week (Monday)
pub fn toWeeklyLabel(allocator: std.mem.Allocator, ts: i64) ![]u8 {
    const epoch_seconds = @as(u64, @intCast(ts));
    const epoch = std.time.epoch.EpochSeconds{ .secs = epoch_seconds };
    const day = epoch.getEpochDay();
    
    // 1970-01-01 was Thursday (day 3 if Mon=0)
    // Calculate days since a known Monday
    const days_since_epoch = day.day;
    const day_of_week = (days_since_epoch + 3) % 7; // 0=Mon, 6=Sun
    
    const start_of_week_days = days_since_epoch - day_of_week;
    const end_of_week_days = start_of_week_days + 6;
    
    const start_ep: std.time.epoch.EpochDay = .{ .day = start_of_week_days };
    const start_yd = start_ep.calculateYearDay();
    const start_md = start_yd.calculateMonthDay();
    const end_ep: std.time.epoch.EpochDay = .{ .day = end_of_week_days };
    const end_yd = end_ep.calculateYearDay();
    const end_md = end_yd.calculateMonthDay();
    
    return std.fmt.allocPrint(allocator, "{d:0>2}-{d:0>2} -> {d:0>2}-{d:0>2}", .{
        start_md.month.numeric(),
        start_md.day_index + 1,
        end_md.month.numeric(),
        end_md.day_index + 1,
    });
}
