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
    uint allTimePool;

    address[] contributors;
    uint[] shares;

  }

  /// @dev Mapping from NFT tokenId => Game results.
  mapping(uint => GameResults) public results;

  /// @dev Mapping from NFT tokenId => contributor address => number of payouts claimed.
  mapping(uint => mapping(address => uint)) public payoutClaims;

  /// @dev Mapping from NFT tokenId => payout round => total pool for that round.
  mapping(uint => mapping(uint => uint)) public totalPoolByRound;

  /// @dev Events.
  event FeeReceived(address indexed payee, uint indexed amount);
  event PoolUpdated(uint indexed tokenId, uint allTimePoolAmount, uint newPoolAmount);
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

    // Store game results.
    
    uint currentPool = results[_tokenId].allTimePool;
    uint currentPayoutRounds = results[_tokenId].payoutRounds;

    results[_tokenId] = GameResults({
      tokenId: _tokenId,
      totalContributors: _contributors.length,
      payoutRounds: currentPayoutRounds,
      allTimePool: currentPool,

      contributors: _contributors,
      shares: _shares
    });

    emit GameResultSubmitted(_tokenId, _contributors, _shares);
  }

  /// @dev Update the pool size of a game.
  function updatePool(uint _tokenId, uint _amount) external onlyOwner {
    
    GameResults memory gameResults = results[_tokenId];

    // Update global vars for the particular game.
    gameResults.allTimePool += _amount;
    gameResults.payoutRounds += 1;

    // Store payout pool for this particular round.
    totalPoolByRound[_tokenId][gameResults.payoutRounds] = _amount;

    // Store updated game results.
    results[_tokenId] = gameResults;

    emit PoolUpdated(_tokenId, gameResults.allTimePool, _amount);
  }

  /// @dev Lets a contributor withraw their stake in their game NFT's accrued sales fees.
  function collectPayout(uint _tokenId) external {
    
    GameResults memory gameResults = results[_tokenId];

    // A contributor can't claim more payouts than payout rounds.
    require(payoutClaims[_tokenId][_msgSender()] < gameResults.payoutRounds, "Heroic Story: already claimed payout");
    
    // Update the contributor's # of payouts claimed.
    payoutClaims[_tokenId][_msgSender()] += 1;
    // Get the round # of this payout.
    uint roundForPayout = payoutClaims[_tokenId][_msgSender()];

    // Get payout shares.
    uint idx = gameResults.contributors.length;

    for(uint i = 0; i < gameResults.contributors.length; i += 1) {
      if(gameResults.contributors[i] == _msgSender()) {
        idx = i;
        break;
      }
    }

    // Calculate payout.
    uint payout = (totalPoolByRound[_tokenId][roundForPayout] * gameResults.shares[idx]) / MAX_BPS;

    // Send payment.
    (bool success,) = (_msgSender()).call{ value: payout }("");
    require(success, "Heroic Story Manager: failed payout.");

    emit SharesCollected(_msgSender(), _tokenId, gameResults.shares[idx], payout);
  }
}