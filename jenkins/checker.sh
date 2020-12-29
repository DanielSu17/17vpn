#!/bin/bash

CHECKER="circle/syntax_checker.py circle/check_providers.py circle/remote_check.py"
ERROR_TAGGING=',{"type":"section","text":{"type":"mrkdwn","text":"@sre"}}'
COMMIT_MESSAGE=$(git log  --pretty=format:'%B' "${GIT_COMMIT}"^!)

docker login -u "${DOCKER_USER}" -p "${DOCKER_PASS}"

TMP=$(git log  --pretty=format:'%an (%ae)' "${GIT_COMMIT}"^!)
# If Author is empty, it'll fail
if [[ "${TMP}" == *"17.media"* ]]; then
    if [[ "${TMP}" == *"noreply"* ]]; then
        COMMITER_INFO=$(git log  --pretty=format:'%an (%ae)' "${GIT_COMMIT}"^! | cut -d'(' -f 1)
    else
        COMMITER_INFO=$(git log  --pretty=format:'%an (%ae)' "${GIT_COMMIT}"^! | cut -d'(' -f 2 | cut -d')' -f 1)
    fi
else
    COMMITER_INFO=$(git log  --pretty=format:'%B' "${GIT_COMMIT}"^! | head -n1 | cut -d'-' -f 1 | cut -d' ' -f 1)
fi

main(){
    echo "--- start checking ---"
    HEADER="Authorization: Bearer ${SLACKTOKEN}"
    USERID=$(curl -s -X GET --header "${HEADER}" https://slack.com/api/users.lookupByEmail?email="${COMMITER_INFO}" | jq -r .user.id)
    curl -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"Config commit:\n*<https://github.com/17media/configs/commit/$GIT_COMMIT | $GIT_COMMIT>*\"}},{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Build URL:*\n*<${BUILD_URL}|URL>*\"}},{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Test Started*\n*Commited By:*\n ${COMMITER_INFO}\n*Commit Message:*\n ${COMMIT_MESSAGE}\"}},{\"type\": \"divider\"}]}" "${SLACK}"
    for SCRIPT in ${CHECKER}; do
        docker run --rm -v "$(pwd)":/repo 17media/config-check:latest /bin/sh -c "cd /repo && python3 /repo/${SCRIPT}"
        ## get output status ##
        STATUS=$?
        ## take some decision ##
        
        if [ ${STATUS} -eq 0 ] 
        then
            echo "${SCRIPT} command was successful" 
        else
            curl -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"Config commit:\n*<https://github.com/17media/configs/commit/$GIT_COMMIT | $GIT_COMMIT>*\"}},{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Build URL:*\n*<${BUILD_URL}|URL>*\"}},{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Tests of ${SCRIPT} failed*\n*Commited By:*\n <@${USERID}>\n*Commit Message:*\n${COMMIT_MESSAGE} \"},\"accessory\":{\"type\":\"image\",\"image_url\":\"https://api.slack.com/img/blocks/bkb_template_images/notificationsWarningIcon.png\",\"alt_text\":\"Warning\"}}${ERROR_TAGGING},{\"type\": \"divider\"}]}" "${SLACK}"
            exit 1
        fi
    done;
    curl -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"Config commit:\n*<https://github.com/17media/configs/commit/$GIT_COMMIT | $GIT_COMMIT>*\"}},{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Build URL:*\n*<${BUILD_URL}|URL>*\"}},{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Tests Passed*\n*Commited By:*\n ${COMMITER_INFO}\n*Commit Message:*\n${COMMIT_MESSAGE} \"}},{\"type\": \"divider\"}]}" "${SLACK}"
    echo "--- finish checking ---"
    # TODO: Add push to etcd here
}

main "$@"