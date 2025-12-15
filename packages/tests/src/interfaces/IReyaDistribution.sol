// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { UD60x18 } from "@prb/math/UD60x18.sol";

struct EIP712Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 deadline;
}

struct LeafInfo {
    address wallet;
    uint256 allocation;
}

struct WalletInfo {
    bool claimedOrLocked;
    uint256 lockedStakedAmount;
    uint256 lockedTimestamp;
}

struct ClaimingConfiguration {
    bytes32 root;
    uint256 startTimestamp;
    uint256 endTimestamp;
    uint256 lockDuration;
    UD60x18 lockMultiplier;
}

struct GlobalConfiguration {
    address stakedReyaTokenAddress;
    address coreProxyAddress;
}

interface IReyaDistribution {
    function owner() external view returns (address);
    function initialize(address initialOwner) external;
    function setConfiguration(
        GlobalConfiguration memory globalConfiguration,
        ClaimingConfiguration memory claimingConfiguration
    )
        external;
    function rescueTokens(address tokenAddress, address receiver) external;
    function pause() external;
    function unpause() external;
    function claim(LeafInfo memory leafInfo, bytes32[] calldata proof) external returns (uint256);
    function claimBySig(
        LeafInfo memory leafInfo,
        bytes32[] calldata proof,
        EIP712Signature calldata signature
    )
        external
        returns (uint256);
    function lock(LeafInfo memory leafInfo, bytes32[] calldata proof) external returns (uint256);
    function lockBySig(
        LeafInfo memory leafInfo,
        bytes32[] calldata proof,
        EIP712Signature calldata signature
    )
        external
        returns (uint256);
    function release(address wallet) external returns (uint256);
    function getWalletInfo(address owner) external view returns (WalletInfo memory);
    function getConfiguration() external view returns (GlobalConfiguration memory, ClaimingConfiguration memory);
}
