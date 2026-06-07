# Sprite Foundry Handoff - 2026-06-06

## Session Rules

- Dev/source work happens in the dev WSL checkout under `/home/nymph`.
- Test WSL is `\\wsl.localhost\NymphsCore\home\nymph` and is for end-user testing only.
- Do not manually edit installed module files, markers, manifests, cached manifests, or runtime state in test WSL unless explicitly approved.
- Test through the normal path: publish source, update the dev registry, then install/update through NymphsCore Manager.
- Follow `/home/nymph/NymphsCore/docs/NYMPHS_MODULE_MAKING_GUIDE.md`.
- Sprite Foundry belongs in the dev registry, not the public registry.
- The old `nymphs-sprite` repo/module is only a backup/reference. Do not delete it.

## Correct Module Framing

The module is called **Sprite Foundry**.

Sprite Foundry should expose the actual Sprite Foundry workflow in a Nymphs-style module UI. Do not describe it as Nymphs Sprite except when referring to the old backup/reference module.

Z-Image/Nunchaku is only a backend dependency for the relevant Sprite Foundry generation method. It must not become the visible workflow, dump surprise outputs into Z-Image behind the user's back, or replace Sprite Foundry's run/review/export flow.

The intended user-facing flow is:

```text
subject/config
  -> generation method
  -> generated attempts
  -> review / accept / reject
  -> produce / export
  -> outputs
```

If the selected Sprite Foundry method needs Z-Image, Generate should start Z-Image automatically as a backend service.

## Important Repos

- Sprite Foundry source: `/home/nymph/NymphsModules/sprite-foundry`
- Sprite Foundry remote: `git@github.com:nymphnerds/sprite-foundry.git`
- Dev registry: `/home/nymph/NymphsModules/nymphs-registry/nymphs-dev.json`
- Public registry: `/home/nymph/NymphsModules/nymphs-registry/nymphs.json`
- Nymphs Image / Z-Image source: `/home/nymph/NymphsModules/zimage`
- Old backup/reference module: `/home/nymph/NymphsModules/nymphs-sprite`

## Current Published State

Sprite Foundry `1.2.6` is pushed.

- Commit: `159def3fb42c1a0bfde085b06bf8c4eca8a5e39e`
- Message: `Start Z-Image backend from Sprite Foundry generate`
- Raw manifest verified live at version `1.2.6`

Dev registry is pushed.

- Commit: `07e9750`
- `registry_version`: `46`
- Sprite Foundry `manifest_version`: `1.2.6`
- Manifest URL:
  `https://raw.githubusercontent.com/nymphnerds/sprite-foundry/159def3fb42c1a0bfde085b06bf8c4eca8a5e39e/nymph.json`
- Manifest hash:
  `e944007858f8171946e529b9ecba4738c3391bdc175bda729652831cecadb5fd`

Public registry still does not advertise Sprite Foundry.

## What Changed In 1.2.6

- `Generate Foundry Run` now starts Nymphs Image / Z-Image automatically before running the Foundry `generate-nymphscore` path.
- The UI no longer disables Generate just because Z-Image is stopped, as long as required assets are present.
- Added `scripts/sprite_foundry_start_backend.sh`.
- Added `sprite_foundry_start_zimage_backend()` in `scripts/_sprite_foundry_common.sh`.
- Replaced the Runtime `Foundry` button with `Start Backend`.
- Runtime `Check` now shows status output instead of silently swallowing it.
- Status/details wording now says Generate will start Z-Image automatically.
- Bumped `nymph.json` and `CHANGELOG.md` to `1.2.6`.

## Verification Already Done

- `bash -n` passed for changed shell scripts.
- `python3 -m json.tool` passed for `nymph.json`.
- Inline JavaScript extracted from `ui/manager.html` passed `node --check`.
- `git diff --check` passed.
- Raw GitHub `nymph.json` verified at `1.2.6`.
- Raw dev registry verified with Sprite Foundry `1.2.6`.
- Public registry checked for no `sprite-foundry` entry.

## Tomorrow's First Test

Use the test WSL only through Manager.

