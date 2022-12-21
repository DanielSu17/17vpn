# [Wave] [TW] IAP bonus

- 在限時返利時間，items 裡 key 代表的 product 將會被取代成 value 的 product，此外，在返利時間以外則僅會顯示 key 的 product。(ex: 返利時間，points_34650 會被取代成 points_event_35250)
- bonus_[point] 的 point 將會在網頁上顯示加贈的點數。

example:
```
bonus_items_web:
  enabled: true
  start_time: "2022-02-10 20:00:00 (GMT+0800)"
  end_time: "2022-04-29 21:00:00 (GMT+0800)"
  items:
    sta_points_3880:
      bonus_id: sta_points_3880_bonus_200
```
