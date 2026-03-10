pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import {
    ReyaCollateralForkCheck,
    ReyaSpotMarketConfigExpectations
} from "../../reya_common/collaterals/ReyaCollateral.fork.c.sol";

contract ReyaCollateralForkTest is ReyaForkTest, ReyaCollateralForkCheck {
    uint128 constant REYA_SPOT_MARKET_ID = 12;

    function test_reya_global_collateral_config() public view {
        check_reya_global_collateral_config();
    }

    function test_reya_spot_market_config() public view {
        ReyaSpotMarketConfigExpectations memory expected = ReyaSpotMarketConfigExpectations({
            spotMarketId: REYA_SPOT_MARKET_ID,
            oracleDeviation: 0,
            minimumOrderBase: 1e18,
            baseSpacing: 0.1e18,
            priceSpacing: 1e11 // 1e-7 unscaled
         });
        check_reya_spot_market_config(expected);
    }

    function test_reya_spot_market_enabled() public view {
        check_reya_spot_market_enabled(REYA_SPOT_MARKET_ID);
    }
}
