# TODO deprecated version > v0.6.15
# System message configuration

This config file stores system messages.

Rule
- Accecpt more than two system messages.
- If there's no language code, its default language is "EN".
- If there's language code without message, the system message will be blank.
- `Invalid time format(2017-7-25T6:1:1+08:00)`, make sure there're two digits, `correct(2017-07-25T06:01:01+08:00)` !!!

Example:
```yaml
- msg:
    EN: testing.
    TW: 測試.
    CN: 
  startTime: 2017-07-25T00:00:00+08:00
  endTime: 2017-08-24T23:59:59+08:00
- msg:
  EN: testing.
  TW: 測試.
  startTime: 2017-08-25T00:00:00+08:00
  endTime: 2018-09-25T23:59:59+08:00
```
-> result (EN: testing, TW: "測試", CN: "", JP: "testing", KR: "testing")
