// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MeliToken is ERC20, ERC20Burnable, AccessControl, Pausable  {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    event Withdraw(address indexed to,uint256 amount,uint256 nonce);
    
    constructor() ERC20("MELI", "MELI"){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
    
    modifier checkContract(address sender){
        require(Address.isContract(sender) ,'caller is not a manager contract');
        _;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    
    function claimPayment(address account,uint256 amount,uint256 nonce) 
        external 
        checkContract(msg.sender)
        onlyRole(MANAGER_ROLE)
    {
        _transfer(address(this),account,amount);
        emit Withdraw(account,amount,nonce);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
