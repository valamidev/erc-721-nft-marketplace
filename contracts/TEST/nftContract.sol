// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract Token is ERC721("testToken", "tNFT") {
    function mint(address owner, uint256 id) public {

         console.log("Mint %s for %s", id, owner);
        _mint(owner, id);
    }
}