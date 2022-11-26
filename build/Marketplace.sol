// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File @openzeppelin/contracts/security/ReentrancyGuard.sol@v4.8.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/utils/Context.sol@v4.8.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.8.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol@v4.8.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v4.8.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/IERC721.sol@v4.8.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol@v4.8.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


// File contracts/Marketplace.sol

pragma solidity ^0.8.7;
// License to
// https://github.com/TheGreatHB/NFTEX/blob/main/contracts/NFTEX.sol

contract RarityHeadMarketplace is ERC721Holder, Ownable, ReentrancyGuard {
    struct Order {
        uint8 orderType; //0:Fixed Price, 1:English Auction
        address seller;
        IERC721 token;
        uint256 tokenId;
        uint256 startPrice;
        uint256 endBlock;
        uint256 lastBidPrice;
        address lastBidder;
        bool isSold;
        bool isCancelled;
    }

    mapping(IERC721 => bytes32[]) public orderIdByToken;
    mapping(address => bytes32[]) public orderIdBySeller;
    mapping(IERC721 => uint16) public royaltyFee;
    mapping(bytes32 => Order) public orderInfo;

    address public feeAddress;
    uint16 public feePercent;
    uint16 public extendOnBid;

    event MakeOrder(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address indexed seller
    );
    event CancelOrder(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address indexed seller
    );
    event Bid(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address indexed bidder,
        uint256 bidPrice
    );
    event Claim(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address seller,
        address indexed taker,
        uint256 price
    );

    constructor() {
        feeAddress = msg.sender;
        feePercent = 100; // Fee 1%
        extendOnBid = 50; // Auction expiry extend with 50 blocks by default
    }

    // view fx
    function getCurrentPrice(bytes32 _order) public view returns (uint256) {
        Order storage o = orderInfo[_order];
        uint8 orderType = o.orderType;
        if (orderType == 0) {
            return o.startPrice;
        } else {
            uint256 lastBidPrice = o.lastBidPrice;
            return lastBidPrice == 0 ? o.startPrice : lastBidPrice;
        } 
    }

    function tokenOrderLength(IERC721 _token)
        public
        view
        returns (uint256)
    {
        return orderIdByToken[_token].length;
    }

    function sellerOrderLength(address _seller)
        external
        view
        returns (uint256)
    {
        return orderIdBySeller[_seller].length;
    }

    function bulkList(
        IERC721 _token,
        uint256[] memory _ids,
        uint256 _startPrice,
        uint256 _endBlock,
        uint256 _type
    ) public {
        require(_ids.length > 0, "At least 1 ID must be supplied");

        if (_type == 0) {
            for (uint256 i = 0; i < _ids.length; i++) {
                _makeOrder(0, _token, _ids[i], _startPrice, _endBlock);
            }
        }

        if (_type == 2) {
            for (uint256 i = 0; i < _ids.length; i++) {
                _makeOrder(2, _token, _ids[i], _startPrice, _endBlock);
            }
        }
    }

    // make order fx
    //0:Fixed Price, 1:English Auction
    function fixedPrice(
        IERC721 _token,
        uint256 _id,
        uint256 _price,
        uint256 _endBlock
    ) public {
        _makeOrder(0, _token, _id, _price,  _endBlock);
    } //ep=0. for gas saving.

    function auction(
        IERC721 _token,
        uint256 _id,
        uint256 _startPrice,
        uint256 _endBlock
    ) public {
        _makeOrder(1, _token, _id, _startPrice, _endBlock);
    } //ep=0. for gas saving.



    function _makeOrder(
        uint8 _orderType,
        IERC721 _token,
        uint256 _id,
        uint256 _startPrice,
        uint256 _endBlock
    ) internal nonReentrant {
        require(_endBlock > block.number, "Duration must be more than zero");

        //push
        bytes32 hash = _hash(_token, _id, msg.sender);
        orderInfo[hash] = Order(
            _orderType,
            msg.sender,
            _token,
            _id,
            _startPrice,
            _endBlock,
            0,
            address(0),
            false,
            false
        );
        orderIdByToken[_token].push(hash);
        orderIdBySeller[msg.sender].push(hash);

        //check if seller has a right to transfer the NFT token. safeTransferFrom.
        _token.safeTransferFrom(msg.sender, address(this), _id);

        emit MakeOrder(_token, _id, hash, msg.sender);
    }

    function _hash(
        IERC721 _token,
        uint256 _id,
        address _seller
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.number, _token, _id, _seller));
    }

    // Bids must be at least 5% higher than the previous bid.
    // If someone bids in the last 5 minutes of an auction, the auction will automatically extend by 5 minutes.
    function bid(bytes32 _order) external payable {
        Order storage o = orderInfo[_order];
        uint256 endBlock = o.endBlock;
        uint256 lastBidPrice = o.lastBidPrice;
        address lastBidder = o.lastBidder;

        require(o.orderType == 1, "only for English Auction");
        require(o.isCancelled == false, "Canceled order");
        require(block.number <= endBlock, "Auction has ended");
        require(o.seller != msg.sender, "Can not bid on your own order");

        if (lastBidPrice != 0) {
            require(
                msg.value >= lastBidPrice + (lastBidPrice / 20), // 5%
                "low price bid"
            ); 
        } else {
            require(
                msg.value >= o.startPrice && msg.value > 0,
                "low price bid"
            );
        }

        if (block.number > endBlock - extendOnBid) {
            o.endBlock = endBlock + extendOnBid;
        }

        o.lastBidder = msg.sender;
        o.lastBidPrice = msg.value;

        if (lastBidPrice != 0) {
            (bool sent, ) = payable(lastBidder).call{value: lastBidPrice}("");
            require(sent, "Failed to send Ether on outbid");
        }

        emit Bid(o.token, o.tokenId, _order, msg.sender, msg.value);
    }

    function buy(bytes32 _order) external payable {
        Order storage o = orderInfo[_order];
        uint256 endBlock = o.endBlock;
        require(block.number <= endBlock, "Listing has ended");
        require(o.isCancelled == false, "Canceled order");
        require(o.orderType == 0, "It's a English Auction");
        require(o.isSold == false, "Already sold");

        uint256 currentPrice = getCurrentPrice(_order);
        require(msg.value == currentPrice, "Price error");

        o.isSold = true; //reentrancy proof

        payFee(o.seller, currentPrice, o.token);
 
        o.token.safeTransferFrom(address(this), msg.sender, o.tokenId);

        emit Claim(
            o.token,
            o.tokenId,
            _order,
            o.seller,
            msg.sender,
            currentPrice
        );
    }

    function claim(bytes32 _order) public {
        Order storage o = orderInfo[_order];
        address seller = o.seller;
        address lastBidder = o.lastBidder;
        require(o.isSold == false, "Already sold");
        require(o.isCancelled == false, "Already cancelled");
        require(
            seller == msg.sender || lastBidder == msg.sender,
            "Access denied"
        );
        require(o.orderType == 1, "English Auction only");
        require(block.number > o.endBlock, "Auction has not ended");

        IERC721 token = o.token;
        uint256 tokenId = o.tokenId;
        uint256 lastBidPrice = o.lastBidPrice;

        o.isSold = true;

        payFee(seller, lastBidPrice, o.token);

        token.safeTransferFrom(address(this), lastBidder, tokenId);

        emit Claim(token, tokenId, _order, seller, lastBidder, lastBidPrice);
    }

    function bulkClaim(bytes32[] memory _ids) public nonReentrant {
        require(_ids.length > 0, "At least 1 ID must be supplied");
        for (uint256 i = 0; i < _ids.length; i++) {
            claim(_ids[i]);
        }
    }

    function cancelOrder(bytes32 _order) public {
        Order storage o = orderInfo[_order];
        require(o.seller == msg.sender, "Access denied");
        require(o.lastBidPrice == 0, "Bidding exist"); //for EA. but even in DA, FP, seller can withdraw his/her token with this fx.
        require(o.isSold == false, "Already sold");
        require(o.isCancelled == false, "Already cancelled");

        IERC721 token = o.token;
        uint256 tokenId = o.tokenId;

        o.isCancelled = true;

        token.safeTransferFrom(address(this), msg.sender, tokenId);
        emit CancelOrder(token, tokenId, _order, msg.sender);
    }

    function bulkCancel(bytes32[] memory _ids) public nonReentrant {
        require(_ids.length > 0, "At least 1 ID must be supplied");
        for (uint256 i = 0; i < _ids.length; i++) {
            cancelOrder(_ids[i]);
        }
    }

    function payFee(address _seller, uint256 _price, IERC721 _token) private {
        uint256 fee = (_price * feePercent) / 10000;

        if(royaltyFee[_token] > 0){
            fee = (_price * (feePercent + royaltyFee[_token])) / 10000;
        }

        (bool sentToSeller, ) = payable(_seller).call{value: _price - fee}("");
         require(sentToSeller, "Failed to send Ether to seller");
        (bool sentFee, ) = payable(feeAddress).call{value: fee}("");
         require(sentFee, "Failed to send Ether to Fee collector");
    }

    // This method required in case a Contract disable transfering for any reason!
    // The token will stuck forever in the contract, only for emergency!
    function emergencyCancelOrder(bytes32 _order) external onlyOwner nonReentrant{
        Order storage o = orderInfo[_order];
        address lastBidder = o.lastBidder;
        uint256 lastBidPrice = o.lastBidPrice;
        uint256 endBlock = o.endBlock + 1000; // At least 1000 block should passed, to avoid any backdoor
        require(lastBidPrice != 0, "Bidding exist");
        require(o.isSold == false, "Already sold");
        require(o.isCancelled == false, "Already cancelled");
        require(block.number >= endBlock, "Listing has ended");
   
        o.isCancelled = true;

        IERC721 token = o.token;
        uint256 tokenId = o.tokenId;
        address seller = o.seller;

        token.transferFrom(address(this), seller, tokenId);

        (bool sent, ) = payable(lastBidder).call{value: lastBidPrice}("");

        // In case bidder can't accept fund
        if(!sent){
            payable(feeAddress).transfer(lastBidPrice);
        }
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(this), "Cannot be pointed self");
        feeAddress = _feeAddress;
    }

    function setRoyaltyFee(IERC721 _token, uint16 _percent) external onlyOwner {
        require(_percent >= 0, "Must be positive");
        require(_percent <= 1000, "Input value is more than 10%");
        royaltyFee[_token] = _percent;
    }

    function updateFeePercent(uint16 _percent) external onlyOwner {
        require(_percent >= 0, "Must be positive");
        require(_percent <= 1000, "Input value is more than 10%");
        feePercent = _percent;
    }

    function setExtendOnBid(uint16 _value) external onlyOwner {
        require(_value >= 0, "Must be positive");
        require(_value <= 1000, "Cannot extend more than 1000 block");
        extendOnBid = _value;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable nonReentrant {
        payable(feeAddress).transfer(msg.value);
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable nonReentrant {
        payable(feeAddress).transfer(msg.value);
    }
}
