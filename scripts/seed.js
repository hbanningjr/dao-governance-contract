// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat');
const config = require('../src/config.json');

const tokens = (n) => {
  return hre.ethers.utils.parseUnits(n.toString(), 'ether');
};

const ether = tokens;

async function main() {
  console.log(`Fetching accounts & network...\n`);

  const accounts = await hre.ethers.getSigners();
  const funder = accounts[0];
  const investor1 = accounts[1];
  const investor2 = accounts[2];
  const investor3 = accounts[3];
  const recipient = accounts[4];

  let transaction;

  const { chainId } = await ethers.provider.getNetwork();
  console.log(chainId);

  console.log(`Fetching token and transferring to accounts...\n`);

  const token = await ethers.getContractAt('Token', config[chainId].token.address);
  console.log(`Token fetched at ${token.address}\n`);

  transaction = await token.transfer(investor1.address, tokens(200000));
  await transaction.wait();

  transaction = await token.transfer(investor2.address, tokens(200000));
  await transaction.wait();

  transaction = await token.transfer(investor3.address, tokens(200000));
  await transaction.wait();

  console.log(`Fetching dao...\n`);

  const dao = await ethers.getContractAt('DAO', config[chainId].dao.address);
  console.log(`DAO fetched: ${dao.address}\n`);

  transaction = await funder.sendTransaction({
    to: dao.address,
    value: ether(1000),
  });
  await transaction.wait();
  console.log(`Sent funds to DAO treasury\n`);

  for (let i = 0; i < 3; i++) {
    transaction = await dao.connect(investor1).createProposal(`Proposal${i + 1}`, ether(100), recipient.address);
    await transaction.wait();

    transaction = await dao.connect(investor1).vote(i + 1);
    await transaction.wait();

    transaction = await dao.connect(investor2).vote(i + 1);
    await transaction.wait();

    transaction = await dao.connect(investor3).vote(i + 1);
    await transaction.wait();

    transaction = await dao.connect(investor1).finalizeProposal(i + 1);
    await transaction.wait();

    console.log(`Finalized proposal ${i + 1}\n`);
  }

  console.log(`Creating one more proposal...\n`);

  transaction = await dao.connect(investor1).createProposal(`Proposal4`, ether(100), recipient.address);
  await transaction.wait();

  transaction = await dao.connect(investor1).vote(4);
  await transaction.wait();

  transaction = await dao.connect(investor2).vote(4);
  await transaction.wait();

  transaction = await dao.connect(investor3).vote(4);
  await transaction.wait();

  console.log(`Finished.\n`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
