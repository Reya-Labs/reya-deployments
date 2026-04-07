pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";

import "./DataTypes.sol";
import { IPassivePerpProxy, MarketConfigurationData } from "../../src/interfaces/IPassivePerpProxy.sol";
import { MarginInfo } from "../../src/interfaces/ICoreProxy.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

contract StorageReyaForkTest is Test {
    StaticEcosystem sec;
    DynamicEcosystem dec;

    /// @dev When true, depositNewMA always uses the direct deposit path (deal + approve + deposit)
    ///      instead of going through the Periphery. Used by devnet where the shared Cronos Periphery
    ///      points to the wrong Core.
    bool internal useDirectDeposit;
}
