#!/usr/bin/env bash

# set -o pipefail
set -o nounset
set -o errexit

if [ -z "${REVISION}" ]; then
  echo "abort, REVISION not defined"
  exit 1
fi

COMMIT_ID="${REVISION}"
COMMIT_MESSAGE=$(git log  --pretty=format:'%B' "${GIT_COMMIT}"^! | head -n1)

function push() {
  docker run --rm              \
    -e ENVIRONMENT="${1}"        \
    -e APPLICATION="${2}"        \
    -e ENDPOINTS="${3}"          \
    -v "$(pwd)":/configs:ro      \
    -t 17media/pusher:v19.4.25
}

config_paths=$(git diff-tree --no-commit-id --name-only -r "${COMMIT_ID}" | grep -E -o '^envs\/(sta|prod|uat)/[^\/]+' | sort | uniq)
echo "[debug] detected changes with config_paths: ${config_paths}"

curl -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":muscle:Push to ETCD Started.:etcd:\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"*Message*:${COMMIT_MESSAGE}\n*Commit*:${GIT_COMMIT}  *Job*: <${BUILD_URL}|URL>\"}]},{\"type\":\"divider\"}]}" "${SLACK}"

for config_path in $config_paths; do
  echo "[debug] processing config_path: ${config_path}"

  config_env=$(echo "${config_path}" | cut -d'/' -f2)
  config_app=$(echo "${config_path}" | cut -d'/' -f3)

  # support prod/sta only
  if [ "${config_env}" = "sta" ] || [ "${config_env}" = "prod" ] || [ "${config_env}" = "uat" ]; then
    # naming rule: ENDPOINTS_{{ APP_NAME }}_{{ CONFIG_ENV }}
    dynamic_endpoints="ENDPOINTS_$(echo "${config_app}" | tr '[:lower:]' '[:upper:]')_$(echo "${config_env}" | tr '[:lower:]' '[:upper:]')"
    endpoints=$(eval echo "\$${dynamic_endpoints}")

    if [ -n "${endpoints}" ]; then
      echo "[debug] ${config_env} / ${config_app} / ${endpoints}"
      push "${config_env}" "${config_app}" "${endpoints}"
    else
      echo "abort, no endpoint defined"
      curl -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":warning:Push to ETCD Failed.:red_thinking::etcd:\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"*Message*:${COMMIT_MESSAGE}\n*Commit*:${GIT_COMMIT}  *Job*: <${BUILD_URL}|URL> @sre\"}]},{\"type\":\"divider\"}]}" "${SLACK}"
      exit 1
    fi
  else
    echo "[debug] unsupported config_env, skipped" 
    continue
  fi
done

curl -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":white_check_mark:Push to ETCD Successfully.:etcd:\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"*Message*:${COMMIT_MESSAGE}\n*Commit*:${GIT_COMMIT}  *Job*: <${BUILD_URL}|URL>\"}]},{\"type\":\"divider\"}]}" "${SLACK}"
