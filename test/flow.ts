import { ethers } from "hardhat"
import { expect } from "chai"
import { Contract, ContractFactory } from "@ethersproject/contracts"
import { Signer } from "@ethersproject/abstract-signer"

describe("Testing entire basic flow", function () {

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
        heroicStory.on("MintedNFT", async (tokenId, _uri, minter, derivedFromNFT, derivedFromTokenId) => {
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

      await heroicStory.mintTo(await owner.getAddress(), "", lootAddress, lootTokenId);
      await MintedNFTPromise;

      expect(await heroicStory.ownerOf(nftTokenId)).to.equal(await owner.getAddress());
    })
  })

  describe("Test payouts", async () => {
    it("Should distribute payouts correctly", async () => {
      const amount = ethers.utils.parseEther("100.0")
      await heroicStory.updateResults(nftTokenId, [await contributors[0].getAddress(), await contributors[1].getAddress(), await contributors[2].getAddress(), await contributors[3].getAddress()], [1, 2, 3, 4])
      await heroicStory.updatePool(nftTokenId, amount, {
        value: amount,
      })

      await heroicStory.connect(contributors[0]).collectPayout(nftTokenId)

      const SharesCollectedPromise = new Promise((resolve, reject) => {
        heroicStory.on("SharesCollected", async (sender, tokenId, shares, amountPaid) => {
          expect(sender).to.equal(await contributors[0].getAddress())
          expect(tokenId).to.equal(nftTokenId)
          expect(shares).to.equal(1)
          expect(amountPaid).to.equal(amount.div(10))

          resolve(null)
        })

        setTimeout(() => {
          reject(new Error("Timeout: SharesCollected"))
        }, 10000)
      })

      await SharesCollectedPromise
    })
  })
})