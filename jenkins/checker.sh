#!/bin/bash

if [ -n "$1" ]; then
    ENV=$1
fi

CHECKER="circle/syntax_checker.py circle/check_providers.py"

commits=$(git log --pretty=format:'%H' "${GIT_PREVIOUS_SUCCESSFUL_COMMIT}".."${GIT_COMMIT}")
for commit in ${commits}; do
    message=$(git log --pretty=format:'%B' "${commit}"^! | head -n1)
    COMMIT_MESSAGE=$(printf "%s\n%s" "${COMMIT_MESSAGE}" "${message}")
done

AUTHOR_EMAIL=$(git --no-pager show -s --format='%ae' $GIT_COMMIT)
# commit from admin page
if [[ "${AUTHOR_EMAIL}" == *"tf-ig"* ]]; then
    AUTHOR_EMAIL=$(git log --pretty=format:'%B' "${GIT_COMMIT}"^! | head -n1 | cut -d'-' -f 1 | cut -d' ' -f 1)
# commit from Jenkins
elif [[ "${AUTHOR_EMAIL}" == "no-reply@17"* ]]; then
    AUTHOR_EMAIL=$(git log --pretty=format:'%B' "${GIT_COMMIT}"^! | head -n1 | cut -d'-' -f 2 | cut -d' ' -f 2)
fi

mention_author_in_slack() {
    HEADER="Authorization: Bearer ${SLACKTOKEN}"
    USERID=$(curl --insecure -s -X GET --header "${HEADER}" https://slack.com/api/users.lookupByEmail?email="${AUTHOR_EMAIL}" | jq -r .user.id)

    if [[ -n ${USERID} && ${USERID} != "null" ]]; then
        curl --insecure -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":warning: ${ENV} Config Check Failed :red_thinking:\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"*Author*:<@${USERID}>  *Commit*:<https://github.com/17media/configs/commit/${GIT_COMMIT}|${GIT_COMMIT}>\n*Build*:<${BUILD_URL}|URL>  *Message*:${COMMIT_MESSAGE}\"}]},{\"type\":\"divider\"}]}" "${SLACK}"
    else
        SRE_MENTION='{"type":"section","text":{"type":"mrkdwn","text":"<!subteam^S4Y7W93V1>"}}'
        curl --insecure -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":warning: ${ENV} Config Check Failed :red_thinking:\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"*Author*:${AUTHOR_EMAIL}  *Commit*:<https://github.com/17media/configs/commit/${GIT_COMMIT}|${GIT_COMMIT}>\n*Build*:<${BUILD_URL}|URL>  *Message*:${COMMIT_MESSAGE}\"}]},${SRE_MENTION},{\"type\": \"divider\"}]}" "${SLACK}"
    fi
}

main() {
    echo "--- start checking ---"
    
    # local config checker
    changed_files=$(git log --name-only --pretty=format: "${GIT_PREVIOUS_SUCCESSFUL_COMMIT}".."${GIT_COMMIT}" | grep yaml$)
    config_env=$(git log --name-only --pretty=format: "${GIT_PREVIOUS_SUCCESSFUL_COMMIT}".."${GIT_COMMIT}" | grep yaml$ | awk -F "/" '$1=="envs" {print $2}' | sort -u)

    for env in ${config_env}; do
        if [[ "${env}" == "dev" ]]; then
            continue
        fi
        
        if [[ -n "$ENV" && "${env}" != "$ENV" ]]; then
            continue
        fi

        curl --insecure -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":crossed_fingers: ${ENV} Config Check Started\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"*Author*:${AUTHOR_EMAIL}  *Commit*:<https://github.com/17media/configs/commit/${GIT_COMMIT}|${GIT_COMMIT}> *Build*:<${BUILD_URL}|URL> \"}]},{\"type\":\"divider\"}]}" "${SLACK}"
        
        for SCRIPT in ${CHECKER}; do
            docker run --rm -v "$(pwd)":/repo 17media/config-check:latest /bin/sh -c "cd /repo && python3 /repo/${SCRIPT}"

            STATUS=$?
            if [ ${STATUS} -eq 0 ]; then
                echo "${SCRIPT} command was successful"
            else
                mention_author_in_slack
                exit 1
            fi
        done

        env_files=$(echo "${changed_files}" | grep ${env} | tr '\n' ',')
        echo "${env} : ${env_files}"

        docker pull "17media/config-checker:k8s${env}"
        docker run --rm -v "$(pwd)":/repo/configs "17media/config-checker:k8s${env}" -config_root="/repo/configs" -check_configs="${env_files}" -config_env="${env}"

        LOCAL_CHECKER_STATUS=$?
        if [ ${LOCAL_CHECKER_STATUS} -eq 0 ]; then
            echo "[${env}] Local checker was successful"
            
        else
            mention_author_in_slack
            exit 1
        fi

        curl --insecure -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":white_check_mark: ${ENV} Config Check Passed\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"*Author*:${AUTHOR_EMAIL}  *Commit*:<https://github.com/17media/configs/commit/${GIT_COMMIT}|${GIT_COMMIT}> *Build*:<${BUILD_URL}|URL>\"}]},{\"type\":\"divider\"}]}" "${SLACK}"
    done

    echo "--- finish checking ---"
}

main "$@"
