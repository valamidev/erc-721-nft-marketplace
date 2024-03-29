pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

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

	IERC721[] public listedTokens;
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

	function bulkViewListedTokens(
		uint256 _fromIndex,
		uint16 _limit
	) public view returns (IERC721[] memory) {
		IERC721[] memory result = new IERC721[](_limit);
		for (
			uint256 i = _fromIndex;
			i < listedTokens.length && i < (_fromIndex + _limit);
			i++
		) {
			result[i] = listedTokens[i];
		}
		return result;
	}

	function bulkViewCollectionOrders(
		IERC721 _token,
		uint256 _fromIndex,
		uint16 _limit
	) public view returns (Order[] memory) {
		// Create an empty array to hold the order information
		Order[] memory orders = new Order[](_limit);

		// Iterate through the array of order IDs for the given ERC721 token
		for (
			uint256 i = _fromIndex;
			i < orderIdByToken[_token].length && i < (_fromIndex + _limit);
			i++
		) {
			// Get the order ID for the current iteration
			bytes32 orderId = orderIdByToken[_token][i];

			// Get the order information for the current order ID
			Order memory order = orderInfo[orderId];

			// Add the order information to the array of orders
			orders[i] = order;
		}

		// Return the array of orders
		return orders;
	}

	function bulkViewSellerOrders(
		address _seller,
		uint256 _fromIndex,
		uint16 _limit
	) public view returns (Order[] memory) {
		// Create an empty array to hold the order information
		Order[] memory orders = new Order[](_limit);

		// Get the number of orders made by the seller
		uint256 sellerOrderCount = orderIdBySeller[_seller].length;

		// Iterate through the array of order IDs for the seller
		for (
			uint256 i = _fromIndex;
			i < sellerOrderCount && i < (_fromIndex + _limit);
			i++
		) {
			// Get the order ID for the current iteration
			bytes32 orderId = orderIdBySeller[_seller][i];

			// Get the order information for the current order ID
			Order memory order = orderInfo[orderId];

			// Add the order information to the array of orders
			orders[i] = order;
		}

		// Return the array of orders
		return orders;
	}

	function tokenOrderLength(IERC721 _token) public view returns (uint256) {
		return orderIdByToken[_token].length;
	}

	function sellerOrderLength(
		address _seller
	) external view returns (uint256) {
		return orderIdBySeller[_seller].length;
	}

	function bulkCreateListing(
		IERC721 _token,
		uint256[] memory _ids,
		uint256 _listPrice,
		uint256 _endBlock
	) public {
		require(_ids.length > 0, "At least 1 ID must be supplied");

		for (uint256 i = 0; i < _ids.length; i++) {
			_makeListing(_token, _ids[i], _listPrice, _endBlock);
		}
	}

	function singleCreateListing(
		IERC721 _token,
		uint256 _id,
		uint256 _price,
		uint256 _endBlock
	) public {
		_makeListing(_token, _id, _price, _endBlock);
	}

	function _makeListing(
		IERC721 _token,
		uint256 _id,
		uint256 _listPrice,
		uint256 _endBlock
	) internal nonReentrant {
		require(_endBlock > block.number, "Duration must be more than zero");
		require(
			_token.getApproved(_id) == address(this),
			"Contract not approved to transfer token"
		);

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

		// Create at first listing
		if (orderIdByToken[_token].length == 0) {
			listedTokens.push(_token);
		}

		orderIdByToken[_token].push(hash);
		orderIdBySeller[msg.sender].push(hash);

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

		o.token.safeTransferFrom(o.seller, msg.sender, o.tokenId);

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

		o.isSold = true; //reentrancy proof

		payFee(o.seller, o.listPrice, o.token);

		o.token.safeTransferFrom(o.seller, msg.sender, o.tokenId);

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
