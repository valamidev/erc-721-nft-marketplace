pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

// License to
// https://github.com/TheGreatHB/NFTEX/blob/main/contracts/NFTEX.sol

contract RarityHeadMarketplace is ERC721Holder, Ownable, ReentrancyGuard {
	struct Order {
		address seller;
		IERC721 token;
		uint256 tokenId;
		uint256 listPrice;
		uint256 endBlock;
		bool isSold;
		bool isCancelled;
	}

	mapping(IERC721 => bytes32[]) public orderIdByToken;
	mapping(address => bytes32[]) public orderIdBySeller;
	mapping(IERC721 => uint16) public royaltyFee;
	mapping(bytes32 => Order) public orderInfo;

	address public feeAddress;
	uint16 public feePercent;

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
	event BuyOrder(
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
	}

	function tokenOrderLength(IERC721 _token) public view returns (uint256) {
		return orderIdByToken[_token].length;
	}

	function sellerOrderLength(
		address _seller
	) external view returns (uint256) {
		return orderIdBySeller[_seller].length;
	}

	function bulkList(
		IERC721 _token,
		uint256[] memory _ids,
		uint256 _listPrice,
		uint256 _endBlock
	) public {
		require(_ids.length > 0, "At least 1 ID must be supplied");

		for (uint256 i = 0; i < _ids.length; i++) {
			_makeOrder(_token, _ids[i], _listPrice, _endBlock);
		}
	}

	function fixedPrice(
		IERC721 _token,
		uint256 _id,
		uint256 _price,
		uint256 _endBlock
	) public {
		_makeOrder(_token, _id, _price, _endBlock);
	} //ep=0. for gas saving.

	function _makeOrder(
		IERC721 _token,
		uint256 _id,
		uint256 _listPrice,
		uint256 _endBlock
	) internal nonReentrant {
		require(_endBlock > block.number, "Duration must be more than zero");

		//push
		bytes32 hash = _hash(_token, _id, msg.sender);
		orderInfo[hash] = Order(
			msg.sender,
			_token,
			_id,
			_listPrice,
			_endBlock,
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

	function buy(bytes32 _order) external payable {
		Order storage o = orderInfo[_order];
		uint256 endBlock = o.endBlock;
		require(block.number <= endBlock, "Listing has ended");
		require(o.isCancelled == false, "Canceled order");
		require(o.isSold == false, "Already sold");

		require(msg.value == o.listPrice, "Price error");

		o.isSold = true; //reentrancy proof

		payFee(o.seller, o.listPrice, o.token);

		o.token.safeTransferFrom(address(this), msg.sender, o.tokenId);

		emit BuyOrder(
			o.token,
			o.tokenId,
			_order,
			o.seller,
			msg.sender,
			o.listPrice
		);
	}

	function buyInternal(bytes32 _order) internal {
		Order storage o = orderInfo[_order];
		uint256 endBlock = o.endBlock;
		require(block.number <= endBlock, "Listing has ended");
		require(o.isCancelled == false, "Canceled order");
		require(o.isSold == false, "Already sold");

		require(msg.value == o.listPrice, "Price error");

		o.isSold = true; //reentrancy proof

		payFee(o.seller, o.listPrice, o.token);

		o.token.safeTransferFrom(address(this), msg.sender, o.tokenId);

		emit BuyOrder(
			o.token,
			o.tokenId,
			_order,
			o.seller,
			msg.sender,
			o.listPrice
		);
	}

	function bulkBuy(bytes32[] memory _orders) external payable {
		require(_orders.length > 0, "No orders to buy");
		uint256 totalPrice = 0;
		for (uint256 i = 0; i < _orders.length; i++) {
			Order storage o = orderInfo[_orders[i]];
			totalPrice += o.listPrice;
		}
		require(msg.value >= totalPrice, "Insufficient funds");
		for (uint256 i = 0; i < _orders.length; i++) {
			buyInternal(_orders[i]);
		}
	}

	function cancelOrder(bytes32 _order) public {
		Order storage o = orderInfo[_order];
		require(o.seller == msg.sender, "Access denied");
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

		if (royaltyFee[_token] > 0) {
			fee = (_price * (feePercent + royaltyFee[_token])) / 10000;
		}

		(bool sentToSeller, ) = payable(_seller).call{ value: _price - fee }(
			""
		);
		if (!sentToSeller) {
			// If the call to the seller failed, call the fee collector with the full payment amount
			(bool sentFee, ) = payable(feeAddress).call{ value: _price }("");
			require(sentFee, "Failed to send Ether to Fee collector");
		} else {
			// If the call to the seller was successful, call the fee collector with just the fee amount
			(bool sentFee, ) = payable(feeAddress).call{ value: fee }("");
			require(sentFee, "Failed to send Ether to Fee collector");
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

	// Function to receive Ether. msg.data must be empty
	receive() external payable nonReentrant {
		payable(feeAddress).transfer(msg.value);
	}

	// Fallback function is called when msg.data is not empty
	fallback() external payable nonReentrant {
		payable(feeAddress).transfer(msg.value);
	}
}
