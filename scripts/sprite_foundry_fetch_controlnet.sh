#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_sprite_foundry_common.sh"

selected_model="sprite_foundry_starter_stack"
args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      selected_model="${2:-}"
      shift 2
      ;;
    --model=*)
      selected_model="${1#*=}"
      shift
      ;;
    --hf_token|--hf-token)
      export NYMPHS3D_HF_TOKEN="${2:-}"
      shift 2
      ;;
    --hf_token=*|--hf-token=*)
      export NYMPHS3D_HF_TOKEN="${1#*=}"
      shift
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

fetch_script="$(sprite_foundry_zimage_script zimage_fetch_models.sh 2>/dev/null || true)"
python_bin="$(sprite_foundry_python_bin)"

fetch_zimage_profile() {
  local model="$1"
  if [[ -z "${fetch_script}" ]]; then
    echo "ERROR: Sprite Foundry needs Nymphs Image installed to fetch shared Z-Image backend weights." >&2
    echo "expected=${HOME}/Z-Image/scripts/zimage_fetch_models.sh" >&2
    exit 1
  fi
  echo "delegate=nymphs-image"
  echo "model=${model}"
  echo "fetch_script=${fetch_script}"
  "${fetch_script}" --model "${model}" "${args[@]}"
}

fetch_lora() {
  local profile="$1"
  local repo_id="$2"
  local repo_file="$3"
  local library_id="$4"
  local library_file="$5"

  sprite_foundry_ensure_dirs
  echo "Sprite Foundry LoRA fetch"
  echo "model=${profile}"
  echo "repo=${repo_id}"
  echo "target=${SPRITE_FOUNDRY_LORA_ROOT}/${library_id}/${library_file}"
  "${python_bin}" - "${repo_id}" "${repo_file}" "${SPRITE_FOUNDRY_HF_CACHE_DIR}" "${SPRITE_FOUNDRY_LORA_ROOT}" "${library_id}" "${library_file}" <<'PY'
from __future__ import annotations

import os
import shutil
import sys
from pathlib import Path

try:
    from huggingface_hub import hf_hub_download
except Exception as exc:
    raise SystemExit(f"ERROR: huggingface_hub is required to fetch Sprite Foundry LoRAs: {exc}")

repo_id, repo_file, cache_dir, lora_root, library_id, library_file = sys.argv[1:7]
token = os.getenv("NYMPHS3D_HF_TOKEN") or os.getenv("HF_TOKEN") or None
downloaded = Path(hf_hub_download(repo_id=repo_id, filename=repo_file, cache_dir=cache_dir, token=token))
target_dir = Path(lora_root).expanduser() / library_id
target_dir.mkdir(parents=True, exist_ok=True)
target = target_dir / library_file
if downloaded.resolve() != target.resolve():
    shutil.copy2(downloaded, target)
print(f"LoRA ready: {target}", flush=True)
PY
}

fetch_mks0813() {
  fetch_lora \
    "sprite_foundry_lora_mks0813_pixel_art" \
    "mks0813/z-image-turbo-pixel-lora" \
    "epoch-1.safetensors" \
    "mks0813_pixel_art" \
    "mks0813_pixel_art.safetensors"
}

fetch_skyasl() {
  fetch_lora \
    "sprite_foundry_lora_skyasl_pixel_artist" \
    "SkyAsl/Pixel-artist-Z" \
    "adapter_model.safetensors" \
    "skyasl_pixel_artist" \
    "skyasl_pixel_artist.safetensors"
}

fetch_tarn59() {
  fetch_lora \
    "sprite_foundry_lora_tarn59_pixel_art" \
    "tarn59/pixel_art_style_lora_z_image_turbo" \
    "pixel_art_style_z_image_turbo.safetensors" \
    "tarn59_pixel_art" \
    "tarn59_pixel_art.safetensors"
}

case "${selected_model}" in
  sprite_foundry_starter_stack|starter|complete|complete_sprite_foundry_stack)
    echo "Sprite Foundry starter stack fetch"
    fetch_zimage_profile int4_r32
    fetch_zimage_profile zimage_controlnet_2_1
    fetch_mks0813
    ;;
  sprite_foundry_all_loras|all_loras|all-loras)
    fetch_mks0813
    fetch_skyasl
    fetch_tarn59
    ;;
  zimage_controlnet_2_1|sprite_foundry_controlnet_2_1|sprite_foundry_controlnet|sprite-foundry-controlnet)
    echo "Sprite Foundry ControlNet fetch"
    fetch_zimage_profile zimage_controlnet_2_1
    ;;
  sprite_foundry_lora_mks0813_pixel_art|mks0813_pixel_art|zimage_turbo_pixel_lora)
    fetch_mks0813
    ;;
  sprite_foundry_lora_skyasl_pixel_artist|skyasl_pixel_artist|pixel_artist_z)
    fetch_skyasl
    ;;
  sprite_foundry_lora_tarn59_pixel_art|tarn59_pixel_art|pixel_art_style_lora)
    fetch_tarn59
    ;;
  *)
    echo "Unsupported Sprite Foundry fetch selection: ${selected_model:-none}" >&2
    echo "Expected starter stack, ControlNet, all LoRAs, or one Sprite Foundry LoRA profile." >&2
    exit 2
    ;;
esac

cat <<EOF
MODEL FETCH COMPLETE
selected=${selected_model}
shared_lora_root=${SPRITE_FOUNDRY_LORA_ROOT}
shared_hf_cache=${SPRITE_FOUNDRY_HF_CACHE_DIR}
EOF
