import { Signer } from "@ethersproject/abstract-signer";
import { ethers } from "hardhat";

async function main() {
  
  // Get signers
  const [somePerson]: Signer[] = await ethers.getSigners();
}

main()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })