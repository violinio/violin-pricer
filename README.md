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

| Chain     | Pricer                                     | PricerHandlerV1                            | PricerHandlerV1Implementation              |
| --------- | ------------------------------------------ | ------------------------------------------ | ------------------------------------------ |  
| Astar     | 0x393c80eD875eDe4dc9da8E5C9CA8959c5A36d6b4 | 0xa0369dE28D0A3A701f8cf364B1f2AeB2Fb1E3B32 | 0xFABd8b7E408C48FFf04363AeBf8865453A7B02F6 |
| Aurora    | 0x393c80eD875eDe4dc9da8E5C9CA8959c5A36d6b4 | 0x4D45BE6C0a35cEd60AeeC57F778337Ac09e9D777 | 0x3444E5Ec105c1E4beb3ee8a9E714bF07fD53819E |
| Avalanche | 0x393c80eD875eDe4dc9da8E5C9CA8959c5A36d6b4 | 0x4D45BE6C0a35cEd60AeeC57F778337Ac09e9D777 | 0x2CaB72b2b4241d6881F9EdB4B7256bE1F6f1FEC8 |
| Arbitrum  | 0x7495Bd05276CD4B192e315fAf891759039fA5884 | 0x7FA4b073CCf898c97299ac5aCEb5dE8d5Ef2c7f6 | 0x4fd9016c5ff784709e8CcF0f6E8aDd357803bf91 |
| BSC       | 0x393c80eD875eDe4dc9da8E5C9CA8959c5A36d6b4 | 0x4D45BE6C0a35cEd60AeeC57F778337Ac09e9D777 | 0x3444E5Ec105c1E4beb3ee8a9E714bF07fD53819E |
| Celo      | | |
| Doge      | 0x7495Bd05276CD4B192e315fAf891759039fA5884 | 0x7FA4b073CCf898c97299ac5aCEb5dE8d5Ef2c7f6 | 0x4fd9016c5ff784709e8CcF0f6E8aDd357803bf91 |
| Optimism  | 0x7495Bd05276CD4B192e315fAf891759039fA5884 | 0x7FA4b073CCf898c97299ac5aCEb5dE8d5Ef2c7f6 | 0x4fd9016c5ff784709e8CcF0f6E8aDd357803bf91 |
| Cronos    | 0x393c80eD875eDe4dc9da8E5C9CA8959c5A36d6b4 | 0x4D45BE6C0a35cEd60AeeC57F778337Ac09e9D777 | 0x3444E5Ec105c1E4beb3ee8a9E714bF07fD53819E |
| ETH       | 0x393c80eD875eDe4dc9da8E5C9CA8959c5A36d6b4 | 0xa0369dE28D0A3A701f8cf364B1f2AeB2Fb1E3B32 | 0x3444E5Ec105c1E4beb3ee8a9E714bF07fD53819E |
| EVMOS     | 0x393c80eD875eDe4dc9da8E5C9CA8959c5A36d6b4 | 0xa0369dE28D0A3A701f8cf364B1f2AeB2Fb1E3B32 | 0xFABd8b7E408C48FFf04363AeBf8865453A7B02F6 |
| Emerald   | 0x393c80eD875eDe4dc9da8E5C9CA8959c5A36d6b4 | 0xC1208BBf26a79fA2152CC8E073f615395DF8007b | 0x2CaB72b2b4241d6881F9EdB4B7256bE1F6f1FEC8 |
| Fantom    | 0x393c80eD875eDe4dc9da8E5C9CA8959c5A36d6b4 | 0x85715bd110D70985d8A5B60D17B6B4882080A597 | 0x2E2CbEed2853000fe93388273f6Be635880134AE |
| Fusion    | 0x393c80eD875eDe4dc9da8E5C9CA8959c5A36d6b4 | 0x4D45BE6C0a35cEd60AeeC57F778337Ac09e9D777 | 0x3444E5Ec105c1E4beb3ee8a9E714bF07fD53819E |
| Harmony   | 0x393c80ed875ede4dc9da8e5c9ca8959c5a36d6b4 | 0xC8A34fFac73A4a028bDb6DeE6720A4A4aaf19102 | 0x2E2CbEed2853000fe93388273f6Be635880134AE |
| Heco      | 0x7495Bd05276CD4B192e315fAf891759039fA5884 | 0x7FA4b073CCf898c97299ac5aCEb5dE8d5Ef2c7f6 | 0x4fd9016c5ff784709e8CcF0f6E8aDd357803bf91 |
| Fuse      | 0x393c80eD875eDe4dc9da8E5C9CA8959c5A36d6b4 | 0x0A9046De7AA5e9f35814Aba901D7e19B0F466e11 | 0x2E2CbEed2853000fe93388273f6Be635880134AE |
| Polygon   | 0x75fB02aFAB420fBeed53B5Ee3703b91fAb111fbD | 0x47a02D924F3F64BE696955fA559D0Dd613186562 | 0x3A143Acb2E6B2Dd9C018c3A59885048C28F31dA2 |
| Metis     | 0x4bAeFD514e0f7d51C510c5139a1a736a56296964 | 0xB62cfC3EaBBa0B1aC9c8175Ce60203a7717b0769 | 0x3099088C4Fe5e822c204fd64840ae2F5290cA9cd |
| Milkomeda | 0x393c80eD875eDe4dc9da8E5C9CA8959c5A36d6b4 | 0xa0369dE28D0A3A701f8cf364B1f2AeB2Fb1E3B32 | 0xFABd8b7E408C48FFf04363AeBf8865453A7B02F6 |
| MoonBeam  | 0xe7aBd3963B497Bb97Cba431Bc156002Fb339262F | 0xB62cfC3EaBBa0B1aC9c8175Ce60203a7717b0769 | 0x3099088C4Fe5e822c204fd64840ae2F5290cA9cd |

## Documentation
The pricer consists of a simple interface contract `Pricer` that calls its `implementation` using a normal call. The `implementation` is an upgradable proxy with the actual pricing logic. This setup allows us to delete the state by setting the `Pricer` implementation to a new contract and maintain the state by upgrading the `implementation` proxy.

### Pricer
The pricer contract is the interface contract that is never expected to change. It forwards all calls to its `implementation` which is initially the PricerHandler.

### PricerHandler
The pricer handler is the contract that actually handles the pricing logic, this contract can have state and is upgradeable.

### Notes
#### Fusion
For Fusion we use the Chainge deployment:
- router: 0x2bfc80b3aba8bcaf9d89bfe9809ff64a28c9ad81
- factory: 0x74aC9080Bf16D3603F6aef02dBe1Ce8806049BAd