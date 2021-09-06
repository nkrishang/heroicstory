// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721Tradable } from "./ERC721Tradable.sol";

contract HeroicStory is ERC721Tradable {
  
  address public heroicStoryManager;
    
  string public _contractURI;
  string public _base;

  /**
  *   @dev Whitelist the proxy accounts of OpenSea users so that they are automatically able to trade any item on 
  *   @dev OpenSea (without having to pay gas for an additional approval)
  **/
  constructor(
    
    string memory _name,
    string memory _symbol,
    
    address _proxyRegistryAddress,
    address _heroicStoryManager
  
  ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {}

  modifier onlyManager(address _caller) {
    require(_caller == heroicStoryManager, "Heroic Story: only the manager can call this function.");
    _;
  }

  /// @dev Returns the base URI for the contract's NFTs.
  function baseTokenURI() public view override returns (string memory) {
    return _base;
  }
  
  /// @dev Returns the URI for the storefront-level metadata of the contract.
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  /// @dev Let `HeroicStoryManager` set the contract URI
  function setContractURI(string calldata _URI) external onlyManager(_msgSender()) {
    _contractURI = _URI;
  } 
  
  /// @dev Let `HeroicStoryManager` set the contract URI
  function setBasetURI(string calldata _URI) external onlyManager(_msgSender()) {
    _base = _URI;
  }
}