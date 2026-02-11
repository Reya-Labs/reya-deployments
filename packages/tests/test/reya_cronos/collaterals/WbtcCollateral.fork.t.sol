pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import {
    WbtcCollateralForkCheck,
    WbtcCollateralConfigExpectations,
    WbtcSpotMarketConfigExpectations
} from "../../reya_common/collaterals/WbtcCollateral.fork.c.sol";

contract WbtcCollateralForkTest is ReyaForkTest, WbtcCollateralForkCheck {
    uint128 constant WBTC_SPOT_MARKET_ID = 11;

    function test_Cronos_wbtc_collateral_config() public view {
        WbtcCollateralConfigExpectations memory expected = WbtcCollateralConfigExpectations({
            depositingEnabled: true,
            cap: 11_579_208_923_731_619_542_357_098_500_868_790_785_326_998_466_564_056_403_945_758_400_791,
            autoExchangeThreshold: 0,
            autoExchangeInsuranceFee: 0.01e18,
            autoExchangeDustThreshold: 0,
            priceHaircut: 0.1e18,
            autoExchangeDiscount: 0.02e18
        });
        check_wbtc_collateral_config(expected);
    }

    function test_Cronos_wbtc_global_collateral_config() public view {
        check_wbtc_global_collateral_config();
    }

    function test_Cronos_wbtc_spot_market_config() public view {
        WbtcSpotMarketConfigExpectations memory expected = WbtcSpotMarketConfigExpectations({
            spotMarketId: WBTC_SPOT_MARKET_ID,
            oracleDeviation: 0,
            minimumOrderBase: 1e14,
            baseSpacing: 1e14,
            priceSpacing: 1e16
        });
        check_wbtc_spot_market_config(expected);
    }

    function test_Cronos_wbtc_spot_market_enabled() public view {
        check_wbtc_spot_market_enabled(WBTC_SPOT_MARKET_ID);
    }

    function test_Cronos_wbtc_auto_exchange_enabled() public view {
        check_wbtc_auto_exchange_enabled();
    }

    function test_Cronos_WbtcTradeWithWbtcCollateral() public {
        check_WbtcTradeWithWbtcCollateral();
    }
}
