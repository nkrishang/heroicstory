// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721Tradable} from "./ERC721Tradable.sol";

contract HeroicStory is ERC721Tradable {
    /// @dev URI-related variables.
    string public _contractURI;

    /// @dev 10000 is 100 %.
    uint256 public MAX_BPS = 10000;

    struct GameResults {
        uint256 tokenId;
        uint256 totalContributors;
        uint256 payoutRounds;
        uint256 allTimePool;
        address[] contributors;
        uint256[] shares;
    }

    /// @dev Mapping from NFT tokenId => Game results.
    mapping(uint256 => GameResults) public results;

    /// @dev Mapping from NFT tokenId => contributor address => number of payouts claimed.
    mapping(uint256 => mapping(address => uint256)) public payoutClaims;

    /// @dev Mapping from NFT tokenId => payout round => total pool for that round.
    mapping(uint256 => mapping(uint256 => uint256)) public totalPoolByRound;

    /// @dev Events.
    event FeeReceived(address indexed payee, uint256 indexed amount);
    event PoolUpdated(
        uint256 indexed tokenId,
        uint256 allTimePoolAmount,
        uint256 newPoolAmount
    );
    event GameResultSubmitted(
        uint256 indexed tokenId,
        address[] contributors,
        uint256[] shares
    );
    event SharesCollected(
        address indexed contributor,
        uint256 indexed tokenId,
        uint256 shares,
        uint256 payout
    );

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
    function updateResults(
        uint256 _tokenId,
        address[] calldata _contributors,
        uint256[] calldata _shares
    ) external onlyOwner {
        require(
            _contributors.length == _shares.length,
            "Heroic Story: unequal amounts of contributors and shares"
        );

        // Store game results.

        uint256 currentPool = results[_tokenId].allTimePool;
        uint256 currentPayoutRounds = results[_tokenId].payoutRounds;

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
    function updatePool(uint256 _tokenId, uint256 _amount)
        external
        payable
        onlyOwner
    {
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
    function collectPayout(uint256 _tokenId) external {
        GameResults memory gameResults = results[_tokenId];

        // Get the round # of this payout.
        uint256 roundForPayout = payoutClaims[_tokenId][_msgSender()];

        // A contributor can't claim more payouts than payout rounds.
        require(
            roundForPayout < gameResults.payoutRounds,
            "Heroic Story: already claimed payout"
        );

        // Get payout shares.
        uint256 idx = gameResults.contributors.length;

        for (uint256 i = 0; i < gameResults.contributors.length; i += 1) {
            if (gameResults.contributors[i] == _msgSender()) {
                idx = i;
                break;
            }
        }

        // Calculate total amount to pay.
        uint256 totalAmountToPay;

        for (uint256 j = roundForPayout; j < gameResults.payoutRounds; j += 1) {
            totalAmountToPay +=
                (totalPoolByRound[_tokenId][roundForPayout] *
                    gameResults.shares[idx]) /
                MAX_BPS;
        }

        // Update the contributor's # of payouts claimed.
        payoutClaims[_tokenId][_msgSender()] = gameResults.payoutRounds;

        // Send payment.
        (bool success, ) = (_msgSender()).call{value: totalAmountToPay}("");
        require(success, "Heroic Story Manager: failed payout.");

        emit SharesCollected(
            _msgSender(),
            _tokenId,
            gameResults.shares[idx],
            totalAmountToPay
        );
    }
}
