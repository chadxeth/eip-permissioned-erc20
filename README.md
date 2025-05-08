# Oracle-Permissioned ERC-20 Transfers with ZK-Verified SWIFT ISO 20022 Payment Instructions

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

This repository provides a reference implementation for EIP-XXXX, a standard for permissioned ERC-20 tokens.

The core idea is an ERC-20 token (`PermissionedERC20.sol`) where standard transfers (`A` to `B`) require validation from an on-chain `TransferOracle.sol`. This oracle verifies off-chain authorizations, attested by ZK-SNARK proofs, before permitting transfers.

This implementation uses:
*   **Hardhat:** For development, testing, and deployment.
*   **Solidity:** For smart contracts (using OpenZeppelin contracts as base).
*   **Circom / snarkjs:** For the zero-knowledge proof circuit and verifier generation.
*   **TypeScript:** For tests and scripts.

## Key Components

1.  **`contracts/PermissionedERC20.sol`**: The ERC-20 token overriding `_update` to check with the oracle.
2.  **`contracts/TransferOracle.sol`**: Manages transfer approvals based on ZK proofs.
3.  **`contracts/verifier/Groth16Verifier.sol`**: The ZK-SNARK verifier contract (requires generation from the circuit).
4.  **`circuits/iso_pain.circom`**: The Circom circuit defining rules for proof generation (currently a placeholder).
5.  **`test/`**: Hardhat tests written in TypeScript.
6.  **`scripts/`**: Deployment and interaction scripts using Hardhat.

## Prerequisites

*   [Node.js](https://nodejs.org/) (v18+ recommended)
*   [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)
*   [Circom](https://docs.circom.io/getting-started/installation/) & [snarkjs](https://github.com/iden3/snarkjs#installation) (Required only if modifying/building ZK circuits)

## Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/YOUR_REPO_PATH/eip-permissioned-erc20.git # Replace with your repo path
    cd eip-permissioned-erc20
    ```
2.  Install dependencies:
    ```bash
    npm install
    # or
    # yarn install
    ```

## Usage

### Compile Contracts

```bash
npm run build:contracts
# or
npx hardhat compile
```

### Run Tests

```bash
npm test
# or
npx hardhat test
```

### Code Formatting & Linting

*   Format all code (Solidity & TypeScript):
    ```bash
    npm run format
    ```
*   Check formatting and lint Solidity:
    ```bash
    npm run lint
    ```

### Run Local Hardhat Node

```bash
npx hardhat node
```

### Deploy to Local Node

(Ensure a local node is running first)

```bash
npm run deploy:local
# or
npx hardhat run scripts/deploy.ts --network localhost
```

### Circuit Compilation & Verifier Generation

Refer to the instructions in `circuits/README.md` if you need to build the ZK circuits or generate a new verifier contract.

## Documentation

*   **Test Plan:** `tests/UnitTests.md`
*   **EIP Walkthrough:** `docs/EIP-walkthrough.md`
*   **Circuit Details:** `circuits/README.md`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details (assuming one exists).
