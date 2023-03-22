# IAP fraud detection settings
This file is designed for IAP fraud validator

**In order to avoid repetition. Please make sure the user isn't on this list before you add a new one.**

### YAML spec

```
iapFraud:
  enable: true
  rules:
    # Accumulated IAP BBC purchase more than <newbie.maxPurchase> times within <newbie.minutes> minutes after 17LIVE account has created.
    newBie:
      minutes: 5
      maxPurchase: 10
      reason: "Accumulated IAP BBC purchase more than 10 times within 5 minutes after 17LIVE account has created."
    # Under same 17LIVE account, user has requested Apple/Google refund more than <refund.maxRefund> times during last <refund.countPeriod> period.
    refund:
      maxRefund: 5
      countPeriod: P1Y # ISO8601, format:PnYnMnDTnHnMnS, e.g: P1Y1M1D means last 1 year + 1 month + 1 day 
      reason: "Under same 17LIVE account, user has requested Apple/Google refund more than 5 times in recent 3 months."
  alert:
    enable: true
    notifChannels:
      - C017756FY4B # fraud-ops-skyeye
    notifUsers:
      - UNF6265G9   # Jimmy Chang (TW CEOO/Revenue)
      - U035JRME6DN # Eric Shih (TW Revenue)
    ccUsers:
      - S0RF9QE4B   # skyeye
      - SAQ18NAKG   # jp-customer-success-g
      - SQ8EYN16F   # jp-revenue
    message: "Please note that the following user has been detected as potential fraud refund user with the following reason, user has been prohibited to top up BBC via IAP. Kindly fill in the sheet if the user is needed to be freeze or ban and reply under this thread when completed for SkyEye to keep as record."

  whitelist:
    - 2a091777-b06d-4cad-9b02-70193365e1e3  # ftcy0118
    - 3128adcd-ea2c-438d-93cf-00baf1d7374a  # jen87
```
