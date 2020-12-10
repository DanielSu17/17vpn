# 直播間內公告訊息

This config file stores system messages.

Rule
- Accecpt more than two system messages.
- If there's no language code, its default language is "EN".
- If there's language code without message, the system message will be blank.
- `Invalid time format(2017-7-25T6:1:1+08:00)`, make sure there're two digits, `correct(2017-07-25T06:01:01+08:00)` !!!

Example:
```yaml
EN:
  - msg: testing
    startTime: 2017-07-31T00:00:00+08:00
    endTime: 2017-08-31T23:59:59+08:00
  - msg: testing2
    startTime: 2017-09-01T00:00:00+08:00
    endTime: 2017-10-31T23:59:59+08:00
CN:
  - msg:
    startTime: 2017-07-31T00:00:00+08:00
    endTime: 2017-08-31T23:59:59+08:00
TW:
  - msg: 測試
    startTime: 2017-07-31T00:00:00+08:00
    endTime: 2017-08-31T23:59:59+08:00
JP:
  - msg: テスト
    startTime: 2017-07-31T00:00:00+09:00
    endTime: 2017-08-31T23:59:59+09:00
```
-> result on 2017-08-01T00:00:00+08:00 (EN: testing, TW: "測試", CN: "", JP: "テスト", KR: "testing")
