// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Interface for the FakeNFTMarketplace
 */
interface IFakeNFTMarketplace {
    /**
     * @dev getPrice() returns the price of an NFT from the FakeNFTMarketplace
     * @return Returns the price in Wei for an NFT
     */
    function getPrice() external view returns (uint256);

    /**
     * @dev isAvailable() returns whether or not the given _tokenId has already been purchased
     * @return Returns a boolean value - true if available, false if not
     */
    function isAvailable(uint256 _tokenId) external view returns (bool);

    /**
     * @dev makePurchase() purchases an NFT from the FakeNFTMarketplace
     * @param _tokenId - the fake NFT tokenID to purchase
     */
    function makePurchase(uint256 _tokenId) external payable;
}

interface ICryptoDevsNFT {
    /**
     * @dev balanceOf returns the number of NFTs owned by the given address
     * @param owner - address to fetch number of NFTs for
     * @return Returns the number of NFTs owned
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev tokenOfOwnerByIndex returns a tokenID at given index for owner
     * @param owner - address to fetch the NFT TokenID for
     * @param index - index of NFT in owned tokens array to fetch
     * @return Returns the TokenID of the NFT
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);
}

contract CryptoDevsDAO is Ownable {}
