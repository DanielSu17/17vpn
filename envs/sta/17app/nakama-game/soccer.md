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