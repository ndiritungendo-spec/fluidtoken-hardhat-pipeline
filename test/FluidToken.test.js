const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FluidToken", function () {
  let token, owner, addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    const signers = [owner.address, addr1.address];
    const FluidToken = await ethers.getContractFactory("FluidToken");
    token = await FluidToken.deploy(
      owner.address,  // foundation
      owner.address,  // relayer
      signers,
      1,  // approvals
      owner.address,  // marketing
      owner.address,  // team
      owner.address   // dev
    );
    await token.waitForDeployment();
  });

  it("Should mint total supply and transfer allocations", async function () {
    const totalSupply = await token.TOTAL_SUPPLY();
    expect(await token.totalSupply()).to.equal(totalSupply);
    expect(await token.balanceOf(owner.address)).to.equal(totalSupply);  // Initial mint to contract, then transfers
  });

  it("Should allow owner to pause sales", async function () {
    await expect(token.pauseSales()).to.emit(token, "SalesPaused").withArgs(true);
    expect(await token.salesPaused()).to.be.true;
  });
});