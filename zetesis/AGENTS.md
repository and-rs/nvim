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
