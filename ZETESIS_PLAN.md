# zetesis plan

## Goal

Build small repo-owned fuzzy picker binary for Neovim and general CLI use.

Core idea:

- fzf/sk-like terminal picker.
- zf-like filepath matcher.
- FFF-like file brain.
- Lua supplies context and owns final actions.

## Non-goals

- No daemon initially.
- No file preview initially.
- No Telescope/snacks/mini dependency.
- No broad picker ecosystem at start.
- No Windows priority.
- No complex theme/highlight model.

## Prior art

### zf

Good match:

- Zig.
- Filepath-first fuzzy matching.
- Filename priority.
- space-separated terms.
- strict path matching when query contains separators.
- CLI and library shape.
- small scope.

Missing for target:

- frecency.
- git status ranking.
- current-buffer penalty.
- query-to-file memory.
- Neovim context injection.
- project-specific file brain.

### FFF

Good target behavior:

- long-lived repo index idea, but no daemon at first.
- frecency-ranked files.
- git-aware ranking.
- filename/exact filename/special entry boosts.
- current file penalty.
- query/file combo memory.
- constraints later.

## Implementation approach

- Temporarily clone `zf` for reference.
- Do not fork `zf`.
- Mirror its initial project shape where useful.
- Mimic its filepath-first matcher behavior first.
- Grow from general-purpose matcher into file brain incrementally.
- Check `libvaxis` for Zig TUI patterns and copy only barebones ideas needed to ship.

## Binary shape

Name: `zt`

Modes:

- `zt files`
- `zt pick`

### `files`

Scans/selects files for current repo.

Inputs:

- `--cwd <path>`
- `--current-file <path>`
- `--filter <text>`
- `--output-file <path>`
- `--plain`

Planned later:

- `--query <text>` as initial interactive query.
- `--multi`.
- `--no-preview` if preview ever exists.
- `--output json|path`.
Output:

- selected path by default.
- selected JSON if `--output json`.

### `pick`

Generic picker for Lua-provided sources.

Inputs:

- lines from stdin now.
- `--filter <text>` for non-interactive filtering.
- `--plain` to disable filepath boosts.

Planned later:

- stdin JSONL.
- `--source jsonl|lines`.
- `--display-field label`.
- `--id-field id`.
- `--query <text>` as initial interactive query.
- `--multi`.
- `--output json|line`.

Output:

- selected original JSONL unchanged, or selected line unchanged.

## JSONL schema

```json
{"id":"buf:12","kind":"buffer","label":"init.lua","path":"lua/init.lua","lnum":1,"col":1,"score":10}
```

Required:

- `label`

Optional:

- `id`
- `kind`
- `path`
- `lnum`
- `col`
- `score`
- arbitrary metadata

## File brain MVP

File list:

- Prefer `git ls-files --cached --others --exclude-standard`.
- Fallback to recursive scan if not git repo.
- Ignore engine can wait.

Ranking:

- fuzzy score.
- filename match boost.
- exact filename boost.
- strict path match boost.
- current-file penalty.
- git dirty boost.
- frecency boost.
- query/file combo boost.
- special entry file boost:
  - `init.lua`
  - `mod.rs`
  - `lib.rs`
  - `main.rs`
  - `index.ts`
  - `index.tsx`
  - `index.js`
  - `__init__.py`

Git status:

- `git status --porcelain=v1 -z`
- mark modified, staged, untracked, deleted, renamed.
- dirty files get boost and sign/marker in TUI.

Frecency:

- record opened path with timestamp.
- decay old accesses.
- keep per-project data.

Query combo:

- key: `(project, query)`.
- value: selected path, open count, timestamp.
- boost same query if repeated.

## Storage choice

Use SQLite first.

Reasons:

- avoids JSONL-to-SQLite migration later.
- gives durable query/file memory immediately.
- makes frecency updates cheap.
- supports indexed lookups for project, path, query, timestamp, and counts.
- handles cleanup/decay without custom compaction logic.

Cost:

- dependency and linking complexity.
- bigger binary/build story.
- cross-compilation extra friction.

Accepted because persistent ranking data is core product, not optional cache.

## TUI design

Style:

- terminal 16-color semantic palette.
- yazi-like simple layout.
- prompt + results.
- optional help/footer.
- no 100 highlight groups.
- no file preview.

Implementation notes:

- Build Zig TUI, not Lua UI.
- Study `libvaxis` for terminal input/rendering patterns.
- Keep first UI minimal: prompt, scrollable result list, selection marker, footer.
- Add richer layout only after matcher and file brain feel good.

