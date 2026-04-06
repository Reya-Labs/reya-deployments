pragma solidity >=0.8.19 <0.9.0;

import { PerpFillForkCheck } from "./PerpFill.fork.c.sol";
import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";
import {
    ICoreProxy,
    MarginInfo,
    Command as Command_Core,
    CommandType,
    DutchLiquidationInput
} from "../../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy, PerpPosition } from "../../../src/interfaces/IPassivePerpProxy.sol";
import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd, SD59x18, UNIT as ONE_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

/**
 * @title LiquidationPerpOBForkCheck
 * @notice Fork tests for liquidation in the perpOB model
 * @dev Uses fill-based position opening (executePerpFill) and oracle-pushed mark prices.
 *      In perpOB: backstop liquidation goes to a dedicated backstop liquidator account
 *      instead of the passive pool.
 *      Legacy LiquidationForkCheck is kept separately for cronos/mainnet.
 */
contract LiquidationPerpOBForkCheck is PerpFillForkCheck {
    address private liqUser;
    address private liqLiquidator;
    uint128 private liqUserAccountId;
    uint128 private liqLiquidatorAccountId;
    uint128 private backstopAccountId;

    function setupLiquidationTest(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();

        // Push initial mark price at $3000
        pushMarkPrice(marketId, 3000e18);
        pushFundingRate(marketId, 0); // zero funding to simplify

        (liqUser,) = makeAddrAndKey("liqUser");
        liqUserAccountId = depositNewMA(liqUser, sec.rusd, 500e6);

        (liqLiquidator,) = makeAddrAndKey("liqLiquidator");
        liqLiquidatorAccountId = depositNewMA(liqLiquidator, sec.rusd, 50_000e6);

        // Open a leveraged long position for the user via fill
        // User goes long 1 ETH at $3000 (~$3000 exposure, $500 collateral = ~6x leverage)
        executePerpFill({
            buyerAccountId: liqUserAccountId,
            sellerAccountId: liqLiquidatorAccountId,
            marketId: marketId,
            baseDelta: 1e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        // Verify position opened
        PerpPosition memory userPos = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqUserAccountId);
        assertEq(userPos.base, 1e18, "User should be long 1 ETH");
    }

    /**
     * @notice Test Dutch liquidation in perpOB model
     * @dev Opens leveraged long, drops price to make account underwater,
     *      executes Dutch liquidation to transfer position to liquidator
     */
    function check_DutchLiquidation_PerpOB(uint128 marketId) internal {
        setupLiquidationTest(marketId);

        // Drop mark price to make user underwater
        // User has $500 collateral, long 1 ETH from $3000
        // At $2300: unrealized PnL = -$700, total margin ~= -$200 -> underwater
        pushMarkPrice(marketId, 2300e18);
        mockFreshPrices();

        // Execute Dutch liquidation
        {
            uint128[] memory marketIds = new uint128[](1);
            marketIds[0] = marketId;

            bytes[] memory inputs = new bytes[](1);
            inputs[0] = abi.encode(sd(-1e18), ud(0)); // close entire long

            Command_Core[] memory commands = new Command_Core[](1);
            commands[0] = Command_Core({
                commandType: uint8(CommandType.DutchLiquidation),
                inputs: abi.encode(
                    DutchLiquidationInput({
                        liquidatableAccountId: liqUserAccountId,
                        quoteCollateral: sec.rusd,
                        marketIds: marketIds,
                        inputs: inputs
                    })
                ),
                marketId: 0,
                exchangeId: 0
            });

            vm.prank(liqLiquidator);
            ICoreProxy(sec.core).execute(liqLiquidatorAccountId, commands);
        }

        // Verify post-liquidation state
        // User should have no position
        {
            MarginInfo memory userMargin = ICoreProxy(sec.core).getUsdNodeMarginInfo(liqUserAccountId);
            assertEq(userMargin.liquidationMarginRequirement, 0, "User LMR should be zero after liquidation");

            PerpPosition memory userPos = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqUserAccountId);
            assertEq(userPos.base, 0, "User position should be closed");
        }

        // Liquidator should have absorbed the position
        {
            MarginInfo memory liqMargin = ICoreProxy(sec.core).getUsdNodeMarginInfo(liqLiquidatorAccountId);
            assertGt(liqMargin.liquidationMarginRequirement, 0, "Liquidator should have margin requirement");
        }
    }

    /**
     * @notice Test backstop liquidation in perpOB model
     * @dev In perpOB, backstop liquidation transfers position to a dedicated backstop
     *      liquidator account instead of the passive pool.
     */
    function check_BackstopLiquidation_PerpOB(uint128 marketId, uint128 backstopLiquidatorAccountId) internal {
        setupLiquidationTest(marketId);

        // Drop price severely to trigger backstop eligibility
        // At $2100: unrealized PnL = -$900, total margin ~= -$400 -> deeply underwater
        pushMarkPrice(marketId, 2100e18);
        mockFreshPrices();

        PerpPosition memory backstopPosBefore =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, backstopLiquidatorAccountId);

        // Execute backstop liquidation
        vm.prank(liqLiquidator);
        ICoreProxy(sec.core).executeBackstopLiquidation(
            liqUserAccountId, backstopLiquidatorAccountId, sec.rusd, 1e18
        );

        // Verify user position is closed
        {
            MarginInfo memory userMargin = ICoreProxy(sec.core).getUsdNodeMarginInfo(liqUserAccountId);
            assertEq(userMargin.liquidationMarginRequirement, 0, "User LMR should be zero after backstop");

            PerpPosition memory userPos = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqUserAccountId);
            assertEq(userPos.base, 0, "User position should be closed");
        }

        // Backstop liquidator account should have absorbed the position
        PerpPosition memory backstopPosAfter =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, backstopLiquidatorAccountId);
        assertEq(
            backstopPosAfter.base,
            backstopPosBefore.base + 1e18,
            "Backstop account should have absorbed position"
        );
    }
}
