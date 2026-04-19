//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";

contract DAO {
    address owner;
    Token public token;
    uint256 public quorum;

    struct Proposal {
        uint256 id;
        string name;
        uint256 amount;
        address payable recipient;
        uint256 votes;
        bool executed;
        bool finalized;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    mapping(address => mapping(uint256 => bool)) votes;

    event Propose(uint id, uint256 amount, address recipient, address creator);

    event Vote(uint256 proposalId, uint256 votes, address voter);
    event Finalize(uint256 id);

    constructor(Token _token, uint256 _quorum) {
        owner = msg.sender;
        token = _token;
        quorum = _quorum;
    }

    // Function to receive Ether.

    receive() external payable {}

    modifier onlyInvestor() {
        require(token.balanceOf(msg.sender) > 0, "must be token holder");
        _;
    }

    //Create proposal

    function createProposal(
        string memory _name,
        uint256 _amount,
        address payable _recipient
    ) external onlyInvestor {
        require(address(this).balance > _amount, "Invalid amount");

        proposalCount = proposalCount + 1;

        proposals[proposalCount] = Proposal(
            proposalCount,
            _name,
            _amount,
            _recipient,
            0,
            false,
            false
        );

        emit Propose(proposalCount, _amount, _recipient, msg.sender);
    }

    function vote(uint256 _id) external onlyInvestor {
        //Fetch proposal from mapping by id
        Proposal storage proposal = proposals[_id];

        //Don't let investors vote twice
        require(!votes[msg.sender][_id], "already voted");

        //update votes
        proposal.votes += Token(token).balanceOf(msg.sender);

        // track that user has voted
        votes[msg.sender][_id] = true;

        emit Vote(_id, proposal.votes, msg.sender);
    }

    // Finalize proposal & transfer funds

    function finalizeProposal(uint256 _id) external {
        Proposal storage proposal = proposals[_id];

        require(_id > 0 && _id <= proposalCount, "invalid proposal id");
        require(!proposal.executed, "proposal already executed");
        require(
            proposal.votes >= quorum,
            "must reach quorum to finalize proposal"
        );
        // Check if the contract has enough balance to transfer
        require(address(this).balance >= proposal.amount);

        // Transfer the funds
        proposal.recipient.transfer(proposal.amount);

        (bool sent, ) = proposal.recipient.call{value: proposal.amount}("");
        require(sent, "Failed to send Ether");

        // Emit event
        emit Finalize(_id);

        proposal.executed = true;
    }
}

//1. Send 100 ETH to Tom
//2. Send 50 ETH to Jane for Web DEV
//3. Send 1 ETH to Julie for Marketing
