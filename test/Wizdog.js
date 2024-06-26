const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("WIZDOG Token", function () {
  let WIZDOG;
  let wizdogLogic;
  let wizdogProxy;
  let wizdog;
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

    // Deploy WIZDOG logic contract
    WIZDOG = await ethers.getContractFactory("Wizdog");
    wizdogLogic = await WIZDOG.deploy();
    await wizdogLogic.waitForDeployment();

    // Deploy the WIZDOGProxy contract
    const WIZDOGProxy = await ethers.getContractFactory("WIZDOGProxy");
    
    // Prepare the constructor data for the WIZDOG contract
    const constructData = WIZDOG.interface.encodeFunctionData("WizdogConstructor");

    wizdogProxy = await WIZDOGProxy.deploy(constructData, await wizdogLogic.getAddress());
    await wizdogProxy.waitForDeployment();

    // Create an instance of the WIZDOG contract at the proxy address
    wizdog = WIZDOG.attach(await wizdogProxy.getAddress());

    // Set UniswapV2Router
    await wizdog.setUniswapV2Router(await uniswapRouter.getAddress());
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await wizdog.owner()).to.equal(owner.address);
    });

    it("Should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await wizdog.balanceOf(owner.address);
      expect(await wizdog.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe("Transactions", function () {
    it("Should transfer tokens between accounts", async function () {
      await wizdog.transfer(addr1.address, 50);
      const addr1Balance = await wizdog.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(50);

      await wizdog.connect(addr1).transfer(addr2.address, 50);
      const addr2Balance = await wizdog.balanceOf(addr2.address);
      expect(addr2Balance).to.equal(50);
    });

    it("Should fail if sender doesn't have enough tokens", async function () {
      const initialOwnerBalance = await wizdog.balanceOf(owner.address);
      await expect(
        wizdog.connect(addr1).transfer(owner.address, 1)
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
      expect(await wizdog.balanceOf(owner.address)).to.equal(initialOwnerBalance);
    });

    it("Should update balances after transfers", async function () {
      const initialOwnerBalance = await wizdog.balanceOf(owner.address);
      await wizdog.transfer(addr1.address, 100);
      await wizdog.transfer(addr2.address, 50);

      const finalOwnerBalance = await wizdog.balanceOf(owner.address);
      expect(finalOwnerBalance).to.equal(initialOwnerBalance - 150n);

      const addr1Balance = await wizdog.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(100);

      const addr2Balance = await wizdog.balanceOf(addr2.address);
      expect(addr2Balance).to.equal(50);
    });
  });

  describe("Fees", function () {
    it("Should exclude owner from fees", async function () {
      expect(await wizdog.isExcludedFromFees(owner.address)).to.be.true;
    });

    it("Should allow owner to exclude address from fees", async function () {
      await wizdog.excludeFromFees(addr1.address, true);
      expect(await wizdog.isExcludedFromFees(addr1.address)).to.be.true;
    });
  });

  describe("Owner functions", function () {
    it("Should allow owner to set dev wallet", async function () {
      await wizdog.setDevWallet(devWallet.address);
      expect(await wizdog.devWallet()).to.equal(devWallet.address);
    });

    it("Should allow owner to set buy tax", async function () {
      await wizdog.setBuyTaxFee(7);
      expect(await wizdog.buyTax()).to.equal(7);
    });

    it("Should allow owner to set sell tax", async function () {
      await wizdog.setSellFee(8);
      expect(await wizdog.sellTax()).to.equal(8);
    });

    it("Should allow owner to set max transfer", async function () {
      const newMaxTransfer = ethers.parseEther("1000000");
      await wizdog.setMaxTransfer(newMaxTransfer);
      expect(await wizdog.maxTransfer()).to.equal(newMaxTransfer);
    });

    it("Should allow owner to update code", async function () {
      const NewWIZDOG = await ethers.getContractFactory("Wizdog");
      const newWizdogLogic = await NewWIZDOG.deploy();
      await newWizdogLogic.waitForDeployment();

      await wizdog.updateCode(await newWizdogLogic.getAddress());
      
      // You might want to add more assertions here to verify the upgrade was successful
    });
  });
});