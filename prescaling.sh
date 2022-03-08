#!/bin/bash
set -euxo pipefail

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
# start_time - 30m
_start=$(TZ=Asia/Taipei date -d "$start_date $start_time" +%s)
start=$(TZ=Asia/Taipei date -d @$(($_start - 30 * 60)) '+%F %T')
# end_time + 1hr
_end=$(TZ=Asia/Taipei date -d "$end_date $end_time" +%s)
end=$(TZ=Asia/Taipei date -d @$(($_end + 1 * 60 * 60)) '+%F %T')

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
done < events.txt

branch="prescaling_$today"

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

if [[ $(git diff --stat) != '' ]];
then
  sudo apt update
  sudo apt install gh
  git config --global user.email "no-reply@17.media"
  git config --global user.name "github-actions-bot"
  git commit -am "[Infra] GKE prescaling for Google Calendar events [skip ci]"
  git push --set-upstream origin $branch
  pr_url=$(gh pr create --title "[Infra] GKE prescaling" --body $today)
  curl -X POST --data-urlencode "payload={\"channel\": \"#eng-sre-log\", \"username\": \"prescaling\", \"text\": \"PR Created\n $pr_url \", \"icon_emoji\": \":jp:\"}" "$SLACK_WEBHOOK_URI"
else
  echo 'Calendar unchanged.'
fi
