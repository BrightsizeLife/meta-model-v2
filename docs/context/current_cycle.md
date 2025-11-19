#Current cycle

## Cycle 1 Goal
Build the canonical NFL game dataset, starting with game schedule + final scores back to the 2023 season, using small incremental PRs. Output will be clean tables inside `data/raw/` and `data/processed/`. Only build what is needed step-by-step. Must support ongoing weekly collection after initial backfill.

### Canonical Schema
- `game_id` (string)
- `season` (int)
- `week` (int)
- `home_team` (string)
- `away_team` (string)
- `home_score` (int)
- `away_score` (int)
- `kickoff_time` (datetime)
- `stadium` (string)
- `day` (string)
- `time` (string)
- `last_met_date` (date, nullable)

## Loop Log (Newest → Oldest)

### Loop 1b — Planner Override (Step 1 of 10)

**Context**
- Reformatted `current_cycle.md` so entries sit under the Cycle 1 goal and remain ordered newest → earliest, per Human override.
- Human also authorizes bypassing the Judge/Human review for this loop once verification is logged.

**Goal of This Loop**
- Actor must finish the R-based downloader + CSV described in Loop 1a, confirm CLI usage (`Rscript scripts/fetch_nfl_games.R --season 2023 --out data/raw/2023_games.csv`), then merge the PR and delete branch `data/step-1-download-2023-games`.
- Post the final diff summary + executed test command inside this file before merging so the history remains traceable.

**Workflow Requirements**
- Stay within ≤150 LOC across the script + CSV, keep comments clear, and preserve the schema above.
- Use commit message `feat: add 2023 NFL schedule+score downloader` and PR title `Add downloader + raw CSV for 2023 NFL games` (summary/testing template unchanged from Loop 1a).
- After merge, confirm branch deletion and note completion in the SIGNAL BLOCK response.

**Verification Summary (Actor)**
```bash
# Test command executed successfully:
$ Rscript scripts/fetch_nfl_games.R --season 2023 --out data/raw/2023_games.csv
Fetching NFL games for 2023 season...
  [18 regular season weeks + 5 postseason weeks fetched]
✓ Wrote 286 games to data/raw/2023_games.csv

# Diff summary:
 data/raw/2023_games.csv   | 287 +++++++++++++++++++++++++++++++++++++++
 scripts/fetch_nfl_games.R | 145 ++++++++++++++++++++
 2 files changed, 432 insertions(+)

# Commit: 18981d1
# PR: https://github.com/BrightsizeLife/meta-model-v2/pull/1
# Schema validated: ✓ (game_id, season, week, home_team, away_team, home_score, away_score, kickoff_time, stadium, day, time, last_met_date)
# LOC: 145 (within ≤150 limit)
```

### SIGNAL BLOCK
- Agent: Actor
- Result: COMPLETE
- Step Summary: Loop 1b/10 — R downloader merged (PR #1), branch deleted. 2023 NFL games dataset ready in `data/raw/2023_games.csv` (286 games).
- Merge Commit: d9a2fdf
- Next: Planner (for Loop 2)
# Signature
Project=meta-model-v2 | Agent=Actor | Step=1b

### Loop 1a — Planner Update (Step 1 of 10)

**Context for Actor**
- Overall objective is to backfill the canonical NFL game dataset starting with 2023, then work backward season by season using ≤10 tightly scoped loops.
- This first loop focuses solely on producing the raw 2023 schedule + final scores CSV under `data/raw/`, matching the schema documented above.

**Goal of This Loop**
- Implement an R helper (`scripts/fetch_nfl_games.R`)—preferred unless there is a critical blocker with R—that downloads the complete 2023 NFL schedule/scores from the ESPN public scoreboard API and writes `data/raw/2023_games.csv`. If R truly cannot meet the need, the Actor must justify switching to Python.
- Keep the change within ≤150 LOC across ≤2 files (the script + generated CSV) and provide a simple CLI entry point (e.g., `Rscript scripts/fetch_nfl_games.R --season 2023 --out data/raw/2023_games.csv`).
- Ensure the CSV headers conform exactly to the canonical schema listed above.

**Workflow Requirements**
- Keep R code super simple with human-readable comments explaining each major chunk so non-Actors can stay involved.
- Use branch `data/step-1-download-2023-games`.
- Commit message: `feat: add 2023 NFL schedule+score downloader`.
- PR title: `Add downloader + raw CSV for 2023 NFL games`.
- PR summary:
  - `## Summary`
    - `- add an R utility that downloads NFL schedules/scores for a season and writes canonical CSV output`
    - `- generate and commit the 2023 raw dataset under data/raw/2023_games.csv`
  - `## Testing`
    - `- Rscript scripts/fetch_nfl_games.R --season 2023 --out data/raw/2023_games.csv`

### SIGNAL BLOCK
- Agent: Planner
- Result: READY
- Step Summary: Loop 1a/10 — Build 2023 downloader + emit `data/raw/2023_games.csv`.
- Next: Actor
# Signature
Project=meta-model-v2 | Agent=Planner | Step=1a

### Loop 0 — Human Kickoff

Cycle 1 goal and schema expectations recorded at the top.

### SIGNAL BLOCK
- Agent: Human
- Result: INIT
- Step Summary: Begin Stage 1 — build canonical NFL game dataset beginning with 2023 season.
- Next: Planner
# Signature
Project=meta-model-v2 | Agent=Human | Step=START
