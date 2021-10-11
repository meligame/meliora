pragma solidity =0.8.0;

interface MelioraCommonSpace {

    struct Meliora {
        uint8 star;
        uint8 breedCount;
    }
    
    function getMeliora(uint256 tokenId) external returns(uint8 star,uint8 breedCount);

    function exists(uint256 tokenId) external returns(bool);

    function ownerOf(uint256 tokenId) external view returns(address);

    function birthMeliora(address owner,uint256 fatherTokenId,uint256 momTokenId,uint256 tokenId) external;

    function upGradeMeliora (uint256 upTokenId,uint8 star,uint256 burnTokenId) external;
    
    function reloadMeliora (uint256 tokenId) external;
    
    
}
