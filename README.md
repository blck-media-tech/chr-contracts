# CHR contracts
Token and presale contracts for Chancer.

## Token contract
Basic ERC20 token with exposed functions for minting(onlyOwner) and for burning(only yours) tokens.

## Presale contract
Contract for sailing tokens.
<br/>
Presale contract is time-limited ability to purchase tokens not listed on any platform.
Presale divided in several stages with specified limit for each stage.
After presale is end user can claim purchased tokens and get them on token contract.

## Preparations
Contracts were written using hardhat and foundry. To start it you should have [foundry](https://book.getfoundry.sh/getting-started/installation) and [node](https://nodejs.org/en/download) installed

To install all dependencies you should run `forge install` and `npm install`

## Compiling contracts
You can use either foundry or hardhat to compile contracts:
- `forge compile` or `forge build` for compiling with foundry. Artifacts will be placed in `/out` directory
- `npx hardhat compile` for compiling with hardhat. Artifacts will be placed in `/artifacts` directory

## Running tests
Contracts were covered with tests by foundry.
To run foundry test you should use `forge test` command. It can be augmented with additional params:
- gas-report - add `--gas-report` to print report with info about used gas
- verbosity - you can indicate verbosity level using `-v` flag. There are 4 [verbosity levels](https://book.getfoundry.sh/forge/tests#logs-and-traces) from 2(`-vv`) to 5(`-vvvvv`)

## Deploying contracts
Before deploying contracts you should specify several values in `.env` file:
```
ETHERSCAN_API_KEY=
DEPLOYER_PRIVATE_KEY=
SEPOLIA_RPC_URL=
MAINNET_RPC_URL=
```
After values are specified you should manually inspect deploying arguments in deploy scripts(will be refactored and optimized in future)
After deployment arguments are inspected you can start deploying using command with following template:
```
// Template
forge script \
    <path to deployment script>:<deployment script contract name> \
    --rpc-url <address af RPC node that should be used for deploying> \
    --broadcast \
    --verify
```
```
// Example of deploying USDT mock contract for sepolia testnet
forge script \
    script/test/USDT.mock.deploy.s.sol:USDTMockDeployScript \
    --rpc-url https://rpc2.sepolia.org \
    --broadcast \
    --verify \
    --with-gas-price=50 # 50 wei per gas is enough for sepolia transactions
```
More options can be found in [foundry doc](https://book.getfoundry.sh/reference/forge/forge-script).




