# Nakama game config

## Promotion Rule
- enable(`bool`): Enable the promotion or not. Supported value: `true,false`
- enableTimeRange
    - startTime(`"YYYY-MM-DD hh:mm:ss (GMT+0800)"`): The start time of this promotion.
    - endTime(`"YYYY-MM-DD hh:mm:ss (GMT+0800)"`): The end time of this promotion.
- msgI18nKey(`string`): The i18n key of the message.
- actionTarget(`string`): The target of the action. Supported values: `game_center,fruitfarm`
- regionMode(`string`): The region mode. Supported value: `all,include,exlude`
- regions(`array of strings`): The IP regions.
- versionControl:
    - enable(`bool`): Enable version control or not. Supported value: `true,false`
    - ios(`string`): The minimum iOS version support.
    - android(`string`): The minimum Android version support.
