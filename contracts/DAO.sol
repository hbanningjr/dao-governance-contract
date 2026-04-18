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
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    event Propose(uint id, uint256 amount, address recipient, address creator);

    constructor(Token _token, uint256 _quorum) {
        owner = msg.sender;
        token = _token;
        quorum = _quorum;
    }

    // Function to receive Ether.

    receive() external payable {}

    modifier onlyInvestor() {
        require(Token(token).balanceOf(msg.sender) > 0, "must be token holder");
        _;
    }

    //Create proposal

    function createProposal(
        string memory _name,
        uint256 _amount,
        address payable _recipient
    ) external onlyInvestor {
        require(address(this).balance > _amount, "Invalid amount");

        require(Token(token).balanceOf(msg.sender) > 0, "must be token holder");

        proposalCount = proposalCount + 1;

        proposals[proposalCount] = Proposal(
            proposalCount,
            _name,
            _amount,
            _recipient,
            0,
            false
        );

        emit Propose(proposalCount, _amount, _recipient, msg.sender);
    }

    //1. Send 100 ETH to Tom
    //2. Send 50 ETH to Jane for Web DEV
    //3. Send 1 ETH to Julie for Marketing
}
