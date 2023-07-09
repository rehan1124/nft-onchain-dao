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

/**
 * Interface for CryptoDevsNFT
 */
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

contract CryptoDevsDAO is Ownable {
    struct Proposal {
        // Id of token to be purchased from NFT marketplace
        uint256 tokenId;
        // Unix timestamp for propsal deadline
        uint256 deadline;
        // Number of votes with approval
        uint256 approvedVotes;
        // Number of votes who declined proposal
        uint256 declinedVotes;
        // Is proposal already executed?
        bool isPropsalExecuted;
        // If the given NFT/TokenID has already been used for vote
        mapping(uint256 => bool) votersToken;
    }

    // ID to Proposal mapping
    mapping(uint256 => Proposal) public proposals;

    // Number of proposals made
    uint256 public numberOfProposalsMade;

    // Contract interface
    IFakeNFTMarketplace fakeNFTMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    constructor(address _fakeNFTMarketplace, address _cryptoDevsNFT) payable {
        fakeNFTMarketplace = IFakeNFTMarketplace(_fakeNFTMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    /**
     * Only CryptoDevsNFT holder can execute the function
     */
    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "Does not NFT.");
        _;
    }

    function createProposal(
        uint256 _nftTokenId
    ) external nftHolderOnly returns (uint256) {
        // Check if NFT is still available for purchase
        require(
            fakeNFTMarketplace.isAvailable(_nftTokenId),
            "This NFT is not for sale."
        );

        // Add new proposal
        // By default, for first proposal, value for numberOfProposalsMade will be 0;
        Proposal storage proposal = proposals[numberOfProposalsMade];
        proposal.tokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;

        // Update counter so that new proposal can be added in `proposals` mapping.
        numberOfProposalsMade++;

        // We want to return proposals starting from 0th index
        return numberOfProposalsMade - 1;
    }
}
