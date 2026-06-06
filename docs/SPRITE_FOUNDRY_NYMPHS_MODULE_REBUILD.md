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

## 2026-06-06 Feature-Fix Pass

Version `1.2.3` fixes the first broken module workbench path found during
Manager testing:

- The workbench was sending `--lora-trigger-b64-*`, but
  `scripts/sprite_foundry_generate.sh` only accepted plain `--lora-trigger`.
  The generation wrapper now decodes that field the same way it already decoded
  prompt and LoRA path chunks.
- The UI was exposing run-scoped lifecycle commands before a run existed. Those
  buttons now stay disabled until a run ID is present.
- The review accept/reject bridge tried to pass `run_id + direction` to a
  Foundry CLI command that actually expects an attempt ID. The wrapper now
  resolves the selected run/direction to the latest review-pending attempt, or
  fails clearly if no attempt exists.
- Sprite Foundry status now reports Z-Image installed/running/model state and
  Z-Image pixel LoRA choices. The UI uses that to disable generation until
  ControlNet, backend models, backend runtime, and a LoRA are ready.

This pass does not prove end-to-end ControlNet generation. It makes the module
feature path testable again. The next real test is still:

```text
publish 1.2.3 -> update registry -> Manager update on test WSL ->
open Sprite Foundry UI -> start/open Z-Image -> verify ready state ->
run one Sprite Foundry generation
```

## 2026-06-06 Sprite-Owned Fetch Pass

Version `1.2.5` moves the visible asset preparation workflow back under Sprite
Foundry:

- Sprite Foundry Details now exposes a `Model Fetch` dropdown for the starter
  stack, ControlNet, all bundled LoRAs, and individual pixel-art LoRAs.
- LoRAs fetched from Sprite Foundry are written to the shared LoRA folder used
  by the LoRA module and Z-Image, preserving their Hugging Face repo/file names:

```text
$HOME/LoRA/loras/mks0813--z-image-turbo-pixel-art-lora/z-image-turbo-pixel-art-lora.safetensors
$HOME/LoRA/loras/SkyAsl--Pixel-artist-Z/adapter_model.safetensors
$HOME/LoRA/loras/tarn59--pixel_art_style_lora_z_image_turbo/pixel_art_style_z_image_turbo.safetensors
```

- Z-Image backend weights and ControlNet still use the shared Nymphs Hugging
  Face cache. Sprite Foundry owns the action, while Nymphs Image owns the
  backend fetch implementation for Z-Image weights.
- Sprite Foundry status reports those shared LoRA files as Sprite Foundry cache
  profiles so the Manager Details page can show them as downloaded.
- The workbench LoRA dropdown is driven by real `.safetensors` files in
  `$HOME/LoRA/loras`; custom user LoRAs are shown by their actual folder/file
  name.
- Sprite Foundry LoRA fetch emits the standard compact NymphsCore model-fetch
  progress lines: `MODEL FETCH STARTED`, repeated `MODEL FETCH STATUS`, and
  `MODEL FETCH COMPLETE`.
- Cache deletion is scoped to known Sprite Foundry LoRA filenames and the
  ControlNet weight. It does not touch user-trained LoRAs, datasets, jobs,
  outputs, logs, or runtime files.

## Next Work

- Continue wiring the Manager-hosted UI as a full Sprite Foundry workbench, not
  a backend batch UI.
- Keep all Foundry lifecycle features available: status, gates, review,
  accept/reject, lineage/story, maps/finish, export.
- Fix and verify Z-Image ControlNet with the Nunchaku fork before enabling the
  NymphsCore morph/control path as a normal workflow.
- Keep normal/depth post-process map research as future work unless it can be
  implemented without ComfyUI.
