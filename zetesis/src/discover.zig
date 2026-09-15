const std = @import("std");
const git = @import("git.zig");

const Allocator = std.mem.Allocator;
const GitStatus = git.GitStatus;

pub const Item = struct {
    path: []const u8,
    git: GitStatus = .none,
};

pub const Index = struct {
    allocator: Allocator,
    items: std.ArrayList(Item) = .empty,
    by_path: std.StringHashMap(usize),

    pub fn init(allocator: Allocator) Index {
        return .{
            .allocator = allocator,
            .by_path = .init(allocator),
        };
    }

    pub fn deinit(self: *Index) void {
        for (self.items.items) |item| self.allocator.free(item.path);
        self.items.deinit(self.allocator);
        self.by_path.deinit();
        self.* = undefined;
    }

    pub fn add(self: *Index, path: []const u8) !void {
        const cleaned = normalizePath(path);
        if (cleaned.len == 0) return;
        if (self.by_path.contains(cleaned)) return;
        const owned = try self.allocator.dupe(u8, cleaned);
        errdefer self.allocator.free(owned);
        const item_index = self.items.items.len;
        try self.items.append(self.allocator, .{ .path = owned });
        try self.by_path.put(owned, item_index);
    }

    pub fn contains(self: *const Index, path: []const u8) bool {
        return self.by_path.contains(normalizePath(path));
    }

    pub fn statusOf(self: *const Index, path: []const u8) ?GitStatus {
        const item_index = self.by_path.get(normalizePath(path)) orelse return null;
        return self.items.items[item_index].git;
    }
};

pub const Pump = enum { more, done };

const GitJob = struct {
    allocator: Allocator,
    io: std.Io,
    cwd: std.process.Child.Cwd,
    stdout: ?[]u8 = null,
    stderr: ?[]u8 = null,
    ok: bool = false,

    fn deinit(self: *GitJob) void {
        if (self.stdout) |stdout| self.allocator.free(stdout);
        if (self.stderr) |stderr| self.allocator.free(stderr);
        self.stdout = null;
        self.stderr = null;
    }
};

pub const Discover = struct {
    allocator: Allocator,
    io: std.Io,
    cwd: std.process.Child.Cwd,
    fd_bin: []const u8,
    leftover: std.ArrayList(u8) = .empty,
    fd_child: ?std.process.Child = null,
    git_job: GitJob,
    git_thread: ?std.Thread = null,
    finished: bool = false,

    pub fn start(self: *Discover, allocator: Allocator, io: std.Io, cwd: std.process.Child.Cwd) !void {
        const fd_bin = findFd(io, cwd) orelse return error.FdMissing;
        self.* = .{
            .allocator = allocator,
            .io = io,
            .cwd = cwd,
            .fd_bin = fd_bin,
            .git_job = .{
                .allocator = allocator,
                .io = io,
                .cwd = cwd,
            },
        };

        self.git_thread = try std.Thread.spawn(.{}, gitWorker, .{&self.git_job});
        errdefer {
            self.joinGit();
            self.git_job.deinit();
            self.leftover.deinit(self.allocator);
        }

        self.fd_child = spawnFd(io, cwd, mainFdArgv(fd_bin)) catch |err| switch (err) {
            error.FileNotFound => return error.FdMissing,
            else => |e| return e,
        };
    }

    pub fn deinit(self: *Discover) void {
        self.killFd();
        self.joinGit();
        self.git_job.deinit();
        self.leftover.deinit(self.allocator);
        self.* = undefined;
    }

    pub fn pump(self: *Discover, index: *Index) !Pump {
        if (self.finished) return .done;

        if (self.fd_child) |*child| {
            const stdout = child.stdout orelse return error.Unexpected;
            var chunk: [65536]u8 = undefined;
            const n = stdout.readStreaming(self.io, &.{chunk[0..]}) catch |err| switch (err) {
                error.EndOfStream => {
                    try self.finish(index);
                    return .done;
                },
                else => |e| return e,
            };
            try takeNulPaths(index, &self.leftover, chunk[0..n], false);
            return .more;
        }

        try self.finish(index);
        return .done;
    }

    fn finish(self: *Discover, index: *Index) !void {
        try self.flushLeftover(index);
        self.closeFd();
        try self.mergeEnvFiles(index);
        self.joinGit();
        try overlayGit(index, &self.git_job);
        self.finished = true;
    }

    fn closeFd(self: *Discover) void {
        if (self.fd_child) |*child| {
            _ = child.wait(self.io) catch {};
            self.fd_child = null;
        }
    }

    fn killFd(self: *Discover) void {
        if (self.fd_child) |*child| {
            child.kill(self.io);
            self.fd_child = null;
        }
    }

    fn joinGit(self: *Discover) void {
        if (self.git_thread) |thread| {
            thread.join();
            self.git_thread = null;
        }
    }

    fn flushLeftover(self: *Discover, index: *Index) !void {
        if (self.leftover.items.len == 0) return;
        try index.add(self.leftover.items);
        self.leftover.clearRetainingCapacity();
    }

    fn mergeEnvFiles(self: *Discover, index: *Index) !void {
        const result = std.process.run(self.allocator, self.io, .{
            .argv = envFdArgv(self.fd_bin),
            .cwd = self.cwd,
        }) catch return;
        defer self.allocator.free(result.stdout);
        defer self.allocator.free(result.stderr);
        switch (result.term) {
            .exited => |code| if (code != 0) return,
            else => return,
        }
        try takeNulPaths(index, &self.leftover, result.stdout, true);
    }
};

