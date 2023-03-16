# crazystair control 設定 (IN)

This is the configuration for IN crazystair control.

## simple
```yaml
enable: false          # 是否開放
timeSlots:             # 開放時間段(可多區段, 但開放時間不可重疊)
  - startTime: "2021-08-01 00:00:00 (GMT+0800)"
    endTime: "2021-08-10 23:59:59 (GMT+0800)"
  - startTime: "2021-08-11 00:00:00 (GMT+0800)"
    endTime: "2021-08-20 23:59:59 (GMT+0800)"
  - startTime: "2021-08-21 00:00:00 (GMT+0800)"
    endTime: "2021-08-30 23:59:59 (GMT+0800)"


#  [Notice]
#  1. 活動開始後 startTime 不可更改, 否則會導致榜單無法顯示
# 
#  2. 活動開始後調整 endTime, 可作為延長時間或提早結束, 但調整後的結束時間·小於·現在時間會直接結束榜單, 且榜單資料也不會做修正
#     Example: 
#         timeNow: 2021-08-05
#         endTime(2021-08-10) -> endTime(2021-08-01)
#         8/1 ~ 8/5 這段時間內的榜單資料並不會清除, 仍會存在於榜單上
#
#  3. 如果現在沒有進行中的榜單, 則會顯示上個榜單的資訊(所以請·不要清除·過期榜單的資訊, 否則會無法發現上個榜單的資訊)
#
#  4. 結束的榜單資訊最多只保留 6 個月, 6個月後如要查詢榜單請至BQ查詢
#
```


