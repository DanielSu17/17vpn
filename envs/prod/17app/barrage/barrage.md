# 直播間彈幕設定

#### Sample
```shell
barrages:
  - type: 9
    point: 10000
    enabled: true
    army: true
    startTime: 2022-09-15 (GMT+0800) # optional
    endTime: 2022-10-15 (GMT+0800) # optional
    regions: # optional. If not set, it will be available in all regions.
      - TW
    versionControl:
      ios: "3.201.0"
      android: "2.116.0"
    key: barrage_type_berryrocket # lokalise key
    animationID: barrage_type_berryrocket # animation id
```

#### Description
1. type 0~9 為系統靜態預設彈幕，請勿修改設定
2. type 需要是唯一且 >=0 的數字
3. point 大於 0 代表免費的用完後使用會消耗點數; point 等於 0 代表免費的用完後將不可購買
4. enabled 控制可開關彈幕
5. army 控制是否受到戰隊特權影響; true 代表進入戰隊直播間時顯示次數會額外增加戰隊特權給予的使用次數
6. startTime 與 endTime 代表彈幕的有效期間，若不設定則代表永久有效
7. regions 代表彈幕的有效地區，若不設定則代表所有地區都有效
8. versionControl 代表彈幕的版本控制，若不設定則代表所有版本都有效
9. key 為 lokalise 上設定的 i18n key．
10. animationID 為提供給 client 下載動畫檔案路徑．對應到 ../../files/animation.yaml 中的 animationID


