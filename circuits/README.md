# ISO Pain Circom Circuit (`iso_pain.circom`)

This directory contains the Circom circuit responsible for verifying the integrity and origin of transfer approvals based on canonicalised ISO 20022 `pain.001.001.09` messages (or other structured data).

**Current Status: Placeholder**

The current `iso_pain.circom` is a **placeholder** circuit. It defines the expected public inputs that the `TransferOracle.sol` contract requires for `approveTransfer`, but it **does not** implement the actual ISO message processing, canonicalization, hashing (e.g., Keccak), or Merkle proof verification logic specified in the EIP.

## Purpose

The final circuit's goal is to generate a ZK-SNARK (Groth16) proof attesting that a given set of transfer parameters (sender, recipient, amounts, expiry) was derived correctly and authorized within a specific, canonicalised off-chain message, linked to a root hash, and authorized by a known issuer.

## Placeholder Public Inputs

The placeholder circuit (`main` component) defines the following public inputs, which correspond to the `publicInputs` array expected by `TransferOracle.approveTransfer`:

1.  `root`: (uint256) The root hash of a Merkle tree (or similar commitment) representing the batch or source of the original off-chain message.
2.  `senderHash`: (uint256) A hash derived from the sender's details within the canonicalised message (e.g., Poseidon or Keccak hash).
3.  `recipientHash`: (uint256) A hash derived from the recipient's details within the canonicalised message.
4.  `minAmt`: (uint256) The minimum transfer amount approved (scaled if necessary, e.g., by 1000).
5.  `maxAmt`: (uint256) The maximum transfer amount approved (scaled if necessary, e.g., by 1000).
6.  `currencyHash`: (uint256) A hash of the currency code (e.g., "USD").
7.  `expTs`: (uint256) The Unix timestamp when the approval expires (represented as uint64 in Solidity, but uint256 in circuit).

## Placeholder Private Inputs

The placeholder contains a dummy `privateData` array. In the real circuit, these would include:

*   The relevant fields from the canonicalised ISO message.
*   The Merkle proof path connecting the message data to the public `root`.
*   Any intermediate values needed for hashing or validation.

## Placeholder Constraints & Output

The placeholder includes trivial constraints (like hashing public inputs) and a `computedHash` output. The real circuit would implement constraints such as:

*   Verifying the Merkle proof against the `root`.
*   Hashing sender/recipient details to match `senderHash`/`recipientHash`.
*   Validating data fields according to the ISO spec and EIP rules.
*   Ensuring internal consistency.

## Building the Circuit & Verifier (Requires Circom Installation)

1.  **Install Circom & snarkjs:** Follow instructions at [https://docs.circom.io/](https://docs.circom.io/) and [https://github.com/iden3/snarkjs#installation](https://github.com/iden3/snarkjs#installation).
2.  **Compile Circuit:**
    Run the following command **from the project root directory**:
    ```bash
    # Create output directories if they don't exist
    mkdir -p circuits/build/iso_pain_js
    
    # Compile the circuit, specifying node_modules as library path
    circom circuits/iso_pain.circom --r1cs --wasm --sym -o circuits/build -l node_modules
    ```
    *Note: The `include` paths within `iso_pain.circom` should be relative to `node_modules` (e.g., `"circomlib/circuits/poseidon.circom"`).*

3.  **Trusted Setup (Dummy for development, replace with real ceremony for production):**
    Run these commands **from the project root directory**.
    *   Powers of Tau (Phase 1 - do once for a constraint size, e.g., 2^12):
        ```bash
        # Using ptau file included in repo for convenience
        # If generating new, use commands below:
        # snarkjs powersoftau new bn128 14 pot14_0000.ptau -v 
        # snarkjs powersoftau contribute pot14_0000.ptau pot14_0001.ptau --name="First contribution" -v -e="some random entropy"
        # snarkjs powersoftau prepare phase2 pot14_0001.ptau pot14_final.ptau -v
        echo "Using existing powersOfTau28_hez_final_14.ptau - skipping generation."
        # Ensure the .ptau file exists in the root or adjust path below
        ```
        *(Use `circuits/powersOfTau28_hez_final_14.ptau` or your generated final `.ptau` file in the next step)*

4.  **Generate ZKey (Phase 2 - circuit specific):**
    Run **from the project root directory**:
    ```bash
    snarkjs groth16 setup circuits/build/iso_pain.r1cs circuits/powersOfTau28_hez_final_14.ptau circuits/build/iso_pain_0000.zkey
    ```
5.  **Contribute to ZKey (Dummy for development):**
    Run **from the project root directory**:
    ```bash
    snarkjs zkey contribute circuits/build/iso_pain_0000.zkey circuits/build/iso_pain_final.zkey --name="Circuit key contribution" -v -e="more random entropy"
    ```
    *(Use `iso_pain_final.zkey` in subsequent steps. If you skip this, use `iso_pain_0000.zkey` as the final zkey)*

6.  **Export Verification Key (JSON for off-chain verification):**
    Run **from the project root directory**:
    ```bash
    snarkjs zkey export verificationkey circuits/build/iso_pain_final.zkey circuits/build/verification_key.json
    ```
7.  **Generate Verifier Contract (Solidity for on-chain verification):**
    Run **from the project root directory**:
    ```bash
    # Ensure the output directory exists
    mkdir -p contracts/verifier
    snarkjs zkey export solidityverifier circuits/build/iso_pain_final.zkey contracts/verifier/Groth16Verifier.sol
    ```

**IMPORTANT:** 
*   Ensure the output path for `Groth16Verifier.sol` (`contracts/verifier/Groth16Verifier.sol`) matches the import path used in `TransferOracle.sol`.
*   The generated `Groth16Verifier.sol` should replace any placeholder file if you intend to use the actual circuit proof verification. 