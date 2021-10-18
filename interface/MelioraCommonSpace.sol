pragma solidity ^0.8.0;

interface MelioraCommonSpace {
    
    function _tokenIdCounter() external view returns(uint);

    function ownerOf(uint256 tokenId) external view returns(address);
    
    function createVoidMeliora(address owner,uint tokenId) external;

    function birthMeliora(address owner,uint tokenId) external;

    function upGradeMeliora (uint256 upTokenId,uint256 burnTokenId,uint8 star) external;
    
    
    
}
