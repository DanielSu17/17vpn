# Nakama game external provider config

## Game providers config
Request Verification for game providers
```yaml
gameProviders:
  - name: MeMe #used to map provider's secretKey
  - providerID: d7ed3e48-ed36-11ed-a05b-0242ac120003
    ipWhitelist: #external serverIP whitelist
      - 10.0.0.1
      - 10.0.0.2
    gameIDs:  #gameIDs providers has access to
      - greedyGame
```
