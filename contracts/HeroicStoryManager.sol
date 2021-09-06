// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { HeroicStory } from "./HeroicStory.sol";

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HeroicStoryManager is Ownable {

  HeroicStory public heroicStory;
  
  uint public MAX_BPS = 10000;

  struct GameResults {
    
    uint tokenId;
    uint totalContributors;
    uint totalPool;

    address[] contributors;
    uint[] shares;
  }

  mapping(uint => GameResults) public results;

  event GameResult(address[] contributors, uint[] shares);

  constructor() {}

  event FeeReceived(address payee, uint amount);
  event GameResultSubmitted(uint tokenId, address[] contributors, uint[] shares);
  event SharesCollected(address contributor, uint tokenId, uint shares, uint payout);

  /// @dev Let the contract receive Ether payments.
  receive() external payable {
    emit FeeReceived(msg.sender, msg.value);
  }

  /// @dev Deploys the `HeroicStory` NFT collection.
  function beginStory(
    
    string memory _name,
    string memory _symbol,
    address _proxyRegistryAddress
  
  ) external onlyOwner {

    // Get `HeroicStory` bytecode.
    bytes memory heroicStoryBytecode = abi.encodePacked(type(HeroicStory).creationCode, abi.encode(
      _name, _symbol, _proxyRegistryAddress, address(this)
    ));

    // Get salt for deploying `HeroicStory`
    bytes32 salt = keccak256(abi.encodePacked("Heroic Story", block.number));

    // Deploy `HeroicStory`
    address heroicStoryAddress = Create2.deploy(0, salt, heroicStoryBytecode);
    
    // Set `HeroicStory`
    heroicStory = HeroicStory(heroicStoryAddress);
  }

  /// @dev Stores the result of a round of Heroic Story.
  function updateResults(uint _tokenId, address[] calldata _contributors, uint[] calldata _shares) external onlyOwner {
    
    require(_contributors.length == _shares.length, "Heroic Story: unequal amounts of contributors and shares");

    uint currentPool = results[_tokenId].totalPool;

    results[_tokenId] = GameResults({
      tokenId: _tokenId,
      totalContributors: _contributors.length,
      totalPool: currentPool,

      contributors: _contributors,
      shares: _shares
    });

    emit GameResultSubmitted(_tokenId, _contributors, _shares);
  }

  /// @dev Lets a contributor withraw their stake in the round's accrued sales fees.
  function collectPayout(uint _tokenId) external {

    GameResults memory gameResults = results[_tokenId];

    uint idx = gameResults.contributors.length;

    for(uint i = 0; i < gameResults.contributors.length; i += 1) {
      if(gameResults.contributors[i] == msg.sender) {
        idx = i;
        break;
      }
    }

    uint payout = (gameResults.totalPool * gameResults.shares[idx]) / MAX_BPS;

    (bool success,) = (msg.sender).call{ value: payout }("");
    require(success, "Heroic Story Manager: failed payout.");

    emit SharesCollected(msg.sender, _tokenId, gameResults.shares[idx], payout);
  }

  /// @dev Let `HeroicStoryManager` set the contract URI
  function setContractURI(string calldata _URI) external onlyOwner {
    heroicStory.setContractURI(_URI);
  } 
  
  /// @dev Let `HeroicStoryManager` set the contract URI
  function setBasetURI(string calldata _URI) external onlyOwner {
    heroicStory.setBasetURI(_URI);
  }
}