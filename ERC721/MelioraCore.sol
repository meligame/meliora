pragma solidity ^0.8.0;

import "./MelioraBaseEnumerable.sol";
import "../interface/MelioraCommonSpace.sol";

contract MelioraCore is MelioraBaseEnumerable {
    
    event MelioraUpGrade(uint256 indexed upId,uint256 burnId,uint8 currentStar);
    
    event MelioraBirth(address indexed owner,uint256 indexed tokenId,uint256 fatherTokenId,uint256 momTokenId,uint256 unLockTime);
    
    mapping(uint256=>MelioraCommonSpace.Meliora) melioras;
    
    bool public canCreateZero = true;
    
    modifier canCreateVoidMeliora{
        require(canCreateZero,"can not create void meliora");
        _;
    }
    
    function closeCreateVoidMeliora() external onlyRole(DEFAULT_ADMIN_ROLE){
        canCreateZero = false;
    }
    
    function getMeliora(uint256 tokenId) external view returns(MelioraCommonSpace.Meliora memory){
        MelioraCommonSpace.Meliora memory meli = melioras[tokenId];
        return meli;
    }
    
    function exists(uint256 tokenId) external view returns(bool){
        return super._exists(tokenId);
    }
    
    function createVoidMeliora(address owner,uint256 tokenId) external canCreateVoidMeliora onlyRole(MANAGER_ROLE){
        _birthMeliora(owner,tokenId,0,0,0);
    }
    
    function birthMeliora(address owner,uint256 fatherTokenId,uint256 momTokenId,uint256 tokenId,uint256 unLockTime) external onlyRole(MANAGER_ROLE){
         _updateParentsInfo(fatherTokenId,momTokenId,unLockTime);
         _birthMeliora(owner,tokenId,fatherTokenId,momTokenId,unLockTime);
    }
    
    function _birthMeliora(address _owner,uint256 _tokenId,uint256 _fatherTokenId,uint256 _momTokenId,uint256 _unLockTime) internal{
        MelioraCommonSpace.Meliora memory meliora = MelioraCommonSpace.Meliora(0,0,0);
        melioras[_tokenId] = meliora;
        _mint(_owner,_tokenId);
        emit MelioraBirth(_owner,_tokenId,_fatherTokenId,_momTokenId,_unLockTime);
    }
    
    function _updateParentsInfo(uint256 fatherTokenId,uint256 momTokenId,uint256 unLockTime) internal{
        MelioraCommonSpace.Meliora storage father = melioras[fatherTokenId];
        father.breedCount+=1;
        father.unLockTime = unLockTime;
        MelioraCommonSpace.Meliora storage mom = melioras[momTokenId];
        mom.breedCount+=1;
        mom.unLockTime = unLockTime;
    }
    
    function upGradeMeliora (uint256 upTokenId,uint8 _star,uint256 burnTokenId) external onlyRole(MANAGER_ROLE){
        MelioraCommonSpace.Meliora storage meliora = melioras[upTokenId];
        meliora.star = _star;
        super._setTokenURI(upTokenId,caluteTokenURI(upTokenId));
        _burn(burnTokenId);
        delete melioras[burnTokenId];
        emit MelioraUpGrade(upTokenId,burnTokenId,_star);
    }
}