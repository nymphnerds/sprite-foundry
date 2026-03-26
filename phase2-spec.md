# Phase 2 — Registry + Review Loop

## Purpose

Turn a folder of PNGs into a production foundry with durable identity, mandatory review, and queryable decision history.

## Guiding constraint

No asset can silently bypass review. Every accept/reject/regen decision is stored, not implied. You can answer "why did this version win?" from the registry alone.

---

## SQLite Schema

### Tables

#### `subjects`

The character definition. One row per character in the foundry.

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | slug, e.g. `sera_vale`, `kael_morrow` |
| display_name | TEXT NOT NULL | e.g. "Sera Vale" |
| role | TEXT | e.g. "crew broker / quartermaster" |
| consumer | TEXT | e.g. "Star Freight" |
| subject_sheet_path | TEXT | relative path to subject-sheet.md |
| created_at | TEXT NOT NULL | ISO 8601 |

#### `runs`

A generation run. One run = one execution of the pipeline for one subject.

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | e.g. `kael_1c_20260326_033800` |
| subject_id | TEXT NOT NULL FK | → subjects.id |
| stack | TEXT NOT NULL | e.g. `A_v2` |
| seed | INTEGER NOT NULL | |
| gen_width | INTEGER NOT NULL | e.g. 576 |
| gen_height | INTEGER NOT NULL | e.g. 768 |
| sprite_target | INTEGER NOT NULL | e.g. 48 |
| prompt_hash | TEXT | SHA256 of full positive prompt (for drift detection) |
| subject_sheet_hash | TEXT | SHA256 of subject sheet at generation time (for subject drift detection) |
| recipe_json | TEXT | full recipe blob |
| created_at | TEXT NOT NULL | ISO 8601 |

#### `attempts`

A single direction within a run. One attempt = one generated image for one direction.

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK AUTOINCREMENT | |
| run_id | TEXT NOT NULL FK | → runs.id |
| direction | TEXT NOT NULL | one of: front, front_left, left, back_left, back, back_right, right, front_right |
| seed | INTEGER NOT NULL | may differ from run seed for regens |
| state | TEXT NOT NULL | lifecycle state (see below) |
| parent_attempt_id | INTEGER FK NULL | → attempts.id (for regens) |
| regen_reason | TEXT NULL | decision code that triggered regen |
| regen_note | TEXT NULL | reviewer free-text |
| created_at | TEXT NOT NULL | ISO 8601 |

**Indexes:**
- `INDEX idx_attempts_run_dir ON attempts(run_id, direction)` — lookup by run + direction
- `UNIQUE INDEX idx_attempts_one_accepted ON attempts(run_id, direction) WHERE state = 'finish_accepted'` — enforces only one accepted attempt per (run, direction) at any time

#### `artifacts`

Physical files produced by an attempt.

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK AUTOINCREMENT | |
| attempt_id | INTEGER NOT NULL FK | → attempts.id |
| kind | TEXT NOT NULL | one of: `raw`, `pixel`, `normal_raw`, `normal`, `depth_raw`, `depth`, `contact_sheet`, `raw_inspection` |
| path | TEXT NOT NULL | relative to foundry root |
| width | INTEGER | |
| height | INTEGER | |
| hash | TEXT | SHA256 of file contents |
| created_at | TEXT NOT NULL | ISO 8601 |

#### `reviews`

Every review decision is a row. Never mutated — append-only history.

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK AUTOINCREMENT | |
| attempt_id | INTEGER NOT NULL FK | → attempts.id |
| review_type | TEXT NOT NULL | `mechanical`, `raw_source`, `pixel`, `finish` |
| decision | TEXT NOT NULL | `pass`, `fail`, `accept`, `reject`, `needs_regen` |
| code | TEXT NULL | decision code (see below) |
| note | TEXT NULL | reviewer free-text |
| reviewer | TEXT NOT NULL | `auto` for mechanical, human name for manual |
| created_at | TEXT NOT NULL | ISO 8601 |

#### `finish_captures`

Godot finish lab captures linked to attempts.

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK AUTOINCREMENT | |
| attempt_id | INTEGER NOT NULL FK | → attempts.id |
| lighting_state | TEXT NOT NULL | `baseline`, `moonlight`, `torch`, `moon_particles_depth` |
| path | TEXT NOT NULL | relative to foundry root |
| created_at | TEXT NOT NULL | ISO 8601 |

