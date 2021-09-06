import { Signer } from "@ethersproject/abstract-signer";
import { BigNumber } from "@ethersproject/bignumber";
import { Contract, ContractFactory } from "@ethersproject/contracts";
import { ethers } from "hardhat";

async function main(): Promise<void> {

  const collectionName: string = "Heroic Story";
  const collectionSymbol: string = "STORY";
  const proxyRegistryAddress: string = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";

  const [deployer]: Signer[] = await ethers.getSigners();
  console.log(`Deploying with address:`, await deployer.getAddress());
  
  const heroicStoryFactory: ContractFactory = await ethers.getContractFactory("HeroicStory");
  const heroicStory: Contract = await heroicStoryFactory.deploy(
    collectionName,
    collectionSymbol,
    proxyRegistryAddress
  )

  const tx = await heroicStory.deployTransaction.wait()

  console.log(`HeroicStory deploy estimate: `, parseInt((tx.gasUsed).toString()));
}

main()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })