# iap point layout rule


## sample

```yaml
eventIAPs:
  - eventID: "event-1"
    showCountdownUnderSticker: false
    showCountdownInPopUp: false
    stickerURL: "https://assets-17app.akamaized.net/30feb803-3274-42e2-8e41-187274f2314b.png"
    eventInfo:
      eventTitleI18nKey: ""
      eventURL: ""
      bannerImageURL: "https://cdn.17app.co/a53c6a00-3ed4-4bca-a5eb-6ffbcba53599.png" 
    layoutInfo:
      titlePicURL: "https://assets-17app.akamaized.net/ab606b67-67e2-4c6a-9ec6-593c2f499508.png"
      messageColor: "#6F6777"
      messageShadowColor: "#F5F5F5"
      messageI18nKey: ""
      descBgURL: "https://assets-17app.akamaized.net/cb259911-8e1a-4e18-93c2-c699df64080a.png"
      descLeftBottomURL: "test.png"
      descRightBottomURL: "test.png"
      highlightBgURL: "https://cdn.17app.co/b505d3b8-994d-42cd-a86f-304ac491040c.png"
      highlightIconURL: "https://assets-17app.akamaized.net/eeae83cf-ae8b-48a8-b465-a5180f87b8f9.png"
      rewardIconURL:
          premiumBaby: https://cdn.17app.co/05134ee3-2d68-4308-b901-61a9fbf02948.png
    colorInfo:
      pointColor: "#28232D"
      bonusPointColor: "#B36F6777"
      priceColor: "#28232D"
      rewardTextColor: "#F69355"
    pointProducts:
      - productID: "media17_points_330"
        shouldHighlight:  true
      - productID: "media17_points_1720"
        shouldHighlight:  false
      - productID: "media17_points_3540"
        shouldHighlight:  false
      - productID: "media17_points_8550"
        shouldHighlight:  false
      - productID: "media17_points_15420"
        shouldHighlight:  false
      - productID: "media17_points_35980"
        shouldHighlight:  false
    displayRewardInfo: true

defaultIAP:
  layoutInfo:
    highlightBgURL: "https://cdn.17app.co/b505d3b8-994d-42cd-a86f-304ac491040c.png"
    highlightIconURL: "https://assets-17app.akamaized.net/eeae83cf-ae8b-48a8-b465-a5180f87b8f9.png"
  colorInfo:
    pointColor: "#28232D"
    bonusPointColor: "#F5487D"
    priceColor: "#28232D"
  pointProducts:
    - productID: "media17_points_35980"
      shouldHighlight:  true
    - productID: "media17_points_15420"
      shouldHighlight:  false
    - productID: "media17_points_8550"
      shouldHighlight:  false
    - productID: "media17_points_3540"
      shouldHighlight:  false
    - productID: "media17_points_1720"
      shouldHighlight:  false
    - productID: "media17_points_330"
      shouldHighlight:  false
```

## Rules

* eventIAPs(`array of struct`):
  * eventID(`string`): 跟 `reward.yaml` 對應的 eventID
  * showCountdownUnderSticker(`bool`): 要不要在貼紙底下顯示倒數
  * showCountdownInPopUp(`bool`): 要不要在PopUp顯示倒數
  * stickerURL(`string`): 貼紙的網址
  * eventInfo(`struct`):
    * eventTitleI18nKey(`string`): event 標題文字的 i18n key
    * eventURL(`string`): event 網址
    * bannerImageURL(`string`): banner 網址
  * layoutInfo(`struct`):
    * titlePicURL(`string`): 標題圖的網址
    * messageColor(`color code`): 訊息的色碼
    * messageShadowColor(`color code`): 訊息的底色色碼
    * messageI18nKey(`string`): 訊息的 i18n key
    * descBgURL(`string`): 敘述的背景圖網址
    * descLeftBottomURL(`string`): 敘述左下角圖的網址
    * descRightBottomURL(`string`): 敘述右下角圖的網址
    * highlightBgURL(`string`): highlight背景圖網址
    * highlightIconURL(`string`): highlight icon 網址
    * rewardIconURL(`struct`):
      * premiumbaby(`string`): 尊榮寶寶icon 的網址
  * colorInfo(`struct`):
    * pointColor(`color code`): 點數的色碼
    * bonusPointColor(`color code`): 加贈點數的色碼
    * priceColor(`color code`): 價格的色碼
    * rewardTextColor(`color code`): 獎勵文字色碼
  * pointProducts(`array of struct`):
    * productID(`string`):
    * shouldHighlight(`bool`): 要不要以highlight方式顯示這個product
  * displayRewardInfo(`bool`): 要不要顯示獎勵資訊

* defaultIAP(`struct`):
  * layoutInfo(`struct`): 同 eventIAPs.layoutInfo
  * colorInfo(`struct`): 同 eventIAPs.colorInfo
  * pointProducts(`array of struct`): 同 eventIAPs. pointProducts
