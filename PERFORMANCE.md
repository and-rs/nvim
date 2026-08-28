# Performance orientation

This note maps the code paths that are likely to determine Zetesis performance.
It is intended as a reading guide before changing algorithms or measuring
anything.

## Two different kinds of delay

There are two user-visible moments to keep separate:

1. **Startup delay**: time from `zt files` until the picker appears.
2. **Search delay**: time after typing a query until rows update; this also
   includes non-interactive `--filter` mode.

They use different subsystems, so an improvement to one may not affect the
other.

## Startup: file discovery

Start reading at `src/main.zig`, `runFiles`, then follow:

```text
runFiles
  -> files.collectProjectEntries
      -> git ls-files -z --cached --others --exclude-standard
      -> files/git.collectEntries
          -> statFile for every listed path
          -> git status --porcelain=v1 -z
```

The Git path therefore starts two external Git processes and performs one
filesystem stat for every candidate path. This is a reasonable way to obtain
accurate project files and status markers, but it is likely the dominant startup
cost in a large repository or on a slow filesystem.

If Git fails, `files/walk.zig` recursively walks the tree instead. That is also
filesystem-bound, especially outside a Git repository.

Questions to answer with measurements before changing this path:

- Is time spent mostly launching Git, running Git, or calling `statFile`?
- How many paths are normally discovered in the repositories that feel slow?
- Is Git-status ranking worth delaying initial display, or could status be
  loaded later?
- Does the fallback walker visit expensive generated directories not already
  excluded by `ignoredPath`?

## Interactive search: refresh on every edit

Start at `src/picker/mod.zig`, `Model.onChange`:

```text
text field changes
  -> Model.refresh
      -> list.State.refresh
          -> results.rankRows
              -> match.parseQuery
              -> match.rankQueryTop
```

Every query edit scans the whole input source. For each matching line, the
matcher scores query terms against the path and its components. After ranking,
the picker constructs row data and widgets for up to `max_ranked_rows`
(currently 512).

This makes the full candidate count the main factor in typing responsiveness. A
longer, multi-term query also adds matching work per candidate.

### Ranking implementation detail

`match.rankQueryTop` keeps its best results sorted by calling `insertBounded`
for each matching candidate. `insertBounded` linearly searches and shifts items
in its current result list.

For interactive search, that list is capped at 512. The rough upper bound is
therefore proportional to:

```text
number of source lines × 512
```

plus the fuzzy-matching work itself. The cap prevents the UI from constructing
arbitrary numbers of rows, but it does not avoid scanning the entire source.

Before changing this, measure whether the matcher or bounded insertion actually
dominates. A heap or selection algorithm could reduce maintenance of the top
results, but would add implementation complexity and needs a stable final
ordering rule.

## Non-interactive `--filter`: likely algorithmic hotspot

`src/main.zig`, `runPicker`, calls:

```zig
matcher.rankQueryTop(allocator, source.lines, terms, filter_options, source.lines.len)
```

Here the result limit equals the number of source lines. That removes the
interactive 512-row bound. Since `insertBounded` performs linear ordered
insertion, a query that matches many inputs can approach quadratic work in the
number of matches.

This is the clearest algorithmic performance candidate in the current code. It
affects `--filter`, not the normal interactive picker.

Useful measurements:

- Candidate count and matched-result count.
- Time with broad queries such as an empty string or a common character.
- Time with selective queries.
- Comparison between `rankQueryTop(..., lines.len)` and a collect-then-sort
  implementation.

## Per-candidate matcher work

Relevant code is in `src/match/mod.zig`:

- `rankQuery` handles parsed query terms.
- `rankNeedle` evaluates fuzzy matching.
- `bestComponentMatch` splits a path into slash-separated components and scores
  them.
- `queryMatchIndexes` runs after ranking to calculate character highlighting
  offsets.

Important consequence: a matching result can be examined once for ranking and
again to produce highlight indexes. Highlight computation is only done for
retained ranked rows, which is good, but each retained row may still be
processed for every query term.

Potential later questions:

- Do highlighting indexes need to be exact for every visible row?
- Can ranking return enough match-position information to avoid a second pass?
- Are filenames/path components being recalculated frequently enough to justify
  precomputation?

These are not recommended changes yet; they need profiling evidence.

## Rendering and allocations

After interactive ranking, `picker/list.zig` builds `RankedLine`, `Row`, and
`SizedBox` values for every retained result. When scores are shown, it also
allocates a formatted score string for every visible row. `Model.refresh` resets
its arena before rebuilding these transient values.

Because the interactive result set is capped at 512, this is more likely a
secondary cost than the full-source matching scan. It may matter on constrained
terminals or when redraw frequency is high.

## Recommended measurement order

1. Time `zt files` startup separately from opening the picker.
2. Measure interactive query refreshes against a representative large
   repository.
3. Measure `--filter` with both broad and selective queries.
4. Profile before making structural matcher changes.
5. Optimize the path demonstrated by measurements, not the path that merely
   looks expensive in source.

## Current summary

- **Likely startup bottleneck:** Git discovery/status plus `statFile` for every
  discovered path.
- **Likely interactive bottleneck:** scanning and fuzzy-ranking the full source
  on every query change.
- **Likely largest algorithmic issue:** `--filter` requesting all ranked results
  while using linear sorted insertion.
- **Secondary cost:** constructing and rendering up to 512 rows, including
  score-label allocations when enabled.
