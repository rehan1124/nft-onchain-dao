// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract FakeNFTMarketPlace {
    // Map TokenID to owner address
    mapping(uint256 => address) tokenToAddress;

    // NFT purchase price
    uint256 private constant NFT_PRICE = 0.01 ether;

    function makePurchase(uint256 _tokenId) external payable {
        // Check if NFT price is being paid or not
        require(msg.value == NFT_PRICE, "This NFT costs 0.01 ether.");

        // Once payment check is PASS, create mapping for tokeId to address.
        tokenToAddress[_tokenId] = msg.sender;
    }

    function getPrice() external view returns (uint256) {
        return NFT_PRICE;
    }

    function isAvailable(uint256 _tokenId) external view returns (bool) {
        if (tokenToAddress[_tokenId] == address(0)) {
            return true;
        } else {
            return false;
        }
    }
}