---

## Lifecycle States

An attempt moves through these states in order. No state can be skipped. Transitions are enforced by the CLI.

```
generated
    │
    ├─→ mechanical_fail  (terminal — needs regen)
    │
    ▼
mechanical_pass
    │
    ▼
raw_review_pending
    │
    ├─→ raw_rejected  (terminal — needs regen)
    │
    ▼
raw_accepted
    │
    ▼
pixel_review_pending
    │
    ├─→ rejected  (terminal — needs regen)
    │
    ▼
accepted
    │
    ▼
finish_review_pending
    │
    ├─→ finish_rejected  (terminal — needs regen or map rederive)
    │
    ▼
finish_accepted
    │
    ├─→ superseded  (when a child regen is accepted)
    │
    ▼
(final — this is the canonical version)
```

**Regen rule:** A `needs_regen` outcome on any terminal state creates a new child attempt with `parent_attempt_id` pointing to the failed attempt. The parent stays in its terminal state forever. The child starts at `generated` and runs the full lifecycle again.

**Superseded rule:** When a child attempt reaches `finish_accepted`, its parent (if previously `finish_accepted`) transitions to `superseded`. Only one attempt per (run, direction) can be `finish_accepted` at any time (enforced by partial unique index).

---

## Decision Codes

### Generation-side codes (used during raw_source and pixel review)

| Code | Meaning |
|------|---------|
| `multi_subject_composition` | More than one figure in the frame |
| `identity_drift` | Character doesn't match subject sheet |
| `diagonal_collapse` | Diagonal view loses form/readability |
| `silhouette_break` | Silhouette unrecognizable at target size |
| `costume_landmark_mismatch` | Required landmark missing, wrong side, or wrong shape |
| `palette_drift` | Colors diverge from subject sheet palette family |
| `muddy_read` | Details unreadable at 48px |
| `overrendered_detail` | Too much detail for target resolution |
| `needs_paintover` | Minor fix possible with manual correction |
| `off_center` | Figure not centered in frame |
| `background_residue` | Background removal incomplete |

### Finish-side codes (used during finish review)

| Code | Meaning |
|------|---------|
| `false_volume` | Normal map creates incorrect 3D impression |
| `normal_noise` | Normal map has artifacts/noise that disrupt lighting |
| `depth_hallucination` | Depth map misreads form structure |
| `specular_plastic` | Specular response looks artificial |
| `shader_blur` | Shader processing destroys pixel clarity |
| `finish_overpowering_sprite` | Lighting/effects dominate the base sprite |
| `direction_map_inconsistency` | Maps don't match across turnaround |

### Mechanical codes (auto-assigned)

| Code | Meaning |
|------|---------|
| `wrong_size` | Not 48x48 |
| `no_alpha` | Missing alpha channel |
| `background_opaque` | Corner sampling detects opaque background |
| `empty_frame` | No foreground content detected |

---

## CLI Commands

Tool: `foundry` (Python CLI, click or argparse)

### `foundry run <subject_id>`

Execute a generation run for a subject.
- Reads subject sheet
- Submits 8-direction workflow to ComfyUI
- Saves raw + pixel artifacts
- Runs mechanical checks automatically
- Creates run, attempt, artifact, and review records
- Outputs run ID

### `foundry check <run_id>`

Run mechanical gates on an existing run. Only checks what is provable from stored artifacts.
- **Dimension check:** pixel artifacts are 48x48
- **Transparency check:** alpha channel present, corners transparent
- **Direction count:** 8 pixel artifacts registered for the run
- **Raw-source check:** single-subject composition gate on raw artifacts
- Auto-creates `mechanical` review records with `pass`/`fail` + code
- Does NOT check maps or finish (those are separate lifecycle stages with their own commands)

### `foundry review show <run_id>`

Display review status for a run.
- Shows each direction: state, review history, artifact paths
- Surfaces raw inspection sheet path + pixel contact sheet path
- Shows lineage (parent/child regens)
- Shows prior decisions with codes and notes

### `foundry review accept <attempt_id> [--note TEXT]`

