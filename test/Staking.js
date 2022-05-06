const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking", function() {
    let staking, wbtc;
    let holder, wallet1, wallet2;
    beforeEach(async function() {
        // Get wallet for signing transactions
        [holder, wallet1, wallet2] = await ethers.getSigners();
        
        // Deploying contracts
        const Wbtc = await ethers.getContractFactory("Wbtc", holder);
        wbtc = await Wbtc.deploy();
        const Staking = await ethers.getContractFactory("Staking", wallet1);
        staking = await Staking.deploy();

        // Whitelisting wbtc in staking contracts
        await staking.whitelistCoin("wbtc", wbtc.address);
    });

    describe('deployment', function() {
        it('should mint tokens to holder', async function() {
            expect(await wbtc.balanceOf(holder.address)).to.equal(5000);
        });

        it('owner in staking contract should be set', async function() {
            expect(await staking.owner()).to.equal(wallet1.address);
        });

        it('whitelist coin should show in staking contract', async function() {
            expect(await staking.whitelistedCoin('wbtc')).to.equal(wbtc.address);
        });

        it('should deposit 100 coin into staking contract', async function() {
            // Approve contract first before transferFrom can be used
            await wbtc.approve(staking.address, 100);
            expect(await wbtc.allowance(holder.address, staking.address)).to.equal(100);

            await staking.connect(holder).depositCoin('wbtc', 100);
            expect(await staking.stakingBalance(holder.address, 'wbtc')).to.equal(100);
            expect(await wbtc.balanceOf(holder.address)).to.equal(4900);
        });

        it('should withdraw 5 coin into staking contract', async function() {
            // Approve contract first before transferFrom can be used
            await wbtc.approve(staking.address, 10);
            await staking.connect(holder).depositCoin('wbtc', 10);
            await staking.connect(holder).withdrawCoin('wbtc', 10);
            expect(await staking.stakingBalance(holder.address, 'wbtc')).to.equal(0);
            expect(await wbtc.balanceOf(holder.address)).to.equal(5000);
        });
    });
});