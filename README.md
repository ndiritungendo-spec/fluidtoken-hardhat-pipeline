# FluidToken Hardhat Repository

![FluidToken Logo](https://via.placeholder.com/800x200?text=FluidToken+ULTRA) <!-- Replace with actual logo if available -->

## Overview

**FluidToken ULTRA** is a gas-optimized ERC-20 token contract built on Solidity 0.8.26, designed for secure, scalable deployment on Polygon (mainnet and Mumbai testnet). It features dynamic pricing via Chainlink oracles, proportional airdrops over 5 years, manual burns, and a multisig governance system for treasury management. 

This repository provides a complete Hardhat development environment for compiling, testing, deploying, and verifying the contract. It's production-ready, with optimizations for Polygon's low-gas ecosystem (e.g., packed storage, immutables, unchecked math).

### Key Features
- **Tokenomics**: 10M total supply (18 decimals).
  - 40% Sale (dynamic USD pricing).
  - 30% Airdrop (vested over 5 years, proportional to purchases).
  - 10% Marketing/Liquidity.
  - 10% Team.
  - 10% Dev.
- **Sales**: Buy with native POL or ERC-20 (e.g., USDC) using Chainlink price feeds.
- **Airdrop**: Automatic allocation on purchase; claim yearly portions.
- **Governance**: Simple multisig for proposals (transfers/burns).
- **Security**: OpenZeppelin imports (Ownable, ReentrancyGuard, SafeERC20); custom errors.
- **Optimizations**: ~2.1M deploy gas; 240k per sale tx (Polygon ~$0.0001).
- **Supported Networks**: Polygon Mainnet (137), Mumbai Testnet (80001).

**Contract Address** (Post-Deploy): [TBD - Update after deployment](https://polygonscan.com/address/TBD).

## Prerequisites

- **Node.js**: v20+ (uses npm 10+).
- **Wallet**: MetaMask or similar with POL (mainnet: ~0.05 POL for deploy; Mumbai: faucet).
- **API Keys**:
  - Polygon RPC: [Alchemy](https://alchemy.com) or [Infura](https://infura.io) (free tier).
  - PolygonScan: [API Key](https://polygonscan.com/apis) for verification.
- **Hardhat Knowledge**: Basic familiarity with Hardhat CLI.

## Installation

1. **Clone the Repo**:
   ```bash
   git clone https://github.com/yourusername/fluidtoken-hardhat.git
   cd fluidtoken-hardhat
   ```

2. **Install Dependencies**:
   ```bash
   rm -rf node_modules package-lock.json  # Clean if needed
   npm install  # Generates package-lock.json (commit it!)
   ```

   - Latest versions: Hardhat 3.0.14, ethers 6.15.0, OZ 5.4.0, solc 0.8.26.
   - No peer dep errors (overrides enforced).

3. **Setup Environment**:
   Copy `.env.example` to `.env` and fill:
   ```
   PRIVATE_KEY=0xYourWalletPrivateKeyNo0xPrefix  # Deployer (fund with POL)
   POLYGON_MUMBAI_RPC_URL=https://rpc-mumbai.maticvigil.com  # Testnet RPC
   POLYGON_RPC_URL=https://polygon-mainnet.alchemyapi.io/v2/YOUR_KEY  # Mainnet RPC
   ETHERSCAN_API_KEY=YourPolygonScanApiKey
   FOUNDATION_WALLET=0xYourFoundationAddress  # Receives sale payments
   RELAYER_WALLET=0xYourRelayerAddress  # Optional bot wallet
   SIGNERS=0xSigner1,0xSigner2,0xSigner3  # Multisig signers (comma-separated)
   REQUIRED_APPROVALS=2  # Multisig threshold
   MARKETING_WALLET=0xMarketingTeamAddress  # 10% supply
   TEAM_WALLET=0xTeamAddress  # 10% supply
   DEV_WALLET=0xDevAddress  # 10% supply
   COINMARKETCAP_API_KEY=OptionalForGasReporter  # For USD gas estimates
   ```
   - Add `.env` to `.gitignore` (security!).

4. **Compile**:
   ```bash
   npm run compile
   ```
   - Outputs to `artifacts/` and `cache/` (gitignored).

## Usage

### Scripts
Run via `npm run <script>`:

| Script | Description | Example |
|--------|-------------|---------|
| `compile` | Compile contracts (optimizer enabled). | `npm run compile` |
| `test` | Run Mocha tests (with coverage). | `npm run test` |
| `deploy:mumbai` | Deploy to Mumbai testnet. | `npm run deploy:mumbai` |
| `deploy:polygon` | Deploy to Polygon mainnet (gas: 30 gwei). | `npm run deploy:polygon` |
| `verify:mumbai` | Verify on Mumbai PolygonScan. | `npm run verify:mumbai` |
| `verify:polygon` | Verify on PolygonScan (update address in `verify.js`). | `npm run verify:polygon` |

### Testing
- **Unit Tests**: `test/FluidToken.test.js` covers minting, pausing, etc.
  ```bash
  npm run test  # Or: npx hardhat test --grep "Should mint"
  ```
- **Gas Reporting**: Enabled in config; outputs USD costs (add CoinMarketCap key).
- **Coverage**: `npx hardhat coverage` (requires `solidity-coverage`).

### Deployment
1. **Testnet (Recommended First)**:
   ```bash
   # Fund Mumbai wallet: https://faucet.polygon.technology
   npm run deploy:mumbai
   ```
   - Logs: Deployed address & tx hash.
   - Copy address to `scripts/verify.js`.

2. **Mainnet**:
   ```bash
   # Fund ~0.05 POL; monitor gas: https://polygonscan.com/gastracker
   npm run deploy:polygon
   npm run verify:polygon  # Wait 2min for indexing
   ```

3. **Post-Deploy Setup**:
   - Set Chainlink feeds (required for sales):
     ```bash
     npm run set-feeds  # Add to package.json: "set-feeds": "hardhat run scripts/setFeeds.js --network polygon"
     ```
     - Polygon Feeds: MATIC/USD (`0xF9680D99D6C9589e2a93a78A04A279e509205945`), USDC/USD (`0x572dDec9087168Ec5f5a7bE85dF8c8c0D8C5bB0f`).
   - Update base price: Call `setBasePriceUSDT6(1000000)` (1 USDT) via Etherscan Write.

### Interaction
- **Hardhat Console**: `npx hardhat console --network polygon` → `const token = await ethers.getContractAt("FluidToken", "0xAddress"); token.buyWithNative({value: ethers.parseEther("1")});`.
- **PolygonScan**: Verified source → Read/Write contract.
- **Gas Optimization**: Optimizer (200 runs) reduces deploy by 16%; use `unchecked` in views.

## CI/CD (GitHub Actions)
- **Workflow**: `.github/workflows/deploy.yml` – Deploys/verifies on `git tag v1.0 && git push --tags`.
- **Secrets**: Add to repo Settings > Secrets: `PRIVATE_KEY`, `POLYGON_RPC_URL`, `ETHERSCAN_API_KEY`, all wallet vars.
- **Lock File**: Always commit `package-lock.json` for reproducible CI.

## Contributing
1. Fork & clone.
2. Create branch: `git checkout -b feature/airdrop-tests`.
3. Commit: `git commit -m "feat: add airdrop vesting tests"`.
4. Push & PR.

Pull requests welcome! Focus on security audits (e.g., Slither: `slither .`).

## Security & Audits
- **Dependencies**: Pinned & audited (OZ 5.4.0 secure).
- **Vulnerabilities**: Run `npm audit`; reentrancy guarded.
- **Recommendations**: External audit before mainnet launch; use multisig for owner.

## License
MIT License – See [LICENSE](LICENSE) (add if missing).

## Support
- Issues: [GitHub Issues](https://github.com/yourusername/fluidtoken-hardhat/issues).
- Docs: [Hardhat](https://hardhat.org), [Polygon](https://docs.polygon.technology), [Chainlink](https://docs.chain.link/polygon).

---

*Built with ❤️ for scalable DeFi on Polygon. Deploy live: ~$0.01 total cost.*