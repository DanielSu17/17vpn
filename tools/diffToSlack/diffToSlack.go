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
	reFilename := regexp.MustCompile("^diff --git a/([a-zA-Z0-9./]*)")
	lines := strings.Split(diff, "\n")
	filename := ""
	lastFilename := ""
	added := ""
	removed := ""
	attachments := []slack.Attachment{}
	// Scan diff content
	for _, line := range lines {
		// Get filename
		match := reFilename.FindStringSubmatch(line)
		if match != nil {
			filename = match[1]
			fmt.Println(filename)
		}

		// Next File send slack and reset
		if lastFilename != filename {
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
	// Handel last file
	if removed != "" {
		attachments = append(attachments, slack.Attachment{
			Pretext:  lastFilename,
			Fallback: removed,
			Text:     removed,
			Color:    colorDanger,
		})
	}
	if added != "" {
		attachments = append(attachments, slack.Attachment{
			Pretext:  lastFilename,
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
	commitMsg := fmt.Sprintf("[Misc] Update i18n\nslackUserID: %s\nslackUserEmail: %s", slackUserID, slackUserEmail)
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
			Fallback: "failed at " + strings.Join(displayCmd, " ") + "\nError: " + stderr.String(),
			Text:     "failed at " + strings.Join(displayCmd, " ") + "\nError: " + stderr.String(),
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
	api.PostMessage(slackUserID, options...)
}
