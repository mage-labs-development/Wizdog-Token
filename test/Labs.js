const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("LABS", function () {
  async function deployLABSFixture() {
    const [owner, otherAccount] = await ethers.getSigners();

    const LABS = await ethers.getContractFactory("LABS");
    const labs = await upgrades.deployProxy(LABS, [], { initializer: "LABSConstructor" });
    await labs.deployed();

    return { labs, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { labs, owner } = await deployLABSFixture();
      expect(await labs.owner()).to.equal(owner.address);
    });

    it("Should mint 1 billion tokens to the owner", async function () {
      const { labs, owner } = await deployLABSFixture();
      const totalSupply = await labs.totalSupply();
      expect(await labs.balanceOf(owner.address)).to.equal(totalSupply);
    });
  });

  describe("Fees", function () {
    it("Should set buy and sell fees correctly", async function () {
      const { labs } = await deployLABSFixture();
      const buyTax = await labs.buyTax();
      const sellTax = await labs.sellTax();

      expect(buyTax).to.equal(5);
      expect(sellTax).to.equal(5);
    });

    it("Should apply buy tax when buying from Uniswap", async function () {
      const { labs, owner, otherAccount } = await deployLABSFixture();
      await labs.setUniswapV2Router(otherAccount.address); // Assuming using otherAccount as router for simplicity
      await labs.setOwner(owner.address);  // Needed for `initialize`

      const amount = ethers.utils.parseUnits("100", 18); // 100 tokens
      await labs.transfer(otherAccount.address, amount); // Simulate buying by transferring to the Uniswap router

      const tax = amount.mul(labs.buyTax()).div(100); // 5% tax
      const expectedBalance = amount.sub(tax);

      expect(await labs.balanceOf(otherAccount.address)).to.equal(expectedBalance);
    });

    it("Should apply sell tax when selling to Uniswap", async function () {
      const { labs, owner, otherAccount } = await deployLABSFixture();
      await labs.setUniswapV2Router(owner.address);  // Needed for `initialize`
      await labs.setOwner(owner.address);  // Needed for `initialize`

      const amount = ethers.utils.parseUnits("100", 18); // 100 tokens
      await labs.transfer(owner.address, amount); // Simulate selling by transferring to the Uniswap pair contract

      const tax = amount.mul(labs.sellTax()).div(100); // 5% tax
      const expectedBalance = amount.sub(tax);

      expect(await labs.balanceOf(owner.address)).to.equal(expectedBalance);
    });
  });

  describe("Ownership", function () {
    it("Should allow owner to update owner address", async function () {
      const { labs, owner, otherAccount } = await deployLABSFixture();
      await labs.connect(owner).setOwner(otherAccount.address);
      expect(await labs.owner()).to.equal(otherAccount.address);
    });

    it("Should fail if non-owner tries to update owner address", async function () {
      const { labs, owner, otherAccount } = await deployLABSFixture();
      await expect(labs.connect(otherAccount).setOwner(otherAccount.address)).to.be.revertedWith(
        "The library is locked. No direct 'call' is allowed"
      );
    });
  });

  describe("Transfers", function () {
    it("Should transfer tokens properly", async function () {
      const { labs, owner, otherAccount } = await deployLABSFixture();

      const amount = ethers.utils.parseUnits("100", 18); // 100 tokens
      await labs.transfer(otherAccount.address, amount);

      expect(await labs.balanceOf(otherAccount.address)).to.equal(amount);
      expect(await labs.balanceOf(owner.address)).to.equal(await labs.totalSupply().sub(amount));
    });

    it("Should fail transfer if exceeds max transfer limit", async function () {
      const { labs, owner, otherAccount } = await deployLABSFixture();

      const maxTransfer = await labs.maxTransfer();
      const amount = maxTransfer.add(ethers.utils.parseUnits("1", 18)); // Exceeding by 1 token

      await expect(labs.transfer(otherAccount.address, amount)).to.be.revertedWith(
        "Transfer amount exceeds the maximum limit"
      );
    });
  });
});