pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

contract OrderForkTest is ReyaForkTest {
    function setUp() public override { }

    function test_SignedFill_ETH() public {
        check_PerpExecuteFill(1);
    }

    function test_SignedFill_BTC() public {
        check_PerpExecuteFill(2);
    }

    function test_SignedFillMetadataBinding_ETH() public {
        check_PerpFillMetadataBinding(1);
    }

    function test_SignedFillNonceReplay_ETH() public {
        check_PerpFillNonceReplay(1);
    }

    function test_SignedFillBatch_ETH() public {
        check_PerpBatchExecuteFill(1);
    }

    function test_SignedFillClose_ETH() public {
        check_PerpFillClosePosition(1);
    }

    function test_SignedFillFees_ETH() public {
        check_PerpFillFees(1);
    }

    function test_SignedFillInsufficientMargin_ETH() public {
        check_PerpFillInsufficientMargin(1);
    }

    function test_SignedFillReduceOnly_ETH() public {
        check_PerpFillReduceOnly(1);
    }

    function test_SignedFillRejectsStaleMark_ETH() public {
        check_PerpMarkPriceStaleness(1);
    }

    function test_SignedFillMarkImpactsMargin_ETH() public {
        check_PerpMarkPriceImpactsMargin(1);
    }

    function test_SignedFillMarginImpact_ETH() public {
        check_PerpFillMarginImpact(1);
    }

    function test_SignedFillReduceOnlyRevert_ETH() public {
        check_PerpFillReduceOnlyRevert(1);
    }

    function test_WithdrawWithOpenPosition_ETH() public {
        check_WithdrawWithOpenPosition(1);
    }

    function test_DeprecatedMarketZeroFeesFlagIsInert_ETH() public {
        // The legacy bot is not authorized on the PerpOB router. Use the owner so this
        // test reaches and proves the deprecated field is economically inert.
        check_PerpFillDeprecatedMarketZeroFeesFlag(1, sec.multisig);
    }

    function test_DeprecatedExchangeZeroFeesFlagIsInert_ETH() public {
        check_PerpFillDeprecatedExchangeZeroFeesFlag(1);
    }

    function test_DeprecatedMakerParametersAreInert_ETH() public {
        check_PerpFillDeprecatedMakerParametersIgnored(1);
    }

    function test_TakerRebate_OG_ETH() public {
        check_PerpFillTakerRebates(1, true, false);
    }

    function test_TakerRebate_VLTZ_ETH() public {
        check_PerpFillTakerRebates(1, false, true);
    }

    function test_TakerRebate_OGAndVLTZ_ETH() public {
        check_PerpFillTakerRebates(1, true, true);
    }

    function test_TakerFeeParameterUpperBound() public {
        check_TakerFeeParameterUpperBound();
    }
}
