// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface ClaimInterface {
    
    function claimPayment(address account,uint256 amount,uint256 nonce) external;
}