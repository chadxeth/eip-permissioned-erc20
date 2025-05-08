# EIP-XXXX Permissioned ERC-20 Walkthrough

This document provides a guide to understanding, building, and running the reference implementation for the Permissioned ERC-20 Token EIP.

**Target Audience:** Developers, auditors, institutions looking to implement or integrate permissioned token transfers.

**Current Status:** v0.1 - Contracts implemented, basic tests passing, placeholder ZK circuit & verifier.

## Overview

This project demonstrates an ERC-20 token (`PermissionedERC20.sol`) where standard transfers (`A` to `B`) are gated by an on-chain `TransferOracle.sol`. The oracle only permits a transfer if it has previously received and verified a corresponding off-chain authorization, attested to by a ZK-SNARK proof.

The key components are:

1.  **PermissionedERC20.sol:** An ERC-20 token that overrides `_update` to call the oracle's `canTransfer` method.
2.  **TransferOracle.sol:** Stores one-time transfer approvals (`{sender, recipient, minAmt, maxAmt, expiry, proofId}`). It verifies ZK proofs (`approveTransfer`) submitted by a designated issuer and consumes approvals (`canTransfer`) when called by the token.
3.  **Groth16Verifier.sol:** (Placeholder) The ZK-SNARK verifier contract, generated from the circuit.
4.  **iso_pain.circom:** (Placeholder) The Circom circuit defining the rules for generating valid proofs from off-chain data (e.g., canonicalised ISO 20022 `pain.001`).

## Quickstart

### Prerequisites

*   [Node.js](https://nodejs.org/) (v18+ recommended)
*   [Circom](https://docs.circom.io/getting-started/installation/) & [snarkjs](https://github.com/iden3/snarkjs#installation) (Required for ZK circuit steps)

### Installation

```bash
git clone https://github.com/YOUR_REPO_PATH/eip-permissioned-erc20.git
cd eip-permissioned-erc20
npm install
```

### Compile Contracts

```bash
npm run build:contracts
```

### Compile Circuits & Generate Verifier (Placeholder)

**Note:** This requires Circom to be installed.

1.  **Compile Circuit:**
    ```bash
    # (Commands from circuits/README.md - requires Circom)
    # circom circuits/iso_pain.circom --r1cs --wasm --sym -o circuits/build
    echo "Skipping circuit compile (requires Circom)"
    ```
2.  **Generate Verifier Contract:**
    ```bash
    # (Commands from circuits/README.md - requires snarkjs & dummy setup)
    # snarkjs zkey export solidityverifier ... contracts/verifier/Groth16Verifier.sol
    echo "Skipping verifier generation (requires Circom build outputs)"
    echo "Using placeholder: contracts/verifier/Groth16Verifier.sol"
    ```
    **Important:** For real use, you MUST replace the placeholder `Groth16Verifier.sol` with the output from `snarkjs`. The placeholder **bypasses proof verification**. 

### Run Tests

```bash
npm test
```

## Demo Flow (Conceptual - requires scripts & ZK setup)

1.  **Deploy Contracts:**
    *   Run a local node: `anvil`
    *   Deploy: `npm run deploy:local` (Script TBD)
    *   This would deploy `Groth16Verifier`, `TransferOracle`, and `PermissionedERC20`.

2.  **Generate Proof & Approve Transfer (Off-chain + On-chain):**
    *   Issuer prepares off-chain data (e.g., ISO `pain.001` JSON).
    *   Canonicalise the JSON using RFC 8785 (`utils/jcs.ts`).
    *   Process canonical data through the (placeholder) ZK circuit logic to get public/private inputs.
    *   Generate ZK proof using `snarkjs` and the compiled circuit (`circuits/build`).
    *   Construct the `TransferApproval` struct and `publicInputs` array.
    *   Submit to the oracle: `npm run approve:local -- --jsonPath <path> ...` (Script TBD)
    *   This script calls `TransferOracle.approveTransfer` with the approval, proof, and public inputs.

3.  **Execute Transfer:**
    *   User `A` (who has tokens) initiates a standard ERC-20 transfer to user `B`.
    *   `PermissionedERC20.transfer(B, amount)` calls `_update`.
    *   `_update` calls `TransferOracle.canTransfer(TokenAddr, A, B, amount)`.
    *   `canTransfer` finds the matching, unexpired approval, consumes it, and returns the `proofId`.
    *   `_update` emits `TransferValidated` and calls `super._update`.
    *   `super._update` emits `Transfer` and updates balances.

## Security Assumptions & Considerations

*   **ZK Circuit Correctness:** The security heavily relies on the Circom circuit accurately and completely enforcing the rules specified in the EIP regarding the underlying off-chain data.
*   **Verifier Generation:** The `Groth16Verifier.sol` MUST be generated correctly from the circuit's trusted setup.
*   **Trusted Setup:** The Groth16 setup ceremony (Powers of Tau + phase 2) must be performed securely. For production, a real multi-party computation ceremony is required.
*   **Oracle Issuer Security:** The private key of the `issuer` account (the `owner` of the `TransferOracle`) must be kept secure. Compromise allows submitting arbitrary approvals.
*   **Oracle `permissionedToken` Immutability:** The link between the oracle and the token is fixed at deployment. Upgrades require deploying a new oracle/token pair.
*   **Proof ID Uniqueness:** The `proofId` (derived from `root`, `senderHash`, `recipientHash`) combined with the `_consumedProofIds` mapping prevents replay of the *same* authorization proof.
*   **Canonicalisation:** The off-chain process MUST use a deterministic canonicalisation algorithm (like RFC 8785 JCS) before processing data for the circuit.
*   **Gas Costs:** ZK proof verification (`approveTransfer`) is expensive. Transfer gas (`canTransfer` + ERC20) is lower but includes storage reads/writes for the approval list.

## TODOs / Future Work (v0.2+)

*   Implement actual Circom circuit for ISO `pain.001` canonicalisation and hashing.
*   Complete TypeScript helper scripts (`deploy.ts`, `approve_transfer.ts`).
*   Implement RFC 8785 canonicaliser (`jcs.ts`).
*   Perform real dummy trusted setup and generate working Verifier contract.
*   Potentially add getter function to `TransferOracle` to inspect specific approval details.
*   Refine gas costs with real verifier.
*   Explore stretch goals (Proxy pattern, Permit2, PLONK). 