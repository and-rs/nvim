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
        try self.append(cleaned);
        try self.by_path.put(self.items.items[self.items.items.len - 1].path, self.items.items.len - 1);
    }

    pub fn append(self: *Index, path: []const u8) !void {
        const cleaned = normalizePath(path);
        if (cleaned.len == 0) return;
        const owned = try self.allocator.dupe(u8, cleaned);
        errdefer self.allocator.free(owned);
        try self.items.append(self.allocator, .{ .path = owned });
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
    done: std.atomic.Value(bool) = .init(false),

    fn deinit(self: *GitJob) void {
        if (self.stdout) |stdout| self.allocator.free(stdout);
        if (self.stderr) |stderr| self.allocator.free(stderr);
        self.stdout = null;
        self.stderr = null;
    }
};

const FdJob = struct {
    allocator: Allocator,
    io: std.Io,
    cwd: std.process.Child.Cwd,
    fd_bin: []const u8,
    mutex: std.atomic.Mutex = .unlocked,
    queue: std.ArrayList([]u8) = .empty,
    child: ?std.process.Child = null,
    stop: std.atomic.Value(bool) = .init(false),
    done: std.atomic.Value(bool) = .init(false),

    fn deinit(self: *FdJob) void {
        for (self.queue.items) |path| self.allocator.free(path);
        self.queue.deinit(self.allocator);
    }

    fn pushPath(self: *FdJob, path: []const u8) void {
        const cleaned = normalizePath(path);
        if (cleaned.len == 0) return;
        const owned = self.allocator.dupe(u8, cleaned) catch return;
        while (!self.mutex.tryLock()) {}
        defer self.mutex.unlock();
        self.queue.append(self.allocator, owned) catch {
            self.allocator.free(owned);
        };
    }
};

pub const Discover = struct {
    allocator: Allocator,
    io: std.Io,
    fd_job: FdJob,
    git_job: GitJob,
    fd_thread: ?std.Thread = null,
    git_thread: ?std.Thread = null,
    finished: bool = false,
    overlaid: bool = false,

    pub fn start(self: *Discover, allocator: Allocator, io: std.Io, cwd: std.process.Child.Cwd) !void {
        const fd_bin = findFd(io, cwd) orelse return error.FdMissing;
        self.* = .{
            .allocator = allocator,
            .io = io,
            .fd_job = .{
                .allocator = allocator,
                .io = io,
                .cwd = cwd,
                .fd_bin = fd_bin,
            },
            .git_job = .{
                .allocator = allocator,
                .io = io,
                .cwd = cwd,
            },
        };

        self.git_thread = try std.Thread.spawn(.{}, gitWorker, .{&self.git_job});
        errdefer {
            self.stopWorkers();
            self.fd_job.deinit();
            self.git_job.deinit();
        }

        self.fd_job.child = spawnFd(io, cwd, mainFdArgv(fd_bin)) catch |err| switch (err) {
            error.FileNotFound => return error.FdMissing,
            else => |e| return e,
        };
        self.fd_thread = try std.Thread.spawn(.{}, fdWorker, .{&self.fd_job});
    }

    pub fn deinit(self: *Discover) void {
        self.stopWorkers();
        self.fd_job.deinit();
        self.git_job.deinit();
        self.* = undefined;
    }

    pub fn pump(self: *Discover, index: *Index) !Pump {
        if (self.finished) return .done;

        try self.drainQueue(index);

        const fd_done = self.fd_job.done.load(.acquire);
        const git_done = self.git_job.done.load(.acquire);
        if (!(fd_done and git_done)) return .more;

        self.joinWorkers();
        if (!self.overlaid) {
            try overlayGit(index, &self.git_job);
            self.overlaid = true;
        }
        self.finished = true;
        return .done;
    }

    fn drainQueue(self: *Discover, index: *Index) !void {
        if (!self.fd_job.mutex.tryLock()) return;
        defer self.fd_job.mutex.unlock();
        for (self.fd_job.queue.items) |path| {
            try index.add(path);
            self.allocator.free(path);
        }
        self.fd_job.queue.clearRetainingCapacity();
    }

    fn stopWorkers(self: *Discover) void {
        self.fd_job.stop.store(true, .release);
        if (self.fd_job.child) |*child| {
            child.kill(self.io);
            self.fd_job.child = null;
        }
        self.joinWorkers();
    }

    fn joinWorkers(self: *Discover) void {
        if (self.fd_thread) |thread| {
            thread.join();
            self.fd_thread = null;
        }
        if (self.git_thread) |thread| {
            thread.join();
            self.git_thread = null;
        }
    }
};

pub fn collect(allocator: Allocator, io: std.Io, cwd: std.process.Child.Cwd) !Index {
    var d: Discover = undefined;
    try d.start(allocator, io, cwd);
    defer d.deinit();
    var index = Index.init(allocator);
    errdefer index.deinit();
    while (try d.pump(&index) == .more) {
        try io.sleep(.fromMilliseconds(1), .real);
    }
    return index;
}

fn gitWorker(job: *GitJob) void {
    defer job.done.store(true, .release);
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

fn fdWorker(job: *FdJob) void {
    defer job.done.store(true, .release);
    drinkFd(job);
    if (job.stop.load(.acquire)) return;
    mergeEnvFiles(job);
}

fn drinkFd(job: *FdJob) void {
    const stdout = (job.child orelse return).stdout orelse return;
    var leftover: std.ArrayList(u8) = .empty;
    defer leftover.deinit(job.allocator);
    while (!job.stop.load(.acquire)) {
        var chunk: [65536]u8 = undefined;
        const n = stdout.readStreaming(job.io, &.{chunk[0..]}) catch |err| switch (err) {
            error.EndOfStream => {
                if (leftover.items.len > 0) job.pushPath(leftover.items);
                return;
            },
            else => return,
        };
        takeNulIntoJob(job, &leftover, chunk[0..n]);
    }
}

fn takeNulIntoJob(job: *FdJob, leftover: *std.ArrayList(u8), chunk: []const u8) void {
    var start: usize = 0;
    while (start < chunk.len) {
        const rel = std.mem.indexOfScalarPos(u8, chunk, start, 0) orelse break;
        if (leftover.items.len > 0) {
            leftover.appendSlice(job.allocator, chunk[start..rel]) catch return;
            job.pushPath(leftover.items);
            leftover.clearRetainingCapacity();
        } else {
            job.pushPath(chunk[start..rel]);
        }
        start = rel + 1;
    }
    if (start < chunk.len) leftover.appendSlice(job.allocator, chunk[start..]) catch {};
}

fn mergeEnvFiles(job: *FdJob) void {
    const result = std.process.run(job.allocator, job.io, .{
        .argv = envFdArgv(job.fd_bin),
        .cwd = job.cwd,
    }) catch return;
    defer job.allocator.free(result.stdout);
    defer job.allocator.free(result.stderr);
    switch (result.term) {
        .exited => |code| if (code != 0) return,
        else => return,
    }
    var leftover: std.ArrayList(u8) = .empty;
    defer leftover.deinit(job.allocator);
    takeNulIntoJob(job, &leftover, result.stdout);
    if (leftover.items.len > 0) job.pushPath(leftover.items);
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

fn normalizePath(path: []const u8) []const u8 {
    var result = std.mem.trim(u8, path, " \t\r\n");
    while (result.len >= 2 and result[0] == '.' and result[1] == '/') {
        result = result[2..];
    }
    return result;
}
