pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SrusdCollateralForkCheck } from "../../reya_common/collaterals/SrusdCollateral.fork.c.sol";
import { PerpFillForkCheck } from "../../reya_common/trade/PerpFill.fork.c.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

/**
 * @title SrusdCollateralForkTest (Devnet)
 * @notice Fork tests for sRUSD as a collateral on devnet.
 * @dev sRUSD is devnet's OWN token, deposits are enabled, and its parent
 *      collateral oracle is the live REYAPOOL#1 pool-share node (computed
 *      from PassivePool.getSharePrice at read time), so the shared view /
 *      deposit-withdraw / transfer checks run here unmodified. The
 *      `check_trade_srusdCollateral_*` and `check_srusd_cap_exceeded`
 *      helpers are NOT wired: they route orders through the periphery
 *      matcher, which reverts InvalidPeripheryExecution under the perpOB
 *      deployment — the fill-collateralization path is covered by the
 *      perpOB-native test below instead.
 */
contract SrusdCollateralForkTest is ReyaForkTest, SrusdCollateralForkCheck, PerpFillForkCheck {
    uint128 internal constant ETH_MARKET_ID = 1;

    function testFuzz_Devnet_SRUSDMintBurn(address attacker) public {
        vm.assume(attacker != sec.pool);
        checkFuzz_SRUSDMintBurn(attacker);
    }

    function test_Devnet_SrusdViewFunctions() public {
        check_srusd_view_functions();
    }

    function test_Devnet_SrusdDepositWithdraw() public {
        check_srusd_deposit_withdraw();
    }

    function test_Devnet_SrusdTransferRestrictions() public {
        check_transfer_srusdCollateral();
    }

    /// A perpOB fill where the short side is collateralized ENTIRELY by
    /// sRUSD. Proves the whole chain: sRUSD deposit -> margin valuation via
    /// the live pool-share node (with haircut) -> fill admission ->
    /// position update. This is the perpOB replacement for the shared
    /// periphery-matcher trade checks.
    function test_Devnet_PerpFillWithSrusdCollateral_ETH() public {
        setupPerpTestActors();
        mockFreshPrices();

        uint256 entryPrice = 3000e18;
        mockFreshPrice(sec.ethUsdcStorkNodeId, entryPrice);
        mockFreshPrice(sec.ethUsdcStorkMarkNodeId, entryPrice);
        pushMarkPriceWithinCollar(ETH_MARKET_ID, entryPrice);
        pushFundingRate(ETH_MARKET_ID, 0);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 100_000e6);
        // 100k sRUSD (30 decimals) on the short side — ample margin for a
        // 1 ETH position at 3000; the devnet sRUSD cap is MaxUint256, so this is purely a
        // sizing choice.
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.srusd, 100_000e30);

        executePerpFill(buyerAccountId, sellerAccountId, ETH_MARKET_ID, 1e18, entryPrice, 1, 1, 1);

        assertEq(
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(ETH_MARKET_ID, sellerAccountId).base,
            -1e18,
            "short (sRUSD-collateralized) position"
        );
        assertEq(
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(ETH_MARKET_ID, buyerAccountId).base,
            1e18,
            "long position"
        );
    }
}
