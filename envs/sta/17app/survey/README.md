# In-App Survey Ops Config Manual
The In-App Survey system has two main parts from the config perspective, locations, and surveys.

## Locations
A *location* is a place in one of the clients that a survey can appear in. It also defines everything the client needs to know about timing, and display behavior for the survey in this location.

For example, if we wanted to have a survey appear on the first slot of hotpage_v3 in a region, we might name the location `hotpagev3_slot1`

Each region can have its own list of locations.

**IMPORTANT: A survey location name must be unique!**

### Location Parameters

| Property            | Type | Example                                | Description                                                                                                                                                                                                                                                                                           |
|:--------------------|:-----|:---------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `surveyID`          | `string`        | "CSAT-20220115"                        | This is ID of the survey that should be shown in this location. You can see currently defined surveys in the `survey.yaml` config.                                                                                                                                                                    |
| `campaignID`        | `string`        | "cfc92106-fd8c-4ae6-b63d-e838edc08171" | An identifier for this run of the survey. See: `startTime` and `endTime`. Recommend using [a UUID generator](https://www.uuidgenerator.net/version4), as it can be considered be unique string.                                                                                                       |
| `enabled`           | `bool`          | true                                   | A circuit breaker option that will disable the survey, even if the current time is between `startTime` and `endTime`                                                                                                                                                                                  |
| `startTime`         | `string`        | "2022-01-01T12:00:00+08:00"            | When the survey should start at GMT+8. The date format has 3 parts, the date, the time, and the timezone. The example string parts would be "2022-01-01" for date, "T12:00:00" for time, and "+08:00" for timezone.                                                                                   |
| `endTime`           | `string`        | "2022-06-25T12:00:00+08:00"            | When the survey should stop at GMT+8. Formatting is the same as `startTime`                                                                                                                                                                                                                           |
| `displayFrequency`  | `int` | 2592000                                | A length of time in Seconds. How much time should pass before showing a new Main Question and a new Follow Question for the defined `surveyID` (See: `survey.yaml`). Note: A month has 2592000 seconds.                                                                                               |
| `displayDuration`   | `int` | 648000                                 | A length of time in Seconds. How many seconds between survey display runs. Note: 648000 = 2592000 (a month of seconds)/4 = a week                                                                                                                                                                     |
| `userPercentage`    | `int` | 10                                     | A percentage represented as number between 0 and 100. A value of 10 means that 10% of users will be presented the survey if they are within the `displayDuration` window of an active survey run. This field will be deprecated after the new logic applied with `displayGroupCount`.                 |
| `displayGroupCount` | `int` | 10                                     | A number to set how many groups the users separated. A value of 10 means that users will be separated into 10 groups and only the user with the display group matched the current display group will be presented the survey if they are within the `displayDuration` window of an active survey run. |


### Example Locations Config
```yaml
hotpagev3_slot1:
  surveyID: "CSAT-20220115"                           # A particular survey can be used in more than one location...
  campaignID: "cfc92106-fd8c-4ae6-b63d-e838edc08171"  # but the campaignID should be unique
  enabled: true
  startTime: "2022-01-01T12:00:00+08:00"
  endTime: "2022-06-25T12:00:00+08:00"
  displayFrequency: 1296000   # Time in Seconds. 2592000 = 1 month, so 2592000/2 = 2 weeks = Refresh the survey in 2 weeks
  displayDuration: 648000     # Time in Seconds. 2592000 = 1 month, so 2592000/4 = 1 week = Show the survey for the first week
  userPercentage: 100         # Show the survey to 100% of users for the displayDuration period, a value we used for testing    

my_other_location:
  surveyID: "CSAT-20220115"                             # A particular survey can be used in more than one location...
  campaignID: "5d43192e-b45b-42c1-8046-546cfa916d20"    # but the campaignID should be unique
  enabled: true
  startTime: "2022-01-01T12:00:00+08:00"
  endTime: "2022-06-25T12:00:00+08:00"
  displayFrequency: 2592000   # Seconds. 2592000 = 1 month = Refresh the survey in 1 month
  displayDuration: 648000     # Seconds. 2592000/4 = 1 week = Show the survey for the first
  userPercentage: 10          # Show the survey to 10% of users for the displayDuration period
```

### Timing Diagram
Here's how the various config values are used to define a location's timing and display behavior.

![How the location config defines timing behavior](https://cdn.17app.co/7bef450a-7535-4da2-9885-ff2ca9dccefd.png)

### Github Path
envs/sta/17app/survey/locations.yaml

## Surveys
There is a single config that contains information about the surveys themselves, and they can be used in any location in any region. The survey config file can be found at `configs/envs/<line>/survey/survey.yaml`

An in-app survey is a defined by a single "main question", and a list of possible "follow questions". Each question gives the user the ability to register a rating from 1-5, and follow questions have an additional "checkmark" option that will end that question set.

The use case for our initial launch will be an Overall Customer Satisfaction rating (the CSAT rating), followed by a request for the user to rate a particular feature. The "option" aspect of the follow question, indicates the user "has never used the feature".

Each survey is referenced by a survey ID key. For example: CSAT-20220115

IMPORTANT: A survey ID must be unique!

### Survey Parameters
| Property | Type | Example | Description |
|:---------|:-----|:--------|:------------|
| `thanksToken` | string | "inapp_csat_feature_survey_thankyou_toast" | A Lokalize token used for providing the final "Thanks" message for users who have filled out a survey |
| `mainQuestion` | Question Object | see Question Structure below | The definition of the main question |
| `followQuestions` | array of Question Objects | array of Questions: see Question Structure below | The list of follow questions that will be chosen from when a follow question is shown |

### Question Parameters
*Main Question* and *Follow Question* objects have the same structure.

| Property | Type | Example | Description |
|:---------|:-----|:--------|:------------|
| `id`       | string | "CSAT-20220115-A001" | A unique string associated with this particular question |
| `type`     | int    | 1 | An integer indicating what type of question this is. 0 = 1-5 rating only (main question), 1 = 1-5 rating + option toggle (follow question) |
| `questionToken` | string | "inapp_csat_overall_survey" | A Lokalize token used for providing translated questions (e.g. "How do you like 17 Live?") |
| `optionToken`   | string | "inapp_csat_feature_survey_question_1" | A Lokalize token used for providing translated option labels (e.g. "I have never used this feature") |

### Example Survey Config
```yaml
# Q1 2022 Overall + Multiple Feature Follow-Up Questions
CSAT-20220115:
  thanksToken: "inapp_csat_feature_survey_thankyou_toast"
  mainQuestion: # Must be answered or skipped before follow questions are displayed
    id: "CSAT-20220115-A001"
    type: 0 # Rating 1-5
    questionToken: "inapp_csat_overall_survey"
  followQuestions: # Can only be displayed after required questions answered or skipped
    - id: "CSAT-20220115-B001"
      type: 1 # Rating 1-5 + option toggle
      questionToken: "inapp_csat_feature_survey_question_1"
      optionToken: "CSAT_inapp_csat_feature_survey_question_nerveruse_1"
    - id: "CSAT-20220115-B002"
      type: 1 # Rating 1-5 + option toggle
      questionToken: "inapp_csat_feature_survey_question_2"
      optionToken: "CSAT_inapp_csat_feature_survey_question_nerveruse_2"
    - id: "CSAT-20220115-B003"
      type: 1 # Rating 1-5 + option toggle
      questionToken: "inapp_csat_feature_survey_question_3"
      optionToken: "CSAT_inapp_csat_feature_survey_question_nerveruse_3"
    - id: "CSAT-20220115-B004"
      type: 1 # Rating 1-5 + option toggle
      questionToken: "inapp_csat_feature_survey_question_4"
      optionToken: "CSAT_inapp_csat_feature_survey_question_nerveruse_4"
    - id: "CSAT-20220115-B005"
      type: 1 # Rating 1-5 + option toggle
      questionToken: "inapp_csat_feature_survey_question_5"
      optionToken: "CSAT_inapp_csat_feature_survey_question_nerveruse_5"
    - id: "CSAT-20220115-B006"
      type: 1 # Rating 1-5 + option toggle
      questionToken: "inapp_csat_feature_survey_question_6"
      optionToken: "CSAT_inapp_csat_feature_survey_question_nerveruse_6"
    - id: "CSAT-20220115-B007"
      type: 1 # Rating 1-5 + option toggle
      questionToken: "inapp_csat_feature_survey_question_7"
      optionToken: "CSAT_inapp_csat_feature_survey_question_nerveruse_7"
    - id: "CSAT-20220115-B008"
      type: 1 # Rating 1-5 + option toggle
      questionToken: "inapp_csat_feature_survey_question_8"
      optionToken: "CSAT_inapp_csat_feature_survey_question_nerveruse_8"
    - id: "CSAT-20220115-B009"
      type: 1 # Rating 1-5 + option toggle
      questionToken: "inapp_csat_feature_survey_question_9"
      optionToken: "CSAT_inapp_csat_feature_survey_question_nerveruse_9"
    - id: "CSAT-20220115-B010"
      type: 1 # Rating 1-5 + option toggle
      questionToken: "inapp_csat_feature_survey_question_10"
      optionToken: "CSAT_inapp_csat_feature_survey_question_nerveruse_10"
```

For questions, please contact David Smith (PJM HQ) or John O'Connor (HQ ENG)
