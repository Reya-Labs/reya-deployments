pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PerpFillForkCheck } from "../../reya_common/trade/PerpFill.fork.c.sol";

contract PerpFillForkTest is ReyaForkTest, PerpFillForkCheck {
    uint128 constant ETH_MARKET_ID = 1;

    function test_Devnet_PerpExecuteFill_ETH() public {
        check_PerpExecuteFill(ETH_MARKET_ID);
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

    function test_Devnet_PerpFillZeroFees_ETH() public {
        check_PerpFillZeroFees(ETH_MARKET_ID, sec.setMarketZeroFeeBot);
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

    function test_Devnet_PerpFillFeeDiscounts_OG_ETH() public {
        check_PerpFillFeeDiscounts(ETH_MARKET_ID, true, false);
    }

    function test_Devnet_PerpFillFeeDiscounts_VLTZ_ETH() public {
        check_PerpFillFeeDiscounts(ETH_MARKET_ID, false, true);
    }

    function test_Devnet_PerpFillFeeDiscounts_OG_VLTZ_ETH() public {
        check_PerpFillFeeDiscounts(ETH_MARKET_ID, true, true);
    }

    function test_Devnet_PerpFillExchangeZeroFees_ETH() public {
        check_PerpFillExchangeZeroFees(ETH_MARKET_ID);
    }
}
