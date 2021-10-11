pragma solidity ^0.8.0;

import "./MelioraBaseEnumerable.sol";
import "../interface/MelioraCommonSpace.sol";

contract MelioraCore is MelioraBaseEnumerable {
    
    event MelioraUpGrade(address indexed owner,uint256 indexed upId,uint256 burnId,uint8 currentStar);
    
    event MelioraBirth(address indexed owner,uint256 indexed tokenId,uint256 fatherTokenId,uint256 momTokenId);
    
    mapping(uint256=>MelioraCommonSpace.Meliora) melioras;
    
    bool public canCreateZero = true;
    
    modifier canCreateZeroMeliora{
        require(canCreateZero,"can not create");
        _;
    }
    
    function closeCreateZero() external onlyRole(MANAGER_ROLE){
        canCreateZero = false;
    }
    
    function getMeliora(uint256 tokenId) external view returns(MelioraCommonSpace.Meliora memory){
        MelioraCommonSpace.Meliora memory meli = melioras[tokenId];
        return meli;
    }
    
    function exists(uint256 tokenId) external view returns(bool){
        return super._exists(tokenId);
    }
    
    function createZeroMeliora(address owner,uint256 tokenId) external canCreateZeroMeliora onlyRole(MANAGER_ROLE){
        _birthMeliora(owner,tokenId,0,0);
    }
    
    function birthMeliora(address owner,uint256 fatherTokenId,uint256 momTokenId,uint256 tokenId) external onlyRole(MANAGER_ROLE){
         _updateParentsInfo(fatherTokenId,momTokenId);
         _birthMeliora(owner,tokenId,fatherTokenId,momTokenId);
    }
    
    function _birthMeliora(address _owner,uint256 _tokenId,uint256 _fatherTokenId,uint256 _momTokenId) internal{
        MelioraCommonSpace.Meliora memory meliora = MelioraCommonSpace.Meliora(0,0);
        melioras[_tokenId] = meliora;
        safeMint(_owner,_tokenId);
        emit MelioraBirth(_owner,_tokenId,_fatherTokenId,_momTokenId);
    }
    
    function _updateParentsInfo(uint256 fatherTokenId,uint256 momTokenId) internal{
        MelioraCommonSpace.Meliora storage father = melioras[fatherTokenId];
        father.breedCount+=1;
        MelioraCommonSpace.Meliora storage mom = melioras[momTokenId];
        mom.breedCount+=1;
       
    }
    
    function upGradeMeliora (uint256 upTokenId,uint8 _star,uint256 burnTokenId) external onlyRole(MANAGER_ROLE){
        MelioraCommonSpace.Meliora storage meliora = melioras[upTokenId];
        meliora.star = _star;
        super._setTokenURI(upTokenId,caluteTokenURI(upTokenId,meliora.star));
        _burn(burnTokenId);
        delete melioras[burnTokenId];
        emit MelioraUpGrade(msg.sender,upTokenId,burnTokenId,_star);
    }
    
    function reloadMeliroa (uint256 meliroaId) external onlyRole(MANAGER_ROLE){
        MelioraCommonSpace.Meliora storage meliora = melioras[meliroaId];
        meliora.breedCount = 0;
        meliora.star = 0;
    }
}