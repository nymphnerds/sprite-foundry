# NymphsCore Backend Handoff

This branch keeps Sprite Foundry as the main system and replaces only the
generation backend.

## What Changed

- Added `pipeline/nymphscore_client.py`, a small Nymphs Image HTTP client.
- Added `pipeline/foundry_gen_nymphscore.py`, a Foundry-integrated Z-Image runner.
- Added `foundry generate-nymphscore` to the existing CLI.
- Kept existing Foundry registry, attempts, review states, mechanical gates,
  map generation, finish pipeline, and export commands.

## Flow

```text
character config
  -> foundry generate-nymphscore
  -> Nymphs Image /generate
  -> raw + pixel artifacts in bakeoff/{run_id}
  -> foundry register-run/register-attempt
  -> foundry check
  -> review-show / review-accept / produce / export
```

## Backend Mapping

Original ComfyUI stack:

```text
CheckpointLoaderSimple -> LoraLoader -> CLIPTextEncode -> KSampler -> VAEDecode -> SaveImage
```

NymphsCore fork stack:

```text
Nymphs Image /generate
  provider=zimage
  model_id=Tongyi-MAI/Z-Image-Turbo
  lora_path=<Z-Image Turbo pixel art LoRA>
  nunchaku_rank=<32 or 128>
  nunchaku_precision=auto|int4|fp4
```

The generated image is still normalized into Foundry's expected artifacts:

```text
bakeoff/{run_id}/{direction}_raw.png
bakeoff/{run_id}/{direction}.png
bakeoff/{run_id}/raw_inspection.png
bakeoff/{run_id}/contact_sheet.png
bakeoff/{run_id}/recipe.json
bakeoff/{run_id}/manifest.json
```

## Size Policy

The original export contract is 48x48. This branch allows `--sprite-size 24..512`
and defaults to `96`, because Z-Image pixel-art LoRAs often produce useful detail
that is lost at 48px. Foundry's DB records the chosen size as `sprite_target`, so
mechanical gates validate against the selected target.
