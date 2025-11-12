Contract Logic Explained
## Contract Logic (FluidToken.sol)

The `FluidToken` is a **fair-launch ERC-20 token** with **controlled supply**, **user-driven deflation**, and **governance via multisig**. Below is a full breakdown of all mechanics.

---

### Tokenomics

| Allocation | % of Total | Amount (FLD) | Vesting |
|----------|------------|--------------|-------|
| **Total Supply** | 100% | 10,000,000 | Fixed |
| **Sale Supply** | 40% | 4,000,000 | Sold via price oracle |
| **Airdrop Pool** | 30% | 3,000,000 | 5-year linear vesting |
| **Marketing/Liquidity** | 10% | 1,000,000 | Sent to wallet at deploy |
| **Team** | 10% | 1,000,000 | Sent to wallet at deploy |
| **Dev** | 10% | 1,000,000 | Sent to wallet at deploy |

> **No pre-mine. No hidden mint.**

---

### Core Features

#### 1. **Buy with Stablecoins or Native Token**
Users can buy FLD using:
- Any ERC-20 (e.g. USDT, USDC) → via Chainlink price feed
- Native token (POL/MATIC) → via native price feed

**All funds go directly to `foundationWallet`.**

```solidity
buyWithERC20(payToken, payAmount)
buyWithNative() // payable
Price: Set in USDT (6 decimals) → 1e6 = $1.00
No gas fee splitting or rewards → 100% transparent
2. Airdrop (5-Year Vesting)
30% of total supply reserved
Buyers receive pro-rata airdrop based on purchase
Claimable once per year for 5 years
claimAirdrop()
Prevents dump. Encourages long-term holding.
3. Burning (Deflationary)
Two burn functions:
Function
Who
Burns From
burn(amount)
Any holder
Their own balance
burnContractTokens(amount)
Owner only
Contract's unsold tokens
// Holder burns their tokens
await token.burn(100e18);

// Owner reduces unsold supply
await token.burnContractTokens(500000e18);
No burnFrom() → No one can burn your tokens
4. Multisig Governance (Signers)
Configurable requiredApprovals
Signers can:
Create proposals
Approve proposals
Execute (when threshold met)
createProposal(token, to, amount)
approveProposal(id)
executeProposal(id)
Used for treasury withdrawals, upgrades, or partnerships.
5. Admin Functions (Owner Only)
setFldPriceUSDT6(price)
setPriceFeed(token, feed)
setNativePriceFeed(feed)
setFoundationWallet(addr)
setRelayerWallet(addr)
All settings are updatable but fully transparent.
Security & Transparency
Feature
Status
Open Source
Verified on Polygonscan
No Mint Function
totalSupply fixed at deploy
No Pausable
No central kill switch
No Blacklist
Fully decentralized
CI/CD Pipeline
Auto-test, deploy, verify
Contract Address (Polygon)
0xec9123Aa60651ceee7c0E084c884Cd33478c92a5
View on Polygonscan
Wallets
Role
Address
Foundation
0x51b88d94a23e91770b2ccc1d24ac6804551e1262
Relayer
0x96f3d6c8e43518f1f62ff530ebf8ef8faf5b8063
Marketing
0xD40C17e2076A6CaB4fCb4C7ad50693c0bd87c96F
Team
0x22A978289a5864be1890DAC00154A7d343273342
Dev
0x4cA465F7B25b630B62b4C36b64Dff963f81E27C0
How to Interact
// Buy with USDT
await usdt.approve(tokenAddr, 100e6);
await token.buyWithERC20(usdtAddr, 100e6);

// Buy with POL
await token.buyWithNative({ value: ethers.parseEther("10") });

// Burn
await token.burn(ethers.parseUnits("100", 18));

// Claim Airdrop (after 1 year)
await token.claimAirdrop();
Fair. Transparent. Deflationary. Governed.
