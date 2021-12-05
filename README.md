# Violin Pricer
 The Violin pricer can pice most on-chain assets. 

## Deploy
```
yarn deploy avax    
```

### Testing
```
yarn test hardhat 
```

The testing require a FORK_URI to be set.

### Environment variables
- PRIVATE_KEY
- ETHERSCAN_APIKEY
- FORK_URI

## Contracts
The contracts have been deployed as-is on a variety of chains.

### Staging

| Chain   | Pricer                                     | PricerHandlerV1                            | PricerHandlerV1Implementation              |
| ------- | ------------------------------------------ | ------------------------------------------ | ------------------------------------------ |
| BSC     |  |  |
| Celo    |  |  | 
| Cronos  |  |  |
| Fantom  | 0x393c80eD875eDe4dc9da8E5C9CA8959c5A36d6b4 | 0x85715bd110D70985d8A5B60D17B6B4882080A597 | 0x2E2CbEed2853000fe93388273f6Be635880134AE |
| Harmony |  0x393c80ed875ede4dc9da8e5c9ca8959c5a36d6b4 | 0xC8A34fFac73A4a028bDb6DeE6720A4A4aaf19102 | 0x2E2CbEed2853000fe93388273f6Be635880134AE |
| Polygon |  |

## Documentation
The pricer consists of a simple interface contract `Pricer` that calls it's `implementation` using a normal call. The `implementation` is an upgradable proxy with the actual pricing logic. This setup allows us to delete the state by setting the `Pricer` implementation to a new contract and maintain the state by upgrading the `implementation` proxy.

### Pricer
The pricer contract is the interface contract that is never expected to change. It forwards all calls to its `implementation` which is initially the PricerHandler.

### PricerHandler
The pricer handler is the contract that actually handles the pricing logic, this contract can have state and is upgradeable.