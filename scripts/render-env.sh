#!/usr/bin/env bash
# Renders .env.example keys from environment variables of the same name into
# the systemd EnvironmentFile format on stdout. Missing keys are reported on
# stderr and omitted. Shared by the deploy and environment workflows.
set -euo pipefail

while IFS='=' read -r key _ || [ -n "$key" ]; do
  case "$key" in
    '' | \#*) continue ;;
  esac
  val="${!key:-}"
  if [ -n "$val" ]; then
    printf '%s="%s"\n' "$key" "$(printf '%s' "$val" | sed 's/["\\]/\\&/g')"
  else
    echo "warning: $key missing from environment" >&2
  fi
done < .env.example