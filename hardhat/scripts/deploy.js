// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  // --- CryptoDevsNFT deployment ---
  const nftContract = await hre.ethers.deployContract("CryptoDevsNFT");
  await nftContract.waitForDeployment();
  console.log("CryptoDevsNFT address: ", nftContract.target);

  // --- FakeNFTMarketPlace deployment ---
  const fakeNftMarketPlace = await hre.ethers.deployContract(
    "FakeNFTMarketPlace"
  );
  await fakeNftMarketPlace.waitForDeployment();
  console.log("FakeNFTMarketPlace address: ", fakeNftMarketPlace.target);

  // --- CryptoDevsDAO deployment ---
  const cryptoDevsDao = await hre.ethers.deployContract("CryptoDevsDAO", [
    fakeNftMarketPlace.target,
    nftContract.target,
  ]);
  await cryptoDevsDao.waitForDeployment();
  console.log("CryptoDevsDAO address: ", cryptoDevsDao.target);

  // Wait for 30 seconds before proceeding with contract verification
  await sleep(30 * 1000);

  // --- CryptoDevsNFT verification ---
  await hre.run("verify:verify", {
    address: nftContract.target,
    constructorArguments: [],
  });

  // --- FakeNFTMarketPlace verification ---
  await hre.run("verify:verify", {
    address: fakeNftMarketPlace.target,
    constructorArguments: [],
  });

  // --- CryptoDevsDAO deployment ---
  await hre.run("verify:verify", {
    address: cryptoDevsDao.target,
    constructorArguments: [fakeNftMarketPlace.target, nftContract.target],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
