// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

// Allows anyone to claim a token if they exist in a merkle root.
interface ICumulativeMerkleDrop {
    // This event is triggered whenever a call to #setMerkleRoot succeeds.
    event MerkelRootUpdated(
        address token,
        bytes32 oldMerkleRoot,
        bytes32 newMerkleRoot
    );
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(
        address indexed token,
        address indexed account,
        uint256 amount
    );

    error InvalidProof();
    error NothingToClaim();
    error MerkleRootWasUpdated();

    // Returns the address of the token distributed by this contract.
    // function token() external view returns (address);

    // Returns the merkle root of the merkle tree containing cumulative account balances available to claim.
    function merkelRoots(address token) external view returns (bytes32);

    // Sets the merkle root of the merkle tree containing cumulative account balances available to claim.
    function setMerkleRoot(address token, bytes32 merkleRoot_) external;

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    struct ClaimParams {
        address token;
        address account;
        uint256 cumulativeAmount;
        bytes32 expectedMerkleRoot;
        bytes32[] merkleProof;
    }

    function claim(ClaimParams calldata params) external;

    function multiClaim(ClaimParams[] calldata params) external;
}
