# zetesis plan

## Plan preface

- Objective: build `zetesis` / `zt` as middle ground between `fzf` and `fff`.
- `fzf` class strength to keep: usable general-purpose matcher for many picker jobs,
  not only files.
- `fff` class strength to grow toward: file-aware ranking and repo-aware file
  behavior that beats generic fuzzy tools on file picking.
- Current practical target: make `zt` strong enough to replace `fzf` for common
  stdin-driven and file-driven picker flows, while keeping clear path toward
  smarter file ranking later.
- Non-goal for now: full `fff` replacement, daemon, preview, or giant background
  indexer.

## Locked decisions

- Project name: `zetesis`.
- Binary name: `zt`.
- Language: Zig.
- UI dependency: libvaxis.
- CLI subcommands: `stdin`, `files`, `help`.
- `stdin` stays name. Do not restore `pick`.

- Lua owns terminal launch, editor integration, and final action execution.
- Zig owns matching, file collection, picker state, protocol output, and CLI
  parsing.
- No preview initially.
- No daemon initially.
- No Nerd Font, emoji, or ambiguous-width markers.
- Cursor marker at row start: `>`.
- Mark marker at row start: `:`.
- Git marker at row end.
- Persistent memory starts with SQLite when file-brain work begins.

## Decision rules

- Favor usable general-purpose picker first, then add file intelligence without
  making stdin mode weird.
- Favor explicit subcommands over magic mixed argument parsing.
- Parser, help text, docs, and tests must move together.

- No git-status or file-brain expansion until picker/help/list boundaries stop
  fighting each other.
- Prefer many small verifiable tasks over large vague milestones.
- Every behavior change should have at least one validation step: build, test,
  command check, or manual TUI check.
- Keep architecture honest:
  - `src/main.zig`: CLI boundary, mode dispatch, top-level orchestration.
  - `src/picker_state.zig`: pure state.
  - `src/picker_reducer.zig`: command/reducer behavior.
  - `src/picker.zig`: shell integration and rendering glue.
  - `lua/config/zetesis.lua`: Neovim bridge only.

## Found issues

- Pressing Enter with empty input still clears something it should not clear.
- Git-tracked paths deleted from working tree can still leak into `zt files`
  output.
- Git marker slot exists but status is not populated.
- Suspend/resume freeze still unproven.
- Help path drift risk exists when CLI changes but docs/tests do not.

## Goal

Build `zt`: repo-owned Zig terminal picker for Neovim and CLI use.

- matcher: general-purpose fuzzy matching usable for stdin pickers.
- matcher: file-aware ranking strong enough to beat generic fuzzy tools for file
  picking.
- UI: libvaxis terminal picker, no preview.
- Neovim: Lua opens floating terminal and owns final editor actions.
- long-term: FFF-like file brain with repo awareness, git state, current-buffer
  context, frecency, and query/file memory.

## Current state

Working:

- [x] `zt stdin` reads stdin lines.
- [x] `zt stdin --filter <query>` prints ranked matches.
- [x] `zt files --cwd <path>` uses git file collection, with recursive non-git
  fallback.
- [x] `zt files --filter <query>` works.
- [x] `zt help` works.

- [x] Neovim command `:ZetesisFiles` opens floating terminal and calls
  `zt files --cwd --current-file --output-file`.
- [x] Output protocol is action lines:
  - `edit	path`
  - `vsplit	path`
  - `tabedit	path`
  - `quickfix	path`
- [x] Lua parses action protocol and keeps bare-path fallback.
- [x] Enter with no marks edits current row.
- [x] Enter with marks sends marked paths to quickfix.
- [x] `<C-v>` opens vertical split.
- [x] `<C-y>` toggles mark marker `:` and moves cursor down when possible.
- [ ] Help mode opens with `Ctrl-;`, uses same searchable list UI, and Enter runs
  selected help action.

- [x] `Esc` in help returns to file picker.
- [x] `Esc` and `<C-c>` quit picker.
- [x] `<C-g>` quit removed.
- [x] `Ctrl-/`, `?`, and `/` help fallbacks removed.


Project layout:

- `src/main.zig`: CLI parsing, modes, current file collection, output handoff.
- `src/matcher.zig`: zf-like ranking, filename boost, strict path matching,
  current-file penalty.
- `src/actions.zig`: action enum, help action enum, help rows.
- `src/key_decoder.zig`: `vaxis.Key` -> internal picker command.
- `src/picker_reducer.zig`: mode + command -> picker effect.
- `src/picker_state.zig`: pure mode/query/cursor state.
- `src/picker.zig`: libvaxis shell, prompt/list/footer, marking, help execution,
  protocol result.
- `src/row.zig`: custom row widget with cursor/mark/git marker columns.
- `lua/config/zetesis.lua`: Neovim float, terminal job, action output
  parser/executor.

Known caveats:

