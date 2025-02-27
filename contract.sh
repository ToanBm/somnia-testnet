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
rm hardhat.config.ts

cat <<'EOF' > hardhat.config.ts
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    somnia: {
      url: "https://dream-rpc.somnia.network",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
};

export default config;
EOF

# Step 4: Create MyToken.sol contract
echo "Create ERC20 contract..."
rm contracts/Lock.sol

cat <<'EOF' > contracts/BuyMeCoffee.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract BuyMeCoffee {
    event CoffeeBought(
        address indexed supporter,
        uint256 amount,
        string message,
        uint256 timestamp
    );

    address public owner;

    struct Contribution {
        address supporter;
        uint256 amount;
        string message;
        uint256 timestamp;
    }
    
    Contribution[] public contributions;

    constructor() {
        owner = msg.sender;
    }

    function buyCoffee(string memory message) external payable {
        require(msg.value > 0, "Amount must be greater than zero.");
        contributions.push(
            Contribution(msg.sender, msg.value, message, block.timestamp)
        );

        emit CoffeeBought(msg.sender, msg.value, message, block.timestamp);
    }

    function withdraw() external {
        require(msg.sender == owner, "Only the owner can withdraw funds.");
        payable(owner).transfer(address(this).balance);
    }

    function getContributions() external view returns (Contribution[] memory) {
        return contributions;
    }

    function setOwner(address newOwner) external {
        require(msg.sender == owner, "Only the owner can set a new owner.");
        owner = newOwner;
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
rm ignition/modules/Lock.ts

cat <<'EOF' > ignition/modules/deploy.ts
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const BuyMeCoffee = buildModule("BuyMeCoffee", (m) => {
  const contract = m.contract("BuyMeCoffee");
  return { contract };
});

module.exports = BuyMeCoffee;
EOF

# Step 8: Deploying the smart contract
echo "Deploying the smart contract..."
yes | npx hardhat ignition deploy ./ignition/modules/deploy.ts --network somnia






