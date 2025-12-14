
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITransparentUpgradeableProxy {
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}