- `picker.zig` still owns rendering, protocol output, and vaxis shell code.
- `picker_list.zig` now owns list rows, row widgets, marks, and list refresh
  state.
- No SQLite store yet.

## Clean home gate

No git-status or file-brain work until picker/help/list code is clean enough to
stop fighting itself.

Done:

- [x] Remove `<C-g>` quit from code/help text.
- [x] Replace temporary `Ctrl-/` with `Ctrl-;`.
- [x] Add `F1` fallback for help outside Neovim terminal.
- [x] Remove `?` fallback.
- [x] Remove `/` text-input help hack.
- [x] Add `key_decoder.zig` tests for `Ctrl-;`, no `<C-g>`, no `?`.

- [x] Keep `picker_state.zig` pure.
- [x] Keep `actions.zig` as help/action registry.
- [x] Lua action protocol parsing restored.
- [x] User manually confirmed help keymaps feel clean.
- [x] `actions.zig` maps help actions to shared dispatch actions.
- [x] Empty help selection lookup is explicit and tested.
- [x] `picker_state.zig` tests existing file-query restore after help search.
- [x] Git status is clean; helper modules are tracked.

Still needed before git work:

- [ ] Keep `ZT_LOG` or equivalent env-gated debug hook available while terminal
  input is still evolving.
- [ ] Split remaining overgrown picker responsibilities only where boundary is real.
- [ ] Keep help/file mode transitions easy to reason about.
- [ ] Keep output protocol path separate from render path.

## Action checklist

### CLI and help contract

- [x] rename any remaining `pick` language in code/docs/tests to `stdin`.
- [x] lock CLI help contract:
  - `zt help` prints thorough top-level CLI help.
  - `zt help` does not launch interactive picker mode.
  - subcommands own their own `--help` output.
- [ ] remove `zt help --filter <query>` support from parser/docs/tests.
- [ ] audit `usage()` output for command truth.
- [ ] split help output into:
  - top-level `zt help`
  - `zt stdin --help`
  - `zt files --help`
- [ ] decide exact allowed flags for `stdin`.
- [ ] decide exact allowed flags for `files`.
- [x] decide exact allowed flags for `help`.
- [x] reject mode-invalid flags with exit code `2`.
- [ ] add parser test for unknown subcommand.
- [ ] add parser test for missing value after `--filter`.
- [ ] add parser test for `zt stdin --cwd .` failing.
- [ ] add parser test for `zt files --cwd .` passing.
- [ ] add parser test for `zt help` behavior.
- [ ] add parser test for `zt stdin --help` behavior.
- [ ] add parser test for `zt files --help` behavior.
- [ ] add parser test for `zt help --filter x` failing.
- [ ] add parser test for global `--help` short-circuit behavior if kept.
- [ ] rename `Mode` to `Subcommand` later if code meaning stays clearer that way.


### File collection contract

- [ ] make `zt files` anchor unambiguously to provided `--cwd`.
- [ ] verify absolute vs relative `--cwd` behavior.
- [ ] verify git command runs in intended directory.
- [ ] exclude git-tracked paths deleted from working tree.
- [ ] keep recursive non-git fallback unchanged.
- [ ] decide whether hidden files follow git/fallback source or custom filter rules.
- [ ] decide behavior for unreadable directories in fallback walk.
- [ ] add test for deleted tracked file exclusion.
- [ ] add test for fallback walking in non-git directory.
- [ ] add test for relative `--cwd`.
- [ ] add test for absolute `--cwd`.
- [ ] add test for empty repository result.

### Git status integration

- [ ] parse `git status --porcelain=v1 -z`.
- [ ] map porcelain codes to `Row.GitStatus`.
- [ ] decide displayed marker set exactly: `M`, `A`, `?`, `D`, `R`, or space.
- [ ] populate rightmost marker from git status.
- [ ] decide how rename should display old/new path.
- [ ] decide whether deleted files should ever appear in picker list.
- [ ] add dirty-file boost in matcher.
- [ ] add tests for modified files.
- [ ] add tests for added files.
- [ ] add tests for untracked files.
- [ ] add tests for deleted files.
- [ ] add tests for renamed files.

### Matcher evolution

- [ ] preserve strong generic stdin matching while adding file boosts.
- [ ] document current ranking components.
- [ ] audit current-file penalty behavior.
- [ ] decide whether current-file match should demote exact current file or only near
  duplicates.
- [ ] add special filename boosts:
  - `init.lua`
  - `mod.rs`
  - `lib.rs`
  - `main.rs`
  - `index.ts`
  - `index.tsx`
  - `index.js`
  - `__init__.py`
- [ ] decide whether filename boosts should be language-configurable later.
- [ ] add tests for each filename boost family.
- [ ] add tests proving stdin mode does not inherit file-only boosts incorrectly.
- [ ] add tests for strict path matching.
- [ ] add tests for current-file penalty.
- [ ] add tests for hide/show score behavior.

