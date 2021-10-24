// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lifecycle/HasNoEther.sol";
import "../interface/MelioraInterface.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract BidVoid is HasNoEther{
    
    using SafeERC20 for IERC20;
    
    address public payTokenAddress = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    
    address private publicKey; 
    
     //Quantity per pre-sale
    uint64 public saleCount;
    
    uint256 public salePrice;
    
    mapping(bytes=>bool) bidNonce;

    event PreSale(
        address indexed _nftAddress,
        address indexed account,
        uint256 indexed _tokenId,
        uint256 _salePrice,
        uint64 _saleCount
    );
    
    event PreSaleCount(
        uint64 _saleCount
    );
    
    function setSaleCountAndPrice(uint64 _saleCount,uint256 _salePrice) external onlyOwner{
        require(_saleCount>0,'saleCount must be more than 0');
        require(_salePrice>0,'salePrice must be more than 0');
        saleCount = _saleCount;
        salePrice = _salePrice;
        emit PreSaleCount(_saleCount);
    }
    
     function setPublicKey(address _public) external onlyOwner{
         publicKey = _public;
     }
    
    
    function bidForVoid(
        address _nftAddress,
        uint256 _timestamp,
        bytes memory _sign
    )
        external
    {
        require(!bidNonce[_sign],'has been used');
        bytes32 message = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender,_timestamp)));
        require(ECDSA.recover(message, _sign) == publicKey);
        bidNonce[_sign] = true;
        require(saleCount > 0,'end of Pre Sale');
        require(_nftAddress != address(0),'zero address');
        MelioraInterface melioraInterface = MelioraInterface(_nftAddress);
        saleCount = saleCount - 1;
        uint256 tokenId = melioraInterface._tokenIdCounter()+15001;
        IERC20(payTokenAddress).safeTransferFrom(msg.sender,address(this),salePrice);
        melioraInterface.birthVoidMeliora(msg.sender,tokenId);
        emit PreSale(_nftAddress,msg.sender,tokenId,salePrice,saleCount);
    }
}