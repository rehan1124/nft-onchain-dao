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
    enum Vote {
        Yes,
        No
    }
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
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "Does not have NFT.");
        _;
    }

    /**
     * Check if proposal is still active to be voted
     * @param _proposalIndex Proposal index
     */
    modifier activeProposalsOnly(uint256 _proposalIndex) {
        require(
            proposals[_proposalIndex].deadline > block.timestamp,
            "Deadline for vote exceeded."
        );
        _;
    }

    /**
     * Check if proposal is still active for vote or if its ready to be executed
     */
    modifier inactiveProposalOnly(uint256 _proposalIndex) {
        require(
            proposals[_proposalIndex].deadline <= block.timestamp,
            "You still have time to vote. Proposal cannot be executed now."
        );
        require(
            !proposals[_proposalIndex].isPropsalExecuted,
            "Proposal executed already."
        );
        _;
    }

    /**
     * @dev Creates new proposal and adds to mapping
     * @param _nftTokenId ID of NFT to be purchased
     * @return Proposal number
     */
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

    /**
     * To be used for voting on any proposal
     * @param _proposalIndex Proposal for which voting is to be done
     * @param _vote Yes or No
     */
    function voteOnProposal(
        uint256 _proposalIndex,
        Vote _vote
    ) external nftHolderOnly activeProposalsOnly(_proposalIndex) {
        Proposal storage proposal = proposals[_proposalIndex];

        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        // Check how many tokens are owned by voter
        // If token ID hasnt been already used for voting, increment number of votes and add token ID to mapping
        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 voterTokenId = cryptoDevsNFT.tokenOfOwnerByIndex(
                msg.sender,
                i
            );
            if (!proposal.votersToken[voterTokenId]) {
                numVotes++;
                proposal.votersToken[voterTokenId] = true;
            }
        }

        require(numVotes > 0, "Not enough votes.");

        if (_vote == Vote.Yes) {
            proposal.approvedVotes += numVotes;
        } else {
            proposal.declinedVotes += numVotes;
        }
    }

    /**
     * Executes the proposal and transfers fund to contract
     * @param _proposalIndex Proposal which has to be executed and funds has to be transferred
     */
    function executeProposal(
        uint256 _proposalIndex
    ) external nftHolderOnly inactiveProposalOnly(_proposalIndex) {
        Proposal storage proposal = proposals[_proposalIndex];

        if (proposal.approvedVotes > proposal.declinedVotes) {
            uint256 nftPrice = fakeNFTMarketplace.getPrice();
            // Check if contract has enough balance to purchase NFT
            require(address(this).balance > nftPrice, "Not enough funds.");
            // Transfer of eth to only happen when votes for Yes > No
            fakeNFTMarketplace.makePurchase{value: nftPrice}(proposal.tokenId);
        }

        // Whether number of votes for Yes > No or vice-versa, execute the proposal.
        proposal.isPropsalExecuted = true;
    }

    /**
     * Withdraw funds from contract and transfer to owner
     */
    function withdrawEth() external onlyOwner {
        uint256 amountInContract = address(this).balance;
        require(amountInContract > 0, "No funds to withdraw.");
        (bool isFundTransferred, ) = payable(owner()).call{
            value: amountInContract
        }("");
        require(isFundTransferred, "Failed to withdraw funds from contract.");
    }

    receive() external payable {}

    fallback() external payable {}
}
