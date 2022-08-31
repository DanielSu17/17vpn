# Nakama game config

## Common setting
- enableIconAnimation(`bool`): Enable the icon animation or not. Supported value: `true,false`
- regionGameOrder(`dictionary`): Define the game order for each IP region. The gameID used in the order list should be one of the keys in games rule section. The example for each item: `[IP region]: [array of strings]`
    - e.g.,
        ```
        regionGameOrder:
          TW:
            - "fruitfarm"
            - "luxurydice"
          JP:
            - "fruitfarm"
        ```

- games(`dictionary`): Define the game info used in the game center. The key is the gameID, check the [Game Info Rule Section](#Game-Info-Rule) for the details of each field.
    - e.g,
        ```
        games:
            fruitfarm:
                enable: true
                icon: "http://cdn.17app.co/b509416d-c234-4f03-a4a7-f13c24939aef.png"
                url: "https://17live-game-sta/fruitfarm/"
                webViewBgColor: "#ffecba"
                nameI18nkey: "ff_name_key"
                descI18nkey: "ff_desc_key"
                versionControl:
                    enable: false
                    ios: "3.126.0"
                    android: "2.41.0"
        ```

## Promotion Rule
- enable(`bool`): Enable the promotion or not. Supported value: `true,false`
- enableTimeRange
    - startTime(`"YYYY-MM-DD hh:mm:ss (GMT+0800)"`): The start time of this promotion.
    - endTime(`"YYYY-MM-DD hh:mm:ss (GMT+0800)"`): The end time of this promotion.
- msgI18nKey(`string`): The i18n key of the message.
- actionTarget(`string`): The target of the action. Supported values: `game_center,fruitfarm`
- regionMode(`string`): The region mode. Supported value: `all,include,exlude`
- regions(`array of strings`): The IP regions. Would be good to use two-letter country code. e.g. `[TW, ID, TH, HK, SG, MO, MY, JP, PH, VN, MM]`
- versionControl:
    - enable(`bool`): Enable version control or not. Supported value: `true,false`
    - ios(`string`): The minimum iOS version support.
    - android(`string`): The minimum Android version support.

## Game Info Rule
- enable(`bool`): Enable the game or not. Supported value: `true,false`
- icon(`string`): The url of the game icon.
- url(`string`): The url of the game.
- webViewBgColor(`string`): The background color of the webview for the game.
- nameI18nkey(`string`): The i18n key of the game name.
- descI18nkey(`string`): The i18n key of the game description.
- versionControl:
    - enable(`bool`): Enable version control or not. Supported value: `true,false`
    - ios(`string`): The minimum iOS version support.
    - android(`string`): The minimum Android version support.
