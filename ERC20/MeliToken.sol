
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../utils/SignUtil.sol";

contract MeliToken is ERC20,Pausable, AccessControl,SignUtil {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor() ERC20("Meli Token", "Meli"){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
    
    event Withdraw(address indexed to,uint256 amount,bytes indexed sign);

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    
    
    function claimPayment(uint256 amount,uint256 nonce,uint256 timestp, bytes memory sig) external {
        require(!withdrawNonce[nonce],'this nonce has been used');
        withdrawNonce[nonce] = true;
        bytes32 message = prefixed(keccak256(abi.encodePacked(address(this),msg.sender,amount,nonce,timestp)));
        require(recoverSigner(message, sig) == publicKey);
        super._transfer(address(this),msg.sender,amount*10**decimals());
        emit Withdraw(msg.sender,amount,sig);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
