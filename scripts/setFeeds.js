const hre = require("hardhat");

async function main() {
  const contractAddress = "0xYourDeployedAddress";  // From deploy
  const FluidToken = await hre.ethers.getContractAt("FluidToken", contractAddress);

  // Polygon Mainnet Chainlink Feeds (verify at docs.chain.link)
  const nativeFeed = "0xF9680D99D6C9589e2a93a78A04A279e509205945";  // MATIC/USD
  const USDC = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";  // USDC
  const usdcFeed = "0x572dDec9087168Ec5f5a7bE85dF8c8c0D8C5bB0f";  // USDC/USD

  const tx1 = await FluidToken.setNativePriceFeed(nativeFeed);
  await tx1.wait();
  console.log("✅ Native (MATIC/USD) feed set");

  const tx2 = await FluidToken.setPriceFeed(USDC, usdcFeed);
  await tx2.wait();
  console.log("✅ USDC feed set");
}

main().catch(console.error);