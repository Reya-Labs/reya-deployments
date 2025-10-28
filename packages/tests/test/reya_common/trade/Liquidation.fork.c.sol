pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";
import { ICoreProxy, CollateralInfo, MarginInfo } from "../../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy, GlobalFeeParameters, CacheStatus } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { sd, SD59x18, UNIT as ONE_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract LiquidationForkCheck is BaseReyaForkTest { }
