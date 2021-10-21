// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";


contract MelioraCore is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIdCounter;
    
    string public tokenURIPrefix = "https://storage.googleapis.com/meli-games/";
    
    string public tokenURISuffix = "/meliora.json";
    
    bool public transferAllow = false;

    constructor() ERC721("Meliora", "MELIORA") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }
    
    event MelioraBirth(address indexed owner,uint256 fatherId,uint256 motherId,uint256 indexed tokenId,uint256 birth,uint256 rebirth);
    
    event MelioraUpGrade(uint256 upId,uint256 burnId,uint8 currentStar);
    
    modifier checkTransfer(address account){
        require(transferAllow ||
        hasRole(MANAGER_ROLE,account) ,'can not transfer');
        _;
    }
    
    modifier checkContract(address sender){
        require(Address.isContract(sender) ,'caller is not a manager contract');
        _;
    }
    
    function setTokenURIPrefix(string memory _tokenURIPrefix)external onlyRole(DEFAULT_ADMIN_ROLE){
        tokenURIPrefix = _tokenURIPrefix;
    }
    
    function setTokenURISuffix(string memory _tokenURISuffix)external onlyRole(DEFAULT_ADMIN_ROLE){
        tokenURISuffix = _tokenURISuffix;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
  
    function transferAllowed(bool _allowd) external onlyRole(DEFAULT_ADMIN_ROLE){
        transferAllow = _allowd;
    }
    
    function birthVoidMeliora(address owner,uint tokenId) 
        external 
        
        checkContract(msg.sender) 
        
        onlyRole(MANAGER_ROLE)
    {
        _birthMeliora(owner,tokenId);
    }
    
    function birthMeliora(address owner,uint fatherId,uint motherId,uint tokenId,uint birth,uint rebirth)  
        external 
    
        checkContract(msg.sender) 
    
        onlyRole(MANAGER_ROLE)
    {
        _birthMeliora(owner,tokenId);
        emit MelioraBirth(owner,fatherId,motherId,tokenId,birth,rebirth);
    }
    
    function _birthMeliora(address owner,uint tokenId) 
        internal
    {
        _mint(owner,tokenId);
        _setTokenURI(tokenId,caluteTokenURI(tokenId,0));
        _tokenIdCounter.increment();
    }
    
    function upGradeMeliora(uint256 upTokenId,uint256 burnId,uint8 star) 
        external 
        onlyRole(MANAGER_ROLE)
    {
        _setTokenURI(upTokenId,caluteTokenURI(upTokenId,star));
        _burn(burnId);
        emit MelioraUpGrade(upTokenId,burnId,star);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        checkTransfer(msg.sender)
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
    
    function caluteTokenURI (uint256 _tokenId,uint8 _star) internal view returns(string memory){
        string memory tokenId = toString(_tokenId);
        string memory star = toString(_star);
        string memory uri = append(tokenId,star);
        return uri;
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
  
    function append(string memory tokenId,string memory star) internal view returns (string memory) {
        return string(abi.encodePacked(tokenURIPrefix,tokenId,'/',star,tokenURISuffix));
    }
  
}
