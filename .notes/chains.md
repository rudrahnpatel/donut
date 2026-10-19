# Chains: plan backwards from a pin

## What

A **chain** is a reusable sequence of steps with durations but no times, e.g. *Commute*:
getting ready 5 → home to stn 5 → train 40.

- **Saving one:** an entry's ⋮ → *Save as chain…* takes it and the entries back to back
  after it. Untick the ones to leave out and name it.
- **Placing one:**
  - a pin's ⋮ → *Fit a chain before…* lays the chain so it ends exactly at the pin
    ("Reach by 4:55" → getting ready from 4:05);
  - *Start a chain here…* lays it from the pin;
  - ✨ → *Add a chain…* lays it from a chosen time (now, rounded up, by default).
- Steps arrive as plan-mode sketches, like a template, so ✓ keeps them and ✕ drops them.
  Overlaps are allowed as usual.

## How

- **Storage:** `Chains` table (schema v4, `createTable` on upgrade, synced like
  templates). `stepsJson` is `[{d, n?, a?, e?, c?}]`.
  - `ChainStep` and the `ChainSteps` extension (`steps`, `length`) are in
    `plan_tools_repo.dart`, with `watchChains` / `saveChain` / `deleteChain` /
    `applyChain(chain, startMin)`.
  - `applyChain` goes through `BlockRepo.create`, the edit overlay.
- **UI** (`lib/features/templates/chains.dart`):
  - `backToBackFrom` finds the run (gaps of at most 1 minute).
  - `saveChainFrom` is the save sheet, `pickChain` the picker (with delete), and
    `placeChain` applies the chain and reports the time span.

## Why

- **Templates are whole days at fixed times;** a chain is the piece that repeats at
  different times (the commute, a morning routine), so it has no times until placed.
  Hence a separate table rather than a flag on templates.
- **Fitting before a pin answers the travel question directly:** "I must reach by 4:55;
  when do I start getting ready?"
- **Saving a chain from existing entries** avoids a step editor: plan it once on the dial,
  then reuse it.
- **Sketches, not saved entries,** because placing several entries at once is a proposal
  to review, the same as templates and "copy yesterday".
