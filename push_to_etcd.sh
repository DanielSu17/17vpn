#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

if [ -z "${REVISION}" ]; then
  echo "abort, REVISION not defined"
  exit 1
fi

COMMIT_ID="${REVISION}"

function push() {
  docker run --rm              \
    -e ENVIRONMENT=${1}        \
    -e APPLICATION=${2}        \
    -e ENDPOINTS=${3}          \
    -v $(pwd):/configs:ro      \
    -t 17media/pusher:v19.4.25
}

config_paths=$(git diff-tree --no-commit-id --name-only -r ${COMMIT_ID} | egrep -o '^envs\/(dev|sta|prod)/[^\/]+' | sort | uniq)
echo "[debug] detected changes with config_paths: $config_paths"

for config_path in $config_paths; do
  echo "[debug] processing config_path: $config_path"

  config_env=$(echo $config_path | cut -d'/' -f2)
  config_app=$(echo $config_path | cut -d'/' -f3)

  # naming rule: ENDPOINTS_{{ APP_NAME }}_{{ CONFIG_ENV }}
  dynamic_endpoints="ENDPOINTS_$(echo ${config_app} | tr '[:lower:]' '[:upper:]')_$(echo ${config_env} | tr '[:lower:]' '[:upper:]')"
  endpoints=$(eval echo "\$${dynamic_endpoints}")

  if [ -n "${endpoints}" ]; then
    echo "[debug] ${config_env} / ${config_app} / ${endpoints}"

    if [ "${config_env}" = "sta" ] || [ "${config_env}" = "prod" ]; then
      push ${config_env} ${config_app} ${endpoints}
    else
      echo "[debug] unsupported config_env, skipped"
    fi
  else
    echo "abort, no endpoint defined"
    exit 1
  fi
done