Visual markers:

- dirty git sign.
- selected marker.
- kind icon optional.
- path dimming optional.


## Current implementation state

Project layout:

- `src/main.zig`: CLI parsing, modes, file collection, stdout/output-file handoff.
- `src/matcher.zig`: zf-like ranking, filename boost, strict path matching, current-file penalty.
- `src/picker.zig`: vaxis app/model, prompt/list/footer, query refresh, selection result.
- `src/row.zig`: repo-owned row widget with direct cell styling.

Working now:

- `zt pick` reads stdin lines.
- `zt pick --filter <query>` prints ranked matches.
- `zt files --cwd <path>` lists git files.
- `zt files --filter <query>` works.
- Neovim float terminal calls `zt files --cwd --current-file --output-file`.
- Enter writes selected path; Lua opens it.
- Selected row styling works through project-owned `Row` widget.
- libvaxis `ScrollView.draw_cursor` is disabled because its cursor wrapper interfered with selected-row styling.
- Cursor marker now rendered by project-owned `Row`, not `ScrollView.draw_cursor`.
- `<C-y>` toggles row mark state and shows `*` in marker column.

Current caveats:

- Marked rows are visual state only; final output still uses current row until multi-output protocol exists.
- No dirty markers, icons, path dimming, or stable list component abstraction beyond `Row` yet.
- No non-git fallback yet.
- No SQLite store yet.

## List component plan

Do not fight `ScrollView.draw_cursor` for rich rows.

Direction:

- Keep `ScrollView` for viewport/scroll bookkeeping for now.
- Own row rendering entirely through `Row`/future `ListItem` widgets.
- Selection is data-driven, not vaxis cursor-drawn.
- Add marker column inside row surface, not outside via `ScrollView.cursor_indicator`.

Row data should eventually include:

- `label` / display text.
- `path` / payload.
- `selected`: current cursor row.
- `marked`: multi-select state.
- `dirty`: git dirty state.
- `kind`: optional source kind.
- `score`: optional debug display.

Visual columns:

- left col 0: cursor marker, `>` or space.
- left col 1: multi marker, `*` or space.
- middle: label/path text.
- right last col: git marker, `M`, `A`, `?`, `D`, `R`, or space.

Rules:

- Markers must be ASCII or plain one-cell Unicode only; no Nerd Font, emoji, or ambiguous-width symbols.
- Text clips before right git marker so marker stays visible.

Near-term list cleanup:

- Replace parallel `rows` / `selected_rows` / `row_boxes` / `selected_row_boxes` with one stable list item array. Done for rows; `row_boxes` remains only as stable `SizedBox` wrappers.
- Row drawing depends on `index == cursor` and item state.
- `Row.Styles` owns normal/current/marker/git styles.
- Add multi-output behavior after action protocol.
## Neovim integration

Lua does:

- calls binary via terminal/floating job.
- passes `--cwd`, `--current-file`.
- for generic sources, writes JSONL to stdin.
- parses selected JSON/path.
- executes action.

Binary does:

- search.
- rank.
- UI.
- selection.

## Milestones

### M1: reference and picker shell

- Clone `zf` temporarily for reference.
- Inspect project layout, matcher setup, CLI shape, terminal handling.
- Create independent Zig project for `zt`.
- Read lines from stdin.
- Fuzzy filter with zf-like filepath-first behavior.
- TUI list + prompt.
- Output selected line.

### M2: file mode

- `zt files --cwd`.
- file list through `git ls-files`.
- filepath ranking with filename priority and path matching.
- output selected path.

### M3: Neovim bridge

- Lua wrapper.
- keymap opens file picker.
- selected path opens with `edit`.

### M4: file brain

- Add SQLite store.
- Record opened path with timestamp and project key.
- Add current-file penalty.
- Add git dirty boost.
- Add frecency boost.
- Add query combo memory.
- Add special filename boost.

### M5: generic JSONL picker

- `zt pick --source jsonl`.
- display field.
- output selected JSON unchanged.
- Lua buffer picker proof.

### M6: packaging

- repo-local binary lookup.
- release binary fallback.
- build-from-source command.
- Linux/macOS first.

## Decisions

- Project name: `zetesis`.
- Binary name: `zt`.
- Language: Zig.
- Reference source: clone `zf` temporarily; no fork.
- Matcher direction: start as zf-like general-purpose matcher, then layer file brain.
- Storage: SQLite first.
- TUI: Zig terminal UI; inspect `libvaxis`, copy only minimum useful patterns.
