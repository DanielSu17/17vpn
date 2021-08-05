## SOP to deploy change of red envelopes
#### Steps:
01. PM defines change required for red envelopes and provides necessary resources
    - reference: https://docs.google.com/spreadsheets/d/1pknu-cqXg4WbBiPa8tuXBjJvMvSLMJoM8LKuGrqDk90/edit#gid=1316320567
02. Engineer updates the config
    - change redenvelope functionality with global scope
      - cases:
        - shut down & restart all red envelopes
        - change fraud prevention rules
      - should update [general settings](#General-Settings)
    - change single redenvelope settings
      - cases:
        - change red envelope styles for Chrismas or New Year, etc.
        - launch new redenvelopes
      - should update [redenvelope settings](#Redenvelope-Settings)
      - should test the UI changes for Android/IOS/Web in DEV/STAG environment
03. Engineer generate a report in JSON format in DEV/STAG environment
    - endpoint to generate report:   ```GET /api/v1/config/redenvelope```
04. PM review the related fields in the report and approve the change
    - [shut down & restart all red envelopes](#show-&-hide-all-red-envelopes)
      - region_mode
      - region
      - startTime
      - enfTime
    - [change red envelope styles for Chrismas or New Year, etc](#show-&-hide-a-single-redenvelope)
      - redenvelopes (setting for single redenvelope)
        - id
        - region_mode
        - region
        - startTime
        - endTime
    - [change fraud prevention setting](#fraud-prevention-2)
      - pickProbabilityThreshold
      - dailySumOfPickedRefreshHour
      - userLockPickedSecs
05. Engineer deploy the config to PROD
06. TODO: Configuration Notification via google calendar (before 2021/3/31)

## Introduction of Red Envelope Config
### General Settings
#### show & hide all red envelopes
* region_mode
    | enum   | definition |
    |:------:|:-----------|
    | 1      | ALL        |
    | 2      | INCLUDE    |
    | 3      | EXCLUDE    |
* regions(`array of string`): array of country codes
* startTime(`int`): show all redenvelopes after start time (unix timestamp)
* endTime(`int`): hide all redenvelopes after end time (unix timestamp), end time must be after start time

#### fraud prevention 1
Spec: https://17media.atlassian.net/browse/PROD-2702
- penalty: the user should waitfor X milliseconds before he/she can join the pick
* sumOfPickedThreshold(`int`): we start to increase penalty when sum the point an user picked exceed the threshold
* pickedSleepPenaltyMsecs(`int`): increase X milliseconds on penalty when an user successfully pick an redenvelope
* maxPenaltyMsecs(`int`): the max millisecond for penalty
* sumOfPickedTTLHours(`int`): reset sum of picked point if the user doesn't pick redenvelopes in X hours
#### fraud prevention 2
Spec: https://docs.google.com/document/d/1nfxPSvGakczo9ui2GmdAwzjYGMOy8mELw2LubcW7wJE
* pickProbabilityThresholds(`map[int]int`): hard cap of the probability to pick redenvelopes
  - X points (sum of points picked today) : Y % to join the pick
* dailySumOfPickedRefreshHour(`int`): the time to reset the sum of points (5 means 05:00 am GMT+08:00)
* userLockPickedSecs(`int`): an user can not get any new points in X seconds if he already got one.

### Redenvelope Settings
#### pointSets:
* id(`string`)
* point(`int32`): total points of an redenvelope
* revenuePoint(`int32`): revenue points for streamer, is usually 30% of point for non-system redenvelopes
* fee(`int32`): fee is usuall 5% of point for non-system redenvelopes
* package_list(`array of struct`): point packages for users to pick
  * point(`int32`)
  * amount(`int32`)
##### Note: point sets don't include the settings for customized redenvelopes
#### styleSets:
* id(`string`)
* marqueeAnimationID(`string`): the id of animation in front of the redenvelope marquee
* redenvelopeDialogURL(`string`): pop-up for redenvelope infos
* winnerDialogURL(`string`): pop-up for showing redenvelopes winners, usually the same as redenvelopeDialogURL
* buttonDecorationURL(`string`): the decoration on the top-right corner of the botton
* resultFailDialogURL(`string`): pop-up for users picked failed
* resultSuccessDialogURL(`string`): pop-up for users picked successfully
* resultAlreadyPickDialogURL(`string`): usually the same as resultSuccessDialogURL
* countdownIconURL(`string`): countdown icon in the stream room
* entryIconURL(`string`): entry icon on the hot page
* countBackgroundColor(`string`): color code of the dot on the countdown icon
* buttonTextColor(`string`): color code of the text on the botton on redenvelope dialog
* additionalTextAndButtonColor(`string`): color code of the botton on redenvelope dialog
#### redenvelopes
* id(`string`)
##### show & hide a single redenvelope
* region_mode:
    | enum   | definition |
    |:------:|:-----------|
    | 1      | ALL        |
    | 2      | INCLUDE    |
    | 3      | EXCLUDE    |
* regions(`array of string`): array of country codes
* startTime(`int64`): show the redenvelope after start time (unix timestamp)
* endTime(`int64`):  hide the redenvelope after end time (unix timestamp), end time must be after start time
* is_offline(`bool`): hide the redenvelope when is_offline is true
##### type and theme
* type:
    | enum   | definition | introduction                                                             |
    |:------:|:-----------|--------------------------------------------------------------------------|
    | 1      | NORMAL     | normal redenvelopes with fixed point set                                 |
    | 2      | CUSTOM     | creator can define the total point of the redenvelope                    |
    | 3      | SYSTEM     | redenvelopes created by system (refer to superstar config)               |
    | 4      | RECOMMEND  | creator can recommend another live room in the pop-up of the redenvelope |
* theme: (should be deprecated after client remove related logics)
    | enum   | definition |
    |:------:|:-----------|
    | 1      | NORMAL     |
    | 3      | SYSTEM     |
##### UI settings
* style(`string`): ID of style set
* name_token(`string`): i18n key of the redenvelope's name.
* img_URL(`string`): gift icon of the redenvelop
* zip_url(`string`): animation setting（Android）
* zip_md5(`string`): animation setting（Android）
* webp_url(`string`): animation setting（IOS）
* webp_md5(`string`): animation setting（IOS）
* webm_url(`string`): animation setting（Web）
* webm_md5(`string`): animation setting（Web）
##### point settings
###### Normal redenvelopes
* pointSetID(`string`): ID of point set
###### Customized redenvelopes
* minPoint(`int32`): the min point users can send in the customized redenvelope
* maxPoint(`int32`): the max point users can send in the customized redenvelope
* revenuePoint(`int32`): the percentage of revenue point for streamer
* fee(`int32`): the percentage of fee
* package_list(`array of struct`): point packages for users to pick
  * point(`int32`)
  * amount(`int32`)
##### others
* countdown_time(`int64`): count down time (second) before users can pick the redenvelope
* event_time(`int64`): event time (second) for users to pick the redenvelope
* announceable(`bool`): whether the creator can choose to send a redenvelope marquee
* announce_threshold(`int`): for customized redenvelopes, the creator can choose to send a redenvelope marquee when the customized points exceed announce threshold
