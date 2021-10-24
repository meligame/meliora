// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lifecycle/HasNoEther.sol";

contract Erc20Mint is HasNoEther{
    
    event CreateClaim(
        address indexed _nftAddress,
        address indexed _account,
        uint256 _tokenId
    );
    
    event ExitClaim(
        address indexed _nftAddress,
        address indexed _account,
        uint256 _tokenId,
        uint256 _profit,
        address _profitAddress 
    );
    
    
     constructor(address _nftAddress,address _profitAddress,uint256 reward,uint256 time){
        nftAddress = _nftAddress;
        profitToken = _profitAddress;
        startHourId = getHoursId(time);
        endHourId = getHoursId(time.add(period));
        hourReward = reward;
    }
    
    using SafeMath for uint256;
    
    uint256 period = 20 days;
    
    address public nftAddress; //escrow nftAddress
    address public profitToken;
    uint256 public startHourId; // the contract deployed time/3600 as startHourId 
    uint256 public endHourId; // the contract deployed (time+period)/3600 as endHourId 
    uint256 public hourReward; // an hour will gift (hourReward)  profitToken
    uint256 public leastOpreateId; 
    uint256[] public hourIdArray; //total HourId 
    
    
    mapping(uint256=>uint256) public tokenIndex;//tokenId => hourIdArray index
    mapping(uint256=>address) public userToken;//tokenId=> user address
    mapping(uint256=>uint256) public hourPerson;//blocknumber => perosnCount
    

    
    function getHoursId(uint256 current) internal pure returns(uint256) {
        return current/3600;
    }
	
    function _updateHourArray(uint256 currentHoursId) internal {
        if(currentHoursId != leastOpreateId){
            hourIdArray.push(currentHoursId);
            leastOpreateId = currentHoursId;
        }
    }
    

    function deposit(uint256 tokenId) external{
        uint256 current = getHoursId(block.timestamp);
        require(current >= startHourId,'claim is not begin');
        require(current < endHourId,'claim has been end');
        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender,'TOKENID_INVALID');
        IERC721(nftAddress).transferFrom(msg.sender,address(this),tokenId);
        uint perCount = _getTotalCount();
        hourPerson[current] = perCount.add(1);
        _updateHourArray(current);
        uint index=0;
        if(hourIdArray.length>0){
            index = hourIdArray.length-1;
        }
        tokenIndex[tokenId] = index;
        userToken[tokenId] = msg.sender;
        emit CreateClaim(nftAddress,msg.sender,tokenId);
    }
    
    function _getTotalCount() internal view returns(uint) {
        uint perCount = 0;
        if(hourIdArray.length >= 1){
            perCount = hourPerson[hourIdArray[hourIdArray.length-1]];
        }
        return perCount;
    }
    
    function withdraw(uint256 tokenId) external {
        uint256 total = getReward(tokenId);
        require(userToken[tokenId] == msg.sender,'Caller is not owner');
        uint256 current = getHoursId(block.timestamp);
        uint perCount = _getTotalCount();
        if(perCount > 0 ){
            hourPerson[current] = perCount.sub(1);
        }
        _updateHourArray(current);
        delete userToken[tokenId];
        delete tokenIndex[tokenId];
        IERC721(nftAddress).transferFrom(address(this),msg.sender,tokenId);
        if(total > 0){
            IERC20(profitToken).transfer(msg.sender,total);
        }
        emit ExitClaim(nftAddress,msg.sender,tokenId,total,profitToken);
    }
	
    function getReward(uint256 tokenId) public view returns(uint256){
        require(userToken[tokenId] != address(0),'INVALID_TOKEN');
        require(userToken[tokenId] == msg.sender,'INVALID_TOKEN');
       
        uint256 currentHourId = getHoursId(block.timestamp);
        uint256 overHourId = currentHourId;
        if(currentHourId > endHourId){
            overHourId = endHourId;
        }
        uint256 totalReward = 0;
        uint256 unRewardHours = 0;
        uint256 everyReward = 0;
        uint256 index = tokenIndex[tokenId];
        for(uint256 i = index;i < hourIdArray.length ; i++){
            everyReward = hourReward.div(hourPerson[hourIdArray[i]]);
            if(i == hourIdArray.length-1){
                unRewardHours = overHourId.sub(hourIdArray[i]);
            }else{
                unRewardHours = hourIdArray[i+1].sub(hourIdArray[i]);
            }
            
            totalReward = totalReward.add(everyReward.mul(unRewardHours));
               
        }
        return totalReward;
    }
   
}