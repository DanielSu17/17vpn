#!/bin/bash

REQUIREMENT="./circle/requirements.txt"
CHECKER="circle/syntax_checker.py circle/check_providers.py circle/remote_check.py"
ERROR_TAGGING=',{"type":"section","text":{"type":"mrkdwn","text":"@sre"}}'
COMMITER_INFO=`git log  --pretty=format:'%an (%ae)' ${GIT_COMMIT}^! `
COMMIT_MSG=`git log  --pretty=format:'%B' ${GIT_COMMIT}^! `

main(){
    echo "--- start checking ---"
    curl -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"Config commit:\n*<https://github.com/tig4605246/actionary/commit/$COMMIT_URL | $GIT_COMMIT>*\"}},{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Build URL:*\n*<${BUILD_URL}|URL>*\"}},{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Test Started*\n*Commited By:*\n ${COMMITER_INFO}\n*Commit Message:*\n${COMMIT_MSG} \"}}]}" ${SLACK}
    for SCRIPT in ${CHECKER}; do
        docker run --rm -v $(pwd):/repo tig4605246/config-checker-python:latest /bin/sh -c "cd /repo && python3 /repo/${SCRIPT}"
        ## get output status ##
        STATUS=$?
        ## take some decision ## 
        if [ ${STATUS} -eq 0 ] 
        then
            echo "${SCRIPT} command was successful" 
        else
            curl -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"Config commit:\n*<https://github.com/tig4605246/actionary/commit/$COMMIT_URL | $GIT_COMMIT>*\"}},{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Build URL:*\n*<${BUILD_URL}|URL>*\"}},{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Tests of ${SCRIPT} failed*\n*Commited By:*\n ${COMMITER_INFO}\n*Commit Message:*\n${COMMIT_MSG} \"},\"accessory\":{\"type\":\"image\",\"image_url\":\"https://api.slack.com/img/blocks/bkb_template_images/notificationsWarningIcon.png\",\"alt_text\":\"Warning\"}}${ERROR_TAGGING}]}" ${SLACK}
            exit -1
        fi
    done;
    curl -X POST -H 'Content-type: application/json' --data "{\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"Config commit:\n*<https://github.com/tig4605246/actionary/commit/$COMMIT_URL | $GIT_COMMIT>*\"}},{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Build URL:*\n*<${BUILD_URL}|URL>*\"}},{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Tests Passed*\n*Commited By:*\n ${COMMITER_INFO}\n*Commit Message:*\n${COMMIT_MSG} \"}}]}" ${SLACK} 
    echo "--- finish checking ---"
}

main $@
