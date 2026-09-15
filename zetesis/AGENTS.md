- for listing ONLY use fd (no find or no rg)
- for git status and rich repo metadata, well git
- tests separated from src files

- flag parsing already has a reasonable shape:
  - we need to generate help output dynamically (not hardcode a print).
  - we need to have robust parsing, args, positions, actions, etc.

- this right here, should be the threaded/concurrent architecture
  ```
  fd thread (drink + .env merge) ─┐
  git thread (already there)     ─┼─ queue ─ tick drain ─ append rows ─ redraw
  vxfw: keys + draw              ─┘
  ```

- looking for likely leak paths is IMPORTANT, because this is zig and it's just likely to happen

- [~] new lua structure with new flag contract
- [x] new ui tested on threaded architecture
- [x] matcher wired
- [ ] bring back previous help menu and actions
- [ ] --filter flags tested
