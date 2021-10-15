pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract TokenDB is  AccessControl{
    
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    mapping(address=>mapping(address=>uint256)) internal withdrawNonce;
    
    mapping(address=>mapping(address=>uint256)) public claimLockTime;
    
    function updateClaimTime(address account,address tokenAddress,uint256 unLockTime) external onlyRole(MANAGER_ROLE){
        withdrawNonce[account][tokenAddress] = unLockTime;
    }
    
    function updateWithdrawNonce(address account,address tokenAddress,uint256 nonce) external onlyRole(MANAGER_ROLE){
        withdrawNonce[account][tokenAddress] = nonce + 1;
    }
    
    function checkNonce(address account,address tokenAddress,uint256 nonce) external view returns(bool){
        return withdrawNonce[account][tokenAddress] == nonce;
    }
    
    function checkLockTime(address account,address tokenAddress) external view returns(bool){
        return block.timestamp > claimLockTime[account][tokenAddress] ;
    }
    
    function getLockTime(address account,address tokenAddress) external view returns(uint256){
        return claimLockTime[account][tokenAddress];
    }
}