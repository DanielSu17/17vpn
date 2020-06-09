# Purchase Reward 規則

## 範例

```yaml
rewardEvents:
  - eventID: "event-01"
    startTime: "2018-12-24T15:00:00+08:00"
    endTime: "2019-02-25T23:59:59+08:00"
    eventRequirements:
      - sellingChannels:
          include:
            - 1
            - 2
        firstPurchase:
          timeRange:
            startTime: "2018-12-24T15:00:00+08:00"
          sellingChannels:
            exclude:
              - 2
          merchandiseID: "mockMerchandiseID"
      - registerDayRange:
          fromDayN: 0
          toDayN: 13
        sellingChannels:
          include:
            - 1
            - 2
      - firstPurchase:
          sellingChannels:
            exclude:
              - 2
          merchandiseID: "mockMerchandiseID"
        abtest:
          name: "abtest"
          groupID: "b"
        sellingChannels:
          include:
            - 1
            - 2
        legacyFirstPurchase:
          enableTimeRange: false
    rules:
      - reward:
          points: 1000
        requirements:
          - merchandiseID: "mockMerchandiseID"
      - reward:
          loyaltyPoints: 5
        requirements:
          - merchandiseID: "mockMerchandiseID1"
      - reward:
          premiumBaby:
            days: 3
        requirements:
          - merchandiseID: "mockMerchandiseID2"
      - reward:
          bonusRatio:
            priceRatio: 0.3
        requirements:
          - merchandiseID: "mockMerchandiseID3"
  - eventID: "event-02"
    eventRequirements:
      - onlyAvailableInSameRegion: true
        secretIAP:
          ID: "mockID"
        sellingChannels:
          include:
            - 1
            - 2
        legacyFirstPurchase:
          enableTimeRange: true
          timeRange:
            startTime: "2018-12-24T15:00:00+08:00"
    rules:
      - reward:
          points: 200
        requirements:
          - merchandiseID: "mockMerchandiseID"
```

## 規則

* rewardEvents(`array of struct`):
  * eventID(`string`): 活動ID
  * startTime/endTime(`RFC3339`): 購買的時間必須在config中定義開始時間與結束時間之間才需要檢查下列規則
  * eventRequirements(`array of struct`): 活動規則
    * sellingChannels: 購買的渠道
      * include/exclude(`array of number`): 包含/排除的渠道
    * onlyAvailableInSameRegion(`bool`): 需要檢查用戶的 `ipRegionGroup` 與 `userRegionGroup` 需相同才需要檢查下列規則
    * execUserRegion: 建單者的區域限制的規則
      * include/exclude(`array of string`): 包含/排除的區域
    * firstPurchase: 首次購買的規則
      * timeRange: 判斷首次購買的時間範圍，若在這段時間範圍內曾購買則不算首購
      * startTime/endTime(`RFC3339`): 開始與結束時間
      * sellingChannels: 判斷首次購買的渠道
        * include/exclude(`array of number`): 包含/排除的渠道
      * merchandiseID(`string`): 指定判斷首次購買的merchandiseID
    * legacyFirstPurchase: 舊的首次購買的規則，使用Mongo User的`lastPurchasePointTime`欄位判斷
      * enableTimeRange(`bool`): 設為`true`代表使用時間範圍來判斷是否有首購資格，`false`則代表只判斷用戶是否曾經購買過，若曾經購買過則不算首購
      * timeRange: 判斷首次購買的時間範圍，若在這段時間範圍內曾購買則不算首購
        * startTime/endTime(`RFC3339`): 開始與結束時間
    * registerDayRange: 用戶註冊的day range
      * fromDayN/toDayN(`number`): 註冊後的N day範圍
    * secretIAP:
      * ID(`string`): 秘密IAP的ID
    * abtest: 用戶符合abtest的group規則
      * name(`string`): abtest name
      * groupID(`string`): 預期abtest的groupID
  * rules(`array of struct`): 獎勵規則
    * reward: 符合條件可拿到的所有獎勵
      * points(`number`): 免費點數
      * premiumBaby: 尊榮寶寶
        * days(`number`): 尊榮寶寶試用天數
      * loyaltyPoints(`number`): VIP積分
      * bonusRatio:
        * priceRatio(`float`): 購買價格對應比例的點數
    * requirements(`array of struct`): 條件
      * merchandiseID(`string`): 購買的merchandiseID

### NOTES

1. 不需要的條件/規則請直接不填key
2. `requirements`/`eventRequirements`是`array of struct`，單一個struct裡定義的所有條件需要都符合，才能算是符合條件，只要array裡任一個struct符合條件就可以拿到獎勵
3. 目前`eventRequirements`的`sellingChannels`是一個重要的條件，所以在設定活動條件的時候是必填
4. `eventID`為必填欄位且不可重複
