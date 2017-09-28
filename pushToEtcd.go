package main

import (
	"bytes"
	"fmt"
	"log"
	"os"
	"os/exec"
	"regexp"
	"strings"

	slack "github.com/17media/slack-go-webhook"
	"github.com/urfave/cli"
)

const (
	gitURL      = "git@github.com:17media/configs.git"
	dockerImage = "17media/pusher-alpine:v1.7-a"
	service     = "Configs"
)

var (
	envs            []string
	commitID        string
	slackURL        string
	githubURL       string
	ensembleIPsSTA  string
	ensembleIPsProd string
)
var ensembleIPs = map[string]string{
	"prod": "http://35.167.6.207:2379,http://35.167.24.50:2379,http://34.212.183.219:2379",
	"sta":  "http://10.11.2.154:2379",
}

type notification struct {
	text  string
	color string
}

func main() {
	app := cli.NewApp()
	app.Flags = []cli.Flag{
		cli.StringFlag{
			Name:   "ensembleIPsSTA",
			EnvVar: "ENSEMBLEIPS_STA",
		},
		cli.StringFlag{
			Name:   "ensembleIPsProd",
			EnvVar: "ENSEMBLEIPS_PROD",
		},
		cli.StringFlag{
			Name:   "env",
			EnvVar: "ENV",
		},
		cli.StringFlag{
			Name:   "docker_user",
			EnvVar: "DOCKER_USER",
		},
		cli.StringFlag{
			Name:   "docker_pass",
			EnvVar: "DOCKER_PASS",
		},
		cli.StringFlag{
			Name:   "docker_email",
			EnvVar: "DOCKER_EMAIL",
		},
		cli.StringFlag{
			Name:   "slack_url",
			EnvVar: "SLACK_URL",
		},
		cli.StringFlag{
			Name: "commit_id",
		},
	}
	app.Action = func(c *cli.Context) error {
		ensembleIPsSTA = c.String("ensembleIPsSTA")
		ensembleIPsProd = c.String("ensembleIPsProd")
		slackURL = c.String("slack_url")
		if slackURL == "" {
			log.Fatal("Repeated EnvVar: SLACK_URL")
		}

		dockerUser := c.String("docker_user")
		if dockerUser == "" {
			log.Fatal("Repeated EnvVar: DOCKER_USER")
		}

		dockerPass := c.String("docker_pass")
		if dockerPass == "" {
			log.Fatal("Repeated EnvVar: DOCKER_PASS")
		}

		dockerEmail := c.String("docker_email")
		if dockerEmail == "" {
			log.Fatal("Repeated EnvVar: DOCKER_EMAIL")
		}

		commitID = c.String("commit_id")
		if commitID == "" {
			log.Fatal("Repeated parameters: --commit_id")
		}
		githubURL = fmt.Sprintf("https://github.com/17media/configs/commit/%s", commitID)
		// checkGitURL()
		dockerLogin(dockerEmail, dockerUser, dockerPass)
		envs = gitDiff()
		for i := range envs {
			fmt.Printf("%s", returnEnsembleIPs(envs[i]))
			// startPush(dockerEmail, dockerUser, dockerPass, envs[i], returnEnsembleIPs(envs[i]))
		}
		return nil
	}

	app.Run(os.Args)
}
func returnEnsembleIPs(env string) string {
	if env == "prod" {
		if ensembleIPsProd != "" {
			return ensembleIPsProd
		}
	} else {
		if ensembleIPsSTA != "" {
			return ensembleIPsSTA
		}
	}
	return ensembleIPs[env]
}

func checkGitURL() {
	command := "config --get remote.origin.url"
	cmd := exec.Command("git", strings.Split(command, " ")...)
	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	err := cmd.Run()
	if err != nil {
		log.Fatal(fmt.Sprint(err) + ": " + stderr.String())
	}
	output := strings.Replace(out.String(), "\n", "", -1)
	if output != gitURL {
		log.Fatal(fmt.Sprintf("your git remote url is %s, but git remote origin need %s", output, gitURL))
	}
}

func startPush(dockerEmail string, dockerUser string, dockerPass string, env string, ensembleIPs string) {
	postSlack(notification{fmt.Sprintf("Deployment begins.\n *Environment*: %s, *Service*: %s\n *Commit*: %s *(<%s|Github>)*", env, service, commitID, githubURL), "#f4a142"}, env)
	pushToEtcd(ensembleIPs, env)
	postSlack(notification{fmt.Sprintf("*%s %s* deployment succeed.", env, service), "good"}, env)
}

func postSlack(n notification, env string) {
	attachment := slack.Attachment{}
	attachment.MrkdwnIn = []string{"fallback", "text"}
	attachment.Color = &n.color
	attachment.Fallback = &n.text
	attachment.Text = &n.text

	payload := slack.Payload{
		Username:    "deployment",
		Channel:     "#dev-event-" + env,
		IconEmoji:   ":snowboarder:",
		Attachments: []slack.Attachment{attachment},
	}
	err := slack.Send(slackURL, "", payload)
	if len(err) > 0 {
		fmt.Printf("error: %s\n", err)
	}
}

func dockerLogin(email string, user string, pwd string) {
	cmd := fmt.Sprintf("login -u %s -p %s", user, pwd)
	dockerCommand(cmd, "Init")
}

func pushToEtcd(etcdIPs string, env string) {
	cmd := fmt.Sprintf("run --rm -e ENVID=%s -e PROJID=17app "+
		"-e COMMITID=%s -e ENSEMBLE=%s %s", env, commitID, etcdIPs, dockerImage)
	dockerCommand(cmd, env)
}

func dockerCommand(command string, env string) {
	outputLog(fmt.Sprintf("Start Execute docker %s", command))
	cmd := exec.Command("docker", strings.Split(command, " ")...)
	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	err := cmd.Run()
	if err != nil {
		msg := fmt.Sprintf("Deployment failed.\n Error: %s",
			stderr.String())
		postSlack(notification{msg, "danger"}, env)
		log.Fatal(fmt.Sprint(err) + ": " + stderr.String())
	}
	fmt.Println("Result: " + out.String())
}

func outputLog(content string) {
	fmt.Println(fmt.Sprintf("====================> %s", content))
}

func gitDiff() []string {
	envs := []string{}
	command := fmt.Sprintf("diff-tree --no-commit-id --name-only -r %s", commitID)
	outputLog(fmt.Sprintf("Start Execute Git %s", command))
	cmd := exec.Command("git", strings.Split(command, " ")...)
	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	err := cmd.Run()
	if err != nil {
		log.Fatal(fmt.Sprint(err) + ": " + stderr.String())
	}

	r := regexp.MustCompile("envs/(prod|sta)")
	m := r.FindAllStringSubmatch(out.String(), -1)

	for _, s := range m {
		envs = append(envs, s[1])
	}
	return removeDuplicates(envs)
}
func removeDuplicates(elements []string) []string {
	encountered := map[string]bool{}
	result := []string{}

	for v := range elements {
		if encountered[elements[v]] != true {
			encountered[elements[v]] = true
			result = append(result, elements[v])
		}
	}
	return result
}
