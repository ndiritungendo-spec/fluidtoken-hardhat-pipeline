const hre = require("hardhat");
require("dotenv").config();

async function main() {
  const network = hre.network.name;
  console.log(`🔍 Verifying on ${network.toUpperCase()} PolygonScan...`);

  // UPDATE THIS with deployed address from deploy.js
  const contractAddress = "0xYourDeployedContractAddressHere";

  if (contractAddress === "0xYourDeployedContractAddressHere") {
    throw new Error("Update contractAddress in script!");
  }

  // Load args from .env (MUST match deploy)
  const foundationWallet = process.env.FOUNDATION_WALLET;
  const relayerWallet = process.env.RELAYER_WALLET;
  const signersStr = (process.env.SIGNERS || "").split(',').map(s => s.trim()).filter(Boolean);
  const requiredApprovals = parseInt(process.env.REQUIRED_APPROVALS || "2");
  const marketingWallet = process.env.MARKETING_WALLET;
  const teamWallet = process.env.TEAM_WALLET;
  const devWallet = process.env.DEV_WALLET;

  const constructorArgs = [
    foundationWallet,
    relayerWallet,
    signersStr,
    requiredApprovals,
    marketingWallet,
    teamWallet,
    devWallet
  ];

  console.log("Constructor args:", constructorArgs);

  await hre.run("verify:verify", {
    address: contractAddress,
    constructorArguments: constructorArgs,
  });

  const scanUrl = network === 'polygon' ? `https://polygonscan.com/address/${contractAddress}` : `https://mumbai.polygonscan.com/address/${contractAddress}`;
  console.log(`✅ Verified! View at: ${scanUrl}#code`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});