1. In NymphsCore Manager, update Sprite Foundry from the dev registry to `1.2.6`.
2. Open Sprite Foundry UI.
3. Leave Z-Image stopped.
4. Hit `Generate Foundry Run`.
5. Expected behavior:
   - Sprite Foundry starts Nymphs Image / Z-Image automatically.
   - It waits for `http://127.0.0.1:8090/server_info`.
   - Then it runs the Sprite Foundry generation path.

If Generate still says backend not ready, inspect:

- Installed Sprite Foundry version and marker.
- Installed `nymph.json` entrypoints include `start_backend`.
- Sprite Foundry UI has refreshed to the new `1.2.6` HTML.
- Z-Image status script output in test WSL.

Do not manually patch the installed test WSL files.

## Known Issues To Investigate Next

### ControlNet / Nunchaku Performance

Earlier logs showed the ControlNet path entered Z-Image/Nunchaku, loaded pipeline components, and loaded a LoRA, but generation was extremely slow at roughly `180-210 sec/it`. The app was then closed.

This is separate from the backend-start bug. After confirming Generate starts Z-Image automatically, investigate whether ControlNet is actually using CUDA/Nunchaku correctly.

### Old Test WSL LoRA Layout

Test WSL may still contain old renamed LoRA folders from previous builds:

```text
/home/nymph/LoRA/loras/mks0813_pixel_art/
/home/nymph/LoRA/loras/skyasl_pixel_artist/
/home/nymph/LoRA/loras/tarn59_pixel_art/
```

New Sprite Foundry fetch preserves the real Hugging Face-style identity:

```text
/home/nymph/LoRA/loras/mks0813--z-image-turbo-pixel-art-lora/z-image-turbo-pixel-art-lora.safetensors
/home/nymph/LoRA/loras/SkyAsl--Pixel-artist-Z/adapter_model.safetensors
/home/nymph/LoRA/loras/tarn59--pixel_art_style_lora_z_image_turbo/pixel_art_style_z_image_turbo.safetensors
```

Do not manually clean test WSL unless explicitly approved. If cleanup is needed, prefer a proper module-owned delete/repair action.

### LoRA Naming Clarification

There are three separate LoRA names in play:

- **User-facing Hugging Face identity:** keep the real repo name, for example
  `mks0813/z-image-turbo-pixel-art-lora`,
  `SkyAsl/Pixel-artist-Z`, and
  `tarn59/pixel_art_style_lora_z_image_turbo`.
- **Fetch/profile id:** internal action values such as
  `sprite_foundry_lora_mks0813_pixel_art`,
  `sprite_foundry_lora_skyasl_pixel_artist`, and
  `sprite_foundry_lora_tarn59_pixel_art`.
  These are action/profile ids only; do not use them as visible replacement
  names for the LoRAs.
- **Shared LoRA folder:** new Sprite Foundry fetches write repo-derived
  folders under `$HOME/LoRA/loras`, replacing `/` with `--`:

```text
$HOME/LoRA/loras/mks0813--z-image-turbo-pixel-art-lora/z-image-turbo-pixel-art-lora.safetensors
$HOME/LoRA/loras/SkyAsl--Pixel-artist-Z/adapter_model.safetensors
$HOME/LoRA/loras/tarn59--pixel_art_style_lora_z_image_turbo/pixel_art_style_z_image_turbo.safetensors
```

The old test WSL folders such as `mks0813_pixel_art`,
`skyasl_pixel_artist`, and `tarn59_pixel_art` are legacy aliases/custom choices.
Status may still list them if they exist, but they should not be treated as the
canonical Sprite Foundry fetch result.

## User Intent To Preserve

- Keep the module name and language as Sprite Foundry.
- Expose the actual Sprite Foundry workflow.
- Keep the UI Nymphs-style.
- Do not turn the module into a generic Z-Image interface.
- Do not hide generated outputs.
- Do not fill the Z-Image output folder behind the user's back.
- Keep LoRA names as downloaded from Hugging Face.
- Do not invent internal IDs or friendly replacement names for LoRAs.
- Compare other Nymphs modules before changing module details-page or runtime patterns.
