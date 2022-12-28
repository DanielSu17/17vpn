#!/bin/bash
set -euxo pipefail

SLACK_USER_TOKEN="${SLACK_USER_TOKEN:-SLACK_USER_TOKEN_NOT_FOUND}"
OPSGENIE_TOKEN="${OPSGENIE_TOKEN:-OPSGENIE_TOKEN_NOT_FOUND}"

sudo apt-get update
sudo apt-get install gcalcli -y
today=$(date +%F)
until=$(date -d "$today +2 month" +%F)
gcalcli --calendar='ENG Support' --nocolor agenda $today $until --tsv --nostarted > events.txt
tmp_file=tmp.yaml

while read -r line
do
start_date=$(echo $line | awk '{ print $1 }')
start_time=$(echo $line | awk '{ print $2 }')
end_date=$(echo $line | awk '{ print $3 }')
end_time=$(echo $line | awk '{ print $4 }')
name=$(echo $line | awk '{ $1=$2=$3=$4=""; print $0 }')

if [ -z $start_date ];
then
  echo "Skip empty line."
else
# start_time - 30m + GMT+8 hr
_start=$(date -d "$start_date $start_time" +%s)
start=$(date -d @$(($_start - 30 * 60 + 8 * 60 * 60)) '+%F %T')
# end_time + 1hr + GMT+8 hr
_end=$(date -d "$end_date $end_time" +%s)
end=$(date -d @$(($_end + 1 * 60 * 60 + 8 * 60 * 60)) '+%F %T')

if [[ $name =~ .*"香港活動支援".* ]];
then
  echo "HK event"
cat << EOF >> $tmp_file
# $name
- startTime: "$start (GMT+0800)"
  endTime: "$end (GMT+0800)"
  HPAConfigs:
  - name: k8sprod-goapi-main
    minReplicas: 70
  - name: k8sprod-golives-main
    minReplicas: 85
  - name: k8sprod-gotrade-main
    minReplicas: 12
  - name: k8sprod-gocells-main
    minReplicas: 25
  - name: k8sprod-gousersearch-main
    minReplicas: 10
  - name: k8sprod-revprox-main
    minReplicas: 36

EOF
elif [[ $name =~ .*"台灣活動支援".* ]];
then
  echo "TW event"
cat << EOF >> $tmp_file
# $name
- startTime: "$start (GMT+0800)"
  endTime: "$end (GMT+0800)"
  HPAConfigs:
  - name: k8sprod-goapi-main
    minReplicas: 70
  - name: k8sprod-golives-main
    minReplicas: 85
  - name: k8sprod-gotrade-main
    minReplicas: 12
  - name: k8sprod-gocells-main
    minReplicas: 25
  - name: k8sprod-gousersearch-main
    minReplicas: 10
  - name: k8sprod-revprox-tw-main
    minReplicas: 36

EOF
else
  echo "JP event"
cat << EOF >> $tmp_file
# $name
- startTime: "$start (GMT+0800)"
  endTime: "$end (GMT+0800)"
  HPAConfigs:
  - name: k8sprod-goapi-main
    minReplicas: 70
  - name: k8sprod-golives-main
    minReplicas: 85
  - name: k8sprod-gotrade-main
    minReplicas: 12
  - name: k8sprod-gocells-main
    minReplicas: 25
  - name: k8sprod-gousersearch-main
    minReplicas: 10
  - name: k8sprod-revprox-jp-main
    minReplicas: 36

EOF
fi

fi
done < events.txt

branch="prescaling"

if [ -f "$tmp_file" ];
then
  yaml_path=envs/prod/17app/gke/scheduled_scaling.yaml
  git checkout -b $branch
  mv tmp.yaml $yaml_path
  sudo apt install -y yamllint
  yamllint -d relaxed --no-warnings $yaml_path
else
  echo "No calendar event exists."
  exit 0
fi

oncaller_mail="$(curl \
  --connect-timeout 60 \
  --max-time 60 \
  --request GET "https://api.opsgenie.com/v2/schedules/sre_team_schedule/on-calls?scheduleIdentifierType=name&flat=true" \
  --header "Authorization: GenieKey ${OPSGENIE_TOKEN}" | jq -r .data.onCallRecipients[])"

echo "Oncaller's email: ${oncaller_mail}"

oncaller_slack_id="$(curl \
  --connect-timeout 60 \
  --max-time 60 \
  --request GET "https://slack.com/api/users.lookupByEmail?email=${oncaller_mail}" \
  --header "Authorization: Bearer ${SLACK_USER_TOKEN}" | jq -r .user.id)"

if [[ $(git diff --stat) != '' ]];
then
  sudo apt update
  sudo apt install gh
  git config --global user.email "no-reply@17.media"
  git config --global user.name "github-actions-bot"
  git add $yaml_path
  git commit -m "[Infra] GKE prescaling for Google Calendar events"
  git push -f --set-upstream origin $branch
  current_branch_pr_status=$(gh pr view --json 'state' -q '.state' | xargs)
  if [[ $current_branch_pr_status != 'OPEN' ]];
  then
    # oncall group team id: S4Y7W93V1
    pr_url=$(gh pr create --title "[Infra] GKE prescaling" --body $today)
    curl -X POST --data-urlencode "payload={\"channel\": \"#eng-sre-log\", \"text\": \"<@${oncaller_slack_id}> Prescaling PR Created c.c. <!subteam^S0280LZPHNF>\n $pr_url \"}" "$SLACK_WEBHOOK_URI"
  else
    pr_exists_msg="PR already exists, just go to merge ${branch} branch directly."
    curl -X POST --data-urlencode "payload={\"channel\": \"#eng-sre-log\", \"text\": \"<@${oncaller_slack_id}> ${pr_exists_msg} c.c. <!subteam^S0280LZPHNF> \"}" "$SLACK_WEBHOOK_URI"
  fi
else
  echo 'Calendar unchanged.'
fi
