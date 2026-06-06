# Sprite Foundry NymphsCore Module Rebuild

Date: 2026-06-06

## Decision

`/home/nymph/NymphsModules/sprite-foundry` is the module repo for this work.
`/home/nymph/NymphsModules/nymphs-sprite` remains a backup/reference repo and
must not be deleted.

The module identity is **Sprite Foundry**:

- module id: `sprite-foundry`
- module name: `Sprite Foundry`
- install root: `$HOME/Sprite-Foundry`
- repo: `https://github.com/nymphnerds/sprite-foundry.git`

## What Was Wrong

The abandoned `nymphs-sprite` flow behaved like a custom Z-Image batch generator.
It exposed a confusing two-step path:

```text
Generate Sources -> Generate + Process
```

That was not a clear Sprite Foundry workflow. It also leaked Z-Image backend
outputs into the sprite review strip and made it look like the same character
set was generated twice.

## Correct Foundry Shape

Sprite Foundry owns the visible workflow:

```text
subject -> run -> direction attempts -> gates -> review -> accepted sprites -> export
```

Generation backends are implementation details. Z-Image/Nunchaku is the
NymphsCore backend path, not the UI concept.

The Nymphs UI should be a Sprite Foundry workbench, not a smaller one-button
generator. It should expose the Foundry stages:

```text
generation method -> gates -> review/accept/reject -> maps/finish -> export
```

## Foundry Generation Methods

The CLI now exposes the existing generation paths explicitly:

```text
foundry generate-nymphscore
foundry generate-stack-a-v2
foundry generate-morph
foundry generate-turnaround
```

The Manager action group calls `scripts/sprite_foundry_generate.sh` with one of:

```text
nymphscore
stack_a_v2
morph
turnaround
```

These are generation-stage methods inside the Sprite Foundry lifecycle, not
separate products and not a separate Z-Image workflow.

## Backend Output Ownership

Z-Image/Nunchaku must not fill the normal Z-Image output folder while serving
Sprite Foundry. The NymphsCore generation path now passes an explicit
Sprite-Foundry-owned output directory to Z-Image, then moves the backend result
into the Foundry `bakeoff/<run_id>/` run as the raw direction image. The
temporary backend folder is removed after the move when empty.

The visible review/output surface should therefore show Sprite Foundry outputs:

- `bakeoff/<run_id>/` raw/pixel/contact-sheet review artifacts
- `boards/` finish/review boards
- `derived/` maps and derived artifacts
- `exports/<subject>/<run_id>/` deterministic shipped packs

## Current Verification

Local dev sanity checks completed:

```text
python3 -m json.tool nymph.json
bash -n scripts/*.sh
python3 -m py_compile foundry/cli.py
python3 -m foundry.cli --help
scripts/sprite_foundry_cli.sh --command status
scripts/install_sprite_foundry.sh
$HOME/Sprite-Foundry/scripts/sprite_foundry_status.sh
python3 scripts/sprite_foundry_ui_server.py --host 127.0.0.1 --port 7002 --root .
curl http://127.0.0.1:7002/health
curl http://127.0.0.1:7002/server_info
curl 'http://127.0.0.1:7002/api/outputs?limit=3'
```

This is not an end-user test. End-user testing still requires publishing the
module repo, verifying raw `nymph.json`, updating registry only if needed, and
installing/updating through Manager.

## Next Work

- Continue wiring the Manager-hosted UI as a full Sprite Foundry workbench, not
  a backend batch UI.
- Keep all Foundry lifecycle features available: status, gates, review,
  accept/reject, lineage/story, maps/finish, export.
- Fix and verify Z-Image ControlNet with the Nunchaku fork before enabling the
  NymphsCore morph/control path as a normal workflow.
- Keep normal/depth post-process map research as future work unless it can be
  implemented without ComfyUI.
