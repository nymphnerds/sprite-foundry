# ControlNet Research For Sprite Foundry

Current as of 2026-06-07.

This doc collects the ControlNet research links, implementation facts, and UI
ideas raised during the Sprite Foundry / Z-Image ControlNet session.

## Source Links

Primary / technical:

- ControlNet paper, "Adding Conditional Control to Text-to-Image Diffusion
  Models": https://arxiv.org/abs/2302.05543
- Diffusers ControlNet documentation:
  https://huggingface.co/docs/diffusers/using-diffusers/controlnet
- Alibaba PAI Z-Image Turbo ControlNet Union 2.1 model card:
  https://huggingface.co/alibaba-pai/Z-Image-Turbo-Fun-Controlnet-Union-2.1/blob/main/README.md
- OpenPose repository:
  https://github.com/CMU-Perceptual-Computing-Lab/openpose
- OpenPose project documentation:
  https://cmu-perceptual-computing-lab.github.io/openpose/web/html/doc/index.html

User-linked explainer:

- Stable Diffusion Art ControlNet guide:
  https://stable-diffusion-art.com/controlnet/

## Core ControlNet Concept

ControlNet is not just prompt engineering. It adds an extra visual conditioning
input to image generation. The prompt still describes what to draw, but the
control image tells the model what structure to follow.

For Sprite Foundry, this means:

```text
prompt/style says what the sprite is
control image says where the body/pose/outline/structure should be
LoRA says what visual language to use
```

The ControlNet paper frames this as spatial conditioning for pretrained
text-to-image diffusion models. Diffusers describes the practical version as
passing structural controls such as canny edges, depth maps, or human pose
alongside the prompt.

## Control Types Relevant To Sprite Foundry

The current Z-Image Turbo ControlNet Union 2.1 2602 weight supports multiple
control conditions:

```text
Canny
Depth
Pose
MLSD
HED
Scribble
Gray
```

For Sprite Foundry, the likely useful modes are:

### Pose

Pose controls skeleton/keypoint layout. This is the route that maps most closely
to OpenPose.

Good for:

- body stance
- arm/leg angles
- weapon pose
- direction/action consistency
- resizable stick-rig UI

Weak for:

- exact silhouette
- costume mass
- creature body width
- non-human body forms unless the pose representation supports them

Sprite UI name:

```text
Pose Guide
```

### Scribble

Scribble uses a drawn control image. This is the strongest match for a manual
sketch surface.

Good for:

- hand-authored sprite silhouette
- rough body mass
- rough weapon outlines
- simple readable gesture drawings
- "draw the pose, generate the sprite"

Weak for:

- precise anatomical keypoints
- automatic pose editing unless we build the editor

Sprite UI name:

```text
Sketch Guide
```

### Canny / HED / Line-Like Edges

Canny and HED preserve edge/composition information from an image. Canny is
sharper and more literal; HED/soft-edge style controls are often more forgiving.

Good for:

- preserving outline from an existing sprite/reference
- turning a guide drawing into a stronger edge map
- remaking or restyling a known silhouette

Weak for:

- inventing a pose from scratch
- avoiding over-preservation of unwanted details

Sprite UI name:

```text
Outline Guide
```

### Depth

Depth preserves spatial layout. It may be useful later for isometric or 3D-ish
sprite workflows, but it is not the first target for 8-way pixel sprites.

Sprite UI name:

```text
Depth Guide
```

### MLSD

MLSD detects straight lines. It is best for buildings, interiors, props, and
hard-surface structure. It is probably not a primary character-sprite control.

Sprite UI name:

```text
Line Structure
```

### Gray

The 2602 Z-Image model adds Gray Control. Treat this as research-only until we
test what it actually does in our pipeline.

## OpenPose Explanation

OpenPose is a pose-estimation system. It extracts body, hand, face, and foot
keypoints from an image and connects those points into a skeleton. In ControlNet
workflows, that skeleton becomes a pose control image.

For Sprite Foundry:

```text
Prompt: goblin archer, pixel art, hood, bow
Pose guide: head here, torso here, bow arm raised here, legs angled here
Result: goblin archer generated in that pose
```

Important limitation:

- OpenPose-style control guides pose, not exact body outline.
- It may keep the stance while the model invents body width, costume, and
  silhouette.
- For exact outline/mass, use Sketch Guide or Outline Guide instead.

## UI Direction: Make ControlNet Visible But Not Technical

Normal users should not have to think "ControlNet model/preprocessor/control
map." In Sprite Foundry, call it:

```text
Direction Guides
Shape Guides
Pose Guide
Sketch Guide
Outline Guide
```

Technical terms can live in Advanced:

- control type
- guide strength / ControlNet scale
- start step
- end step
- control image preview

The core UI message should be:

```text
This is the shape guide Sprite Foundry will use.
```

## Proposed Sprite Flow

```text
Subject
  -> Body Shape
  -> Direction Guides
  -> Style
  -> Generate 8-Way
  -> Review
  -> Export
```

### Subject

Choose/edit:

- name
- class/archetype
- prompt
- weapon/tool
- colors/materials
- optional notes

### Body Shape

Pick the broad creature/body type:

