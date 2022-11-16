// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.17;

// License to
// https://github.com/TheGreatHB/NFTEX/blob/main/contracts/NFTEX.sol

contract RarityHeadMarketplace is ERC721Holder, Ownable {
    struct Order {
        uint8 orderType; //0:Fixed Price, 1:English Auction
        address seller;
        IERC721 token;
        uint256 tokenId;
        uint256 startPrice;
        uint256 startBlock;
        uint256 endBlock;
        uint256 lastBidPrice;
        address lastBidder;
        bool isSold;
        bool isCancelled;
    }

    mapping(IERC721 => mapping(uint256 => bytes32[])) public orderIdByToken;
    mapping(address => bytes32[]) public orderIdBySeller;
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

    function tokenOrderLength(IERC721 _token, uint256 _id)
        public
        view
        returns (uint256)
    {
        return orderIdByToken[_token][_id].length;
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
    //0:Fixed Price, 1:Dutch Auction, 2:English Auction
    function englishAuction(
        IERC721 _token,
        uint256 _id,
        uint256 _startPrice,
        uint256 _endBlock
    ) public {
        _makeOrder(1, _token, _id, _startPrice, _endBlock);
    } //ep=0. for gas saving.

    function fixedPrice(
        IERC721 _token,
        uint256 _id,
        uint256 _price,
        uint256 _endBlock
    ) public {
        _makeOrder(0, _token, _id, _price,  _endBlock);
    } //ep=0. for gas saving.

    function _makeOrder(
        uint8 _orderType,
        IERC721 _token,
        uint256 _id,
        uint256 _startPrice,
        uint256 _endBlock
    ) internal {
        require(_endBlock > block.number, "Duration must be more than zero");

        //push
        bytes32 hash = _hash(_token, _id, msg.sender);
        orderInfo[hash] = Order(
            _orderType,
            msg.sender,
            _token,
            _id,
            _startPrice,
            block.number,
            _endBlock,
            0,
            address(0),
            false,
            false
        );
        orderIdByToken[_token][_id].push(hash);
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

    // take order fx
    // you have to pay only BCH for bidding and buying.

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
                msg.value >= lastBidPrice + (lastBidPrice / 20),
                "low price bid"
            ); //5%
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
            payable(lastBidder).transfer(lastBidPrice);
        }

        emit Bid(o.token, o.tokenId, _order, msg.sender, msg.value);
    }

    function buyItNow(bytes32 _order) external payable {
        Order storage o = orderInfo[_order];
        uint256 endBlock = o.endBlock;
        require(endBlock != 0, "Canceled order");
        require(o.isCancelled == false, "Canceled order");
        require(o.orderType == 0, "It's a English Auction");
        require(o.isSold == false, "Already sold");

        uint256 currentPrice = getCurrentPrice(_order);
        require(msg.value >= currentPrice, "Price error");

        o.isSold = true; //reentrancy proof

        uint256 fee = (currentPrice * feePercent) / 10000;
        payable(o.seller).transfer(currentPrice - fee);
        payable(feeAddress).transfer(fee);
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice);
        }

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

    // both seller and taker can call this fx in English Auction. Probably the taker(last bidder) might call this fx.
    // In both DA and FP, buyItNow fx include claim fx.
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

        uint256 fee = (lastBidPrice * feePercent) / 10000;

        o.isSold = true;

        payable(seller).transfer(lastBidPrice - fee);
        payable(feeAddress).transfer(fee);
        token.safeTransferFrom(address(this), lastBidder, tokenId);

        emit Claim(token, tokenId, _order, seller, lastBidder, lastBidPrice);
    }

    function bulkClaim(bytes32[] memory _ids) public {
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

        o.endBlock = 0; //0 endBlock means the order was canceled. - retained for backwards compatibility
        o.isCancelled = true;

        token.safeTransferFrom(address(this), msg.sender, tokenId);
        emit CancelOrder(token, tokenId, _order, msg.sender);
    }

    function bulkCancel(bytes32[] memory _ids) public {
        require(_ids.length > 0, "At least 1 ID must be supplied");
        for (uint256 i = 0; i < _ids.length; i++) {
            cancelOrder(_ids[i]);
        }
    }

    //feeAddress must be either an EOA or a contract must have payable receive fx and doesn't have some codes in that fx.
    //If not, it might be that it won't be receive any fee.
    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    function updateFeePercent(uint16 _percent) external onlyOwner {
        require(_percent <= 1000, "Input value is more than 10%");
        feePercent = _percent;
    }

    function setExtendOnBid(uint16 _value) external onlyOwner {
        require(_value <= 1000, "Cannot extend more than 1000 block");
        extendOnBid = _value;
    }
}
