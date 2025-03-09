#!/bin/bash
# Logo
curl -s https://raw.githubusercontent.com/ToanBm/user-info/main/logo.sh | bash
sleep 3

show() {
    echo -e "\033[1;35m$1\033[0m"
}

# Step 1: Install hardhat
echo "Install Hardhat..."
npm init -y
echo "Install dotenv..."
npm install dotenv

# Step 2: Automatically choose "Create an empty hardhat.config.js"
echo "Choose >> Create a TypeScript project (with Viem)"
npm install --save-dev hardhat@2.22.19

npx hardhat init

# Step 3: Update hardhat.config.js with the proper configuration
echo "Creating new hardhat.config file..."
rm hardhat.config.js

cat <<'EOF' > hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.28",
  networks: {
    somnia: {
      url: "https://dream-rpc.somnia.network",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
};
EOF

# Step 4: Create MyToken.sol contract
echo "Create ERC20 contract..."
rm contracts/Lock.sol

cat <<'EOF' > contracts/DAO.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract DAO {
    struct Proposal {
        string description; // Proposal details
        uint256 deadline;   // Voting deadline
        uint256 yesVotes;   // Votes in favor
        uint256 noVotes;    // Votes against
        bool executed;      // Whether the proposal has been executed
        address proposer;   // Address of the proposer
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public totalProposals;
    uint256 public votingDuration = 10 minutes;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value == 0.001 ether, "Must deposit STT");
        votingPower[msg.sender] += msg.value;
    }

    function createProposal(string calldata description) external {
        require(votingPower[msg.sender] > 0, "No voting power");

        proposals[totalProposals] = Proposal({
            description: description,
            deadline: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposer: msg.sender
        });

        totalProposals++;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp < proposal.deadline, "Voting has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        require(votingPower[msg.sender] > 0, "No voting power");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.yesVotes += votingPower[msg.sender];
        } else {
            proposal.noVotes += votingPower[msg.sender];
        }
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp >= proposal.deadline, "Voting still active");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass");

        proposal.executed = true;

        // Logic for proposal execution
        // Example: transfer STT to proposer as a reward for successful vote pass
        payable(proposal.proposer).transfer(0.001 ether);
    }
}
EOF

# Step 5: Compile contracts
echo "Compile your contracts..."
npx hardhat compile

# Step 6: Create .env file for storing private key
echo "Create .env file..."

read -p "Enter your EVM wallet private key (without 0x): " PRIVATE_KEY
cat <<EOF > .env
PRIVATE_KEY=$PRIVATE_KEY
EOF
 
# Step 7: Create deploy script
echo "Creating deploy script..."
rm ignition/modules/Lock.js

cat <<'EOF' > ignition/modules/deploy.js
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("DAO", (m) => {
  const dao = m.contract("DAO");
  return { dao };
});
EOF

# Step 8: Deploying the smart contract
echo "Deploying your DAO smart contract..."
npx hardhat ignition deploy ./ignition/modules/deploy.js --network somnia

echo "🎉 Successfully deployed $COUNT contracts!"

# Step 7: Create test script
echo "Creating test script..."
rm test/Lock.js

cat <<'EOF' > test/DAO.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DAO", function () {
  let dao;
  let owner, addr1;

  beforeEach(async function () {
    const DAO = await ethers.getContractFactory("DAO");
    dao = await DAO.deploy();
    await dao.waitForDeployment(); // Chờ contract deploy xong
    [owner, addr1] = await ethers.getSigners();
  });

  it("Should allow deposits and update voting power", async function () {
    await dao.connect(addr1).deposit({ value: ethers.parseEther("0.001") });
    expect(await dao.votingPower(addr1.address)).to.equal(ethers.parseEther("0.001"));
  });

  it("Should allow proposal creation", async function () {
    await dao.connect(addr1).deposit({ value: ethers.parseEther("0.001") });
    await dao.connect(addr1).createProposal("Test Proposal");
    const proposal = await dao.proposals(0);
    expect(proposal.description).to.equal("Test Proposal");
  });
});
EOF

# Step 8: Testing the smart contract
echo "Testing your DAO smart contract..."

npx hardhat test
