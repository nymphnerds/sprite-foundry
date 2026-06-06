#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_sprite_foundry_common.sh"

command_name="status"
run_id=""
direction=""
attempt_id=""
code=""
subject_id=""
config=""
extra_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --command)
      command_name="$2"
      shift 2
      ;;
    --run-id)
      run_id="$2"
      shift 2
      ;;
    --direction)
      direction="$2"
      shift 2
      ;;
    --attempt-id)
      attempt_id="$2"
      shift 2
      ;;
    --code)
      code="$2"
      shift 2
      ;;
    --subject-id)
      subject_id="$2"
      shift 2
      ;;
    --config)
      config="$2"
      shift 2
      ;;
    *)
      extra_args+=("$1")
      shift
      ;;
  esac
done

root="$(sprite_foundry_root)"
python_bin="$(sprite_foundry_python_bin)"
sprite_foundry_ensure_dirs
sprite_foundry_touch_log

require_run() {
  if [[ -z "${run_id}" ]]; then
    echo "ERROR: --run-id is required for ${command_name}" >&2
    exit 1
  fi
}

require_direction() {
  if [[ -z "${direction}" ]]; then
    echo "ERROR: --direction is required for ${command_name}" >&2
    exit 1
  fi
}

require_attempt() {
  if [[ -z "${attempt_id}" ]]; then
    echo "ERROR: --attempt-id is required for ${command_name}" >&2
    exit 1
  fi
}

require_code() {
  if [[ -z "${code}" ]]; then
    echo "ERROR: --code is required for ${command_name}" >&2
    exit 1
  fi
}

cd "${root}"
case "${command_name}" in
  status|metrics|drift)
    cmd=("${python_bin}" -m foundry.cli "${command_name}")
    if [[ -n "${run_id}" ]]; then
      cmd+=("${run_id}")
    fi
    ;;
  check|review-show|lineage|winner|produce|export|ship-check|ship-export)
    require_run
    cmd=("${python_bin}" -m foundry.cli "${command_name}" "${run_id}")
    ;;
  batch-accept)
    require_run
    cmd=("${python_bin}" -m foundry.cli batch-accept "${run_id}")
    ;;
  batch-reject)
    require_run
    require_code
    cmd=("${python_bin}" -m foundry.cli batch-reject "${run_id}" "--code" "${code}")
    ;;
  review-accept)
    require_run
    require_direction
    cmd=("${python_bin}" -m foundry.cli review-accept "${run_id}" "${direction}")
    if [[ -n "${attempt_id}" ]]; then
      cmd+=("--attempt-id" "${attempt_id}")
    fi
    ;;
  review-reject)
    require_run
    require_direction
    require_code
    cmd=("${python_bin}" -m foundry.cli review-reject "${run_id}" "${direction}" "--code" "${code}")
    if [[ -n "${attempt_id}" ]]; then
      cmd+=("--attempt-id" "${attempt_id}")
    fi
    ;;
  attempt-detail|story)
    require_attempt
    cmd=("${python_bin}" -m foundry.cli "${command_name}" "${attempt_id}")
    ;;
  subject-add)
    if [[ -z "${subject_id}" ]]; then
      echo "ERROR: --subject-id is required for subject-add" >&2
      exit 1
    fi
    cmd=("${python_bin}" -m foundry.cli subject-add "${subject_id}" "${subject_id}")
    ;;
  *)
    echo "ERROR: unsupported Foundry command: ${command_name}" >&2
    exit 2
    ;;
esac

cmd+=("${extra_args[@]}")
printf 'foundry_command=%s\n' "${command_name}" >> "${SPRITE_FOUNDRY_LOG_FILE}"
exec "${cmd[@]}"
