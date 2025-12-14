// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ITransparentUpgradeableProxy } from "./ITransparentUpgradeableProxy.sol";

interface IProxyAdmin {
    function upgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) external payable;
}   
