pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PerpFillForkCheck } from "../../reya_common/trade/PerpFill.fork.c.sol";
import { IPassivePerpProxyV2, FeeTierParameters } from "../../../src/interfaces/IPassivePerpProxyV2.sol";

contract PerpFillForkTest is ReyaForkTest, PerpFillForkCheck {
    uint128 constant ETH_MARKET_ID = 1;

    function test_Devnet_PerpExecuteFill_ETH() public {
        check_PerpExecuteFill(ETH_MARKET_ID);
    }

    function test_Devnet_PerpFillPriceDeviationCollar_ETH() public {
        setupPerpTestActors();
        mockFreshPrices();

        uint256 markPrice = 3000e18;
        uint256 outOfBandFillPrice = 3200e18;
        pushMarkPrice(ETH_MARKET_ID, markPrice);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        vm.expectRevert(
            abi.encodeWithSelector(
                IPassivePerpProxyV2.PriceDeviationTooLarge.selector,
                ETH_MARKET_ID,
                outOfBandFillPrice,
                markPrice,
                uint256(0.05e18)
            )
        );
        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: ETH_MARKET_ID,
            baseDelta: 0.1e18,
            price: outOfBandFillPrice,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });
    }

    function test_Devnet_PerpFillMetadataBinding_ETH() public {
        check_PerpFillMetadataBinding(ETH_MARKET_ID);
    }

    function test_Devnet_PerpMarkPriceStaleness_ETH() public {
        check_PerpMarkPriceStaleness(ETH_MARKET_ID);
    }

    function test_Devnet_PerpBatchExecuteFill_ETH() public {
        check_PerpBatchExecuteFill(ETH_MARKET_ID);
    }

    function test_Devnet_PerpFillMarginImpact_ETH() public {
        check_PerpFillMarginImpact(ETH_MARKET_ID);
    }

    function test_Devnet_PerpFillNonceReplay_ETH() public {
        check_PerpFillNonceReplay(ETH_MARKET_ID);
    }

    function test_Devnet_PerpFillClosePosition_ETH() public {
        check_PerpFillClosePosition(ETH_MARKET_ID);
    }

    function test_Devnet_PerpMarkPriceImpactsMargin_ETH() public {
        check_PerpMarkPriceImpactsMargin(ETH_MARKET_ID);
    }

    function test_Devnet_PerpFillFees_ETH() public {
        check_PerpFillFees(ETH_MARKET_ID);
    }

    function test_Devnet_PerpFillDeprecatedMarketZeroFeesFlag_ETH() public {
        check_PerpFillDeprecatedMarketZeroFeesFlag(ETH_MARKET_ID, sec.setMarketZeroFeeBot);
    }

    function test_Devnet_PerpFillInsufficientMargin_ETH() public {
        check_PerpFillInsufficientMargin(ETH_MARKET_ID);
    }

    function test_Devnet_PerpFillReduceOnly_ETH() public {
        check_PerpFillReduceOnly(ETH_MARKET_ID);
    }

    function test_Devnet_PerpFillReduceOnlyRevert_ETH() public {
        check_PerpFillReduceOnlyRevert(ETH_MARKET_ID);
    }

    function test_Devnet_WithdrawWithOpenPosition_ETH() public {
        check_WithdrawWithOpenPosition(ETH_MARKET_ID);
    }

    // Fee model checks

    function test_Devnet_FeeTierSchedule() public view {
        uint256[7] memory expectedTakerFees = [
            uint256(0.0003e18),
            uint256(0.00028e18),
            uint256(0.00026e18),
            uint256(0.00024e18),
            uint256(0.00022e18),
            uint256(0.00021e18),
            uint256(0.0002e18)
        ];

        for (uint256 tierId = 0; tierId < expectedTakerFees.length; tierId++) {
            FeeTierParameters memory tier = IPassivePerpProxyV2(sec.perp).getFeeTierParameters(tierId);
            assertEq(tier.takerFee, expectedTakerFees[tierId], "Unexpected taker fee");
            assertEq(tier.makerFee_DEPRECATED, 0, "Deprecated maker fee must be zero");
            assertEq(tier.makerRebate_DEPRECATED, 0, "Deprecated maker rebate must be zero");
        }
    }

    function test_Devnet_PerpFillTakerRebate_OG_ETH() public {
        check_PerpFillTakerRebates(ETH_MARKET_ID, true, false);
    }

    function test_Devnet_PerpFillTakerRebate_VLTZ_ETH() public {
        check_PerpFillTakerRebates(ETH_MARKET_ID, false, true);
    }

    function test_Devnet_PerpFillTakerRebate_OG_VLTZ_ETH() public {
        check_PerpFillTakerRebates(ETH_MARKET_ID, true, true);
    }

    function test_Devnet_PerpFillDeprecatedExchangeZeroFeesFlag_ETH() public {
        check_PerpFillDeprecatedExchangeZeroFeesFlag(ETH_MARKET_ID);
    }

    function test_Devnet_PerpFillDeprecatedMakerParametersIgnored_ETH() public {
        check_PerpFillDeprecatedMakerParametersIgnored(ETH_MARKET_ID);
    }

    function test_Devnet_TakerFeeParameterUpperBound() public {
        check_TakerFeeParameterUpperBound();
    }
}
