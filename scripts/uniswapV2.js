// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers, provider } = hre;


const addresses = {
	WBNB: '0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c',
	CAKE: '0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82',
	factory: '0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73',
	router: '0x10ED43C718714eb63d5aA57B78B54704E256024E',
	bnbWhale: '0x8894e0a0c962cb723c1976a4421c95949be2d4e3'
}

async function main() {
	// Hardhat always runs the compile task when running scripts with its command
	// line interface.
	//
	// If this script is run directly using `node` you may want to call compile
	// manually to make sure everything is compiled
	// await hre.run('compile');

	// impersonateAccounts
	await hre.network.provider.request({
		method: "hardhat_impersonateAccount",
		params: [addresses.bnbWhale],
	});

	const whaleSigner = await ethers.getSigner(addresses.bnbWhale);
	console.log(`bnbWhale: ${await whaleSigner.getAddress()}`);
	// const ethBalance = await whaleSigner.getBalance();
	// console.log(`bnb balance: ${ethers.utils.formatEther(ethBalance)}`);

	const wbnb = new ethers.Contract(
		addresses.WBNB,
		[
			'function approve(address spender, uint amount) public returns(bool)',
			'function balanceOf(address) public view returns(uint256)',
			'function transfer(address to, uint256 amount) public returns(bool)',
			'function transferFrom(address from, address to, uint256 amount) public returns(bool)'
		],
		whaleSigner
	);

	// console.log(`Contract for ${await wbnb.name()}`);
	const [wallet] = await ethers.getSigners();

	// // Transfer wbnb from bnbWhale to wallet1
	const amountSend = ethers.utils.parseEther('200');
	const txn = await wbnb.transfer(wallet.address, amountSend);
	const receipt = await txn.wait();
	console.log(`${ethers.utils.formatEther(amountSend)} WBNB sent: ${receipt.transactionHash}`);

	const beforeWBNBBal = await wbnb.balanceOf(wallet.address);
	console.log(`before WBNB balance: ${ethers.utils.formatUnits(beforeWBNBBal)}`);

	// Do a swap on pancakeswap from wbnb to cake token.
	const router = new ethers.Contract(
		addresses.router,
		[
			'function getAmountsOut(uint256 amountIn, address[] memory path) public view returns(uint256[] memory)',
			'function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns(uint256[] memory amounts)'
		],
		wallet
	);

	const walletWBNBSigner = wbnb.connect(wallet);
	// approve router to spend wallet wbnb
	const amountIn = ethers.utils.parseEther('100');
	await walletWBNBSigner.approve(addresses.router, amountIn);
	// Get the estimates for amountOut from PCS
	const path = [addresses.WBNB, addresses.CAKE];
	const amountOutObj = await router.getAmountsOut(amountIn, path);
	const amountOutMin = amountOutObj[1].mul(ethers.BigNumber.from('90')).div(ethers.BigNumber.from('100'));

	await router.swapExactTokensForTokens(amountIn, amountOutMin, path, wallet.address, Math.floor((Date.now() / 1000)) + 60 * 5);

	const afterWBNBBal = await wbnb.balanceOf(wallet.address);
	console.log(`After WBNB balance: ${ethers.utils.formatUnits(afterWBNBBal)}`);

	const cake = walletWBNBSigner.attach(addresses.CAKE);
	const cakeBal = await cake.balanceOf(wallet.address);

	console.log(`cake swapped: ${ethers.utils.formatUnits(cakeBal)} CAKE`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