### Picker architecture cleanup

- [ ] review `picker.zig` responsibilities line by line.
- [ ] list what belongs to rendering only.
- [ ] list what belongs to protocol output only.
- [ ] list what belongs to shell/vaxis lifecycle only.
- [ ] move one real boundary at a time, not wrapper theater.
- [x] keep `picker_state.zig` pure.
- [x] keep `picker_reducer.zig` reducer-focused.
- [ ] decide whether protocol output should live outside `picker.zig`.
- [ ] decide whether footer/help text generation should move out.
- [ ] add reducer tests for mark operations.
- [ ] add reducer tests for help enter/leave cycles.
- [ ] add reducer tests for no-op Enter on empty help results.
- [ ] prove suspend/resume does not freeze terminal state.
- [ ] add debug hook usage notes for terminal-input debugging.

### Help mode UX

- [x] keep help rows searchable with same matcher path.
- [x] help mode is interactive-only inside picker, not CLI `zt help` mode.
- [ ] decide whether help actions should be grouped visually.
- [ ] decide whether help search should show score column.

- [ ] verify `Esc` restores file query.
- [ ] verify `Esc` restores file cursor.
- [ ] verify `Esc` clears help-only search state.
- [ ] verify Enter on help item dispatches intended action.
- [ ] verify Enter on empty help result does nothing.
- [x] add tests for help selection lookup.
- [x] add tests for help query restore path.

### Output protocol and Lua bridge

- [x] keep action protocol stable: `edit`, `vsplit`, `tabedit`, `quickfix`.
- [ ] decide whether protocol should later carry line/column.
- [ ] decide whether protocol should later carry multiple quickfix items in richer
  form.
- [ ] add Zig-side tests for emitted protocol strings if missing.
- [x] keep Lua bare-path fallback.
- [ ] add Lua tests for mixed action and bare-path lines.
- [ ] add Lua tests for empty output.
- [ ] add Lua tests for unknown action fallback behavior.
- [ ] verify `:ZetesisFiles` still passes `--cwd`, `--current-file`, and
  `--output-file` correctly.
- [ ] verify terminal close timing after action output.

### Persistence and file brain

- [ ] choose SQLite schema for frecency.
- [ ] choose SQLite schema for query/file memory.
- [ ] decide key shape: repo root + relative path.
- [ ] decide decay strategy for frecency.
- [ ] decide write timing: immediate, delayed, or exit batch.
- [ ] add repository-root detection for persistence keys.
- [ ] add tests for repo key derivation.
- [ ] add tests for frecency updates.
- [ ] add tests for query/file memory lookup.
- [ ] keep persistence optional while core UX still moving.

### Generic picker expansion

- [ ] design generic stdin/path-independent ranking path explicitly.
- [ ] decide whether future JSONL source belongs under `stdin` or new subcommand.
- [x] if JSONL stays planned, rename old `pick` wording to `stdin --source jsonl`.
- [ ] define display field selection behavior.
- [ ] define output behavior: selected JSON unchanged.
- [ ] add parser tests for source selection when implemented.
- [ ] add fixture tests for JSONL rows when implemented.

### Validation checklist

Automated:

```sh
cd zetesis
zig fmt build.zig src/*.zig
zig build test
zig build
printf 'alpha\nbeta\n' | zig-out/bin/zt stdin --filter alp
zig-out/bin/zt help
```

Neovim Lua parser/bridge with bob:

```sh
bob run 0.12.2 --headless --clean -u NONE \
  -c 'set rtp+=.' \
  -c 'lua package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path; local z=require("config.zetesis"); local r=z._parse_output({"edit\tfoo.lua","vsplit\tbar.lua","bare.lua","quickfix\ta.lua"}); assert(r[1].action=="edit" and r[1].path=="foo.lua"); assert(r[2].action=="vsplit" and r[2].path=="bar.lua"); assert(r[3].action=="edit" and r[3].path=="bare.lua"); assert(r[4].action=="quickfix" and r[4].path=="a.lua")' \
  -c 'qa'
```

Manual TUI:

- [ ] `:ZetesisFiles` opens picker.
- [ ] cursor marker follows movement.
- [ ] Enter opens current item when no marks exist.
- [ ] `<C-y>` toggles `:` and moves down.
- [ ] Enter with marks populates quickfix.
- [ ] `<C-v>` vsplits current item.
- [ ] `<C-t>` opens current item in tab.
- [ ] `Ctrl-;` opens searchable help mode.
- [ ] `F1` opens searchable help mode.
- [ ] help search filters action rows.
- [ ] Enter on help action runs action.
- [ ] Enter on empty help result does nothing and does not quit.
- [ ] Esc in help returns to file picker and restores file query/cursor.
- [ ] Esc and `<C-c>` quit cleanly.
- [ ] `<C-g>` does not quit.
- [ ] suspend/resume does not freeze terminal state.