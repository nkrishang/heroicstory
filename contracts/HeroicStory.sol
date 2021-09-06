// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721Tradable } from "./ERC721Tradable.sol";

contract HeroicStory is ERC721Tradable {
  
  /// @dev URI-related variables.
  string public _contractURI;

  /// @dev 10000 is 100 %.
  uint public MAX_BPS = 10000;

  struct GameResults {
    
    uint tokenId;
    uint totalContributors;
    
    uint payoutRounds;
    uint totalPool;

    address[] contributors;
    uint[] shares;

  }

  /// @dev Mapping from NFT tokenId => Game results.
  mapping(uint => GameResults) public results;
  mapping(uint => mapping(address => uint)) public payoutClaims;

  /// @dev Events.
  event FeeReceived(address indexed payee, uint indexed amount);
  event PoolUpdated(uint indexed tokenId, uint totalPoolAmount);
  event GameResultSubmitted(uint indexed tokenId, address[] contributors, uint[] shares);
  event SharesCollected(address indexed contributor, uint indexed tokenId, uint shares, uint payout);

  /**
  *   @dev Whitelist the proxy accounts of OpenSea users so that they are automatically able to trade any item on 
  *   @dev OpenSea (without having to pay gas for an additional approval)
  **/
  constructor(
    
    string memory _name,
    string memory _symbol,
    address _proxyRegistryAddress
  
  ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {}
  
  /// @dev Returns the URI for the storefront-level metadata of the contract.
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  /// @dev Sets contract URI for the storefront-level metadata of the contract.
  function setContractURI(string calldata _URI) external onlyOwner {
    _contractURI = _URI;
  }

  /// @dev Update the results of a game.
  function updateResults(uint _tokenId, address[] calldata _contributors, uint[] calldata _shares) external onlyOwner {
    
    require(_contributors.length == _shares.length, "Heroic Story: unequal amounts of contributors and shares");

    uint currentPool = results[_tokenId].totalPool;
    uint currentPayoutRounds = results[_tokenId].payoutRounds;

    results[_tokenId] = GameResults({
      tokenId: _tokenId,
      totalContributors: _contributors.length,
      payoutRounds: currentPayoutRounds + 1,
      totalPool: currentPool,

      contributors: _contributors,
      shares: _shares
    });

    emit GameResultSubmitted(_tokenId, _contributors, _shares);
  }

  /// @dev Update the pool size of a game.
  function updatePool(uint _tokenId, uint _amount) external onlyOwner {
    results[_tokenId].totalPool = _amount;

    emit PoolUpdated(_tokenId, results[_tokenId].totalPool);
  }

  /// @dev Lets a contributor withraw their stake in their game NFT's accrued sales fees.
  function collectPayout(uint _tokenId) external {
    
    GameResults memory gameResults = results[_tokenId];

    require(payoutClaims[_tokenId][_msgSender()] < gameResults.payoutRounds, "Heroic Story: already claimed payout");
    payoutClaims[_tokenId][_msgSender()] += 1;

    uint idx = gameResults.contributors.length;

    for(uint i = 0; i < gameResults.contributors.length; i += 1) {
      if(gameResults.contributors[i] == _msgSender()) {
        idx = i;
        break;
      }
    }

    uint payout = (gameResults.totalPool * gameResults.shares[idx]) / MAX_BPS;

    (bool success,) = (_msgSender()).call{ value: payout }("");
    require(success, "Heroic Story Manager: failed payout.");

    emit SharesCollected(_msgSender(), _tokenId, gameResults.shares[idx], payout);
  }
}