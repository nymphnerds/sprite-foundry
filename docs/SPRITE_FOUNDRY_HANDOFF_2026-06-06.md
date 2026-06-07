# Sprite Foundry Handoff - Current 2026-06-07

This handoff is the current working state for Sprite Foundry after the
2026-06-07 Z-Image ControlNet/Nunchaku session. The file name is older because
it began on 2026-06-06; treat this content as current.

## Session Rules

- Dev/source work happens in the dev WSL checkout under `/home/nymph`.
- Test WSL is `\\wsl.localhost\NymphsCore\home\nymph` and is for end-user
  testing only.
- Do not manually edit installed module files, markers, manifests, cached
  manifests, or runtime state in test WSL unless explicitly approved.
- Test through the normal path: publish source, update the dev registry, then
  install/update through NymphsCore Manager.
- Follow `/home/nymph/NymphsCore/docs/NYMPHS_MODULE_MAKING_GUIDE.md`.
- If Manager hangs at `Refreshing the modular shell...`, verify WSL can open a
  shell before changing Manager, registry, or status code. A wedged WSL session
  can look exactly like a broken module/status refresh.
- Sprite Foundry belongs in the dev registry, not the public registry.
- The old `nymphs-sprite` repo/module is only a backup/reference. Do not delete
  it.
- Do not resume Manager self-updater work in this Sprite thread unless the user
  explicitly asks for it.

## Current Module Framing

The module is called **Sprite Foundry**.

Sprite Foundry should expose the actual Sprite Foundry workflow in a Nymphs-style
module UI. Do not describe it as Nymphs Sprite except when referring to the old
backup/reference module.

Z-Image/Nunchaku is a backend dependency for the current generation method. It
must not become the visible workflow, dump surprise outputs into Z-Image behind
the user's back, or replace Sprite Foundry's run/review/export flow.

The intended user-facing flow is:

```text
subject/config
  -> body/shape guides
  -> style
  -> generate 8-way
  -> review / accept / reject / regenerate selected
  -> export accepted sprite pack
  -> simple subject output folder
```

## Important Repos

- Sprite Foundry source: `/home/nymph/NymphsModules/sprite-foundry`
- Sprite Foundry remote: `git@github.com:nymphnerds/sprite-foundry.git`
- Dev registry: `/home/nymph/NymphsModules/nymphs-registry/nymphs-dev.json`
- Public registry: `/home/nymph/NymphsModules/nymphs-registry/nymphs.json`
- Nymphs Image / Z-Image source: `/home/nymph/NymphsModules/zimage`
- Nunchaku fork: `/home/nymph/nunchaku`
- Old backup/reference module: `/home/nymph/NymphsModules/nymphs-sprite`

## Current Published State

Sprite Foundry `1.2.7` is pushed and should be installed through Manager from
the dev registry.

- Sprite commit: `4e0d94146362de75afbb9c220565f9570d0614bb`
- Sprite message: `Simplify Sprite Foundry outputs`
- Raw manifest version: `1.2.7`
- Sprite manifest hash:
  `1f97b0efe303d846f7bf9f8c766986091a58cd9ab779ffd773cbd8f765abe70b`

Dev registry is pushed.

- Dev registry file: `nymphs-dev.json`
- `registry_version`: `47`
- Updated: `2026-06-07`
- Sprite Foundry `manifest_version`: `1.2.7`
- Sprite Foundry `manifest_url`:
  `https://raw.githubusercontent.com/nymphnerds/sprite-foundry/main/nymph.json`
- Latest dev-registry Sprite commits:
  - `74f2d59` - `Update Sprite Foundry dev manifest to 1.2.7`
  - `9c7f4ef` - `Use Sprite Foundry main manifest in dev registry`

Public registry state:

- Public registry does not advertise Sprite Foundry.
- Public registry does not advertise old `nymphs-sprite`.
- Public registry does advertise Z-Image / Nymphs Image `0.1.112`.

## Current Z-Image / ControlNet State

Nymphs Image / Z-Image `0.1.112` is pushed and referenced by the public registry.

