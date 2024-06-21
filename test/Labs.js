const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LABS Token", function () {
  let LABS;
  let labsLogic;
  let labsProxy;
  let labs;
  let owner;
  let addr1;
  let addr2;
  let devWallet;
  let uniswapRouter;

  beforeEach(async function () {
    [owner, addr1, addr2, devWallet] = await ethers.getSigners();

    // Deploy mock UniswapV2Router
    const MockRouter = await ethers.getContractFactory("MockUniswapV2Router");
    uniswapRouter = await MockRouter.deploy();
    await uniswapRouter.waitForDeployment();

    // Deploy LABS logic contract
    LABS = await ethers.getContractFactory("LABS");
    labsLogic = await LABS.deploy();
    await labsLogic.waitForDeployment();

    // Deploy the LABSProxy contract
    const LABSProxy = await ethers.getContractFactory("LABSProxy");
    
    // Prepare the constructor data for the LABS contract
    const constructData = LABS.interface.encodeFunctionData("LABSConstructor");

    labsProxy = await LABSProxy.deploy(constructData, await labsLogic.getAddress());
    await labsProxy.waitForDeployment();

    // Create an instance of the LABS contract at the proxy address
    labs = LABS.attach(await labsProxy.getAddress());

    // Set UniswapV2Router
    await labs.setUniswapV2Router(await uniswapRouter.getAddress());
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await labs.owner()).to.equal(owner.address);
    });

    it("Should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await labs.balanceOf(owner.address);
      expect(await labs.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe("Transactions", function () {
    it("Should transfer tokens between accounts", async function () {
      await labs.transfer(addr1.address, 50);
      const addr1Balance = await labs.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(50);

      await labs.connect(addr1).transfer(addr2.address, 50);
      const addr2Balance = await labs.balanceOf(addr2.address);
      expect(addr2Balance).to.equal(50);
    });

    it("Should fail if sender doesn't have enough tokens", async function () {
      const initialOwnerBalance = await labs.balanceOf(owner.address);
      await expect(
        labs.connect(addr1).transfer(owner.address, 1)
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
      expect(await labs.balanceOf(owner.address)).to.equal(initialOwnerBalance);
    });

    it("Should update balances after transfers", async function () {
      const initialOwnerBalance = await labs.balanceOf(owner.address);
      await labs.transfer(addr1.address, 100);
      await labs.transfer(addr2.address, 50);

      const finalOwnerBalance = await labs.balanceOf(owner.address);
      expect(finalOwnerBalance).to.equal(initialOwnerBalance - 150n);

      const addr1Balance = await labs.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(100);

      const addr2Balance = await labs.balanceOf(addr2.address);
      expect(addr2Balance).to.equal(50);
    });
  });

  describe("Fees", function () {
    it("Should exclude owner from fees", async function () {
      expect(await labs.isExcludedFromFees(owner.address)).to.be.true;
    });

    it("Should allow owner to exclude address from fees", async function () {
      await labs.excludeFromFees(addr1.address, true);
      expect(await labs.isExcludedFromFees(addr1.address)).to.be.true;
    });
  });

  describe("Owner functions", function () {
    it("Should allow owner to set dev wallet", async function () {
      await labs.setDevWallet(devWallet.address);
      expect(await labs.devWallet()).to.equal(devWallet.address);
    });

    it("Should allow owner to set buy tax", async function () {
      await labs.setBuyTaxFee(7);
      expect(await labs.buyTax()).to.equal(7);
    });

    it("Should allow owner to set sell tax", async function () {
      await labs.setSellFee(8);
      expect(await labs.sellTax()).to.equal(8);
    });

    it("Should allow owner to set max transfer", async function () {
      const newMaxTransfer = ethers.parseEther("1000000");
      await labs.setMaxTransfer(newMaxTransfer);
      expect(await labs.maxTransfer()).to.equal(newMaxTransfer);
    });

    it("Should allow owner to update code", async function () {
      const NewLABS = await ethers.getContractFactory("LABS");
      const newLabsLogic = await NewLABS.deploy();
      await newLabsLogic.waitForDeployment();

      await labs.updateCode(await newLabsLogic.getAddress());
      
      // You might want to add more assertions here to verify the upgrade was successful
    });
  });
});