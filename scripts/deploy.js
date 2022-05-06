// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  const [holder, wallet1] = await ethers.getSigners();
  console.log(`holder address: ${holder.address}, wallet1 address: ${wallet1.address}`);

  // We get the contract to deploy
  const Wbtc = await ethers.getContractFactory("Wbtc", holder);
  const wbtc = await Wbtc.deploy();
  await wbtc.deployed();
  console.log("Wbtc deployed to:", wbtc.address);

  // Deploying staking contract
  const Staking = await ethers.getContractFactory("Staking", wallet1);
  const staking = await Staking.deploy();

  // whitelisting wbtc to staking contract
  await staking.whitelistCoin('wbtc', wbtc.address);
  const whitelistedAdd = await staking.whitelistedCoin('wbtc');
  console.log('whitelistedCoin: ', whitelistedAdd);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
