# Onmyoji Settings

## Service Configs - Do NOT modify it unless you know what you are doing.
```yaml
gamePoolUserID: "2c32ef57-c0b1-4f37-93be-f2cccef16151" # The user ID of the game pool user.
```

## Game Configs - Modify it according to SPEC.
### Overflow
Recognize the revenue from the game pool.
```yaml
overflow:
  size: 15000000 # While the pool balance is over this value, the game will be overflowed - transfer difference from pool to the revenue.
  sequence: 20 # Check overflow every N rounds.
```

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