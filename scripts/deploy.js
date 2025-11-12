async function main() {
  const FluidToken = await ethers.getContractFactory("FluidToken");
  const args = require("../arguments.js");
  const token = await FluidToken.deploy(...args);

  await token.waitForDeployment();
  console.log("FluidToken deployed to:", await token.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});