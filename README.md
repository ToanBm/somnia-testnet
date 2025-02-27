## Deploy a smart contract on Somnia Testnet using Hardhat
### 1. Clone the repository
```Bash
git clone https://github.com/ToanBm/somnia-testnet.git && cd somnia-testnet
```
### 2. Run the deploy script
```bash
chmod +x contract.sh && ./contract.sh
```
### 3. Deploy next Contract
```bash
yes | npx hardhat ignition deploy ./ignition/modules/deploy.ts --network somnia --reset
```
