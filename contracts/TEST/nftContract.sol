// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract Token is ERC721("testToken", "tNFT") {
	mapping(uint256 => bool) public approvalMap;
	mapping(uint256 => bool) public transferMap;

	function mint(address owner, uint256 id) public {
		console.log("Mint %s for %s", id, owner);
		_mint(owner, id);
	}

	function isApprovalDisabled(uint256 _tokenId) public view returns (bool) {
		return approvalMap[_tokenId];
	}

	function isTransferDisabled(uint256 _tokenId) public view returns (bool) {
		return transferMap[_tokenId];
	}

	modifier onlyIfApprovalEnabled(uint256 _tokenId) {
		require(
			!isTransferDisabled(_tokenId),
			"Approval is disabled for this token"
		);
		_;
	}

	modifier onlyIfTransferEnabled(uint256 _tokenId) {
		require(
			!isTransferDisabled(_tokenId),
			"Transfer is disabled for this token"
		);
		_;
	}

	function approve(
		address _to,
		uint256 _tokenId
	) public override onlyIfApprovalEnabled(_tokenId) {
		address owner = ERC721.ownerOf(_tokenId);
		require(_to != owner, "ERC721: approval to current owner");

		require(
			_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
			"ERC721: approve caller is not token owner or approved for all"
		);

		_approve(_to, _tokenId);
	}

	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) public override onlyIfTransferEnabled(_tokenId) {
		require(
			_isApprovedOrOwner(_msgSender(), _tokenId),
			"ERC721: caller is not token owner or approved"
		);
		_safeTransfer(_from, _to, _tokenId, _data);
	}
}
