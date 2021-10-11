pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract MelioraBaseEnumerable is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    string public tokenURIPrefix = "https://google.store.com/erc/721/meliora/";
    string public tokenURISuffix = "meliora.json";

    constructor() ERC721("Meliora", "MELIORA") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        onlyRole(MANAGER_ROLE)
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId,caluteTokenURI(tokenId,0));
    }
    
    function caluteTokenURI (uint256 _tokenId,uint8 _star) internal view returns(string memory){
        string memory tokenId = uint2str(_tokenId);
        string memory star = uint2str(_star);
        string memory uri = append(tokenId,star);
        return uri;
    }
    
    function uint2str( uint256 _i ) public pure returns (string memory str) {
      if (_i == 0) {
        return "0";
      }
      uint256 j = _i;
      uint256 length;
      while (j != 0) {
        length++;
        j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint256 k = length;
      j = _i;
      while (j != 0){
        bstr[--k] = bytes1(uint8(48 + j % 10));
        j /= 10;
      }
      str = string(bstr);
    }
  
    function append(string memory tokenId, string memory star) internal view returns (string memory) {
        return string(abi.encodePacked(tokenURIPrefix,tokenId,"/",star,"/",tokenURISuffix));
    }
  
}
