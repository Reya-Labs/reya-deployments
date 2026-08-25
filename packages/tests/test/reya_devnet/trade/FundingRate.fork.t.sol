pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { FundingRatePerpOBForkCheck } from "../../reya_common/trade/FundingRatePerpOB.fork.c.sol";
import {
    IPassivePerpProxyV2,
    OracleDataType,
    MarketConfigurationDataV2
} from "../../../src/interfaces/IPassivePerpProxyV2.sol";

contract FundingRateForkTest is ReyaForkTest, FundingRatePerpOBForkCheck {
    uint128 internal constant ETH_MARKET_ID = 1;

    function test_Devnet_PriceSafetyConfiguration_ETH() public view {
        MarketConfigurationDataV2 memory config = IPassivePerpProxyV2(sec.perp).getMarketConfiguration(ETH_MARKET_ID);

        assertEq(config.oracleNodeId, sec.ethUsdcStorkMarkNodeId, "Unexpected independent mark-price node");
        assertEq(config.markPriceMaxStaleDuration, 60, "Unexpected mark-price staleness limit");
        assertEq(config.fundingRateMaxStaleDuration, 10 minutes, "Unexpected funding-rate staleness limit");
        assertEq(config.markPriceMaxDeviation, 0.05e18, "Unexpected mark-price deviation collar");
        assertEq(config.fillPriceMaxDeviation, 0.05e18, "Unexpected fill-price deviation collar");
        assertEq(config.minFundingInterval, 0, "Unexpected minimum funding interval");
    }

    function test_Devnet_MarkPriceDeviationCollar_ETH() public {
        setupFundingTestActors();

        uint256 oraclePrice = 3000e18;
        uint256 outOfBandMarkPrice = 3200e18;
        mockFreshPrice(sec.ethUsdcStorkMarkNodeId, oraclePrice);

        vm.expectRevert(
            abi.encodeWithSelector(
                IPassivePerpProxyV2.PriceDeviationTooLarge.selector,
                ETH_MARKET_ID,
                outOfBandMarkPrice,
                oraclePrice,
                uint256(0.05e18)
            )
        );
        _pushOracleData(ETH_MARKET_ID, OracleDataType.MarkPrice, abi.encode(outOfBandMarkPrice));
    }

    function test_Devnet_PushFundingRate_ETH() public {
        check_PushFundingRate(ETH_MARKET_ID);
    }

    function test_Devnet_FundingRateStaleness_ETH() public {
        check_FundingRateStaleness(ETH_MARKET_ID);
    }

    function test_Devnet_FundingRateStalenessForTrade_ETH() public {
        check_FundingRateStalenessForTrade(ETH_MARKET_ID);
    }

    function test_Devnet_PushMarkPrice_ETH() public {
        check_PushMarkPrice(ETH_MARKET_ID);
    }

    function test_Devnet_FundingRateAccrual_ETH() public {
        check_FundingRateAccrual(ETH_MARKET_ID);
    }
}
