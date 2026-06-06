#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_sprite_foundry_common.sh"

profile=""
confirmed=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      profile="${2:-}"
      shift 2
      ;;
    --profile=*)
      profile="${1#*=}"
      shift
      ;;
    --yes)
      confirmed=true
      shift
      ;;
    --yes=*)
      case "${1#*=}" in
        1|true|yes) confirmed=true ;;
        *) confirmed=false ;;
      esac
      shift
      ;;
    -h|--help)
      cat <<EOF
Usage:
  sprite_foundry_delete_models.sh --profile ${SPRITE_FOUNDRY_CONTROLNET_PROFILE} --yes
  sprite_foundry_delete_models.sh --profile sprite_foundry_lora_mks0813_pixel_art --yes

Deletes only the selected Sprite Foundry dependency. ControlNet is removed from
the shared Hugging Face cache. Sprite LoRAs are removed from the shared LoRA
folder used by the LoRA module and Z-Image. It does not delete outputs, logs,
presets, runtimes, datasets, jobs, or trained user LoRAs outside these known
Sprite Foundry filenames.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
done

if [[ "${confirmed}" != "true" ]]; then
  echo "Refusing to delete model cache without --yes." >&2
  exit 2
fi

delete_lora_profile() {
  local library_id="$1"
  local library_file="$2"
  local repo_dir="$3"
  local repo_file="$4"
  local deleted=0
  local candidates=(
    "${SPRITE_FOUNDRY_LORA_ROOT}/${library_id}/${library_file}"
    "${SPRITE_FOUNDRY_LORA_ROOT}/${library_file}"
    "${SPRITE_FOUNDRY_LORA_ROOT}/${repo_dir}/${repo_file}"
  )
  local file_path
  for file_path in "${candidates[@]}"; do
    case "${file_path}" in
      "${SPRITE_FOUNDRY_LORA_ROOT}"/*) ;;
      *)
        echo "Refusing unsafe LoRA path: ${file_path}" >&2
        exit 3
        ;;
    esac
    if [[ -f "${file_path}" ]]; then
      echo "Deleting Sprite Foundry LoRA: ${file_path}"
      rm -f -- "${file_path}"
      deleted=1
      rmdir "$(dirname "${file_path}")" >/dev/null 2>&1 || true
    fi
  done
  if [[ "${deleted}" -eq 0 ]]; then
    echo "Sprite Foundry LoRA already absent: ${library_file}"
  fi
}

case "${profile}" in
  sprite_foundry_lora_mks0813_pixel_art|mks0813_pixel_art)
    delete_lora_profile \
      "mks0813_pixel_art" \
      "mks0813_pixel_art.safetensors" \
      "mks0813--z-image-turbo-pixel-lora" \
      "epoch-1.safetensors"
    exit 0
    ;;
  sprite_foundry_lora_skyasl_pixel_artist|skyasl_pixel_artist)
    delete_lora_profile \
      "skyasl_pixel_artist" \
      "skyasl_pixel_artist.safetensors" \
      "SkyAsl--Pixel-artist-Z" \
      "adapter_model.safetensors"
    exit 0
    ;;
  sprite_foundry_lora_tarn59_pixel_art|tarn59_pixel_art)
    delete_lora_profile \
      "tarn59_pixel_art" \
      "tarn59_pixel_art.safetensors" \
      "tarn59--pixel_art_style_lora_z_image_turbo" \
      "pixel_art_style_z_image_turbo.safetensors"
    exit 0
    ;;
  "${SPRITE_FOUNDRY_CONTROLNET_PROFILE}"|zimage_controlnet_2_1)
    ;;
  *)
    echo "Unsupported delete profile: ${profile:-none}." >&2
    exit 2
    ;;
esac

cache_dir="$(sprite_foundry_repo_cache_dir "${SPRITE_FOUNDRY_CONTROLNET_REPO}")"
case "${cache_dir}" in
  "${SPRITE_FOUNDRY_HF_CACHE_DIR}"/models--*) ;;
  *)
    echo "Refusing unsafe cache path: ${cache_dir}" >&2
    exit 3
    ;;
esac

if [[ ! -d "${cache_dir}/snapshots" ]]; then
  echo "Sprite Foundry ControlNet cache already absent: ${cache_dir}"
  exit 0
fi

deleted=0
while IFS= read -r -d '' file_path; do
  blob_path=""
  if [[ -L "${file_path}" ]]; then
    blob_path="$(readlink -f "${file_path}" 2>/dev/null || true)"
  fi

  case "${file_path}" in
    "${cache_dir}"/snapshots/*/"${SPRITE_FOUNDRY_CONTROLNET_FILE}") ;;
    *)
      echo "Refusing unsafe cached ControlNet path: ${file_path}" >&2
      exit 3
      ;;
  esac

  echo "Deleting Sprite Foundry ControlNet weight: ${file_path}"
  rm -f -- "${file_path}"
  deleted=1

  if [[ -n "${blob_path}" && "${blob_path}" == "${cache_dir}/blobs/"* && -f "${blob_path}" ]]; then
    still_referenced=false
    while IFS= read -r -d '' sibling; do
      if [[ "$(readlink -f "${sibling}" 2>/dev/null || true)" == "${blob_path}" ]]; then
        still_referenced=true
        break
      fi
    done < <(find "${cache_dir}/snapshots" -type l -print0 2>/dev/null || true)

    if [[ "${still_referenced}" != "true" ]]; then
      echo "Deleting Sprite Foundry ControlNet blob: ${blob_path}"
      rm -f -- "${blob_path}"
    fi
  fi
done < <(find -L "${cache_dir}/snapshots" -mindepth 2 -maxdepth 2 -type f -name "${SPRITE_FOUNDRY_CONTROLNET_FILE}" -print0 2>/dev/null || true)

if [[ "${deleted}" -eq 0 ]]; then
  echo "Sprite Foundry ControlNet already absent: ${SPRITE_FOUNDRY_CONTROLNET_FILE}"
fi
