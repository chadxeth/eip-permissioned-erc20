// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Note: This interface is simplified. The real Groth16Verifier has a specific struct for Pairing.G1Point etc.
// For mocking purposes, we only need the function signature.
interface IGroth16Verifier {
    function verifyProof(
        uint256[2] calldata _pA,
        uint256[2][2] calldata _pB,
        uint256[2] calldata _pC,
        uint256[7] calldata _pubSignals
    ) external view returns (bool);
}

contract MockGroth16Verifier is IGroth16Verifier {
    // --- Configurable State --- 
    bool private _verifyProofResult = true; // Default to true
    bool private _verifyProofCalled = false;
    uint256 private _callCount = 0;

    // Store last inputs if needed for assertions (optional)
    // uint256[2] private _lastPA;
    // uint256[2][2] private _lastPB;
    // uint256[2] private _lastPC;
    // uint256[7] private _lastPubSignals;

    // --- Event ---
    event VerifyProofCalled(
        uint256[2] pA,
        uint256[2][2] pB,
        uint256[2] pC,
        uint256[7] pubSignals
    );

    // --- IGroth16Verifier Implementation ---
    function verifyProof(
        uint256[2] calldata _pA,
        uint256[2][2] calldata _pB,
        uint256[2] calldata _pC,
        uint256[7] calldata _pubSignals
    ) external view override returns (bool) {
        // Can't easily track calls in a view function for state variables, 
        // but we can emit an event (if called via a transaction, less useful for pure view calls).
        // Mocking view functions externally is usually done via tools like smock.
        // For manual mock, we control the return value directly.
        // emit VerifyProofCalled(_pA, _pB, _pC, _pubSignals); // Cannot emit event in view func
        return _verifyProofResult;
    }

    // --- Mock Configuration Functions ---
    function setVerifyProofResult(bool result) external {
        _verifyProofResult = result;
    }

    // --- Configuration Reset (if tracking state) ---
    // function resetState() external { ... }

    // --- View Functions for Assertions (if tracking state) ---
    // function getVerifyProofCalled() external view returns (bool) { ... }
    // function getCallCount() external view returns (uint256) { ... }
    // function getLastProofParams() external view returns (...) { ... }
} 