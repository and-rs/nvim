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
- `zt help`
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

- interactive output uses action lines: `edit\tpath`, `vsplit\tpath`, `tabedit\tpath`, or `quickfix\tpath`.
- selected JSON if `--output json` later.

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

- letter match marker (important).
- dirty git sign.
- selected marker.
- kind icon (denied).
- path dimming (denied).


## Current implementation state

Project layout:

- `src/main.zig`: CLI parsing, modes, file collection, stdout/output-file handoff.
- `src/matcher.zig`: zf-like ranking, filename boost, strict path matching, current-file penalty.
- `src/picker.zig`: vaxis app/model, prompt/list/footer, query refresh, marking, action output protocol.
- `src/row.zig`: repo-owned row widget with direct cell styling and marker columns.

Working now:

- `zt pick` reads stdin lines.
- `zt pick --filter <query>` prints ranked matches.
- `zt files --cwd <path>` lists git files.
- `zt files --filter <query>` works.
- Neovim float terminal calls `zt files --cwd --current-file --output-file`.
- Enter writes `edit\tpath` when no marks exist; Lua opens it.
- When marks exist, Enter writes `quickfix\tpath` for each marked item; Lua sends them to quickfix.
- `<C-v>` writes `vsplit\tpath`; `<C-t>` writes `tabedit\tpath`.
- Selected row styling works through project-owned `Row` widget.
- libvaxis `ScrollView.draw_cursor` is disabled because its cursor wrapper interfered with selected-row styling.
- Cursor marker now rendered by project-owned `Row`, not `ScrollView.draw_cursor`.
- `<C-y>` toggles row mark state and shows `:` in marker column.
- Help mode currently works through a temporary `Ctrl-/` trigger.
- Help mode rows show action description and keybind; Enter runs selected help action.

Current caveats:

- Help trigger is not final. Remove `Ctrl-/` after replacement key is verified.
- Target help key: `Ctrl-;` if terminal/libvaxis emits it reliably.
- Remove `<C-g>` quit binding; keep Esc and `<C-c>` only.
- Help search/input has edge cases when file query already has text.
- `picker.zig` still owns too many jobs: key decoding, reducer logic, rendering, logging, help execution, marks, and protocol output.
- Row/list code needs cleaner boundaries before adding git state.
- Marked rows currently feed quickfix only; no per-mark edit/split/tab multi-action yet.
- No dirty markers, icons, path dimming, or stable list component abstraction beyond `Row` yet.
- No non-git fallback yet.
- No SQLite store yet.

## Clean home gate

No git-status/file-brain work until picker/help/list code is clean.

Required before git work:

- Remove `<C-g>` quit binding from code, help text, and manual checklist.
- Replace temporary `Ctrl-/` help binding with final help binding.
- Test whether `Ctrl-;` arrives as usable `vaxis.Key`; if not, choose another non-text key.
- Remove `?` fallback completely. Done.
- Remove `/` text-input help hack once final help key is reliable.
- Keep `ZT_LOG` available while cleaning input behavior.
- Split pure picker reducer from vaxis shell: key event + current state -> transition/action.
- Split key decoding from behavior: one function maps `vaxis.Key` to internal commands.
- Keep `picker_state.zig` pure; expand it only for query/cursor/mode rules.
- Keep `actions.zig` as action/help registry.
- Move action execution helpers out of ad-hoc help switch code so help rows and keybinds reuse same path.
- Make help query handling explicit:
  - entering help preserves file query and file cursor.
  - help opens with its own query, initially empty unless previously set.
  - typing in help filters only help rows.
  - Esc from help restores file query and cursor.
  - Enter with no help row does nothing and does not quit.
  - opening help while file query has content never injects control bytes into either query.
- Add unit tests for help trigger decoding, mode switching, query preservation, cursor clamping, empty-help-enter no-op, and help action dispatch.
- Clean row/list boundaries:
  - `Row` draws one row only.
  - list state owns cursor/marked/git status.
  - row marker rendering is small and testable.
  - row styles/markers stay centralized.
