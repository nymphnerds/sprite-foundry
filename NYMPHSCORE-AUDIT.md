# NymphsCore Adaptation Audit

This fork now treats `main` as the NymphsCore adaptation branch.

## Current Working Path

`foundry generate-nymphscore` is the primary generation entrypoint.

It keeps the original Foundry system:

- SQLite subjects, runs, attempts, artifacts, reviews, and gate results
- mechanical gates and review states
- raw/pixel review boards
- map derivation and finish-lab commands
- deterministic export packaging

It replaces the original ComfyUI generation call with:

- Nymphs Image `/generate`
- `Tongyi-MAI/Z-Image-Turbo`
- Nunchaku rank/precision options
- Z-Image LoRA path/trigger/scale options
- configurable `--sprite-size 24..512`, default `96`

## Adjusted

- README now describes the fork as NymphsCore/Nymphs Image first.
- `pipeline/foundry_gen_nymphscore.py` registers each direction with its actual
  per-direction seed.
- `pipeline/foundry_maps.py` now follows the run's `sprite_target` instead of
  always downscaling normal/depth maps to 48px.

## Still Original / Legacy

These remain useful as upstream reference paths, but still assume ComfyUI:

- `pipeline/foundry_gen.py`
- `pipeline/foundry_gen_morph.py`
- `pipeline/foundry_gen_iterative.py`
- `pipeline/foundry_gen_turnaround.py`
- `pipeline/foundry_gen_zero123.py`
- `pipeline/run_stack_*.py`
- `pipeline/gen_kael_maps.py`
- much of `site/` and translated README content

## Next Adaptation Targets

1. Map derivation backend
   - Current `foundry_maps.py` still calls ComfyUI preprocessors for normals/depth.
   - Needed: NymphsCore/Nymphs Image or local Depth Anything path for depth, plus a
     normal-map derivation path that does not require ComfyUI.

2. Morphology control
   - Original body-class control uses ComfyUI ControlNet depth/canny.
   - Needed: Z-Image ControlNet Union support once exposed in Nymphs Image, then map
     body-class presets to Nymphs request fields.

3. Finish lab sizing
   - Godot finish-lab was built around 48px sprites.
   - Needed: verify framing/scale for 96/128/192 sprite targets.

4. Docs/site cleanup
   - README is fork-aware now.
   - The handbook site and translated READMEs still describe the original ComfyUI
     runtime and should either be marked legacy or updated later.

5. Smoke test
   - Run `foundry generate-nymphscore` against a live Nymphs Image instance with a
     Z-Image Turbo pixel-art LoRA, accept one small run through gates, then test
     maps/finish/export with the selected sprite size.
