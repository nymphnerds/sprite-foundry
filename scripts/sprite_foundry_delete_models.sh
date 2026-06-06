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

Deletes only the Sprite Foundry ControlNet dependency from the shared Hugging
Face cache. It does not delete outputs, LoRAs, logs, presets, or runtimes.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
done

if [[ "${profile}" != "${SPRITE_FOUNDRY_CONTROLNET_PROFILE}" ]]; then
  echo "Unsupported delete profile: ${profile:-none}." >&2
  exit 2
fi

if [[ "${confirmed}" != "true" ]]; then
  echo "Refusing to delete model cache without --yes." >&2
  exit 2
fi

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