- After clean home passes tests and manual checklist, proceed to `files.zig` and git status.

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
- left col 1: multi marker, `:` or space.
- middle: label/path text.
- right last col: git marker, `M`, `A`, `?`, `D`, `R`, or space.

Rules:

- Markers must be ASCII or plain one-cell Unicode only; no Nerd Font, emoji, or ambiguous-width symbols.
- Text clips before right git marker so marker stays visible.

Near-term list cleanup:

- Replace parallel `rows` / `selected_rows` / `row_boxes` / `selected_row_boxes` with one stable list item array. Done for rows; `row_boxes` remains only as stable `SizedBox` wrappers.
- Row drawing depends on `index == cursor` and item state.
- `Row.Styles` owns normal/current/marker/git styles.
- Next list cleanup: split generic list/action state from file-specific picker state.

## Test suite plan

Core rule: every feature gets a small non-interactive test before TUI polish.

Zig unit tests:

- `matcher.zig`: query splitting, smartcase, strict path matching, filename boost, current-file penalty, stable ranking order.
- `picker.zig`: action output protocol formatting (`edit`, `vsplit`, `tabedit`, `quickfix`).
- `actions.zig`: help rows mirror help entries; help entries map to executable actions.
- `picker_state.zig`: per-mode query/cursor behavior, cursor clamping, entering/exiting help with existing file query.
- future key decoder/reducer module: `Ctrl-;` decode, no `<C-g>`, no `?`, no text-query control byte leak, empty-help-enter no-op.
- future list/row module: marker layout, selected-row style, marked-row state, git marker slot.
- future `files.zig`: git output parsing, non-git fallback walking, git status parsing.
- future storage module: SQLite schema migration, frecency decay, query/file combo lookup.

CLI smoke tests:

- `zt pick --filter` with fixed stdin fixtures.
- `zt files --cwd <fixture> --filter` inside git fixture repo.
- output protocol snapshots for non-interactive modes once action/filter options exist.

Lua bridge tests:

- parse old bare-path output as `edit` fallback.
- parse action output lines.
- quickfix entries use `cwd` + relative path.
- unknown action reports error and does nothing.

Manual TUI checklist until input automation exists:

- cursor marker follows movement.
- `<C-y>` toggles `:` and moves down.
- Enter opens current item when no marks exist.
- Enter with marks populates quickfix.
- `<C-v>` vsplits current item.
- `<C-t>` opens current item in tab.
- Esc and `<C-c>` quit cleanly; `<C-g>` does not quit.
- suspend/resume does not freeze terminal state.
- Final help key opens searchable help mode; candidate is `Ctrl-;`.
- Temporary `Ctrl-/` binding is removed after final key is verified.
- Help mode search filters action rows.
- Enter on help action runs action.
- Enter on empty help result does nothing and does not quit.
- Esc in help returns to file picker without quitting and restores file query/cursor.

Validation command:

```sh
cd zetesis
zig fmt build.zig src/*.zig
zig build test
zig build
```
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

### M4: clean home

- Remove `<C-g>` quit binding.
- Replace temporary `Ctrl-/` help binding with final key after terminal verification.
- Fix help query edge cases.
- Split picker reducer/key decoding from vaxis UI shell.
- Clean row/list boundaries.
- Add tests for reducer, help query behavior, key decoding, and row/list basics.
- Keep git/file-brain work blocked until this milestone is complete.

### M5: file collection and git status

- Move file collection into `files.zig`.
- Add non-git fallback walking.
- Parse `git status --porcelain=v1 -z`.
- Populate row git marker.
- Add dirty-file boost.

### M6: file brain

- Add SQLite store.
- Record opened path with timestamp and project key.
- Add frecency boost.
- Add query combo memory.
- Add special filename boost.

### M7: generic JSONL picker

- `zt pick --source jsonl`.
- display field.
- output selected JSON unchanged.
- Lua buffer picker proof.

### M8: packaging

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