- humanoid
- wide squat
- tall thin
- amorphous
- quadruped
- winged
- custom

This should influence the starting pose rig or sketch guide templates.

### Direction Guides

Show the 8 ControlNet refs as a contact sheet. The user should understand that
these guide images drive the generation.

Potential guide modes:

- Pose Guide
- Sketch Guide
- Outline Guide
- Hybrid Guide

### Style

Pick LoRA/style:

- `mks0813/z-image-turbo-pixel-art-lora`
- `SkyAsl/Pixel-artist-Z`
- `tarn59/pixel_art_style_lora_z_image_turbo`
- custom LoRA from `$HOME/LoRA/loras`

Display real LoRA identities, not invented aliases.

### Generate 8-Way

One big button.

- progress per direction
- no run IDs exposed
- active direction label
- contact sheet first
- direct subject-folder output

### Review

Contact sheet first, then per-direction thumbnails.

Actions:

- accept
- reject
- regenerate selected
- select all
- clear selection

### Export

Export accepted sprites to:

```text
$HOME/NymphsData/outputs/sprite-foundry/<subject_id>/
```

Use simple names:

```text
front.png
front_left.png
left.png
back_left.png
back.png
back_right.png
right.png
front_right.png
contact_sheet.png
raw_inspection.png
```

## Sketch / Pose Board Ideas

The strongest new UI concept is a Sprite Foundry guide board that lets the user
author the ControlNet input directly.

### Pose Rig Mode

A stick-person or creature-rig UI:

- draggable joints
- connected bones
- resizable bone lengths
- head/neck/torso/arm/leg controls
- shoulder width
- hip width
- weapon/prop line
- mirror pose
- rotate/lean whole body
- copy pose to another direction
- derive 8 directions from a front pose, then manually tweak each

This exports a Pose Guide.

This mode is best for:

- clear pose control
- consistent action/direction
- fast authoring without drawing skill

Risk:

- pose guide may not preserve silhouette or body mass strongly enough.

### Sketch Mode

A simple canvas:

- draw freehand guide
- erase
- clear
- copy previous direction
- mirror/flip
- load a guide image
- export all 8 guide images as a contact sheet

This exports a Scribble/Sketch Guide or, after preprocessing, an Outline Guide.

This mode is best for:

- creature silhouettes
- non-human bodies
- weapon shape
- readable pixel-art mass

Risk:

- user has to draw enough structure for the model to follow.

### Hybrid Mode

Pose rig plus optional sketch layer.

Potential path:

1. Pose rig defines joints and action.
2. Sketch layer adds silhouette or weapon outline.
3. User chooses which guide image to send:
   - pose only
   - sketch only
   - outline-processed sketch
   - hybrid preview

This should be a later experiment, not first MVP.

## MVP Recommendation

Start with two guide modes:

```text
Pose Guide
Sketch Guide
```

Do not build every ControlNet mode immediately.

MVP shape:

- 8 guide canvases/contact sheet
- Pose Guide editor with draggable/resizable stick rig
- Sketch Guide freehand canvas
- Preview of exact guide image sent to ControlNet
- Guide Strength advanced slider
- Generate 8-Way uses those guide images

Default to one mode per run. Avoid multi-ControlNet chaining until the single
guide modes are proven.

## Nymphs Image Follow-Up

Nymphs Image should probably get a general ControlNet panel later:

- upload image
- sketch canvas
- canny/edge preview
- pose/depth options when available
- guide strength slider
- start/end advanced settings
- generate with Z-Image ControlNet

Sprite Foundry should then call the same backend through a simpler
workflow-specific UI.

## Current Implementation Notes

Z-Image `0.1.112` makes the no-LoRA ControlNet path usable on the 16 GB GPU:

- ControlNet and Nunchaku transformer stay on CUDA.
- Text encoding runs on CPU to avoid VRAM saturation before inference.
- Shared ControlNet refiner blocks get a Nunchaku RoPE hook.
- `server_info` reports:

```text
controlnet_execution_device=cuda:0
controlnet_text_encoder_device=cpu
controlnet_offload=false
```

This proves the ControlNet mechanics. The next Sprite task is to improve the
guide images and UI flow so the generated results become useful.

## Questions To Test

1. Does Z-Image Turbo ControlNet Union respond best to Pose, Scribble, Canny, or
   HED for tiny sprite characters?
2. Does a pure stick-rig Pose Guide produce enough body proportion control?
3. Does a freehand Scribble Guide give better silhouette for goblins/creatures?
4. Does Outline Guide over-constrain details, or does it improve consistency?
5. What is the best default Guide Strength for 8-step Z-Image Turbo?
6. Should direction guides be generated as 512px square, or should the guide
   canvas match final sprite framing differently?
7. Can a front pose be transformed into 8 direction templates automatically, or
   is manual per-direction tweaking required?
8. Should guide images be saved/exported beside final sprites for debugging and
   repeatability?

## Design Principle

Sprite Foundry should feel like directing a sprite sheet, not configuring a
diffusion backend.

ControlNet should appear as:

```text
draw or pose the guide
choose the style
generate the sprite
review and export
```

The backend can remain technical; the user path should stay simple.
