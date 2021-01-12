#!/bin/bash

CHECKER="circle/syntax_checker.py circle/check_providers.py circle/remote_check.py"
ERROR_TAGGING=',{"type":"section","text":{"type":"mrkdwn","text":"@sre"}}'
#COMMIT_MESSAGE=$(git log  --pretty=format:'%B' "${GIT_COMMIT}"^! | head -n1)
commits=$(git log  --pretty=format:'%H' "${GIT_PREVIOUS_SUCCESSFUL_COMMIT}".."${GIT_COMMIT}")

for commit in ${commits};do
    message=$(git log  --pretty=format:'%B' "${commit}"^! | head -n1)
    COMMIT_MESSAGE=$(printf "%s\n%s" "${COMMIT_MESSAGE}" "${message}")
done

TMP=$(git log  --pretty=format:'%an (%ae)' "${GIT_COMMIT}"^!)

# If Author is empty, it'll fail
if [[ "${TMP}" == *"17.media"* ]]; then
    COMMITER_INFO=$(git log  --pretty=format:'%an (%ae)' "${GIT_COMMIT}"^! | cut -d'(' -f 2 | cut -d')' -f 1)
fi

if [[ "${TMP}" == *"noreply.github"* ]]; then
    COMMITER_INFO=$(git log  --pretty=format:'%an (%ae)' "${GIT_COMMIT}"^! | cut -d' ' -f 1)
fi

if [[ "${TMP}" == *"tf-ig"* ]]; then
    COMMITER_INFO=$(git log  --pretty=format:'%B' "${GIT_COMMIT}"^! | head -n1 | cut -d'-' -f 1 | cut -d' ' -f 1)
fi

main(){
    echo "--- start checking ---"
    HEADER="Authorization: Bearer ${SLACKTOKEN}"
    USERID=$(curl -s -X GET --header "${HEADER}" https://slack.com/api/users.lookupByEmail?email="${COMMITER_INFO}" | jq -r .user.id)
    curl -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":crossed_fingers: Check Started\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"*Author*:${COMMITER_INFO}  *Commit*:<https://github.com/17media/configs/commit/${GIT_COMMIT} | ${GIT_COMMIT}> *Build*:<${BUILD_URL}|URL> \"}]},{\"type\":\"divider\"}]}" "${SLACK}"
    for SCRIPT in ${CHECKER}; do
        docker run --rm -v "$(pwd)":/repo 17media/config-check:latest /bin/sh -c "cd /repo && python3 /repo/${SCRIPT}"
        
        ## get output status ##
        STATUS=$?
        ## take some decision ##
        
        if [ ${STATUS} -eq 0 ] 
        then
            echo "${SCRIPT} command was successful" 
        else
            curl -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":warning: Check Failed :red_thinking:\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"*Author*:<@${USERID}>  *Commit*:<https://github.com/17media/configs/commit/${GIT_COMMIT} | ${GIT_COMMIT}>\n*Build*:<${BUILD_URL}|URL>  *Message*:${COMMIT_MESSAGE}\"}]},{\"type\":\"divider\"}]}${ERROR_TAGGING},{\"type\": \"divider\"}]}" "${SLACK}"
            exit 1
        fi
    done;
    curl -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"plain_text\",\"text\":\":white_check_mark: Check Passed\",\"emoji\":true}},{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"*Author*:${COMMITER_INFO}  *Commit*:<https://github.com/17media/configs/commit/${GIT_COMMIT} | ${GIT_COMMIT}> *Build*:<${BUILD_URL}|URL>\"}]},{\"type\":\"divider\"}]}" "${SLACK}"
    echo "--- finish checking ---"
    # TODO: Add push to etcd here
}

main "$@"