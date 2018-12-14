package main

import (
	"bytes"
	"fmt"
	"log"
	"os"
	"os/exec"
	"regexp"
	"strings"

	"github.com/nlopes/slack"
	"github.com/urfave/cli"
)

const (
	gitURL    = "git@github.com:17media/configs.git"
	gitBranch = "update-i18n"
)

var (
	slackUserID    string
	slackUserEmail string
	slackToken     string
	confirm        string
	env            string
	colorDanger    = "danger"
	colorGood      = "good"
)

func main() {
	app := cli.NewApp()
	app.Flags = []cli.Flag{
		cli.StringFlag{
			Name:   "env",
			EnvVar: "ENV",
		},
		cli.StringFlag{
			Name:   "slackUserID",
			EnvVar: "SLACK_USER_ID",
		},
		cli.StringFlag{
			Name:   "slackUserEmail",
			EnvVar: "SLACK_USER_EMAIL",
		},
		cli.StringFlag{
			Name:   "slackToken",
			EnvVar: "SLACK_TOKEN",
		},
		cli.StringFlag{
			Name:   "confirm",
			EnvVar: "CONFIRM",
		},
	}
	app.Action = func(c *cli.Context) error {
		confirm = c.String("confirm")
		env = c.String("env")
		if env == "" {
			log.Fatal("Repeated EnvVar: ENV")
		}
		slackUserID = c.String("slackUserID")
		if slackUserID == "" {
			log.Fatal("Repeated EnvVar: SLACK_USER_ID")
		}
		slackUserEmail = c.String("slackUserEmail")
		if slackUserEmail == "" {
			log.Fatal("Repeated EnvVar: SLACK_USER_EMAIL")
		}
		slackToken = c.String("slackToken")
		if slackToken == "" {
			log.Fatal("Repeated EnvVar: SLACK_TOKEN")
		}

		if confirm == "" {
			gitDiff()
		} else {
			mergePush()
		}
		return nil
	}
	app.Run(os.Args)
}

func checkDiff(removed, added string) []string {
	checkFailKeys := []string{}
	addedMap := parseKeyVal(added)
	removedMap := parseKeyVal(removed)
	for key, val := range addedMap {
		oldVal, exists := removedMap[key]
		// not exists, new key, pass
		if !exists {
			continue
		}
		// if oldval is empty string
		// always happend when new created key, pass
		if oldVal == "" {
			continue
		}
		// IOS
		if !checkParamCount("%[0-9]*\\$@", oldVal, val) {
			checkFailKeys = append(checkFailKeys, key)
			continue
		}
		// ANDROID
		if !checkParamCount("%[0-9]*\\$s", oldVal, val) {
			checkFailKeys = append(checkFailKeys, key)
			continue
		}
		// Backend
		if !checkParamCount("\\$[0-9]*", oldVal, val) {
			checkFailKeys = append(checkFailKeys, key)
			continue
		}
	}
	return checkFailKeys
}

func checkParamCount(re, oldVal, val string) bool {
	reParam := regexp.MustCompile(re)
	oldParam := reParam.FindAllStringSubmatch(oldVal, -1)
	newParam := reParam.FindAllStringSubmatch(val, -1)
	if len(oldParam) != len(newParam) {
		return false
	}
	return true
}

func parseKeyVal(input string) map[string]string {
	result := map[string]string{}
	list := strings.Split(input, "\n")
	reKeyVal := regexp.MustCompile("\"([^\"]*)\": \"([^\"]*)\"")
	for _, item := range list {
		match := reKeyVal.FindStringSubmatch(item)
		if match == nil {
			continue
		}
		result[match[1]] = match[2]
	}
	return result
}

