const { run } = require("hardhat");  // Hardhat 3 style for tasks
require("dotenv").config();

async function main() {
  const network = require("hardhat").network.name;  // Hardhat 3 access
  console.log(`🔍 Verifying on ${network.toUpperCase()} PolygonScan...`);

  const contractAddress = "0xYourDeployedContractAddressHere";  // UPDATE!

  if (contractAddress === "0xYourDeployedContractAddressHere") {
    throw new Error("Update contractAddress in script!");
  }

  const args = require("./arguments.js");

  console.log("Constructor args:", args);

  await run("verify:verify", {
    address: contractAddress,
    constructorArguments: args,
  });

  const scanUrl = network === 'polygon' ? `https://polygonscan.com/address/${contractAddress}` : `https://mumbai.polygonscan.com/address/${contractAddress}`;
  console.log(`✅ Verified! View at: ${scanUrl}#code`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});