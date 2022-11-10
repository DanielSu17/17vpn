# Ice and Fire Settings

## Service Configs - Do NOT modify it unless you know what you are doing.
```yaml
gameServerHost: "https://17live-game.com" # The host of the game server.
gamePoolUserID: "85b3803c-faa0-4b10-90bd-ea55b0eb769f" # The user ID of the game pool user.
```

## Game Configs - Modify it according to SPEC.
### Overflow
Recognize the revenue from the game pool.
```yaml
overflow:
  size: 15000000 # While the pool balance is over this value, the game will be overflowed - transfer difference from pool to the revenue.
  sequence: 20 # Check overflow every N rounds.
```

### Risk Control System
A system to control the RTP of the game.
See the [SPEC](https://docs.google.com/presentation/d/1KV2bWTbb4_79rv82ldeLPcGRR3Ou4t-m-rn8eO4rubQ/edit#slide=id.g13a5eb8e6c5_0_192) for more details.
```yaml
probabilityTable: # Basic probability of each index.
  # index 0
  - king: 6340
    noble: 2520
    commoner: 1140
  # index 1
  - king: 6360
    noble: 2500
    commoner: 1140

odds: # The odds of each item if a player win.
  king: 1.5 # 1.5 times to payout.
  noble: 4 # 4 times to payout.
  commoner: 9 # 9 times to payout.

tax: # The tax of each round - always transfer from game pool to revenue each round.
  emergency: 0.025 # 2.5%
  loaded: 0.05 # 5%
  fair: 0.05 # 5%

safeline: 12000000

loadedgate: 20000
```
Notice:
- The sum of the probability of each index must be 10000.
- Item key in each index must be the same, and highly correlated to the game, e.g., `king`, `noble`, `commoner` for Ice and Fire game.
- There are 3 pool levels: `emergency`, `loaded`, `fair`. The tax of each level is defined in `tax` field.
- The `safeline` and `loadedgate` fields affect the pool level. See the [mechanism](https://docs.google.com/presentation/d/1KV2bWTbb4_79rv82ldeLPcGRR3Ou4t-m-rn8eO4rubQ/edit#slide=id.g13baac2268b_0_14) for more details.

### Compensation System
According to the policy in Japan, the game must compensate the player if they lose the money.
See the [SPEC](https://www.figma.com/file/04IdeQqQnuMMraHIV1VhjL/%5BStory-Map%5D-Fruit-Farm?node-id=4443%3A4979) for more details.
```yaml
compensation:
  enabled: true # Enable the compensation system.
  items: # Calculate the compensation items by the settings below and the money player lose.
    - pointThreshold: 100
      barrageType: 6
      barrageCount: 1
    - pointThreshold: 500
      barrageType: 7
      barrageCount: 1
    - pointThreshold: 1000
      barrageType: 8
      barrageCount: 1
    - pointThreshold: 10000
      barrageType: 9
      barrageCount: 1
```
Notice:
- The barrage type is defined in the [Barrage Configs](../barrage/barrage.yaml).