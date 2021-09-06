import { Contract } from "@ethersproject/contracts";
import { Signer } from "@ethersproject/abstract-signer";
import { ethers } from "hardhat"

async function main() {

  const contractURI: string = "https://gateway.pinata.cloud/ipfs/QmersbCSAumpkMQHwqPCEqiNNGXRB9t2goXwqCcDMfmpAs"

  // Get signer.
  const [caller]: Signer[] = await ethers.getSigners()

  // Get contract.
  const contractAddr: string = "0x2795d6a72c6b93BC4264dA368dCD49405033EDa9"
  const heroicStory: Contract = await ethers.getContractAt("HeroicStory", contractAddr, caller);

  // Set contract URI
  const tx = await heroicStory.setContractURI(contractURI);
  console.log("Setting contract URI: ", tx.hash);

  await tx.wait()
  console.log("Done!")
}

main()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })