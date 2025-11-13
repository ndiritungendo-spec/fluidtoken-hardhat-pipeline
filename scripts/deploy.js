const { ethers, network } = require("hardhat");  // Add network for logging

async function main() {
  console.log(`\n🚀 Deploying to ${network.name.toUpperCase()}...`);

  const FluidToken = await ethers.getContractFactory("FluidToken");
  const args = require("../arguments.js");

  // Optional: Polygon gas boost
  const deployOverrides = network.name === "polygon" ? { gasPrice: 30000000000n } : {};

  const token = await FluidToken.deploy(...args, deployOverrides);

  await token.waitForDeployment();
  const address = await token.getAddress();
  console.log("✅ FluidToken deployed to:", address);
  console.log("Deployment tx:", await token.deploymentTransaction().hash);

  console.log(`\n💡 Next: Run 'npm run verify:polygon' and set Chainlink feeds.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});