package main

import (
	"fmt"
	"os"
	"time"
)

const (
	startYear = 2022
	endYear   = 2030
)

var (
	envs = []string{
		"dev",
		"sta",
		"prod",
		"uat",
	}

	targetPath = "../../envs/%s/17app/badge/monthlyVIP/%d"

	yamlContent = `# %d monthly VIP badge settings
#
# Format:
# UserID: badgeURL
`

	mdContent = `%d %s VIP下半月儲值獎勵`
)

func main() {
	for _, env := range envs {
		for i := startYear; i <= endYear; i++ {
			folder := fmt.Sprintf(targetPath, env, i)
			if err := os.Mkdir(folder, os.ModePerm); err != nil {
				panic(err)
			}

			for j := 1; j <= 12; j++ {
				// create a yaml file
				yamlPath := folder + "/" + fmt.Sprintf("%d.yaml", j)
				file, err := os.Create(yamlPath)
				if err != nil {
					panic(err)
				}

				if _, err := file.WriteString(
					fmt.Sprintf(yamlContent, i),
				); err != nil {
					file.Close()
					panic(err)
				}
				file.Close()

				// create a md file
				mdPath := folder + "/" + fmt.Sprintf("%d.md", j)
				file, err = os.Create(mdPath)
				if err != nil {
					panic(err)
				}

				if _, err := file.WriteString(
					fmt.Sprintf(mdContent, i, time.Month(j).String()),
				); err != nil {
					file.Close()
					panic(err)
				}
				file.Close()
			}
		}
	}
}