- Z-Image commit: `1076303`
- Z-Image message: `Fix Z-Image ControlNet VRAM path`
- Registry commit for Z-Image `0.1.112`: `fd5f57f`
- Main NymphsCore changelog commit: `b35c587`

The ControlNet 2.1 weight is present in both dev and test WSL caches:

```text
$HOME/NymphsData/cache/huggingface/models--alibaba-pai--Z-Image-Turbo-Fun-Controlnet-Union-2.1/snapshots/5155fc56d17821007d6f62ac192c09e0f0e72016/Z-Image-Turbo-Fun-Controlnet-Union-2.1-2602-8steps.safetensors
```

Expected size:

```text
6712485600 bytes
```

ControlNet is now confirmed to run on GPU for the no-LoRA smoke path:

- `controlnet_execution_device`: `cuda:0`
- `controlnet_text_encoder_device`: `cpu`
- `controlnet_offload`: `false`

The important fix was not a quantized ControlNet weight. The previous hang was
the full ControlNet pipeline saturating a 16 GB GPU before inference. Z-Image
`0.1.112` keeps ControlNet and the Nunchaku transformer on CUDA, moves prompt
encoding to CPU, and adds a Nunchaku RoPE hook around shared ControlNet refiner
blocks.

Validated no-LoRA ControlNet smoke:

- Cold 512px run completed and saved output.
- Warm 512px run completed in about 5 seconds end-to-end.
- This proves the mechanics; output style/quality still needs Sprite-specific
  prompt, guide, LoRA, and review work.

## What Changed In Sprite Foundry 1.2.7

- NymphsCore/Z-Image generation writes final Sprite Foundry images directly to:

```text
$HOME/NymphsData/outputs/sprite-foundry/<subject_id>/
```

- Output names are simple, for example:

```text
front.png
front_raw.png
contact_sheet.png
raw_inspection.png
```

- `Open Outputs` opens:

```text
$HOME/NymphsData/outputs/sprite-foundry
```

- The UI updates progress direction by direction during generation.
- Generation fails fast with a clear message when the selected LoRA cannot
  attach to the current Z-Image/Nunchaku transformer.
- No run IDs should be exposed to the normal user flow.

## Better Sprite Flow To Explore

The goal is to distill Sprite Foundry into the simplest path that gives the best
results.

### 1. Subject

Choose or edit the character:

- name
- class/archetype
- prompt
- weapon/tool
- colors/materials
- optional notes

### 2. Body Shape

Pick a body type that drives the guide shape:

- humanoid
- wide squat
- tall thin
- amorphous
- quadruped
- winged
- custom

The body-shape choice should influence the direction guides before generation.

### 3. Direction Guides

Auto-generate and show the 8 ControlNet reference images as a contact sheet.

User-facing language:

```text
Direction Guides
Shape Guides
This is the shape guide Sprite Foundry will use.
```

Avoid making users think in ControlNet internals. ControlNet should be visible as
the guide system, not as scary backend language.

### 4. Style

Pick the LoRA/style:

- `mks0813/z-image-turbo-pixel-art-lora`
- `SkyAsl/Pixel-artist-Z`
- `tarn59/pixel_art_style_lora_z_image_turbo`
- custom LoRA from `$HOME/LoRA/loras`

The UI should display the real LoRA identity, not invented internal aliases.

### 5. Generate 8-Way

One big Generate button.

- progress per direction
- no run IDs exposed
- show the active direction name
- produce a contact sheet first
- save direct to the subject folder

### 6. Review

Contact sheet first, then per-direction thumbnails.

Expected review actions:

- accept
- reject
- regenerate selected
- select all
- clear selection

The review surface should make it obvious what will be exported.

### 7. Export

Export accepted images to a simple subject folder. Keep naming stable and
predictable.

Suggested shape:

```text
$HOME/NymphsData/outputs/sprite-foundry/<subject_id>/
  contact_sheet.png
  raw_inspection.png
  front.png
  front_left.png
  left.png
  back_left.png
  back.png
  back_right.png
  right.png
  front_right.png
```

## ControlNet Interpretation

For Sprite Foundry, ControlNet is not prompt-only. It is spatial conditioning:
the model receives a control/guide image and tries to preserve that structure
while following the text prompt and style.

Research summary:

