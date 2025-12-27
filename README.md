# RiseIn Swap Contract

A decentralized token swap smart contract built on the Aptos blockchain using the Move programming language. This contract enables users to swap between two tokens (TokenA and TokenB) through a simple liquidity pool mechanism.

## Overview

The swap contract implements a basic automated market maker (AMM) that allows:
- Token swapping between TokenA and TokenB
- Liquidity pool management
- Configurable exchange rates
- Admin-controlled liquidity provisioning

## Contract Features

### Core Functionality
- **Token Swapping**: Swap TokenA for TokenB and vice versa
- **Liquidity Management**: Add liquidity to both token pools
- **Rate Configuration**: Set custom exchange rates between tokens
- **Resource Account**: Uses resource accounts for secure pool management

### Key Components
- `SwapConfig`: Stores admin configuration and exchange rates
- `LiquidityPool<CoinType>`: Manages token reserves for each coin type
- `TokenA` and `TokenB`: Two phantom types representing the tradeable tokens

### Available Functions
- `init()`: Initialize the swap contract
- `set_rate()`: Configure exchange rate (admin only)
- `add_liquidity_a()` / `add_liquidity_b()`: Add liquidity to pools
- `swap_a_to_b()` / `swap_b_to_a()`: Execute token swaps
- `get_rate()`: View current exchange rate
- `get_liquidity_a()` / `get_liquidity_b()`: View pool liquidity

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Aptos CLI**: Install from [Aptos CLI Installation Guide](https://aptos.dev/tools/aptos-cli/install-cli/)
2. **Move Prover** (optional): For formal verification
3. **Git**: For version control

### Verify Installation
```bash
aptos --version
```

## Project Structure

```
risein/
├── Move.toml          # Package configuration
├── sources/
│   ├── swap.move      # Main swap contract
│   └── simple_storage.move
├── tests/             # Test files
├── scripts/           # Deployment scripts
└── build/            # Compiled bytecode (generated)
```

## Compilation

### 1. Compile the Contract
```bash
cd risein
aptos move compile
```

### 2. Verify Compilation
The compiled bytecode will be generated in the `build/` directory. You should see output similar to:
```
Compiling, may take a little while to download git dependencies...
BUILDING risein
{
  "Result": [
    "e0f82045715e2cb83e9cdb5edbb0c40ec422e0d7d770c9ec16770d9e45d22ccb::swap"
  ]
}
```

### 3. Run Tests (Optional)
```bash
aptos move test
```

## Deployment

### Step 1: Configure Your Account

1. **Initialize Aptos CLI**:
```bash
aptos init
```

2. **Create or Import Account**:
```bash
# Create new account
aptos account create

# Or import existing private key
aptos init --private-key <your-private-key>
```

3. **Fund Your Account** (for testnet):
```bash
aptos account fund-with-faucet --account <your-account-address>
```

### Step 2: Deploy the Contract

1. **Deploy to Testnet**:
```bash
aptos move publish --named-addresses risein=<your-account-address>
```

2. **Deploy to Devnet**:
```bash
aptos move publish --named-addresses risein=<your-account-address> --url https://api.devnet.aptoslabs.com/v1
```

3. **Deploy to Mainnet**:
```bash
aptos move publish --named-addresses risein=<your-account-address> --url https://api.mainnet.aptoslabs.com/v1
```

### Step 3: Initialize the Contract

After deployment, initialize the swap contract:

```bash
aptos move run --function-id <your-account-address>::swap::init
```

## Usage Examples

### Initialize the Contract
```bash
aptos move run --function-id <deployed-address>::swap::init
```

### Set Exchange Rate
```bash
# Set rate to 1:2 (1 TokenA = 2 TokenB)
aptos move run --function-id <deployed-address>::swap::set_rate --args u64:1 u64:2
```

### Add Liquidity
```bash
# Add 1000 TokenA to liquidity pool
aptos move run --function-id <deployed-address>::swap::add_liquidity_a --args u64:1000

# Add 2000 TokenB to liquidity pool
aptos move run --function-id <deployed-address>::swap::add_liquidity_b --args u64:2000
```

### Perform Swaps
```bash
# Swap 100 TokenA for TokenB
aptos move run --function-id <deployed-address>::swap::swap_a_to_b --args u64:100 address:<admin-address>

# Swap 200 TokenB for TokenA
aptos move run --function-id <deployed-address>::swap::swap_b_to_a --args u64:200 address:<admin-address>
```

### View Contract State
```bash
# Get current exchange rate
aptos move view --function-id <deployed-address>::swap::get_rate --args address:<admin-address>

# Get TokenA liquidity
aptos move view --function-id <deployed-address>::swap::get_liquidity_a --args address:<admin-address>

# Get TokenB liquidity
aptos move view --function-id <deployed-address>::swap::get_liquidity_b --args address:<admin-address>
```

## Configuration

The contract uses the following configuration in `Move.toml`:

```toml
[addresses]
risein = "e0f82045715e2cb83e9cdb5edbb0c40ec422e0d7d770c9ec16770d9e45d22ccb"
```

Update this address to your deployed contract address.

## Security Considerations

- **Admin Privileges**: Only the admin can add liquidity and set rates
- **Liquidity Checks**: Contract verifies sufficient liquidity before swaps
- **Resource Accounts**: Uses resource accounts for secure fund management
- **Registration**: Automatically registers users for coin types as needed

## Error Codes

- `E_NOT_ADMIN (1)`: Caller is not the admin
- `E_INSUFFICIENT_LIQUIDITY (2)`: Not enough tokens in liquidity pool
- `E_NOT_INITIALIZED (3)`: Contract not initialized

## Development

### Local Development Setup
1. Clone the repository
2. Run `aptos move compile` to verify setup
3. Use `aptos move test` for testing
4. Deploy to devnet for testing

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## Support

For questions and support:
- Check the [Aptos Documentation](https://aptos.dev/)
- Review [Move Language Documentation](https://move-language.github.io/move/)
- Open an issue in the repository

## License

This project is open source. Please check the license file for details.