func gitDiff() {

	folder := fmt.Sprintf("configs_%s", slackUserID)
	// If folder exists, remove it
	if _, err := os.Stat(folder); !os.IsNotExist(err) {
		execCommand("./", "rm", []string{"-fr", folder})
	}

	// git clone
	execCommand("./", "git", []string{"clone", gitURL, folder})

	// checkout branch
	execCommand(folder, "git", []string{"checkout", "-b", gitBranch})

	// Update i18n
	execCommand(folder+"/tools", "python", []string{"update_i18n.py", env})

	// Run git diff
	diff, _ := execCommand(folder, "git", []string{"diff"})

	// Prepare variable
	// parse filename from `diff --git a/envs/prod/17app/i18n/en_us/android.json b/envs/prod/17app/i18n/en_us/android.json`
	reFilename := regexp.MustCompile("^diff --git a/([a-zA-Z0-9./_]*)")
	lines := strings.Split(diff, "\n")
	filename := ""
	lastFilename := ""
	added := ""
	removed := ""
	fileEnv := ""
	attachments := []slack.Attachment{}
	failKeysList := map[string][]string{}
	// Scan diff content
	for _, line := range lines {
		// Get filename
		match := reFilename.FindStringSubmatch(line)
		if match != nil {
			filename = match[1]
			fmt.Println(filename)
			fileEnv = strings.Split(filename, "/")[1]
		}
		if env == "all" {
			// only process prod if we update all envs
			if fileEnv != "prod" {
				continue
			}
		}

		// Next File send slack and reset
		if lastFilename != filename {
			// Check diff for this file
			failKeysList[lastFilename] = checkDiff(removed, added)
			pretext := lastFilename
			if removed != "" {
				attachments = append(attachments, slack.Attachment{
					Pretext:  pretext,
					Fallback: removed,
					Text:     removed,
					Color:    colorDanger,
				})
				pretext = ""
				removed = ""
			}
			if added != "" {
				attachments = append(attachments, slack.Attachment{
					Pretext:  pretext,
					Fallback: added,
					Text:     added,
					Color:    colorGood,
				})
				added = ""
			}

		}

		// Aggregate
		if len(line) > 2 && line[:2] == "+ " {
			added += line[2:] + "\n"
		}
		if len(line) > 2 && line[:2] == "- " {
			removed += "~" + line[2:] + "~\n"
		}

		lastFilename = filename
	}
	pretext := lastFilename
	// Handel last file
	if removed != "" {
		attachments = append(attachments, slack.Attachment{
			Pretext:  pretext,
			Fallback: removed,
			Text:     removed,
			Color:    colorDanger,
		})
		pretext = ""
	}
	if added != "" {
		attachments = append(attachments, slack.Attachment{
			Pretext:  pretext,
			Fallback: added,
			Text:     added,
			Color:    colorGood,
		})
	}
	// Handle nothing to update
	if len(attachments) == 0 {
		attachments = append(attachments, slack.Attachment{
			Fallback: "nothing to update",
			Text:     "nothing to update",
			Color:    colorGood,
		})
	} else {
		validateFail := false
		for filename, failKeys := range failKeysList {
			if len(failKeys) != 0 {
				validateFail = true
				attachments = append(attachments, slack.Attachment{
					Pretext:  filename,
					Fallback: fmt.Sprintf("key: %s validate failed\nnumber of params mismatch", strings.Join(failKeys, ", ")),
					Text:     fmt.Sprintf("key: %s validate failed\nnumber of params mismatch", strings.Join(failKeys, ", ")),
					Color:    colorDanger,
				})
			}
		}
		if validateFail {
			// Append button
			attachments = append(attachments, slack.Attachment{
				Fallback:   "You are unable to continue",
				Text:       "Are you sure to *FORCE* update this diff?",
				CallbackID: "updateI18n",
				Color:      colorDanger,
				Actions: []slack.AttachmentAction{
					slack.AttachmentAction{
						Name:  "i18n confirm",
						Text:  "*FORCE* Update",
						Type:  "button",
						Value: "update",
					},
				},
			})
		} else {
			// Append button
			attachments = append(attachments, slack.Attachment{
				Fallback:   "You are unable to continue",
				Text:       "commit this diff?",
				CallbackID: "updateI18n",
				Color:      "#3AA3E3",
				Actions: []slack.AttachmentAction{
					slack.AttachmentAction{
						Name:  "i18n confirm",
						Text:  "Update",
						Type:  "button",
						Value: "update",
					},
				},
			})
		}
	}
	sendSlack(attachments)
}

func mergePush() {
	folder := fmt.Sprintf("configs_%s", slackUserID)
	// if folder not exists, skip
	if _, err := os.Stat(folder); os.IsNotExist(err) {
		attachments := []slack.Attachment{slack.Attachment{
			Fallback: "data miss, please restart update",
			Text:     "data miss, please restart update",
			Color:    colorDanger,
		}}
		sendSlack(attachments)
		log.Fatal("data miss, bye")
	}
	execCommand(folder, "git", []string{"add", "."})
	// setting commit message
	// slackUserID is used to metion user in slack deployment message at pushToEctd.go
	// nslackUserEmail is used to let people know who did this commit
	commitMsg := fmt.Sprintf("[Misc] Update i18n\nslackUserEmail: %s\nslackUserID: %s", slackUserEmail, slackUserID)
	execCommand(folder, "git", []string{"commit", "-m", commitMsg})

	execCommand(folder, "git", []string{"checkout", "master"})

	execCommand(folder, "git", []string{"merge", gitBranch})

	execCommand(folder, "git", []string{"push", "origin", "master"})

	execCommand("./", "rm", []string{"-fr", folder})

	attachments := []slack.Attachment{slack.Attachment{
		Fallback: "i18n pushed to github\n should be apply in few minutes",
		Text:     "i18n pushed to github:tada:\n should be apply in few minutes:happy:",
		Color:    colorGood,
	}}
	sendSlack(attachments)
}

func execCommand(dir, commands string, args []string) (string, string) {
	var out bytes.Buffer
	var stderr bytes.Buffer

	displayCmd := append([]string{dir, commands}, args...)
	fmt.Println(displayCmd)
	cmd := exec.Command(commands, args...)
	cmd.Dir = dir
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		attachments := []slack.Attachment{slack.Attachment{
			Fallback: "Update fail, please try restart again.\nfailed at " + strings.Join(displayCmd, " ") + "\nError: " + stderr.String(),
			Text:     "Update fail, please try restart again.\nfailed at " + strings.Join(displayCmd, " ") + "\nError: " + stderr.String(),
			Color:    colorDanger,
		}}
		sendSlack(attachments)
		log.Fatal(fmt.Sprint(err) + ": " + stderr.String())
	}
	return out.String(), stderr.String()
}

func sendSlack(attachments []slack.Attachment) {
	api := slack.New(slackToken)
	options := []slack.MsgOption{
		slack.MsgOptionAttachments(attachments...),
		slack.MsgOptionAsUser(true),
	}
	_, _, err := api.PostMessage(slackUserID, options...)
	if err != nil {
		log.Fatal(err)
	}
}
