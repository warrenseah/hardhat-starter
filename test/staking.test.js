const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Staking", function () {
  let staking, wbtc;
  let holder, wallet1, wallet2;

  async function deployFixture() {
    // Get wallet for signing transactions
    [holder, wallet1, wallet2] = await ethers.getSigners();

    // We get the contract to deploy
    wbtc = await ethers.deployContract("Wbtc");
    await wbtc.waitForDeployment();
    // console.log("Wbtc deployed to:", wbtc.target);

    // Deploying staking contract
    staking = await ethers.deployContract("Staking", wallet1);
    await staking.waitForDeployment();

    // whitelisting wbtc to staking contract
    await staking.whitelistCoin("wbtc", wbtc.target);
  }

  //   beforeEach(async function () {
  //     // Get wallet for signing transactions
  //     [holder, wallet1, wallet2] = await ethers.getSigners();

  //     // Deploying contracts
  //     const Wbtc = await ethers.getContractFactory("Wbtc", holder);
  //     wbtc = await Wbtc.deploy();
  //     const Staking = await ethers.getContractFactory("Staking", wallet1);
  //     staking = await Staking.deploy();

  //     // Whitelisting wbtc in staking contracts
  //     await staking.whitelistCoin("wbtc", wbtc.address);
  //   });

  describe("deployment", function () {
    it("should mint tokens to holder", async function () {
      await loadFixture(deployFixture);
      expect(await wbtc.balanceOf(holder.address)).to.equal(5000);
    });

    it("owner in staking contract should be set", async function () {
      expect(await staking.owner()).to.equal(wallet1.address);
    });

    it("whitelist coin should show in staking contract", async function () {
      expect(await staking.whitelistedCoin("wbtc")).to.equal(wbtc.target);
    });

    it("should deposit 100 coin into staking contract", async function () {
      // Approve contract first before transferFrom can be used
      await wbtc.approve(staking.target, 100);
      expect(await wbtc.allowance(holder.address, staking.target)).to.equal(
        100
      );

      await staking.connect(holder).depositCoin("wbtc", 100);
      expect(await staking.stakingBalance(holder.address, "wbtc")).to.equal(
        100
      );
      expect(await wbtc.balanceOf(holder.address)).to.equal(4900);
    });

    it("should withdraw 5 coin into staking contract", async function () {
      // Reset
      await loadFixture(deployFixture);
      // Approve contract first before transferFrom can be used
      await wbtc.approve(staking.target, 10);
      await staking.connect(holder).depositCoin("wbtc", 10);
      await staking.connect(holder).withdrawCoin("wbtc", 10);
      expect(await staking.stakingBalance(holder.address, "wbtc")).to.equal(0);
      expect(await wbtc.balanceOf(holder.address)).to.equal(5000);
    });
  });
});