Accept an attempt at its current review stage.
- `raw_review_pending` → `raw_accepted`
- `pixel_review_pending` → `accepted`
- `finish_review_pending` → `finish_accepted`
- If accepting a child regen, supersedes the parent

### `foundry review reject <attempt_id> --code CODE [--note TEXT]`

Reject an attempt.
- `raw_review_pending` → `raw_rejected`
- `pixel_review_pending` → `rejected`
- `finish_review_pending` → `finish_rejected`
- Code is required (from the decision codes list)

### `foundry regen <attempt_id> --code CODE [--seed SEED] [--note TEXT]`

Create a child regen attempt.
- Parent must be in a terminal-fail state or `accepted` (for improvement)
- Creates new attempt with parent_attempt_id set
- Does NOT auto-run generation (user must `foundry run` or pass `--execute`)
- Records reason code and note

### `foundry status [--subject SUBJECT_ID]`

Dashboard view.
- Per subject: directions finish_accepted/accepted/pending/rejected
- Active runs
- Pending reviews (raw, pixel, and finish separately)
- Regen queue

### `foundry maps <run_id>`

Derive normal + depth maps for a run's accepted sprites.
- Submits to ComfyUI (MiDaS + DepthAnything)
- Saves raw + pixelated map artifacts
- Links artifacts to attempts

### `foundry finish <run_id>`

Run Godot finish lab captures for a run.
- Copies accepted sprites + normals to Godot project
- Triggers import
- Runs 4-state capture sweep
- Saves finish_captures records

---

## Lineage Rules

1. **Every regen creates a new attempt.** Never overwrite an existing attempt's artifacts.
2. **Parent link is immutable.** Once set, `parent_attempt_id` never changes.
3. **Reason code is required.** No anonymous regens.
4. **Changed inputs are recorded.** If seed changed, new seed is on the child attempt. If prompt changed, new run is required (not a regen — a fresh run).
5. **Only one `finish_accepted` per (run, direction) at a time.** Accepting a child supersedes the parent. Enforced by partial unique index.
6. **Superseded is permanent.** A superseded attempt cannot be un-superseded. To revert, accept the original again (which supersedes the child).
7. **Decision trail is append-only.** Reviews are never deleted or mutated. The full history is always queryable.

---

## File Layout

```
star-freight-foundry/
├── foundry.db                    # SQLite database
├── foundry/                      # Python package
│   ├── __init__.py
│   ├── cli.py                    # CLI entry point
│   ├── db.py                     # Schema, migrations, queries
│   ├── generate.py               # ComfyUI generation pipeline
│   ├── mechanical.py             # Automated checks
│   ├── review.py                 # Review lifecycle logic
│   ├── maps.py                   # Normal/depth derivation
│   ├── finish.py                 # Godot finish lab integration
│   └── contact_sheet.py          # Review artifact builders
├── preflight/
│   ├── subject-sheet.md          # Sera Vale
│   └── subject-sheet-kael.md     # Kael Morrow
├── bakeoff/                      # All run output directories
│   ├── stack_a_v2_*/
│   ├── kael_1c_*/
│   └── ...
└── game/godot/render-lab/        # Godot finish lab
```

---

## Acceptance Criteria for Phase 2

Phase 2 is complete when:

- [ ] Every attempt has a durable ID in SQLite
- [ ] Raw review and pixel review are both first-class lifecycle stages
- [ ] Accept/reject/regen decisions are stored with codes, not implied
- [ ] Lineage is visible: any attempt can trace back to its origin
- [ ] No asset can silently bypass review (lifecycle enforced)
- [ ] You can answer "why did this version win?" from the registry alone
- [ ] Existing Phase 1 survivors (Sera + Kael) are retroactively registered
- [ ] `foundry status` gives a clear dashboard of the foundry state

---

## Build Order

| Phase | Scope | Ship artifact |
|-------|-------|---------------|
| 2A | Schema + CLI spine | `foundry.db` schema, `foundry status/check/review show` |
| 2B | Contact-sheet review integration | `foundry review show` surfaces visual artifacts |
| 2C | Mechanical gates | `foundry check` auto-runs all mechanical checks |
| 2D | Decision trail | `foundry review accept/reject/regen` with full lineage |

After 2D: retroactively register Sera and Kael survivors, then the registry is live.
