import { ethers } from "hardhat"
import { expect } from "chai"
import { Contract } from "@ethersproject/contracts"
import { Signer } from "@ethersproject/abstract-signer"

describe("Testing entire basic flow", function() {
  
  // Get signers.
  let owner: Signer;
  let minter: Signer;
  
  let heroicStory: Contract;
})