const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("FluidTokenModule", (m) => {
  // Load constructor args from arguments.js (adjust path if needed)
  const args = require("../../arguments.js");

  // Deploy FluidToken with constructor args
  const fluidToken = m.contract("FluidToken", args, {
    // Optional: Gas settings or from account
    // from: deployer.address,
    // gasLimit: 5000000,
  });

  // Optional: Post-deployment calls (e.g., set price feed)
  // m.call(fluidToken, "setBasePriceUSDT6", [1e6]); // Example: Set initial price

  // Return the deployed contract for chaining in other modules
  return { fluidToken };
});