- The ControlNet paper frames ControlNet as adding spatial conditioning controls
  to text-to-image diffusion models.
- Diffusers ControlNet examples describe supplying a control image, such as a
  depth map, canny map, pose image, or other structure image, so generation
  follows that structure.

Sprite Foundry recommendation:

- call it Direction Guides or Shape Guides in the normal UI
- expose ControlNet scale/start/end only in an Advanced drawer
- keep default values sensible
- make the guide contact sheet visible before generation

Nymphs Image recommendation:

- add a general ControlNet panel later
- upload/sketch/depth/edge image
- control scale slider
- generate through the same Z-Image backend path
- Sprite Foundry should consume that backend in a workflow-specific way

## LoRA Naming Clarification

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
- **Shared LoRA folder:** new Sprite Foundry fetches write repo-derived folders
  under `$HOME/LoRA/loras`, replacing `/` with `--`.

Canonical shared LoRA paths:

```text
$HOME/LoRA/loras/mks0813--z-image-turbo-pixel-art-lora/z-image-turbo-pixel-art-lora.safetensors
$HOME/LoRA/loras/SkyAsl--Pixel-artist-Z/adapter_model.safetensors
$HOME/LoRA/loras/tarn59--pixel_art_style_lora_z_image_turbo/pixel_art_style_z_image_turbo.safetensors
```

Old test WSL folders such as `mks0813_pixel_art`, `skyasl_pixel_artist`, and
`tarn59_pixel_art` are legacy aliases/custom choices. Status may still list them
if they exist, but they should not be treated as the canonical Sprite Foundry
fetch result.

## Testing Rules

Use test WSL only through Manager unless explicitly approved.

Normal test path:

1. Publish Sprite Foundry source.
2. Update the dev registry.
3. Open NymphsCore Manager in dev mode.
4. Update/install Sprite Foundry through Manager.
5. Open Sprite Foundry UI from Manager.
6. Test the user workflow.

Do not manually patch:

- installed module files
- markers
- cached manifests
- runtime state
- status scripts in test WSL

If a Manager or module refresh hangs, first check WSL itself:

```text
wsl -d NymphsCore
wsl -d NymphsCore_Lite
```

If the terminal opens blank or cannot reach a prompt, use `wsl --shutdown` or
restart Windows before changing code.

## Known Issues / Next Work

### Sprite Quality

The ControlNet path now works mechanically, but Sprite output quality is not yet
the final game-ready flow. Next work is better guide generation, prompt shaping,
LoRA selection, and review/regenerate ergonomics.

### Direction Guide Generation

Decide how the guide contact sheet is produced:

- static templates per body type
- generated silhouettes per body type
- editable guide images
- imported user guide/contact sheet
- later: pose/body-shape presets

### UI Simplification

The UI should move toward the Better Sprite Flow:

- Subject
- Body Shape
- Direction Guides
- Style
- Generate 8-Way
- Review
- Export

Keep advanced internals tucked away. Avoid run IDs, backend names, and file
plumbing in the main user path.

### Nymphs Image ControlNet Panel

Nymphs Image should likely get a general ControlNet panel later. Sprite Foundry
can then stay simple and call the same backend through a narrower sprite-focused
workflow.

### LoRA Compatibility

If Z-Image returns:

```text
No Z-Image LoRA weights matched the current Nunchaku transformer modules.
```

the selected `.safetensors` has no matching weights for the current Nunchaku
transformer module names. Another LoRA may work. Do not assume all Z-Image LoRAs
are runtime-compatible with the current quantized Nunchaku path.

## User Intent To Preserve

- Keep the module name and language as Sprite Foundry.
- Expose the actual Sprite Foundry workflow.
- Keep the UI Nymphs-style.
- Do not turn the module into a generic Z-Image interface.
- Do not hide generated outputs.
- Do not fill the Z-Image output folder behind the user's back.
- Keep LoRA names as downloaded from Hugging Face.
- Do not invent internal IDs or friendly replacement names for LoRAs.
- Make outputs simple subject folders, not timestamp/run-id mazes.
- Make ControlNet understandable as guides, not backend jargon.
- Compare other Nymphs modules before changing Manager details-page or runtime
  patterns.
