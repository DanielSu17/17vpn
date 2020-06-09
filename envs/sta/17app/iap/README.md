# iap package rule

## sample

```yaml
merchandises:
  - intervalID: MINV-1ctDZjpachovmswZG2jdRVfkqX7
    merchandiseID: media17_points_8550
    productsOrder:
      - barrage_baby_100
      - premiumbaby_168_hrs
    bonusesOrder:
      - gift_arpk_30_14
      - gift_love_you_100_14
      - gift_lovegif_5_14
      - gift_fighting_100_14
    addons:
      countdownSecs: 36000
      title:
        key: iap_store_giftpackage_newbie
      titleImageURL: https://cdn.17app.co/392ead48-62dc-4321-9a86-923458ce19ab.png
      discountImageURL: https://cdn.17app.co/67882b0c-09ee-429c-be07-92ca3ed8fbab.png
      description:
        - imageURL:
          text:
            key: iap_store_giftpackage_dialog_premium_title
        - imageURL: https://cdn.17app.co/d9023136-e2eb-488f-b1bb-0881dd50dac7.png
          text:
            key: iap_store_giftpackage_dialog_premium_desc
        - imageURL:
          text:
            key: iap_store_giftpackage_dialog_barrage_title
        - imgURL: https://cdn.17app.co/95208519-d504-4063-997a-0a43249cca60.png
          text:
            key: iap_store_giftpackage_dialog_barrage_desc
        - imgURL:
          text:
            key: iap_store_giftpackage_dialog_gift_desc
    purchaseType: 1
    taInfo:
        registerRange:
          dayStart: 0
          dayEnd: 0
        type: 4
        startTime: "2018-12-24T15:00:00+08:00"
        endTime: "2018-12-24T15:00:00+08:00"
    abtestName: ""
```

## Rules
* merchandises(`array of struct`):
  * intervalID(`string`): 禮包內部的 id
  * merchandiseID（`string`): 對google play / app store的id
  * productsOrder(`array of string`): product的順序
  * bonusesOrder(`array of string`): bonus的順序
  * addons(`struct`):
    * countdownSecs(`number`): 距離結束時間多少以前開始 highlight
    * title(`i18n struct`):
      * key(`string`): 標題的i18n key
    * titleImageURL(`string`): 標題底圖的image url
    * discountImageURL(`string`): 折扣的image url
    * description(`array of struct`):
      * imageURL(`string`): 說明圖示
      * text(`i18n struct`):
        * key(`string`): 說明文字的i18n key
    * purchaseType(`number`): 可購買的次數
    | enum | times |
    |------|-------|
    | 1    | 一次  |
    | 2    | 不限  |
    * taInfo(`struct`): 受眾
      * registerRange(`struct`): 註冊天數
        * dayStart(`number`): 開始,若為0則不受限制
        * dayEnd(`number`): 結束,若為0則不受限制
      * type(`number`): 受眾群體
    | enum | meaning |
    | ---- | ------- |
    | 1 | 判斷時間區段沒有購買過 |
    | 2 | 判斷時間區段有購買過 |
    | 3 | 生涯沒有購買過 |
    | 4 | 生涯有購買過 |
      * startTime(`RFC3339`): 受眾的判斷時間開始時間, `不是禮包的有效時間`,若沒有值則不受限制
      * endTime(`RFC339`): 受眾的判斷時間結束時間, `不是禮包的結束時間`,若沒有值則不受限制
    * abtestName(`string`): 禮包測試相關的abtest名稱, 需要 abtest.yaml也做相關的設定