#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_sprite_foundry_common.sh"

installed=false
runtime_present=false
data_present=false
version="not-installed"
running=false
state="available"
health="unavailable"
detail="${SPRITE_FOUNDRY_MODULE_NAME} is not installed."

if [[ -f "${SPRITE_FOUNDRY_MARKER_FILE}" ]]; then
  installed=true
  runtime_present=true
  version="$(tr -d '\r\n' < "${SPRITE_FOUNDRY_MARKER_FILE}")"
  state="installed"
  health="ok"
  detail="${SPRITE_FOUNDRY_MODULE_NAME} is installed."
fi

if [[ -d "${SPRITE_FOUNDRY_OUTPUTS_ROOT}" || -d "${SPRITE_FOUNDRY_CONFIG_DIR}" || -d "${SPRITE_FOUNDRY_LOGS_DIR}" ]]; then
  data_present=true
fi

if [[ -f "${SPRITE_FOUNDRY_UI_PID_FILE}" ]]; then
  pid="$(tr -d '[:space:]' < "${SPRITE_FOUNDRY_UI_PID_FILE}" || true)"
  if [[ -n "${pid}" ]] && kill -0 "${pid}" >/dev/null 2>&1; then
    if sprite_foundry_probe_url "${SPRITE_FOUNDRY_UI_URL}/health" >/dev/null 2>&1; then
      running=true
      state="running"
      health="ok"
      detail="${SPRITE_FOUNDRY_MODULE_NAME} UI is running at ${SPRITE_FOUNDRY_UI_URL}."
    else
      running=true
      state="running"
      health="unreachable"
      detail="${SPRITE_FOUNDRY_MODULE_NAME} UI process exists but health check failed."
    fi
  fi
fi

if [[ "${installed}" == "true" && ! -f "${SPRITE_FOUNDRY_INSTALL_DIR}/foundry/cli.py" ]]; then
  state="repair_needed"
  health="repair-needed"
  detail="${SPRITE_FOUNDRY_MODULE_NAME} install marker exists, but Foundry files are missing."
fi

printf 'id=%s\n' "${SPRITE_FOUNDRY_MODULE_ID}"
printf 'installed=%s\n' "${installed}"
printf 'runtime_present=%s\n' "${runtime_present}"
printf 'data_present=%s\n' "${data_present}"
printf 'version=%s\n' "${version}"
printf 'running=%s\n' "${running}"
printf 'state=%s\n' "${state}"
printf 'health=%s\n' "${health}"
printf 'detail=%s\n' "${detail}"
printf 'install_root=%s\n' "${SPRITE_FOUNDRY_INSTALL_DIR}"
printf 'outputs_root=%s\n' "${SPRITE_FOUNDRY_OUTPUTS_ROOT}"
printf 'ui_url=%s\n' "${SPRITE_FOUNDRY_UI_URL}"
printf 'zimage_url=%s\n' "${SPRITE_FOUNDRY_ZIMAGE_URL}"
