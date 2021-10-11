
pragma solidity =0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interface/MelioraCommonSpace.sol";
import "../utils/SignUtil.sol";


contract MelioraManager is Ownable,SignUtil {
    
    using SafeERC20 for IERC20;
    
    uint8 public maxStar = 5;
    
    uint8 public maxBirthTime = 7;
    
    address public nftAddress;
    address public pceAddress;
    address public meliAddress;
    address public fundAddress;
    
    uint[] public pceBurns=[1500*10**18,2500*10**18,4000*10**18,6500*10**18,10000*10**18,16000*10**18,26000*10**18];
    uint[] public meliBurns=[10*10**18,12*10**18,14*10**18,16*10**18,18*10**18,20*10**18,22*10**18];
    uint[] public upGradePce=[1600*10**18,4800*10**18,16000*10**18,58800*10**18,156000*10**18];
    bool public whetherupPce=true;
    bool public whetherbirthPce=true;
    bool public whetherbirthMeli=true;
    
    
    constructor (address _nftAddress,address _pceAddress,address _meliAddress,address _fundAddress){
        nftAddress  = _nftAddress;
        pceAddress  = _pceAddress;
        meliAddress = _meliAddress;
        fundAddress = _fundAddress;
    }
    
    function setMaxBirthTime (uint8 _maxBirthTime) external onlyOwner {
        maxBirthTime = _maxBirthTime;
    }
    
    function setPceBurns (uint[] memory _pceBurns) external onlyOwner{
        require(_pceBurns.length == maxBirthTime);
        pceBurns = _pceBurns;
    }
    
    function setPceUpGrade (uint[] memory _pceBurns) external onlyOwner{
        require(_pceBurns.length == maxBirthTime);
        upGradePce = _pceBurns;
    }
    
    function setMeliBurns (uint[] memory _meliBurns) external onlyOwner{
        require(_meliBurns.length == maxStar);
        meliBurns = _meliBurns;
    }
    
    function setwhetherBurnMeli(bool _whetherPce,bool _whetherMeli) external onlyOwner{
        require(whetherbirthPce!=_whetherPce || whetherbirthMeli!=_whetherMeli);
        whetherbirthPce = _whetherPce;
        whetherbirthMeli = _whetherMeli;
    }
    
    function updateMaxLevel(uint8 level) external onlyOwner{
        maxStar = level;
    }
    
    function upGradeMeliroa(uint256 tokenId,uint256 burnId) external {
        MelioraCommonSpace nftCommon = MelioraCommonSpace(nftAddress);
        require(nftCommon.exists(tokenId)&&nftCommon.ownerOf(tokenId) == msg.sender&&
        nftCommon.exists(burnId)&&nftCommon.ownerOf(burnId) == msg.sender);
        uint8 upStar; (upStar,) = nftCommon.getMeliora(tokenId);
        uint8 burnStar;(burnStar,) = nftCommon.getMeliora(tokenId);
        require(upStar == burnStar);
        require(upStar < maxStar);
        if(whetherbirthPce){
            uint256 totalBalance = upGradePce[upStar];
            require(IERC20(pceAddress).balanceOf(msg.sender) >= totalBalance,'PCE Blanace is not enough');
            ERC20Burnable(pceAddress).burnFrom(msg.sender, totalBalance);
        }
        nftCommon.upGradeMeliora(tokenId,upStar++,burnId);
    }
    
    //gift meliora to your friends
    function giftMeliroa(uint256 tokenId,address to) external {
        MelioraCommonSpace nftCommon = MelioraCommonSpace(nftAddress);
        require(nftCommon.exists(tokenId)&&nftCommon.ownerOf(tokenId) == msg.sender);
        IERC721(nftAddress).transferFrom(msg.sender, to, tokenId);
    }
    
    
    function birthMeliroa(uint256 fatherTokenId,uint256 momTokenId,uint256 sonTokenId,bytes memory sig) external{
        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender,fatherTokenId,momTokenId,sonTokenId)));
        require(recoverSigner(message, sig) == publicKey);
        MelioraCommonSpace nftCommon = MelioraCommonSpace(nftAddress);
        require(!nftCommon.exists(sonTokenId),'tokenId is exists');
        require(nftCommon.exists(fatherTokenId)&&nftCommon.ownerOf(fatherTokenId) == msg.sender);
        require(nftCommon.exists(momTokenId)&&nftCommon.ownerOf(momTokenId) == msg.sender);
        uint8 fatherBreed; (,fatherBreed) = nftCommon.getMeliora(fatherTokenId);
        uint8 momBreed;(,momBreed) = nftCommon.getMeliora(momTokenId);
        if(whetherbirthPce){
            uint256 totalBalance = pceBurns[fatherBreed] + pceBurns[momBreed];
            require(IERC20(pceAddress).balanceOf(msg.sender) >= totalBalance,'PCE Blanace is not enough');
            ERC20Burnable(pceAddress).burnFrom(msg.sender, totalBalance);
        }
        if(whetherbirthMeli){
            uint256 totalBalance = meliBurns[fatherBreed] + meliBurns[momBreed];
            require(IERC20(meliAddress).balanceOf(msg.sender) >= totalBalance ,'Meli Blanace is not enough');
            IERC20(meliAddress).safeTransferFrom(msg.sender,fundAddress,totalBalance);
        }
        nftCommon.birthMeliora(msg.sender,fatherTokenId,momTokenId,sonTokenId);
    }
}