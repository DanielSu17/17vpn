# HK Survey Locations
This the In-App Survey "locations" config for the HK region. 

A *location* is a place in one of the clients that a survey should appear in. It also defines everything the client needs to know about timing, and display behavior for the survey in this location. 

For example, if we wanted to have a survey appear on the first slot of hotpage_v3, we might name the location `hotpagev3_slot1`  

**IMPORTANT: A survey location name must be unique!**

## Parameters

| Property | Type | Example | Description |
|:---------|:-----|:--------|:------------|
| `surveyID`   | `string`        | "CSAT-20220115" | This is ID of the survey that should be shown in this location. You can see currently defined surveys in the `survey.yaml` config. |
| `campaignID` | `string`        | "cfc92106-fd8c-4ae6-b63d-e838edc08171"| An identifier for this run of the survey. See: `startTime` and `endTime`. Recommend using [a UUID generator](https://www.uuidgenerator.net/version4), as it can be considered be unique string. |
| `enabled`    | `bool`          | true | A circuit breaker option that will disable the survey, even if the current time is between `startTime` and `endTime`|
| `startTime`  | `string`        | "2022-01-01T12:00:00+08:00" | When the survey should start at GMT+8. The date format has 3 parts, the date, the time, and the timezone. The example string parts would be "2022-01-01" for date, "T12:00:00" for time, and "+08:00" for timezone. |
| `endTime`  | `string`        | "2022-06-25T12:00:00+08:00" | When the survey should stop at GMT+8. Formatting is the same as `startTime` |
| `displayFrequency` | `int` | 2592000 | A length of time in Seconds. How much time should pass before showing a new Main Question and a new Follow Question for the defined `surveyID` (See: `survey.yaml`). Note: A month has 2592000 seconds.|
| `displayDuration` | `int` | 648000 | A length of time in Seconds. How many seconds between survey display runs. Note: 648000 = 2592000 (a month of seconds)/4 = a week |
| `userPercentage` | `int` | 10 | A percentage represented as number between 0 and 100. A value of 10 means that 10% of users will be presented the survey if they are within the `displayDuration` window of an active survey run. |


## Example Config
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

## Timing Diagram
Here's how the various config values are used to define a location's timing and display behavior.

![How the location config defines timing behavior](https://cdn.17app.co/7bef450a-7535-4da2-9885-ff2ca9dccefd.png)

## Github Path
envs/sta/17app/survey/HK_locations.yaml

