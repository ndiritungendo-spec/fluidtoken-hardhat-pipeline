require("dotenv").config();

const foundationWallet = process.env.FOUNDATION_WALLET || "0xYourFoundationAddress";  // e.g., deployer wallet
const relayerWallet = process.env.RELAYER_WALLET || "0xYourRelayerAddress";  // e.g., bot wallet
const signers = (process.env.SIGNERS || "0xSigner1,0xSigner2").split(',').map(s => s.trim());  // Array: Comma-separated from .env
const requiredApprovals = parseInt(process.env.REQUIRED_APPROVALS || "2");  // uint256
const marketingWallet = process.env.MARKETING_WALLET || "0xYourMarketingAddress";  // 10% supply
const teamWallet = process.env.TEAM_WALLET || "0xYourTeamAddress";  // 10% supply
const devWallet = process.env.DEV_WALLET || "0xYourDevAddress";  // 10% supply

// Validate basics
if (!foundationWallet || !relayerWallet || signers.length < requiredApprovals || !marketingWallet || !teamWallet || !devWallet) {
  throw new Error("Missing required args in .env – check template!");
}

// Export as array for spread in deploy(...)
module.exports = [
  foundationWallet,
  relayerWallet,
  signers,  // Hardhat handles array serialization
  requiredApprovals,
  marketingWallet,
  teamWallet,
  devWallet
];