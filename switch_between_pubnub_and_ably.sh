#!/bin/bash
set -euxo pipefail

SLACK_USER_TOKEN="${SLACK_USER_TOKEN:-SLACK_USER_TOKEN_NOT_FOUND}"
OPSGENIE_TOKEN="${OPSGENIE_TOKEN:-OPSGENIE_TOKEN_NOT_FOUND}"
#debug
ENV=uat
today=$(date "+%F %H:%M:%S")
yaml_path=envs/"$ENV"/17app/stream/providers.yaml
branch="switch_between_pubnub_and_ably"

# Check yq installed or not first, if not install it with v4.30.4
FILE=/usr/bin/yq
if test -f "$FILE"; then
    echo "$FILE exists, not installing"
else
    echo "$FILE not existing, installing yq"
    VERSION=v4.30.4
    BINARY=yq_linux_amd64
    wget https://github.com/mikefarah/yq/releases/download/"$VERSION"/"$BINARY".tar.gz -O - | tar xz && sudo mv ${BINARY} /usr/bin/yq
fi

sudo apt install -y jq
# call github api to get original yaml file
gh api \
  -H "Accept: application/vnd.github+json" \
  /repos/17media/configs/contents/"$yaml_path" | jq -r ".content" | base64 --decode > original.yaml
echo "generate original.yaml"

# copy the original yaml file to updated yaml file 
cp -p original.yaml updated.yaml
echo "copied orginal.yaml to updated.yaml"

# parse through yq and update the new yaml file
yq -i '(.|.message_providers_general.[] | select(.name == "PUBNUB_MESSAGE") | .weight)='$1 updated.yaml
yq -i '(.|.message_providers_general.[] | select(.name == "ABLY_MESSAGE") | .weight)='$2 updated.yaml
yq -i '(.|.message_providers_dynamic.[] | select(.name == "PUBNUB_MESSAGE") | .weight)='$3 updated.yaml
yq -i '(.|.message_providers_dynamic.[] | select(.name != "PUBNUB_MESSAGE") | .weight)='$4 updated.yaml

echo "update file PUBNUB_MESSAGE $1 , ABLY_MESSAGE $2 ,dynamic PUBNUB_MESSAGE $3 ,dynamic ABLY_MESSAGE $4"

# yaml check or config test before push to etcd
# install yamllint
sudo apt install -y yamllint
yamllint -d relaxed --no-warnings updated.yaml
echo "yamllint test passed"

if [ -f updated.yaml ];
then
  git checkout -b $branch
  mv updated.yaml $yaml_path
else
  echo "No updated file exits."
  exit 0
fi

# oncaller_mail="$(curl \
#   --connect-timeout 60 \
#   --max-time 60 \
#   --request GET "https://api.opsgenie.com/v2/schedules/sre_team_schedule/on-calls?scheduleIdentifierType=name&flat=true" \
#   --header "Authorization: GenieKey ${OPSGENIE_TOKEN}" | jq -r .data.onCallRecipients[])"

# echo "Oncaller's email: ${oncaller_mail}"

# oncaller_slack_id="$(curl \
#   --connect-timeout 60 \
#   --max-time 60 \
#   --request GET "https://slack.com/api/users.lookupByEmail?email=${oncaller_mail}" \
#   --header "Authorization: Bearer ${SLACK_USER_TOKEN}" | jq -r .user.id)"

# oncall_group_slack_id="S0280LZPHNF"

#debug
oncaller_slack_id="U040E6KAARL"
oncall_group_slack_id="S04RL299DFZ"

if [[ $(git diff --stat) != '' ]];
then
  sudo apt update
  sudo apt install gh
  git config --global user.email "no-reply@17.media"
  git config --global user.name "github-actions-bot"
  git add $yaml_path
  git commit -m "[Infra] ${5} file sync"
  git push -f --set-upstream origin $branch

  current_branch_pr_status=$(gh pr view --json 'state' -q '.state' | xargs)
  pr_title="[Infra] ${5}"
  if [[ $current_branch_pr_status != 'OPEN' ]];
  then
    pr_url=$(gh pr create --title "${pr_title}" --body "${today} etcd updated and sync file")
    curl -X POST --data-urlencode "payload={\"channel\":  \"#eng-sre-log\", \"text\": \"<@${oncaller_slack_id}> `${pr_title}` PR Created c.c. <!subteam^${oncall_group_slack_id}>\n ${pr_url} \"}" "$SLACK_WEBHOOK_URI"
    echo "opened ${pr_title} PR"
  else
    pr_exists_msg="`${pr_title}` PR already exists, just go to merge ${branch} branch directly."
    curl -X POST --data-urlencode "payload={\"channel\":  \"#eng-sre-log\", \"text\": \"<@${oncaller_slack_id}> ${pr_exists_msg} c.c. <!subteam^${oncall_group_slack_id}> \"}" "$SLACK_WEBHOOK_URI"
    echo "${pr_title} PR already exists"
  fi
else
  echo 'File unchanged.'
fi

#先手動測試完改自動