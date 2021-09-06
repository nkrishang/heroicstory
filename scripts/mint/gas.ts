import { Signer } from "@ethersproject/abstract-signer";
import { BigNumber } from "@ethersproject/bignumber";
import { Contract, ContractFactory } from "@ethersproject/contracts";
import { ethers } from "hardhat";

async function main(): Promise<void> {

  const collectionName: string = "Heroic Story";
  const collectionSymbol: string = "STORY";
  const proxyRegistryAddress: string = "0xf57b2c51ded3a29e6891aba85459d600256cf317"; // rinkeby

  const [deployer]: Signer[] = await ethers.getSigners();
  console.log(`Deploying with address:`, await deployer.getAddress());
  
  const heroicStoryFactory: ContractFactory = await ethers.getContractFactory("HeroicStory");
  const heroicStory: Contract = await heroicStoryFactory.deploy(
    collectionName,
    collectionSymbol,
    proxyRegistryAddress
  )

  const toAddress = "0xf57b2c51ded3a29e6891aba85459d600256cf317"
  const nftURI = "https://apestandard.com"
  const nftDerivedFrom = "0xf57b2c51ded3a29e6891aba85459d600256cf317"
  const nftDerivedTokenId = 6

  const gasEstimateToMint: BigNumber = await heroicStory.estimateGas.mintTo(toAddress, nftURI, nftDerivedFrom, nftDerivedTokenId);

  console.log("Gas estimate to mint: ", parseInt( gasEstimateToMint.toString() ))
}

main()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })