const std = @import("std");
const metrics = @import("local_metrics.zig");
const ui = @import("ui.zig");

pub const MonitorOptions = struct {
    filter_agent: ?[]const u8 = null,
    graph: bool = false,
    history: bool = false,
    daily: bool = false,
    weekly: bool = false,
    monthly: bool = false,
    all: bool = false,
    format_json: bool = false,
};

pub fn handleMonitor(allocator: std.mem.Allocator, opts: MonitorOptions) !void {
    const stdout = std.fs.File.stdout().deprecatedWriter();

    const home = std.posix.getenv("HOME") orelse return;
    const file_path = try std.fmt.allocPrint(allocator, "{s}/.omni/metrics.csv", .{home});
    defer allocator.free(file_path);

    var global_cmds: usize = 0;
    var global_in: usize = 0;
    var global_out: usize = 0;
    var global_saved: usize = 0;
    var global_ms: u64 = 0;

    var filter_map = std.StringHashMap(metrics.Stats).init(allocator);
    defer filter_map.deinit();

    var agent_map = std.StringHashMap(metrics.Stats).init(allocator);
    defer agent_map.deinit();

    var all_records = std.ArrayListUnmanaged(metrics.Record){};
    defer {
        for (all_records.items) |rec| {
            allocator.free(rec.agent);
            allocator.free(rec.filter_name);
        }
        all_records.deinit(allocator);
    }

    if (std.fs.cwd().openFile(file_path, .{})) |file| {
        defer file.close();
        const data = file.readToEndAlloc(allocator, 10 * 1024 * 1024) catch return;
        defer allocator.free(data);

        var it_lines = std.mem.splitSequence(u8, data, "\n");
        while (it_lines.next()) |ln| {
            if (ln.len == 0) continue;
            const rec = metrics.parseCsvLine(allocator, ln) catch continue;

            if (opts.filter_agent != null and !std.mem.eql(u8, rec.agent, opts.filter_agent.?)) {
                allocator.free(rec.agent);
                allocator.free(rec.filter_name);
                continue;
            }

            try all_records.append(allocator, rec);
            global_cmds += 1;
            global_in += rec.input_bytes;
            global_out += rec.output_bytes;
            if (rec.input_bytes > rec.output_bytes) global_saved += (rec.input_bytes - rec.output_bytes);
            global_ms += rec.ms;

            var f_res = try filter_map.getOrPut(rec.filter_name);
            if (!f_res.found_existing) f_res.value_ptr.* = .{};
            f_res.value_ptr.add(rec);

            var a_res = try agent_map.getOrPut(rec.agent);
            if (!a_res.found_existing) a_res.value_ptr.* = .{};
            a_res.value_ptr.add(rec);
        }
    } else |_| {
        try stdout.print(ui.DIM ++ "  No tracking data yet.\n" ++ ui.RESET, .{});
        return;
    }

    if (global_cmds == 0) {
        try stdout.print(ui.DIM ++ "  No tracking data yet.\n" ++ ui.RESET, .{});
        return;
    }

    // ═══════════════════════════════════════
    // DEFAULT SUMMARY
    // ═══════════════════════════════════════
    if (!opts.daily and !opts.weekly and !opts.monthly and !opts.all and !opts.graph and !opts.history and !opts.format_json) {
        try stdout.print("\n", .{});
        try ui.hline(stdout, .top);
        try ui.row(stdout, ui.BOLD ++ ui.WHITE ++ "OMNI Distillation Monitor" ++ ui.RESET);
        try ui.hline(stdout, .mid);

        const in_str = try metrics.formatBytes(allocator, global_in);
        const out_str = try metrics.formatBytes(allocator, global_out);
        const s_str = try metrics.formatBytes(allocator, global_saved);
        const total_ms_str = try metrics.formatMs(allocator, global_ms, 1);
        const avg_ms_str = try metrics.formatMs(allocator, global_ms, global_cmds);
        defer {
            allocator.free(in_str); allocator.free(out_str); allocator.free(s_str);
            allocator.free(total_ms_str); allocator.free(avg_ms_str);
        }

        const avg_pct = if (global_in > 0) (@as(f64, @floatFromInt(global_saved)) / @as(f64, @floatFromInt(global_in))) * 100.0 else 0.0;
        const s_buf = try std.fmt.allocPrint(allocator, "{s} ({d:.1}%)", .{ s_str, avg_pct }); defer allocator.free(s_buf);
        const t_buf = try std.fmt.allocPrint(allocator, "{s} (avg {s})", .{ total_ms_str, avg_ms_str }); defer allocator.free(t_buf);

        {
            const l = try std.fmt.allocPrint(allocator, ui.GRAY ++ "Distillations   " ++ ui.WHITE ++ "{d}" ++ ui.RESET, .{global_cmds});
            defer allocator.free(l); try ui.row(stdout, l);
        }
        {
            const l = try std.fmt.allocPrint(allocator, ui.GRAY ++ "Input           " ++ ui.WHITE ++ "{s}" ++ ui.RESET, .{in_str});
            defer allocator.free(l); try ui.row(stdout, l);
        }
        {
            const l = try std.fmt.allocPrint(allocator, ui.GRAY ++ "Output          " ++ ui.WHITE ++ "{s}" ++ ui.RESET, .{out_str});
            defer allocator.free(l); try ui.row(stdout, l);
        }
        {
            const l = try std.fmt.allocPrint(allocator, ui.GRAY ++ "Saved           " ++ ui.WHITE ++ "{s}" ++ ui.RESET, .{s_buf});
            defer allocator.free(l); try ui.row(stdout, l);
        }
        {
            const l = try std.fmt.allocPrint(allocator, ui.GRAY ++ "Latency         " ++ ui.WHITE ++ "{s}" ++ ui.RESET, .{t_buf});
            defer allocator.free(l); try ui.row(stdout, l);
        }

        try ui.row(stdout, "");
        const meter_w = 30;
        const filled = @min(@as(usize, @intFromFloat((avg_pct / 100.0) * 30.0)), 30);
        const color = ui.colorForPct(avg_pct);
        
        var mb = std.ArrayListUnmanaged(u8){};
        defer mb.deinit(allocator);
        const mbw = mb.writer(allocator);
        try mbw.print(ui.GRAY ++ "Efficiency  " ++ ui.RESET, .{});
        for (0..filled) |_| try mbw.print("{s}●" ++ ui.RESET, .{color});
        for (0..meter_w - filled) |_| try mbw.print(ui.DIM ++ "○" ++ ui.RESET, .{});
        try mbw.print(" " ++ ui.BOLD ++ "{s}{d:.1}%" ++ ui.RESET, .{ color, avg_pct });
        try ui.row(stdout, mb.items);
        try ui.hline(stdout, .bot);

        // Filter Performance
        if (filter_map.count() > 0) {
            try stdout.print("\n", .{}); try ui.hline(stdout, .top);
            try ui.row(stdout, ui.BOLD ++ ui.WHITE ++ "Filter Performance" ++ ui.RESET); try ui.hline(stdout, .mid);
            try ui.row(stdout, ui.BOLD ++ " #   Filter              Runs     Saved     Rate    Speed " ++ ui.RESET); try ui.hline(stdout, .mid);
            
            var rows = std.ArrayListUnmanaged(metrics.GroupedStats){};
            defer rows.deinit(allocator);
            var it = filter_map.iterator();
            while (it.next()) |entry| try rows.append(allocator, .{ .label = entry.key_ptr.*, .stats = entry.value_ptr.* });
            
            for (0..rows.items.len) |i| {
                for (0..rows.items.len - i - 1) |j| {
                    if (rows.items[j].stats.saved < rows.items[j + 1].stats.saved) {
                        const temp = rows.items[j]; rows.items[j] = rows.items[j + 1]; rows.items[j + 1] = temp;
                    }
                }
            }

            for (rows.items, 0..) |r, idx| {
                const s = r.stats;
                const fs = try metrics.formatBytes(allocator, s.saved);
                const ft = try metrics.formatMs(allocator, s.ms, s.cmds);
                defer { allocator.free(fs); allocator.free(ft); }
                const fp = if (s.input > 0) (@as(f64, @floatFromInt(s.saved)) / @as(f64, @floatFromInt(s.input))) * 100.0 else 0.0;
                const c = ui.colorForPct(fp);
                const rl = try std.fmt.allocPrint(allocator, "{d:>2}. " ++ ui.CYAN ++ "{s:<18}" ++ ui.RESET ++ "{d:>6}  {s:>8}  {s}{d:>6.1}%" ++ ui.RESET ++ "  {s:>7}", .{
                    idx + 1, r.label, s.cmds, fs, c, fp, ft,
                });
                defer allocator.free(rl); try ui.row(stdout, rl);
            }
            try ui.hline(stdout, .bot);
        }

        // Agent Breakdown
        if (agent_map.count() > 0) {
            try stdout.print("\n", .{}); try ui.hline(stdout, .top);
            try ui.row(stdout, ui.BOLD ++ ui.WHITE ++ "Agent Breakdown" ++ ui.RESET); try ui.hline(stdout, .mid);
            var it = agent_map.iterator();
            while (it.next()) |entry| {
                const an = entry.key_ptr.*; const as = entry.value_ptr.*;
                const asv = try metrics.formatBytes(allocator, as.saved);
                const ain = try metrics.formatBytes(allocator, as.input);
                defer { allocator.free(asv); allocator.free(ain); }
                const ap = if (as.input > 0) (@as(f64, @floatFromInt(as.saved)) / @as(f64, @floatFromInt(as.input))) * 100.0 else 0.0;

                const row_msg = try std.fmt.allocPrint(allocator, ui.MAGENTA ++ ui.BOLD ++ "▸ {s}" ++ ui.RESET, .{an});
                defer allocator.free(row_msg);
                try ui.row(stdout, row_msg);
                {
                    const l = try std.fmt.allocPrint(allocator, "  Runs: {d}  Input: {s}  Saved: {s} ({d:.1}%)", .{ as.cmds, ain, asv, ap });
                    defer allocator.free(l); try ui.row(stdout, l);
                }
                var flb = std.ArrayListUnmanaged(u8){};
                defer flb.deinit(allocator);
                const flw = flb.writer(allocator);
                try flw.print("  Filters: ", .{});
                
                var count_f: usize = 0;
                for (all_records.items, 0..) |rec, ri| {
                    if (std.mem.eql(u8, rec.agent, an)) {
                        var already = false;
                        for (0..ri) |pi| {
                            if (std.mem.eql(u8, all_records.items[pi].agent, an) and std.mem.eql(u8, all_records.items[pi].filter_name, rec.filter_name)) {
                                already = true; break;
                            }
                        }
                        if (!already) {
                            if (count_f > 0) try flw.print(ui.GRAY ++ ", " ++ ui.RESET, .{});
                            try flw.print(ui.CYAN ++ "{s}" ++ ui.RESET, .{rec.filter_name});
                            count_f += 1;
                        }
                    }
                }
                try ui.row(stdout, flb.items); try ui.row(stdout, "");
            }
            try ui.hline(stdout, .bot);
        }
        try stdout.print("\n", .{});
    }

    if (opts.format_json) {
        try stdout.print("{{\n  \"summary\": {{\n    \"total_commands\": {d},\n    \"input_bytes\": {d},\n    \"output_bytes\": {d},\n    \"saved_bytes\": {d},\n    \"total_time_ms\": {d}\n  }},\n  \"filters\": [\n", .{
            global_cmds, global_in, global_out, global_saved, global_ms,
        });
        var it = filter_map.iterator(); var first = true;
        while (it.next()) |e| {
            if (!first) try stdout.print(",\n", .{});
            try stdout.print("    {{ \"name\": \"{s}\", \"cmds\": {d}, \"saved\": {d} }}", .{ e.key_ptr.*, e.value_ptr.cmds, e.value_ptr.saved });
            first = false;
        }
        try stdout.print("\n  ],\n  \"agents\": [\n", .{});
        var ait = agent_map.iterator(); first = true;
        while (ait.next()) |e| {
            if (!first) try stdout.print(",\n", .{});
            try stdout.print("    {{ \"name\": \"{s}\", \"cmds\": {d}, \"saved\": {d} }}", .{ e.key_ptr.*, e.value_ptr.cmds, e.value_ptr.saved });
            first = false;
        }
        try stdout.print("\n  ]\n}}\n", .{}); return;
    }

    const TableRenderer = struct {
        fn render(alloc: std.mem.Allocator, map: *std.StringHashMap(metrics.Stats), title: []const u8, out: anytype, rowTitle: []const u8, g_cmds: usize, g_in: usize, g_out: usize, g_s: usize, g_ms: u64) !void {
            const ft = try std.fmt.allocPrint(alloc, "{s} ({d} entries)", .{ title, map.count() }); defer alloc.free(ft);
            try out.print("\n", .{});
            try ui.hline(out, .top);
            const r1 = try std.fmt.allocPrint(alloc, ui.BOLD ++ ui.WHITE ++ " {s}" ++ ui.RESET, .{ft});
            defer alloc.free(r1);
            try ui.row(out, r1); 
            try ui.hline(out, .mid);
            const r2 = try std.fmt.allocPrint(alloc, ui.BOLD ++ " {s:<14} │ {s:>5} │ {s:>8} │ {s:>8} │ {s:>8} │ {s:>6} │ {s:>7} " ++ ui.RESET, .{ rowTitle, "Cmds", "Input", "Output", "Saved", "Rate", "Time" });
            defer alloc.free(r2);
            try ui.row(out, r2);
            try ui.hline(out, .mid);
            
            var rows = std.ArrayListUnmanaged(metrics.GroupedStats){};
            defer rows.deinit(alloc);
            var it = map.iterator(); while (it.next()) |e| try rows.append(alloc, .{ .label = e.key_ptr.*, .stats = e.value_ptr.* });
            for (0..rows.items.len) |idx| {
                for (0..rows.items.len - idx - 1) |j| {
                    if (std.mem.order(u8, rows.items[j].label, rows.items[j + 1].label) == .gt) {
                        const temp = rows.items[j]; rows.items[j] = rows.items[j + 1]; rows.items[j + 1] = temp;
                    }
                }
            }
            for (rows.items) |r| {
                const s = r.stats; const in_s = try metrics.formatBytes(alloc, s.input); const out_s = try metrics.formatBytes(alloc, s.output); const sv_s = try metrics.formatBytes(alloc, s.saved); const ms_s = try metrics.formatMs(alloc, s.ms, s.cmds); defer { alloc.free(in_s); alloc.free(out_s); alloc.free(sv_s); alloc.free(ms_s); }
                const sp = if (s.input > 0) (@as(f64, @floatFromInt(s.saved)) / @as(f64, @floatFromInt(s.input))) * 100.0 else 0.0; const c = ui.colorForPct(sp);
                const rl = try std.fmt.allocPrint(alloc, " " ++ ui.CYAN ++ "{s:<14}" ++ ui.RESET ++ " │ {d:>5} │ {s:>8} │ {s:>8} │ {s:>8} │ {s}{d:>5.1}%" ++ ui.RESET ++ " │ {s:>7} ", .{ r.label, s.cmds, in_s, out_s, sv_s, c, sp, ms_s });
                defer alloc.free(rl); try ui.row(out, rl);
            }
            try ui.hline(out, .mid);
            const gin = try metrics.formatBytes(alloc, g_in); const gout = try metrics.formatBytes(alloc, g_out); const gs = try metrics.formatBytes(alloc, g_s); const gms = try metrics.formatMs(alloc, g_ms, g_cmds); defer { alloc.free(gin); alloc.free(gout); alloc.free(gs); alloc.free(gms); }
            const gp = if (g_in > 0) (@as(f64, @floatFromInt(g_s)) / @as(f64, @floatFromInt(g_in))) * 100.0 else 0.0;
            const tr = try std.fmt.allocPrint(alloc, ui.BOLD ++ " {s:<14} │ {d:>5} │ {s:>8} │ {s:>8} │ {s:>8} │ {d:>5.1}% │ {s:>7} " ++ ui.RESET, .{ "TOTAL", g_cmds, gin, gout, gs, gp, gms });
            defer alloc.free(tr); try ui.row(out, tr); try ui.hline(out, .bot);
        }
    };

    if (opts.daily or opts.weekly or opts.monthly or opts.all) {
        var dm = std.StringHashMap(metrics.Stats).init(allocator);
        var wm = std.StringHashMap(metrics.Stats).init(allocator);
        var mm = std.StringHashMap(metrics.Stats).init(allocator);
        defer { dm.deinit(); wm.deinit(); mm.deinit(); }
        for (all_records.items) |rec| {
            const dl = try metrics.toDailyLabel(allocator, rec.timestamp);
            const wl = try metrics.toWeeklyLabel(allocator, rec.timestamp);
            const ml = try metrics.toMonthlyLabel(allocator, rec.timestamp);
            {
                var res = try dm.getOrPut(dl); if (!res.found_existing) res.value_ptr.* = .{} else allocator.free(dl);
                res.value_ptr.add(rec);
            }
            {
                var res = try wm.getOrPut(wl); if (!res.found_existing) res.value_ptr.* = .{} else allocator.free(wl);
                res.value_ptr.add(rec);
            }
            {
                var res = try mm.getOrPut(ml); if (!res.found_existing) res.value_ptr.* = .{} else allocator.free(ml);
                res.value_ptr.add(rec);
            }
        }
        if (opts.all or opts.daily) try TableRenderer.render(allocator, &dm, "Daily Breakdown", stdout, "Date", global_cmds, global_in, global_out, global_saved, global_ms);
        if (opts.all or opts.weekly) try TableRenderer.render(allocator, &wm, "Weekly Breakdown", stdout, "Week", global_cmds, global_in, global_out, global_saved, global_ms);
        if (opts.all or opts.monthly) try TableRenderer.render(allocator, &mm, "Monthly Breakdown", stdout, "Month", global_cmds, global_in, global_out, global_saved, global_ms);
        var it = dm.keyIterator(); while (it.next()) |k| allocator.free(k.*);
        var wit = wm.keyIterator(); while (wit.next()) |k| allocator.free(k.*);
        var mit = mm.keyIterator(); while (mit.next()) |k| allocator.free(k.*);
    }

    if (opts.graph) {
        var dss = std.StringHashMap(usize).init(allocator);
        defer { var it = dss.keyIterator(); while (it.next()) |k| allocator.free(k.*); dss.deinit(); }
        for (all_records.items) |rec| {
            if (rec.input_bytes > rec.output_bytes) {
                const s = rec.input_bytes - rec.output_bytes;
                const dl = try metrics.toDailyLabel(allocator, rec.timestamp);
                const res = try dss.getOrPut(dl);
                if (!res.found_existing) { res.value_ptr.* = s; } else { res.value_ptr.* += s; allocator.free(dl); }
            }
        }
        var darr = std.ArrayListUnmanaged([]const u8){};
        defer darr.deinit(allocator);
        var it = dss.keyIterator(); while (it.next()) |k| try darr.append(allocator, k.*);
        for (0..darr.items.len) |idx| {
            for (0..darr.items.len - idx - 1) |j| {
                if (std.mem.order(u8, darr.items[j], darr.items[j + 1]) == .gt) {
                    const temp = darr.items[j]; darr.items[j] = darr.items[j + 1]; darr.items[j + 1] = temp;
                }
            }
        }
        var maxv: usize = 0; for (darr.items) |d| { const v = dss.get(d) orelse 0; if (v > maxv) maxv = v; }
        try stdout.print("\n", .{}); try ui.hline(stdout, .top);
        try ui.row(stdout, ui.BOLD ++ ui.WHITE ++ "Distillation Trend" ++ ui.RESET); try ui.hline(stdout, .mid);
        for (darr.items) |d| {
            const v = dss.get(d) orelse 0;
            const bl = if (maxv > 0) @as(usize, @intFromFloat((@as(f64, @floatFromInt(v)) / @as(f64, @floatFromInt(maxv))) * 40.0)) else 0;
            const dl = if (d.len >= 10) d[5..10] else d;
            const sv = try metrics.formatBytes(allocator, v); defer allocator.free(sv);
            var gbuf = std.ArrayListUnmanaged(u8){}; defer gbuf.deinit(allocator); const gbw = gbuf.writer(allocator);
            try gbw.print(ui.GRAY ++ "{s} " ++ ui.RESET, .{dl});
            for (0..bl) |_| try gbw.print(ui.GREEN ++ "▓" ++ ui.RESET, .{});
            for (0..40 - bl) |_| try gbw.print(ui.DIM ++ "░" ++ ui.RESET, .{});
            try gbw.print(" " ++ ui.WHITE ++ "{s}" ++ ui.RESET, .{sv});
            try ui.row(stdout, gbuf.items);
        }
        try ui.hline(stdout, .bot);
    }

    if (opts.history) {
        try stdout.print("\n", .{}); try ui.hline(stdout, .top);
        try ui.row(stdout, ui.BOLD ++ ui.WHITE ++ "Recent Distillations" ++ ui.RESET); try ui.hline(stdout, .mid);
        const count = if (all_records.items.len > 10) 10 else all_records.items.len;
        for (all_records.items.len - count..all_records.items.len) |idx| {
            const rec = all_records.items[idx];
            const epoch = std.time.epoch.EpochSeconds{ .secs = @as(u64, @intCast(rec.timestamp)) };
            const day = epoch.getEpochDay(); const yd = day.calculateYearDay(); const md = yd.calculateMonthDay();
            const dsecs = epoch.getDaySeconds();
            const saved = if (rec.input_bytes > rec.output_bytes) rec.input_bytes - rec.output_bytes else 0;
            const sv = try metrics.formatBytes(allocator, saved); defer allocator.free(sv);
            const pct = if (rec.input_bytes > 0) (@as(f64, @floatFromInt(saved)) / @as(f64, @floatFromInt(rec.input_bytes))) * 100.0 else 0.0;
            const c = ui.colorForPct(pct); const dot = if (pct >= 50.0) "◆" else if (pct >= 20.0) "◇" else "·";
            const hl = try std.fmt.allocPrint(allocator, ui.GRAY ++ "{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}" ++ ui.RESET ++ " {s}{s}" ++ ui.RESET ++ " " ++ ui.CYAN ++ "{s:<15}" ++ ui.RESET ++ " " ++ ui.GRAY ++ "[{s:<12}]" ++ ui.RESET ++ " {s}{d:>4.1}%" ++ ui.RESET ++ " " ++ ui.DIM ++ "({s:>8})" ++ ui.RESET, .{
                md.month.numeric(), md.day_index + 1, dsecs.getHoursIntoDay(), dsecs.getMinutesIntoHour(),
                c, dot, rec.filter_name, rec.agent, c, pct, sv,
            });
            defer allocator.free(hl); try ui.row(stdout, hl);
        }
        try ui.hline(stdout, .bot);
    }
}

