# send i18n diff to slack, and update i18n

Create diff and send to slack, and merge and push to github after user confirm

### Usage

`slackUserID` slack user id of people who should receive slack msg

`slackUserEmail` slack user email of people who should receive slack msg

`env` which env that we should update i18n files

`slackToken` specific which slack app we use

`confirm` keep empty to create diff, fill anything to merge and push to github


* clone configs, update i18n ,create diff and send to slack

go run diffToSlack.go --slackUserID=<your slack user id> --slackUserEmail=<your slack user email> --env=all --slackToken=<slack app token>

* merge and push to github

go run diffToSlack.go --slackUserID=<your slack user id> --slackUserEmail=<your slack user email> --env=all --slackToken=<slack app token> --confirm=anythingyouwant
