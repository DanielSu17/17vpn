# Custom Welcome

## Purpose
The concept here is to enable sending a message to a user that is specific _to a
streamer's region_ but is translated to _the user's language_ when the user enters the streamer's
room.

This config has two main sections, `regionMap` and `regionmessages`.

JIRA: https://17media.atlassian.net/browse/PROD-4686

## regionMap

This allows an operator to treat a region as if it's part of another region.

### Example

```yaml
regionMap:
  MY: TW
  SG: TW
```
This means "MY should use the TW config, also, SG should use the message config."

## regionMessages

This section is where messages are configured for each region.

The structure of this config is _similar_ to the config for `system_message` but with a significant
difference. In this config, we use the **region code** as the key for each section, instead of a
**language code**.

###Example

This example config shows that the TW region is configured with two (2) different scheduled messages.
Messages whose time ranges overlap are _considered invalid and will be ignored_.

```yaml
regionMessages:
  TW:
    - msgToken: TW_custom_welcome_001
      defaultLanguage: TW
      startTime: 2017-07-31T00:00:00+08:00
      endTime: 2017-08-25T00:00:00+08:00
    - msgToken: TW_custom_welcome_002
      defaultLanguage: TW
      startTime: 2017-09-31T00:00:00+08:00
      endTime: 2017-10-25T00:00:00+08:00
```

###Message Config Details

| Property | Example | Purpose |
|----------|---------|---------|
| msgToken | TW_custom_welcome_001 | A Lokalise string |
| defaultLanguage | TW | The default language that will be used if there is no registered string for the user's language |
| startTime | 2017-09-31T00:00:00+08:00 | The time at which the message should _start_ being displayed |
| endTime | 2017-10-31T00:00:00+08:00 | The time at which the message should _stop_ being displayed |

###Rules
- Time ranges for messages in a region _cannot overlap_
- `msgToken` values must be set up in the Lokalise localization system
- If there's no message for a user's language, the message in `defaultLanguage` will be returned
- The `msgToken` entry in Lokalise should have a translation registered for `defaultLanguage`
- Always confirm time format is accurate, use 2 digits for months and dates
    - Bad: 2017-7-31T00:00:00+08:00 (should be 07, not 7)
    - Good: 2017-07-31T00:00:00+08:00 (should be 07, not 7)
