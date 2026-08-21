pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PerpFillForkCheck } from "../../reya_common/trade/PerpFill.fork.c.sol";

import {
    ICoreProxy,
    TriggerAutoExchangeInput,
    AutoExchangeAmounts,
    ParentCollateralConfig,
    CollateralConfig
} from "../../../src/interfaces/ICoreProxy.sol";
import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

/**
 * @title AutoExchangeForkTest (Devnet)
 * @notice Auto-exchange behaviour for wETH collateral against rUSD debt.
 * @dev The shared cronos AE checks create rUSD debt through Core
 *      match-order commands, which no longer exist under the perpOB router
 *      (InvalidCommandType) — the same class of incompatibility as the
 *      periphery matcher. This test creates the debt the perpOB-native way:
 *      a wETH-only account takes a short fill (taker fee lands as negative
 *      rUSD), the mark price then moves against it, and a funded liquidator
 *      auto-exchanges rUSD into the account against its wETH at the
 *      configured discount.
 */
contract AutoExchangeForkTest is ReyaForkTest, PerpFillForkCheck {
    uint128 internal constant ETH_MARKET_ID = 1;

    function test_Devnet_AutoExchange_WethCollateral() public {
        setupPerpTestActors();
        mockFreshPrices();

        uint256 entryPrice = 3000e18;
        mockFreshPrice(sec.ethUsdcStorkNodeId, entryPrice);
        mockFreshPrice(sec.ethUsdcStorkMarkNodeId, entryPrice);
        pushMarkPriceWithinCollar(ETH_MARKET_ID, entryPrice);
        pushFundingRate(ETH_MARKET_ID, 0);

        // Short side holds ONLY wETH; every rUSD debit (fees, negative PnL)
        // makes its rUSD margin negative — the AE precondition.
        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 100_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.weth, 2e18);

        executePerpFill(buyerAccountId, sellerAccountId, ETH_MARKET_ID, 1e18, entryPrice, 1, 1, 1);

        // Mark moves 300 against the short; keep every oracle source
        // consistent so the collar and collateral valuation agree.
        uint256 bumpedPrice = 3300e18;
        mockFreshPrice(sec.ethUsdcStorkNodeId, bumpedPrice);
        mockFreshPrice(sec.ethUsdcStorkMarkNodeId, bumpedPrice);
        pushMarkPriceWithinCollar(ETH_MARKET_ID, bumpedPrice);

        int256 sellerRusdBefore = ICoreProxy(sec.core).getTokenMarginInfo(sellerAccountId, sec.rusd).marginBalance;
        require(sellerRusdBefore < 0, "short account should be rUSD-negative before AE");

        (address liquidator,) = makeAddrAndKey("aeLiquidator");
        uint128 liquidatorAccountId = depositNewMA(liquidator, sec.rusd, 10_000e6);
        // AE walks the liquidator's margin too; a never-activated account
        // has firstMarketId 0 and reverts MarketNotFound(0) — the same trap
        // the genesis pool seed hit.
        vm.prank(liquidator);
        ICoreProxy(sec.core).activateFirstMarketForAccount(liquidatorAccountId, ETH_MARKET_ID);

        uint256 requestedQuote = 100e6;
        vm.prank(liquidator);
        AutoExchangeAmounts memory ae = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: sellerAccountId,
                liquidatorAccountId: liquidatorAccountId,
                requestedQuoteAmount: requestedQuote,
                collateral: sec.weth,
                inCollateral: sec.rusd
            })
        );

        // The account's rUSD debt shrinks by what the liquidator paid in.
        int256 sellerRusdAfter = ICoreProxy(sec.core).getTokenMarginInfo(sellerAccountId, sec.rusd).marginBalance;
        require(ae.quoteAmountToAccount > 0, "AE moved no quote to the account");
        // token margin balances are in token decimals (rUSD = 6dp), matching
        // the quote amounts AE returns
        require(
            sellerRusdAfter - sellerRusdBefore >= int256(uint256(ae.quoteAmountToAccount)) - 1,
            "account rUSD debt did not shrink by the exchanged quote"
        );

        // The liquidator receives the account's wETH at the configured
        // discount: collateral received, valued at the (bumped) oracle
        // price, must exceed the quote paid and stay within the discount
        // plus rounding.
        require(ae.collateralAmountToLiquidator > 0, "liquidator received no collateral");
        (, ParentCollateralConfig memory wethParent,) = ICoreProxy(sec.core).getCollateralConfig(1, sec.weth);
        uint256 collateralValue = ae.collateralAmountToLiquidator * bumpedPrice / 1e18;
        uint256 quotePaid18 = (uint256(ae.quoteAmountToAccount) + ae.quoteAmountToIF) * 1e12;
        require(collateralValue >= quotePaid18, "liquidator did not receive at least par value");
        // discount convention is divide-by-(1-d), the same shape as the
        // haircut math: quote / (1 - 0.02) = 1.0204x, not 1.02x
        require(
            collateralValue <= quotePaid18 * 1e18 / (1e18 - wethParent.autoExchangeDiscount) + 1e12,
            "liquidator premium exceeds the configured AE discount"
        );

        // And the wETH actually landed on the liquidator's margin account.
        require(
            ICoreProxy(sec.core).getTokenMarginInfo(liquidatorAccountId, sec.weth).marginBalance
                == int256(ae.collateralAmountToLiquidator),
            "collateral not credited to the liquidator account"
        );
    }
}
