#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_sprite_foundry_common.sh"

args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      shift 2
      ;;
    --model=*)
      shift
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

fetch_script="$(sprite_foundry_zimage_script zimage_fetch_models.sh)" || {
  echo "ERROR: Sprite Foundry needs Nymphs Image installed to fetch its Z-Image ControlNet weight." >&2
  echo "expected=${HOME}/Z-Image/scripts/zimage_fetch_models.sh" >&2
  exit 1
}

echo "Sprite Foundry ControlNet fetch"
echo "delegate=nymphs-image"
echo "model=zimage_controlnet_2_1"
echo "fetch_script=${fetch_script}"

exec "${fetch_script}" --model zimage_controlnet_2_1 "${args[@]}"
