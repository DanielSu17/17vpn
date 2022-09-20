## black_users.yaml
This file is designed for credit crad blacklist

**In order to avoid repetition. Please make sure the user isn't on this list before you add a new one.**

### YAML spec

```
black_users:
  - userID: d3808ada-36ed-47b2-b8d5-e739148f95d1
    description: fraud
    block_starttime: 2019-05-11 20:00:00 (GMT+0800)
    block_endtime: 2023-05-11 20:00:00 (GMT+0800)
    block_web_regions: 
      - HK
      - JP
  - userID: 1499aaaa-d850-4e79-b2fe-abaedcdefe34
    description: fraud
    block_starttime: 2020-05-11 20:00:00 (GMT+0800)
    block_endtime: 2030-05-11 20:00:00 (GMT+0800)
    block_web_regions: 
      - JP
```
