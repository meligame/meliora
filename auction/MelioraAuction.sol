// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;


import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lifecycle/HasNoEther.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interface/MelioraInterface.sol";

/// @title Clock auction for non-fungible tokens.
contract MelioraAuction is Pausable, HasNoEther {
    
    using Counters for Counters.Counter;

    Counters.Counter public _orderIdCounter;
    
    using SafeERC20 for IERC20;
    
    // Represents an auction on an NFT
    struct Auction {
        uint256 orderId;
        // Current owner of NFT
        address payable seller;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;
    }

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;
    
    //
    address public payTokenAddress = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    
    //Quantity per pre-sale
    uint64 public saleCount;
    
    uint256 public salePrice;

    // Map from token ID to their corresponding auction.
    mapping (address => mapping (uint256 => Auction)) public auctions;
    //Map from orderId to auction
    
    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }
    
    event AuctionCreated(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller,
        uint256 _orderId
    );
    
    event AuctionSuccessful(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _totalPrice,
        address _winner,
        uint256 orderId
    );
    
    event AuctionCancelled(
        address indexed _nftAddress,
        uint256 indexed _tokenId
    );

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _ownerCut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000.
    constructor(uint256 _ownerCut) {
        require(_ownerCut <= 10000,'_ownerCut was error');
        ownerCut = _ownerCut;
    }
    


    // Modifiers to check that inputs can be safely stored with a certain
    // number of bits. We use constants and multiple modifiers to save gas.
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615,'value is error');
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455,'value is error');
        _;
    }
    
    /// @dev Creates and begins a new auction.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
    external
    whenNotPaused
    canBeStoredWith128Bits(_startingPrice)
    canBeStoredWith128Bits(_endingPrice)
    canBeStoredWith64Bits(_duration)
    {
        address _seller = msg.sender;
        require(_checkPrice(_startingPrice,_endingPrice),'span is too large');
        require(_nftAddress != address(0),'nftAddress is a Zero address');
        require(_startingPrice>0 && _endingPrice>0,'price error');
        require(_owns(_nftAddress, _seller, _tokenId),'caller is not owner');
        require(_duration >= 1 minutes,'duration must be more than one minute');
        _escrow(_nftAddress, _seller, _tokenId);
        uint256 orderId = _orderIdCounter.current();
        _orderIdCounter.increment();
        Auction memory _auction = Auction(
            orderId,
            payable(_seller),
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(block.timestamp)
        );
        _addAuction(
            _nftAddress,
            _tokenId,
            _auction,
            _seller,
            orderId
        );
        
    }


    function _checkPrice( uint256 _startingPrice,uint256 _endingPrice) internal pure returns(bool){
        uint cut = 0 ;
        if(_endingPrice > _startingPrice ){
            cut = _endingPrice/_startingPrice;
        }
        return (cut < 2);
    }
    
    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _tokenId - ID of token to bid on.
    function bid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _orderId,
        uint256 _amount
    )
    external
    whenNotPaused
    {
        require(_nftAddress!=address(0),'nftAddress can not a Zero Address');
        // _bid will throw if the bid or funds transfer fails
        _bid(_nftAddress,_tokenId,_orderId,_amount);
        _transfer(_nftAddress, msg.sender, _tokenId);
    }
    
    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(address _nftAddress, uint256 _tokenId,uint _orderId) external {
        require(_nftAddress != address(0),'nftAddress is a Zero address');
        Auction memory _auction = auctions[_nftAddress][_tokenId];
        require(_validAuction(_orderId,_auction),'this auction has been bided');
        require(msg.sender == _auction.seller,'caller is not owner');
        _cancelAuction(_nftAddress, _tokenId, _auction.seller);
    }
    
    /// @dev Returns true if the NFT is on auction.
    /// @param _auction - Auction to check.
    function _validAuction(uint256 _orderId,Auction memory _auction) internal pure returns (bool) {
        return (_auction.startedAt > 0 && _auction.orderId == _orderId);
    }
    
    /// @dev Returns current price of an NFT on auction. Broken into two
    ///  functions (this one, that computes the duration from the auction
    ///  structure, and the other that does the price computation) so we
    ///  can easily test that the price computation works correctly.
    function _getCurrentPrice(
        Auction memory _auction
    )
    internal
    view
    returns (uint256)
    {
        uint256 _secondsPassed = 0;
    
        // A bit of insurance against negative values (or wraparound).
        // Probably not necessary (since Ethereum guarantees that the
        // now variable doesn't ever go backwards).
        if (block.timestamp > _auction.startedAt) {
            _secondsPassed = block.timestamp - _auction.startedAt;
        }
        
        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            _secondsPassed
        );
    }
    
    /// @dev Computes the current price of an auction. Factored out
    ///  from _currentPrice so we can run extensive unit tests.
    ///  When testing, make this function external and turn on
    ///  `Current price computation` test suite.
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
    internal
    pure
    returns (uint256)
    {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our external functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addAuction())
        if (_secondsPassed >= _duration) {
            // We've reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return _endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 _totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            
            // This multiplication can't overflow, _secondsPassed will easily fit within
            // 64-bits, and _totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 _currentPriceChange = _totalPriceChange * int256(_secondsPassed) / int256(_duration);
            
            // _currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            int256 _currentPrice = int256(_startingPrice) + _currentPriceChange;
            
            return uint256(_currentPrice);
        }
    }
    
    /// @dev Returns true if the claimant owns the token.
    /// @param _nftAddress - The address of the NFT.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _nftAddress, address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (IERC721(_nftAddress).ownerOf(_tokenId) == _claimant);
    }
    
    /// @dev Adds an auction to the list of open auctions. Also fires the
    ///  AuctionCreated event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(
        address _nftAddress,
        uint256 _tokenId,
        Auction memory _auction,
        address _seller,
        uint256 orderId
    )
    internal
    {
       
        auctions[_nftAddress][_tokenId] = _auction;
        emit AuctionCreated(
            _nftAddress,
            _tokenId,
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration),
            _seller,
            orderId
        );
    }
    
    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(address _nftAddress, uint256 _tokenId) internal {
        delete auctions[_nftAddress][_tokenId];
    }
    
    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(address _nftAddress, uint256 _tokenId, address _seller) internal {
        _removeAuction(_nftAddress, _tokenId);
        _transfer(_nftAddress, _seller, _tokenId);
        emit AuctionCancelled(_nftAddress, _tokenId);
    }
    
    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _nftAddress - The address of the NFT.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _nftAddress, address _owner, uint256 _tokenId) internal {
        // It will throw if transfer fails
        IERC721(_nftAddress).transferFrom(_owner, address(this), _tokenId);
    }
    
    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _nftAddress - The address of the NFT.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _nftAddress, address _receiver, uint256 _tokenId) internal {
        // It will throw if transfer fails
        IERC721(_nftAddress).transferFrom(address(this), _receiver, _tokenId);
    }
    
    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return _price * ownerCut / 10000;
    }
    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _orderId,
        uint256 _amount
    )
    internal
    returns (uint256)
    {
        Auction memory _auction = auctions[_nftAddress][_tokenId];
        require(_validAuction(_orderId,_auction),'invalid auction');
        uint256 _price = _getCurrentPrice(_auction);
        require(_amount >= _price,'_price error');
        address payable _seller = _auction.seller;
        _removeAuction(_nftAddress, _tokenId);
        if (_price > 0) {
            uint256 _auctioneerCut = _computeCut(_price);
            IERC20(payTokenAddress).safeTransferFrom(msg.sender,address(this),_auctioneerCut);
            uint256 _sellerProceeds = _price - _auctioneerCut;
            IERC20(payTokenAddress).safeTransferFrom(msg.sender,_seller,_sellerProceeds);
        }
        emit AuctionSuccessful(
            _nftAddress,
            _tokenId,
            _price,
            msg.sender,
            _orderId
        );
        return _price;
    }
 
}