pub fn handleDiscover(allocator: std.mem.Allocator) !void {
    const stdout = std.fs.File.stdout().deprecatedWriter();
    try stdout.print("\n", .{}); try ui.hline(stdout, .top);
    try ui.row(stdout, ui.BOLD ++ ui.WHITE ++ "Savings Opportunity Scanner" ++ ui.RESET); try ui.hline(stdout, .mid);
    const home = std.posix.getenv("HOME") orelse return; var found: usize = 0;
    const history_files = [_][]const u8{ ".zsh_history", ".bash_history" };
    for (history_files) |hf| {
        const fp = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ home, hf }); defer allocator.free(fp);
        if (std.fs.cwd().openFile(fp, .{})) |file| {
            defer file.close(); const data = try file.readToEndAlloc(allocator, 5 * 1024 * 1024); defer allocator.free(data);
            var it = std.mem.splitSequence(u8, data, "\n");
            var missed = std.ArrayListUnmanaged([]const u8){}; defer missed.deinit(allocator);
            while (it.next()) |ln| {
                if (ln.len == 0) continue;
                if ((std.mem.indexOf(u8, ln, "git diff") != null or std.mem.indexOf(u8, ln, "git log") != null or std.mem.indexOf(u8, ln, "npm install") != null) and std.mem.indexOf(u8, ln, "omni") == null) {
                    var clean = ln; if (std.mem.startsWith(u8, ln, ": ")) { if (std.mem.indexOf(u8, ln, ";")) |idx| { if (idx + 1 < ln.len) clean = ln[idx + 1 ..]; } }
                    try missed.append(allocator, clean);
                }
            }
            const maxs = if (missed.items.len > 10) 10 else missed.items.len;
            for (missed.items.len - maxs..missed.items.len) |idx| {
                const cmd = missed.items[idx]; const tr = if (cmd.len > 68) cmd[0..65] else cmd; const dots_c = if (cmd.len > 68) "..." else "";
                const row_msg = try std.fmt.allocPrint(allocator, ui.RED ++ "○" ++ ui.RESET ++ " " ++ ui.WHITE ++ "{s}{s}" ++ ui.RESET, .{ tr, dots_c });
                defer allocator.free(row_msg); try ui.row(stdout, row_msg);
                try ui.row(stdout, "  " ++ ui.DIM ++ "→ Pipe with `| omni` for ~60% reduction" ++ ui.RESET); found += 1;
            }
        } else |_| {}
    }
    if (found == 0) { try ui.row(stdout, ui.GREEN ++ "● All clear!" ++ ui.RESET ++ " No missed opportunities found."); } else {
        try ui.hline(stdout, .mid); const fmsg = try std.fmt.allocPrint(allocator, ui.YELLOW ++ "  {d} commands could benefit from OMNI distillation" ++ ui.RESET, .{found});
        defer allocator.free(fmsg); try ui.row(stdout, fmsg);
    }
    try ui.hline(stdout, .bot); try stdout.print("\n", .{});
}
