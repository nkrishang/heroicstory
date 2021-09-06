import { ethers } from "hardhat"
import { expect } from "chai"
import { Contract, ContractFactory } from "@ethersproject/contracts"
import { Signer } from "@ethersproject/abstract-signer"

describe("Testing entire basic flow", function() {
  
  // Get signers.
  let owner: Signer;
  let contributors: Signer[];
  
  // Get contract objects.
  let heroicStoryFactory: ContractFactory;
  let heroicStory: Contract;

  // Constructor variables
  const name: string = "Heroic Story"
  const symbol: string = "STORY"
  const proxyRegistryAddress: string = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";

  // Testing variables;
  const nftTokenId: number = 1;

  // Minting args.
  const lootAddress = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
  const lootTokenId = 6;

  before(async () => {
    // Get signers.
    const signers: Signer[] = await ethers.getSigners()
    owner = signers[0];
    contributors = (signers).slice(1, -1);

    // Get contract factory.
    heroicStoryFactory = await ethers.getContractFactory("HeroicStory");
  })

  describe("Test deployment", function () {

    it("Should deploy successfully", async () => {
      const heroicStoryContract: Contract = await heroicStoryFactory.connect(owner).deploy(name, symbol, proxyRegistryAddress);
      expect(await heroicStoryContract.MAX_BPS()).to.equal(10000);
    })
  })

  describe("Test minting", async () => {
    beforeEach(async () => {
      heroicStory = await heroicStoryFactory.connect(owner).deploy(name, symbol, proxyRegistryAddress);
    })

    it("Should let owner mint the NFT successfully", async () => {
      const MintedNFTPromise = new Promise((resolve, reject) => {
        heroicStory.on("MintedNFT", async (tokenId, minter, derivedFromNFT, derivedFromTokenId) => {

          console.log(tokenId, minter, derivedFromNFT, derivedFromTokenId)

          expect(tokenId).to.equal(nftTokenId);
          // expect(minter).to.equal(await owner.getAddress());
          // expect(derivedFromNFT).to.equal(lootAddress);
          expect(derivedFromTokenId).to.equal(lootTokenId);

          resolve(null)
        })

        setTimeout(() => {
          reject(new Error("Timeout: MintedNFT"))
        }, 10000)
      })

      await heroicStory.mintTo(await owner.getAddress(), lootAddress, lootTokenId);
      await MintedNFTPromise;

      expect(await heroicStory.ownerOf(nftTokenId)).to.equal(await owner.getAddress());
    })
  })
})