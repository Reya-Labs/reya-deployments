pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";

import "./DataTypes.sol";
import { IPassivePerpProxy, MarketConfigurationData } from "../../src/interfaces/IPassivePerpProxy.sol";
import { MarginInfo } from "../../src/interfaces/ICoreProxy.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

struct State {
    MarketConfigurationData marketConfig;
    uint128[] counterpartyAccountIds;
    uint256 deadline;
    uint128 exchangeId;
    bytes[] outputs;
    bytes32 digest;
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 staticFees;
    uint256 socketMsgGasLimit;
    MarginInfo poolMarginInfo;
    UD60x18 sharePrice;
}

contract StorageReyaForkTest is Test {
    StaticEcosystem sec;
    DynamicEcosystem dec;
    State s;
}
