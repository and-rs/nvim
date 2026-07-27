# Zetesis source map

## Ownership rules

- `main.zig` owns CLI argument parsing, mode selection, stdin/file source wiring, filter-mode output, and process exit behavior.
- `files/` owns project file discovery. It may use Git or filesystem walking, but it must return candidate data without depending on picker UI modules.
- `git_status.zig` owns shared Git status values used by file discovery, ranking policy, and row rendering.
- `match/` owns query parsing, fuzzy matching, score breakdowns, match indexes, and generic ranked-line APIs.
- `picker/` owns interactive UI state, input handling, viewport synchronization, marks, and action dispatch.
- `picker/protocol.zig` owns serialized picker output. Callers should treat this as the stable Neovim/CLI wire format.
- Lua integration owns decoding picker output and mapping protocol objects to Neovim actions.

## Module map

- `main.zig`
  - Entry point for `zt stdin`, `zt files`, and `zt help`.
  - Converts file entries into picker lines plus optional Git statuses.
  - Uses `match.rankAll` for non-interactive `--filter` output.

- `files/mod.zig`
  - Public file-source facade.
  - Uses Git first, then filesystem walk fallback.
  - Exposes `Entry` and collection functions to `main.zig`.

- `files/git.zig`
  - Converts `git ls-files` output and `git status --porcelain` state into file entries.
  - Must not import picker modules.

- `files/walk.zig`
  - Filesystem fallback for non-Git or failed-Git directories.

- `candidates.zig`
  - Future generic JSONL input parser and normalized candidate model.
  - Converts external objects into picker-facing text plus protocol-facing payload.
  - Must not depend on Vaxis or row rendering.

- `git_status.zig`
  - Shared enum for file status: clean, modified, untracked, deleted, renamed, type-changed, unmerged.
  - Keep this small and UI-neutral.

- `match/mod.zig`
  - Fuzzy scoring and match highlighting indexes.
  - `rankAll` returns every matching candidate sorted by score.
  - `rankTop` returns bounded results for interactive refresh.

- `picker/mod.zig`
  - Vaxis model and event loop.
  - Owns viewport invariants through `syncViewport`.
  - Calls `picker/protocol.zig` for final action output.

- `picker/list.zig`
  - List state, filtered rows, marked paths, visible row widgets, and current selection.
  - Converts ranked result rows into rendered picker rows.

- `picker/row.zig`
  - Row rendering only: text, highlights, score display, Git marker, and mark indicator.
  - Owns row-local layout helpers for right-side score/status placement.
  - Should stay ignorant of discovery and protocol concerns.

- `picker/results.zig`
  - Interactive ranking pipeline for picker rows.
  - Owns result cap, help-mode plain ranking, case-sensitive query behavior, and file Git-status tie-break policy.

- `picker/reducer.zig`
  - Key/action reduction for picker state.

- `picker/state.zig`
  - Picker mode and cursor/action state.

- `picker/actions.zig`
  - User-visible picker actions and help text.

- `picker/key_decoder.zig`
  - Keyboard input mapping into picker actions.

- `picker/protocol.zig`
  - JSONL output formatter for selected file actions.
  - Current shape: `{ "action": "edit", "kind": "file", "path": "src/main.zig" }`.
  - Future object kinds should be added here first, then decoded by Lua.

## Generic candidate input design

### Input mode

- Add future subcommand: `zt candidates`.
- Read stdin as JSONL. Each non-empty line is one candidate object.
- Keep `zt stdin` as plain line mode for fast shell usage and backward compatibility.
- Keep `zt files` as built-in file source with Git status enrichment.

### Candidate object shape

Minimum object:

```json
{"kind":"file","path":"src/main.zig"}
```

Full object:

```json
{
  "kind": "file",
  "text": "src/main.zig:10:5 main",
  "match": "src/main.zig main",
  "display": "src/main.zig:10:5 main",
  "path": "src/main.zig",
  "line": 10,
  "col": 5,
  "action": "edit",
  "data": { "source": "external" }
}
```

Field meanings:

- `kind` controls output semantics. First supported kinds: `file`, `location`, `text`.
- `text` is fallback string used for matching, display, and output when more specific fields are absent.
- `match` is optional search text. If present, matcher ranks this field.
- `display` is optional row text. If present, picker renders this field.
- `path` is required for `file` and `location`.
- `line` and `col` are optional for `file`, required for exact `location`.
- `action` is optional default action override. Picker key action still wins when user chooses split/tab/quickfix.
- `data` is opaque JSON payload preserved only if future protocol needs it. Do not make picker inspect it.

Validation rules:

- Reject malformed JSON line with useful stderr message and exit code 2.
- Reject unknown `kind`.
- Reject `file` without string `path`.
- Reject `location` without string `path` and integer `line`.
- Reject candidates without any usable match/display/output text.
- Ignore unknown fields unless they conflict with known field types.

### Normalized model

Future `candidates.zig` should expose:

```zig
pub const Kind = enum { file, location, text };

pub const Candidate = struct {
    kind: Kind,
    match_text: []const u8,
    display_text: []const u8,
    output: Output,
};

pub const Output = union(Kind) {
    file: FileOutput,
    location: LocationOutput,
    text: TextOutput,
};
```

Normalization rules:

- `match_text = match orelse text orelse display orelse path`.
- `display_text = display orelse text orelse path`.
- `file.output.path = path`.
- `location.output.path = path`, `line = line`, `col = col orelse 1`, `text = text orelse display orelse path`.
- `text.output.text = text orelse display orelse match`.

### Picker integration

Current picker accepts `[]const []const u8` and returns selected paths. Generic candidates should not make picker own JSON parsing.

Planned integration steps:

1. Add `candidates.zig` parser and tests.
2. Add `zt candidates` mode in `main.zig`.
3. Convert `[]Candidate` into `[]match_text` for ranking.
4. Extend picker selection result to return source indexes, not selected strings only.
5. Let `picker/protocol.zig` serialize selected `Candidate.output` objects.
6. Update Lua decoder to handle `file`, `location`, and `text` kinds.

### Output protocol

Keep output JSONL. Examples:

```json
{"action":"edit","kind":"file","path":"src/main.zig"}
{"action":"edit","kind":"location","path":"src/main.zig","line":10,"col":5,"text":"main"}
{"action":"copy","kind":"text","text":"hello"}
```

Protocol rules:

- Picker action decides `action` unless candidate has no meaningful default and selected key maps to one.
- Quickfix over multiple candidates outputs one JSON object per candidate with `action":"quickfix"`.
- Lua parser keeps legacy tab/bare-path fallback until all callers use JSONL.

## Boundaries to protect

- File collection must not import picker UI modules.
- Row rendering must not own shared domain types.
- Picker UI must not hand-format protocol output.
- Match ranking must not know about Vaxis widgets or Neovim actions.
- JSONL protocol changes must remain backward-compatible until Lua fallback is removed.

## Near-term cleanup queue

1. Add `candidates.zig` parser and normalized model tests.
2. Add `zt candidates` mode and keep `zt stdin` unchanged.
3. Change picker selection path to return source indexes for protocol serialization.
