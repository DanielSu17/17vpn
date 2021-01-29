#!/bin/bash

# get env
if [ "${JOB_BASE_NAME}" = "17media-config-checker-prod"  ];then
    CHANGE_FILTER='^envs\/(prod)/[^\/]+'
    ENV="prod"
elif [ "${JOB_BASE_NAME}" = "17media-config-checker-sta"  ];then
    CHANGE_FILTER='^envs\/(sta)/[^\/]+'
    ENV="sta"
elif [ "${JOB_BASE_NAME}" = "17media-config-checker-uat"  ];then
    CHANGE_FILTER='^envs\/(uat)/[^\/]+'
    ENV="uat"
else
    echo "Invalid ENV"
    exit 1
fi

# endpoint for slack message relay
SLACK_ENDPOINT="${SLACK}:8081/send_message"

# initialize variables
CHECKER="circle/syntax_checker.py circle/check_providers.py circle/remote_check.py"

# list of commits
commits=$(git log  --pretty=format:'%H' "${GIT_PREVIOUS_SUCCESSFUL_COMMIT}".."${GIT_COMMIT}")
config_paths=""
commit_list=""
echo "[debug] commits: ${commits}"

# get all change between lastest commit and previously successful commit
for commit in ${commits}; do
  echo "[debug] diff commit ${commit}"
  tmp=$(git diff-tree --no-commit-id --name-only -r "${commit}" | grep -E -o "${CHANGE_FILTER}" ||true;)
  if [ -n "${tmp}" ];then
    config_paths=$(printf "%s\n%s" "${config_paths}" "${tmp}")
    short_msg=$(git log  --pretty=format:'%an-%B' "${commit}"^! | head -n1)
    if [ -z "${commit_list}" ];then
        commit_list="${commit}-${short_msg}"
    else
        commit_list=$(printf "%s,%s-%s" "${commit_list}" "${commit}" "${short_msg}")
    fi
  fi
done

# call push container
function push() {
  docker run --rm              \
    -e ENVIRONMENT="${1}"        \
    -e APPLICATION="${2}"        \
    -e ENDPOINTS="${3}"          \
    -v "$(pwd)":/configs:ro      \
    -t 17media/pusher:v19.4.25
}

# config checks
function check(){
    echo "--- start checking ---"
    echo "0;starting;${commit_list}"
    curl -X POST  -d"0;starting;${commit_list}" "${SLACK_ENDPOINT}"
    for SCRIPT in ${CHECKER}; do
        docker run --rm -v "$(pwd)":/repo 17media/config-check:latest /bin/sh -c "cd /repo && python3 /repo/${SCRIPT}"
        
        ## get output status ##
        STATUS=$?
        ## take some decision ##
        
        if [ ${STATUS} -eq 0 ] 
        then
            echo "${SCRIPT} command was successful" 
        else
            curl -X POST  -d"1;fail;${commit_list}" "${SLACK_ENDPOINT}"
            exit 1
        fi
    done;
    curl -X POST  -d"1;success;${commit_list}" "${SLACK_ENDPOINT}"
    echo "--- finish checking ---"
}

# where we do push
function push_to_etcd(){

    if [ "${config_paths}" == "" ]; then
        echo "Nothing to push"
        exit 0
    fi

    # merge same paths
    config_paths=$(printf "%s" "${config_paths}" | sort | uniq)
    echo "[debug] detected changes with config_paths: ${config_paths}"

    # concatenate variables and call push container
    for config_path in ${config_paths}; do
        echo "[debug] processing config_path: ${config_path}"

        config_env=$(echo "${config_path}" | cut -d'/' -f2)
        config_app=$(echo "${config_path}" | cut -d'/' -f3)

        # push only if the path is ENV
        if [ "${config_env}" = "${ENV}" ] ; then
            curl -X POST  -d"2;starting;${commit_list}" "${SLACK_ENDPOINT}"
            # naming rule: ENDPOINTS_{{ APP_NAME }}_{{ CONFIG_ENV }}
            dynamic_endpoints="ENDPOINTS_$(echo "${config_app}" | tr '[:lower:]' '[:upper:]')_$(echo "${config_env}" | tr '[:lower:]' '[:upper:]')"
            endpoints=$(eval echo "\$${dynamic_endpoints}")

            if [ -n "${endpoints}" ]; then
                echo "[debug] ${config_env} / ${config_app} / ${endpoints}"
                push "${config_env}" "${config_app}" "${endpoints}"
            else
                echo "abort, no endpoint defined"
                curl -X POST  -d"3;fail;${commit_list}" "${SLACK_ENDPOINT}"
                exit 1
            fi
            curl -X POST  -d"3;success;${commit_list}" "${SLACK_ENDPOINT}"
        else
            echo "[debug] unsupported config_env, skipped" 
            continue
        fi
    done
}

main(){
    echo  "Check new commits"
    if [ -z "${config_paths}" ];then
        echo "No update in this webhook"
        exit 0
    fi
    echo  "Send starting message to slack - checker started"
    check
    echo  "Send starting message to slack - checker finished"
    echo  "Send starting message to slack - push started"
    push_to_etcd
    echo  "Send starting message to slack - push finished"

}

main "$@"