pub fn collect(allocator: Allocator, io: std.Io, cwd: std.process.Child.Cwd) !Index {
    var discover: Discover = undefined;
    try discover.start(allocator, io, cwd);
    defer discover.deinit();
    var index = Index.init(allocator);
    errdefer index.deinit();
    while (try discover.pump(&index) == .more) {}
    return index;
}

fn gitWorker(job: *GitJob) void {
    const result = std.process.run(job.allocator, job.io, .{
        .argv = &.{ "git", "status", "--porcelain=v1", "-z" },
        .cwd = job.cwd,
    }) catch return;
    job.stdout = result.stdout;
    job.stderr = result.stderr;
    job.ok = switch (result.term) {
        .exited => |code| code == 0,
        else => false,
    };
}

fn overlayGit(index: *Index, job: *GitJob) !void {
    if (!job.ok) return;
    const stdout = job.stdout orelse return;
    var map = try git.parseStatusMap(index.allocator, stdout);
    defer map.deinit();

    var write: usize = 0;
    for (index.items.items) |item| {
        const status = map.get(item.path) orelse .none;
        if (status == .deleted) {
            _ = index.by_path.remove(item.path);
            index.allocator.free(item.path);
            continue;
        }
        var kept = item;
        kept.git = status;
        index.items.items[write] = kept;
        try index.by_path.put(kept.path, write);
        write += 1;
    }
    index.items.shrinkRetainingCapacity(write);
}

fn mainFdArgv(fd_bin: []const u8) []const []const u8 {
    return &.{ fd_bin, "-0", "--type", "f", "--hidden", "--color", "never", "--strip-cwd-prefix", "-E", ".git" };
}

fn envFdArgv(fd_bin: []const u8) []const []const u8 {
    return &.{
        fd_bin,               "-0",
        "--type",             "f",
        "--hidden",           "--no-ignore",
        "--color",            "never",
        "--strip-cwd-prefix", "--regex",
        "^\\.env($|\\.)",     "-E",
        ".git",               "-E",
        "node_modules",       "-E",
        ".zig-cache",         "-E",
        "target",
    };
}

fn findFd(io: std.Io, cwd: std.process.Child.Cwd) ?[]const u8 {
    if (probeFd(io, cwd, "fd")) return "fd";
    if (probeFd(io, cwd, "fdfind")) return "fdfind";
    return null;
}

fn probeFd(io: std.Io, cwd: std.process.Child.Cwd, bin: []const u8) bool {
    var child = std.process.spawn(io, .{
        .argv = &.{ bin, "--version" },
        .cwd = cwd,
        .stdin = .ignore,
        .stdout = .ignore,
        .stderr = .ignore,
    }) catch return false;
    _ = child.wait(io) catch return false;
    return true;
}

fn spawnFd(io: std.Io, cwd: std.process.Child.Cwd, argv: []const []const u8) !std.process.Child {
    return std.process.spawn(io, .{
        .argv = argv,
        .cwd = cwd,
        .stdin = .ignore,
        .stdout = .pipe,
        .stderr = .ignore,
    });
}

fn takeNulPaths(index: *Index, leftover: *std.ArrayList(u8), chunk: []const u8, flush: bool) !void {
    var start: usize = 0;
    while (start < chunk.len) {
        const rel = std.mem.indexOfScalarPos(u8, chunk, start, 0) orelse break;
        if (leftover.items.len > 0) {
            try leftover.appendSlice(index.allocator, chunk[start..rel]);
            try index.add(leftover.items);
            leftover.clearRetainingCapacity();
        } else {
            try index.add(chunk[start..rel]);
        }
        start = rel + 1;
    }
    if (start < chunk.len) try leftover.appendSlice(index.allocator, chunk[start..]);
    if (flush and leftover.items.len > 0) {
        try index.add(leftover.items);
        leftover.clearRetainingCapacity();
    }
}

fn normalizePath(path: []const u8) []const u8 {
    var result = std.mem.trim(u8, path, " \t\r\n");
    while (result.len >= 2 and result[0] == '.' and result[1] == '/') {
        result = result[2..];
    }
    return result;
}
