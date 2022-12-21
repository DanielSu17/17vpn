# [Wave] [JP] IAP bonus


- During limited bonus period, key of product in items config will be replaced by value of product. Expect, there's only show key of product on website. (ex: During limited bonus period, sta_points_3880 will be replaced by sta_points_3880_bonus_200)
- bonus_[point]:  Hint bonus point will be showed on website.

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
