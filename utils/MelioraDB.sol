pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract MelioraDB is AccessControl{
    
     
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    mapping(uint256=>uint256) public birthLockTime;
     
    function updateBirthTime(uint tokenId,uint lockTime) external onlyRole(MANAGER_ROLE){
        birthLockTime[tokenId] = lockTime;
    }
     
    function checkBirthTime(uint256 tokenId) external view returns(bool){
        return block.timestamp > birthLockTime[tokenId];
    }
     
    function getBirthTime(uint256 tokenId) external view returns(uint256){
        return birthLockTime[tokenId];
    }
}