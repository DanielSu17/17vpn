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

- games(`dictionary`): Define the game info used in the game center. The key is used for mapping the regionOrder array in the `regionPromotion`, check the [Game Info Rule Section](#Game-Info-Rule) for the details of each field.
    - e.g,
        ```
        games:
            fruitfarm:
                enable: true
                gameID: "fruitfarm"
                icon: "http://cdn.17app.co/b509416d-c234-4f03-a4a7-f13c24939aef.png"
                url: "https://17live-game-sta/fruitfarm/"
                webViewBgColor: "#ffecba"
                nameI18nkey: "ff_name_key"
                descI18nkey: "ff_desc_key"
                tippingGift:
                  enable: true
                  triggerPoint: 1000
                  giftInfo:
                    regular:
                    - id: red_envelope
                    - id: flower
                    special:
                      blueberry:
                        id: va
                      pineapple:
                        id: gift_newyear_red_o
                      strawberry:
                        id: va2
                versionControl:
                    enable: false
                    ios: "3.126.0"
                    android: "2.41.0"
        ```

- regionPromotion(`dictionary`): Define the promotion for each IP region. The key is IP region, check the [Region Promotion Rule Section](#Region-Promotion-Rule) for the details of each field.

## Region Promotion Rule
- enable(`bool`): Enable the promotion or not. Supported value: `true,false`
- enableTimeRange
    - startTime(`"YYYY-MM-DD hh:mm:ss (GMT+0800)"`): The start time of this promotion.
    - endTime(`"YYYY-MM-DD hh:mm:ss (GMT+0800)"`): The end time of this promotion.
- msgI18nKey(`string`): The i18n key of the message.
- actionTarget(`string`): The target of the action. Supported values: `gamecenter` or any gameID used in the game order list.
- versionControl:
    - enable(`bool`): Enable version control or not. Supported value: `true,false`
    - ios(`string`): The minimum iOS version support.
    - android(`string`): The minimum Android version support.

## Game Info Rule
- enable(`bool`): Enable the game or not. Supported value: `true,false`
- gameID(`string`): The unique gameID used in the BE server.
- icon(`string`): The url of the game icon.
- url(`string`): The url of the game.
- webViewBgColor(`string`): The background color of the webview for the game.
- nameI18nkey(`string`): The i18n key of the game name.
- descI18nkey(`string`): The i18n key of the game description.
- tippingGift:
  - enable(`bool`): Enable tipping gift or not. Supported value: `true,false`
  - triggerPoint(`number`): The threshold point for tipping gift dialog. If a user winning more than this point in a round, the tipping gift dialog will be shown.
  - giftInfo:
    - regular:
      - id(`string`): The gift id for tipping gift regular items.
      - id(`string`): The gift id for tipping gift regular items.
    - special:
      blueberry:
      id(`string`): The gift id for tipping gift regular items.
      pineapple:
      id(`string`): The gift id for tipping gift regular items.
      strawberry:
      id(`string`): The gift id for tipping gift regular items.
- versionControl:
    - enable(`bool`): Enable version control or not. Supported value: `true,false`
    - ios(`string`): The minimum iOS version support.
    - android(`string`): The minimum Android version support.
