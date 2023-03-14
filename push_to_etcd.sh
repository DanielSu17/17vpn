#!/usr/bin/env bash

# set -o pipefail
set -o nounset
set -o errexit

ETCD_PUSH_IMAGE="17media/pusher:v19.4.25"
ETCD_PUSH_V3_IMAGE="17media/pusherv3:v22.6.14"

if [ -z "${REVISION}" ]; then
  echo "abort, REVISION not defined"
  exit 1
fi

COMMIT_MESSAGE=$(git log  --pretty=format:'%B' "${GIT_COMMIT}"^! | head -n1)

function push() {
  image=${ETCD_PUSH_IMAGE}
  for app in $(echo ${V3_APP_LIST} | tr ";" "\n")
  do
    if [[ "${2}" == ${app} ]]; then
      image=${ETCD_PUSH_V3_IMAGE}
      break
    fi
  done
  echo "[debug] ${image} / ${config_env} / ${config_app} / ${endpoints}"
  docker run --rm                  \
      -e ENVIRONMENT="${1}"        \
      -e APPLICATION="${2}"        \
      -e ENDPOINTS="${3}"          \
      -v "$(pwd)":/configs:ro      \
      -t ${image}
}

# list of commits

# If GIT_PREVIOUS_SUCCESSFUL_COMMIT is not aviable, using previous commit by default.
GIT_PREVIOUS_SUCCESSFUL_COMMIT="${GIT_PREVIOUS_SUCCESSFUL_COMMIT:-$(git rev-parse HEAD~2 | tr -d '\n')}"

commits=$(git log  --pretty=format:'%H' "${GIT_PREVIOUS_SUCCESSFUL_COMMIT}".."${GIT_COMMIT}")
config_paths=""
commit_list=""
echo "[debug] commits: ${commits}"

# Get all change between lastest commit and previously successful commit
for commit in ${commits}; do
  echo "[debug] diff commit ${commit}"
  tmp=$(git diff-tree --no-commit-id --name-only -r "${commit}" | grep -E -o '^envs\/(sta|prod|uat)/[^\/]+' ||true;)
  if [ -n "${tmp}" ];then
    config_paths=$(printf "%s\n%s" "${config_paths}" "${tmp}")
    short_msg=$(git log  --pretty=format:'(%an) %B' "${commit}"^! | head -n1)
    commit_list=$(printf "%s\n%s - %s" "${commit_list}" "${commit}" "${short_msg}")
  fi
done

if [ "${config_paths}" == "" ]; then
  echo "Nothing to push"
  exit 0
fi
# merge same paths
config_paths=$(printf "%s" "${config_paths}" | sort | uniq)
echo "[debug] detected changes with config_paths: ${config_paths}"
curl --insecure -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":merged2: *Updating Following Config Changes to ETCD*\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"${commit_list}\"}]},{\"type\":\"divider\"}]}" "${SLACK}"    

for config_path in ${config_paths}; do
  echo "[debug] processing config_path: ${config_path}"

  config_env=$(echo "${config_path}" | cut -d'/' -f2)
  config_app=$(echo "${config_path}" | cut -d'/' -f3)

  if [ "${config_env}" = "uat" ]  &&  [ "${config_app}" = "wave" ] ; then
    continue
  fi

  # support prod/sta only
  if [ "${config_env}" = "sta" ]  || [ "${config_env}" = "prod" ] || [ "${config_env}" = "uat" ] ; then
    curl --insecure -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":muscle:Push to *${config_env}* ETCD Started.:etcd:\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"*Message*:${COMMIT_MESSAGE}\n*Lastest Commit*:${GIT_COMMIT}  *Job*: <${BUILD_URL}|URL>\"}]},{\"type\":\"divider\"}]}" "${SLACK}"    
    # naming rule: ENDPOINTS_{{ APP_NAME }}_{{ CONFIG_ENV }}
    dynamic_endpoints="ENDPOINTS_$(echo "${config_app}" | tr '[:lower:]' '[:upper:]')_$(echo "${config_env}" | tr '[:lower:]' '[:upper:]')"
    echo "[debug] dynamic_endpoints: ${dynamic_endpoints}"

    # check if variable is defined
    if [ -z $(eval echo "\$${dynamic_endpoints}") ]; then
      echo "[debug] variable ${dynamic_endpoints} is not defined, skip"
    else 
      endpoints=$(eval echo "\$${dynamic_endpoints}")

      if [ -n "${endpoints}" ]; then
        echo "[debug] ${config_env} / ${config_app} / ${endpoints}"
        push "${config_env}" "${config_app}" "${endpoints}"
      elif export | grep "$dynamic_endpoints="; then
        # If variable is defined as empty string ""
        echo "Endpoint ${dynamic_endpoints} is an empty string"
      else
        echo "abort, no endpoint defined"
        curl --insecure -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":warning:Push to *${config_env}* ETCD Failed.:red_thinking::etcd:\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"*Message*:${COMMIT_MESSAGE}\n*Lastest Commit*:${GIT_COMMIT}  *Job*: <${BUILD_URL}|URL> @sre\"}]},{\"type\":\"divider\"}]}" "${SLACK}"
        # exit 1 ignore error if endpoint not found
      fi
    fi

    curl --insecure -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":white_check_mark:Push to *${config_env}* ETCD Successfully.:etcd:\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"*Message*:${COMMIT_MESSAGE}\n*Lastest Commit*:${GIT_COMMIT}  *Job*: <${BUILD_URL}|URL>\"}]},{\"type\":\"divider\"}]}" "${SLACK}"
  else
    echo "[debug] unsupported config_env, skipped" 
    continue
  fi
done
