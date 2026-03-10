pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { ICoreProxy, GlobalCollateralConfig } from "../../../src/interfaces/ICoreProxy.sol";

contract SreyaCollateralForkCheck is BaseReyaForkTest {
    function check_sreya_global_collateral_config() internal view {
        (GlobalCollateralConfig memory globalConfig,) = ICoreProxy(sec.core).getGlobalCollateralConfig(sec.sreya);

        assertEq(globalConfig.collateralAdapter, address(0), "sREYA collateralAdapter should be zero address");
        assertGt(globalConfig.withdrawalWindowSize, 0, "sREYA withdrawalWindowSize should be > 0");
        assertGt(globalConfig.withdrawalTvlPercentageLimit, 0, "sREYA withdrawalTvlPercentageLimit should be > 0");
    }
}
