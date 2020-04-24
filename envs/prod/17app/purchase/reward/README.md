# Purchase Reward 規則

## 範例

```yaml
rewards:
  - startTime: "2018-12-24T15:00:00+08:00"
    endTime: "2019-02-25T23:59:59+08:00"
    rules:
      - reward:
          points: 1000
        requirements:
          - sellingChannels:
              include:
                - 1
                - 2
          - merchandiseID: "mockMerchandiseID"
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
          - firstPurchase:
              sellingChannels:
                exclude:
                  - 2
              merchandiseID: "mockMerchandiseID"
            abtest:
              name: "abtest"
              groupID: "b"
  - onlyAvailableInSameRegion: true
    rules:
    - reward:
        points: 200
      requirements:
        - secretIAP:
            ID: "mockID"
```

## 規則

* rewards(`array of struct`):
  * startTime/endTime(`RFC3339`): 購買的時間必須在config中定義開始時間與結束時間之間才需要檢查下列規則
  * onlyAvailableInSameRegion(`bool`): 需要檢查用戶的 `ipRegionGroup` 與 `userRegionGroup` 需相同才需要檢查下列規則
  * rules(`array of struct`): 規則
    * reward: 符合條件可拿到的所有獎勵
      * points(`number`): 免費點數
      * premiumBaby: 尊榮寶寶
        * days(`number`): 尊榮寶寶試用天數
      * loyaltyPoints(`number`): VIP積分
      * bonusRatio:
        * priceRatio(`float`): 購買價格對應比例的點數
    * requirements(`array of struct`): 條件
      * sellingChannels: 購買的渠道
        * include/exclude(`array of number`): 包含/排除的渠道
      * merchandiseID(`string`): 購買的merchandiseID
      * execUserRegion: 建單者的區域限制的規則
        * include/exclude(`array of string`): 包含/排除的區域
      * firstPurchase: 首次購買的規則
        * timeRange: 判斷首次購買的時間範圍，若在這段時間範圍內曾購買則不算首購
          * startTime/endTime(`RFC3339`): 開始與結束時間
        * sellingChannels: 判斷首次購買的渠道
          * include/exclude(`array of number`): 包含/排除的渠道
        * merchandiseID(`string`): 指定判斷首次購買的merchandiseID
      * registerDayRange: 用戶註冊的day range
        * fromDayN/toDayN(`number`): 註冊後的N day範圍
      * secretIAP:
        * ID(`string`): 秘密IAP的ID
      * abtest: 用戶符合abtest的group規則
        * name(`string`): abtest name
        * groupID(`string`): 預期abtest的groupID

### NOTES

1. 不需要的條件請直接不填key
2. `requirements`是`array of struct`，單一個struct裡定義的所有條件需要都符合，才能算是符合條件，只要array裡任一個struct符合條件就可以拿到獎勵
