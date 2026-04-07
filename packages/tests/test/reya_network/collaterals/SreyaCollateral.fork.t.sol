pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import {
    SreyaCollateralForkCheck,
    SreyaSpotMarketConfigExpectations
} from "../../reya_common/collaterals/SreyaCollateral.fork.c.sol";

contract SreyaCollateralForkTest is ReyaForkTest, SreyaCollateralForkCheck {
    uint128 constant SREYA_SPOT_MARKET_ID = 13;

    function test_sreya_global_collateral_config() public view {
        check_sreya_global_collateral_config();
    }

    function test_sreya_spot_market_config() public view {
        SreyaSpotMarketConfigExpectations memory expected = SreyaSpotMarketConfigExpectations({
            spotMarketId: SREYA_SPOT_MARKET_ID, oracleDeviation: 0, minimumOrderBase: 0, baseSpacing: 0, priceSpacing: 0
        });
        check_sreya_spot_market_config(expected);
    }

    function test_sreya_spot_market_disabled() public view {
        check_sreya_spot_market_disabled(SREYA_SPOT_MARKET_ID);
    }
}
