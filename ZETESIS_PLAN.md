# zetesis plan

## Goal

Build `zetesis`, repo-owned Zig binary `zt`: small fzf/sk-like terminal picker for Neovim and CLI use.

- matcher: zf-like filepath ranking.
- UI: libvaxis terminal picker, no preview.
- Neovim: Lua opens floating terminal and owns final editor actions.
- long-term: FFF-like file brain: repo-aware ranking, git state, current-buffer context, frecency, query/file memory.

## Current state

Working:

- `zt pick` reads stdin lines.
- `zt pick --filter <query>` prints ranked matches.
- `zt files --cwd <path>` uses git file collection, with recursive non-git fallback.
- `zt files --filter <query>` works.
- `zt help` and `zt help --filter <query>` work.
- Neovim command `:ZetesisFiles` opens floating terminal and calls `zt files --cwd --current-file --output-file`.
- Output protocol is action lines:
  - `edit	path`
  - `vsplit	path`
  - `tabedit	path`
  - `quickfix	path`
- Lua parses action protocol and keeps bare-path fallback.
- Enter with no marks edits current row.
- Enter with marks sends marked paths to quickfix.
- `<C-v>` opens vertical split.
- `<C-t>` opens tab.
- `<C-y>` toggles mark marker `:` and moves cursor down when possible.
- Help mode opens with `Ctrl-;`, uses same searchable list UI, and Enter runs selected help action.
- `Esc` in help returns to file picker.
- `Esc` and `<C-c>` quit picker.
- `<C-g>` quit removed.
- `Ctrl-/`, `?`, and `/` help fallbacks removed.

Project layout:

- `src/main.zig`: CLI parsing, modes, current file collection, output handoff.
- `src/matcher.zig`: zf-like ranking, filename boost, strict path matching, current-file penalty.
- `src/actions.zig`: action enum, help action enum, help rows.
- `src/key_decoder.zig`: `vaxis.Key` -> internal picker command.
- `src/picker_reducer.zig`: mode + command -> picker effect.
- `src/picker_state.zig`: pure mode/query/cursor state.
- `src/picker.zig`: libvaxis shell, prompt/list/footer, marking, help execution, protocol result.
- `src/row.zig`: custom row widget with cursor/mark/git marker columns.
- `lua/config/zetesis.lua`: Neovim float, terminal job, action output parser/executor.

Known caveats:

- `picker.zig` still owns rendering, protocol output, and vaxis shell code.
- `picker_list.zig` now owns list rows, row widgets, marks, and list refresh state.
- Git-tracked paths deleted from working tree can still leak into `zt files` output.
- Git marker slot exists but status is not populated.
- No SQLite store yet.
- Suspend/resume freeze still unproven.

## Clean home gate

No git-status/file-brain work until picker/help/list code is clean enough to stop fighting itself.

Done:

- Remove `<C-g>` quit from code/help text.
- Replace temporary `Ctrl-/` with `Ctrl-;`.
- Remove `?` fallback.
- Remove `/` text-input help hack.
- Add `key_decoder.zig` tests for `Ctrl-;`, no `<C-g>`, no `?`.
- Add `picker_reducer.zig` tests for Esc/back, help switch, file-only actions.
- Keep `picker_state.zig` pure.
- Keep `actions.zig` as help/action registry.
- Lua action protocol parsing restored.
- User manually confirmed help keymaps feel clean.
- `actions.zig` maps help actions to shared dispatch actions.
- Empty help selection lookup is explicit and tested.
- `picker_state.zig` tests existing file-query restore after help search.
- Git status is clean; helper modules are tracked.

Still needed before git work:

- Keep `ZT_LOG` or equivalent env-gated debug hook available while terminal input is still evolving.

## Next implementation steps

1. Tighten file-collection contract:
   - make `zt files` anchor unambiguously to provided `--cwd`.
   - exclude git-tracked paths that no longer exist in working tree.
   - keep recursive non-git fallback behavior unchanged.
   - add tests for deleted tracked files and fallback walking.
2. Add git status integration:
   - parse `git status --porcelain=v1 -z`.
   - map status to `Row.GitStatus`.
   - populate rightmost marker: `M`, `A`, `?`, `D`, `R`, or space.
   - add dirty-file boost.
3. Add first file-brain boosts:
   - special filename boost: `init.lua`, `mod.rs`, `lib.rs`, `main.rs`, `index.ts`, `index.tsx`, `index.js`, `__init__.py`.
   - SQLite frecency.
   - SQLite query/file combo memory.
4. Add generic JSONL picker later:
   - `zt pick --source jsonl`.
   - display field.
   - output selected JSON unchanged.
## Test checklist

Automated:

```sh
cd zetesis
zig fmt build.zig src/*.zig
zig build test
zig build
printf 'alpha\nbeta\n' | zig-out/bin/zt pick --filter alp
zig-out/bin/zt help --filter split
```

Neovim Lua parser/bridge with bob:

```sh
bob run 0.12.2 --headless --clean -u NONE \
  -c 'set rtp+=.' \
  -c 'lua package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path; local z=require("config.zetesis"); local r=z._parse_output({"edit\tfoo.lua","vsplit\tbar.lua","bare.lua","quickfix\ta.lua"}); assert(r[1].action=="edit" and r[1].path=="foo.lua"); assert(r[2].action=="vsplit" and r[2].path=="bar.lua"); assert(r[3].action=="edit" and r[3].path=="bare.lua"); assert(r[4].action=="quickfix" and r[4].path=="a.lua")' \
  -c 'qa'
```

Manual TUI:

- `:ZetesisFiles` opens picker.
- cursor marker follows movement.
- Enter opens current item when no marks exist.
- `<C-y>` toggles `:` and moves down.
- Enter with marks populates quickfix.
- `<C-v>` vsplits current item.
- `<C-t>` opens current item in tab.
- `Ctrl-;` opens searchable help mode.
- help search filters action rows.
- Enter on help action runs action.
- Enter on empty help result does nothing and does not quit.
- Esc in help returns to file picker and restores file query/cursor.
- Esc and `<C-c>` quit cleanly.
- `<C-g>` does not quit.
- suspend/resume does not freeze terminal state.

## Design decisions

- Project name: `zetesis`.
- Binary name: `zt`.
- Language: Zig.
- Dependency: libvaxis for terminal UI.
- Reference: inspect `zf` and libvaxis; do not fork.
- No daemon initially.
- No preview initially.
- No Nerd Font, emoji, or ambiguous-width markers.
- Cursor marker at row start: `>`.
- Mark marker at row start: `:`.
- Git marker at row end.
- SQLite first for persistent frecency/query memory once file brain starts.
- Lua stays terminal chrome + editor action executor, not picker UI.
