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

      await heroicStory.mintTo(await owner.getAddress(), "dummyuri", lootAddress, lootTokenId);
      await MintedNFTPromise;

      expect(await heroicStory.ownerOf(nftTokenId)).to.equal(await owner.getAddress());
    })
  })

  describe("Test payouts", async () => {

    beforeEach(async () => {
      heroicStory = await heroicStoryFactory.connect(owner).deploy(name, symbol, proxyRegistryAddress);
      await heroicStory.mintTo(await owner.getAddress(), "dummyuri", lootAddress, lootTokenId);
    })

    it("Should distribute a single payout correctly", async () => {

      const amount = ethers.utils.parseEther("100.0")

      // Assign shares.
      await heroicStory.updateResults(
        nftTokenId,
        // 4 contributors.
        [
          await contributors[0].getAddress(), 
          await contributors[1].getAddress(), 
          await contributors[2].getAddress(), 
          await contributors[3].getAddress()
        ],
        // Shares - [20%, 10%, 5%, 2.5%] 
        [2000, 1000, 500, 250]
      )
      
      // Update pool amount.
      await heroicStory.updatePool(nftTokenId, amount, {
        value: amount,
      })

      const SharesCollectedPromise = new Promise((resolve, reject) => {
        heroicStory.on("SharesCollected", async (sender, tokenId, shares, amountPaid) => {

          expect(sender).to.equal(await contributors[0].getAddress())
          expect(tokenId).to.equal(nftTokenId)
          expect(shares).to.equal(2000)
          expect(amountPaid).to.equal((amount.mul(2000)).div(10000))

          resolve(null)
        })

        setTimeout(() => {
          reject(new Error("Timeout: SharesCollected"))
        }, 10000)
      })

      await heroicStory.connect(contributors[0]).collectPayout(nftTokenId)
      await SharesCollectedPromise
    })

    it("Should distribute multiple payouts correclty", async () => {
      const amount = ethers.utils.parseEther("100.0")

      // Assign shares.
      await heroicStory.updateResults(
        nftTokenId,
        // 4 contributors.
        [
          await contributors[0].getAddress(), 
          await contributors[1].getAddress(), 
          await contributors[2].getAddress(), 
          await contributors[3].getAddress()
        ],
        // Shares - [20%, 10%, 5%, 2.5%] 
        [2000, 1000, 500, 250]
      )
      
      // Update pool amount three times.
      const numPayoutsToCollect: number = 3;

      for(let i = 0; i < numPayoutsToCollect; i++) {
        await heroicStory.updatePool(nftTokenId, amount, {
          value: amount,
        })
      }

      const SharesCollectedPromise = new Promise((resolve, reject) => {
        heroicStory.on("SharesCollected", async (sender, tokenId, shares, amountPaid) => {

          expect(sender).to.equal(await contributors[0].getAddress())
          expect(tokenId).to.equal(nftTokenId)
          expect(shares).to.equal(2000)
          expect(amountPaid).to.equal(((amount.mul(2000)).div(10000)).mul(numPayoutsToCollect))

          resolve(null)
        })

        setTimeout(() => {
          reject(new Error("Timeout: SharesCollected"))
        }, 10000)
      })

      await heroicStory.connect(contributors[0]).collectPayout(nftTokenId)
      await SharesCollectedPromise
    })
  })
})