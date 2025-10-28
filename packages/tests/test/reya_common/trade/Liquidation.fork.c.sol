pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";
import {
    ICoreProxy,
    CollateralInfo,
    MarginInfo,
    Command as Command_Core,
    CommandType,
    DutchLiquidationInput
} from "../../../src/interfaces/ICoreProxy.sol";
import {
    IPassivePerpProxy,
    GlobalFeeParameters,
    CacheStatus,
    PerpPosition
} from "../../../src/interfaces/IPassivePerpProxy.sol";
import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd, SD59x18, UNIT as ONE_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract LiquidationForkCheck is BaseReyaForkTest {
    address user;
    address liquidator;
    uint128 accountId;
    uint128 liquidatorAccountId;

    function setUp() public {
        removeMarketsOILimit();
        mockFreshPrices();

        (user,) = makeAddrAndKey("user");
        accountId = depositNewMA(user, sec.usdc, 1000e6);

        (liquidator,) = makeAddrAndKey("liquidator");
        liquidatorAccountId = depositNewMA(liquidator, sec.usdc, 1000e6);

        // pin risk matrix for market ID 3 (SOL)
        {
            int64[][] memory values = new int64[][](1);
            values[0] = new int64[](1);
            values[0][0] = 947_000_000_000_000; // 25x leverage (given IMR multiplier 1.3)

            vm.prank(sec.multisig);
            uint128 blockId = ICoreProxy(sec.core).createRiskMatrix(1, values);

            vm.prank(sec.multisig);
            IPassivePerpProxy(sec.perp).setRiskBlockId(3, blockId, 0);
        }

        // pin risk matrix for market ID 4 (ARB)
        {
            int64[][] memory values = new int64[][](1);
            values[0] = new int64[](1);
            values[0][0] = 1_479_000_000_000_000; // 20x leverage (given IMR multiplier 1.3)

            vm.prank(sec.multisig);
            uint128 blockId = ICoreProxy(sec.core).createRiskMatrix(1, values);

            vm.prank(sec.multisig);
            IPassivePerpProxy(sec.perp).setRiskBlockId(4, blockId, 0);
        }

        // pin price for market ID 3 (SOL) to 200
        mockFreshPrice(sec.solUsdcStorkMarkNodeId, 200e18);

        // pin price for market ID 4 (ARB) to 0.3
        mockFreshPrice(sec.arbUsdcStorkMarkNodeId, 0.3e18);

        executeCoreMatchOrder({
            marketId: 3,
            sender: user,
            base: sd(30e18),
            priceLimit: ud(type(uint256).max),
            accountId: accountId
        });

        executeCoreMatchOrder({
            marketId: 4,
            sender: user,
            base: sd(40_000e18),
            priceLimit: ud(type(uint256).max),
            accountId: accountId
        });

        // LMR post-trade = 30 * 200 * sqrt(0.000947) + 40000 * 0.3 * sqrt(0.001479) ~= 646
    }

    function check_DutchLiquidation() internal {
        // move down price for market ID 3 (SOL) to 195
        mockFreshPrice(sec.solUsdcStorkMarkNodeId, 195e18);

        // move down price for market ID 4 (ARB) to 0.29
        mockFreshPrice(sec.arbUsdcStorkMarkNodeId, 0.29e18);

        // after the prices decreased:
        // LMR post-trade = 30 * 195 * sqrt(0.000947) + 40000 * 0.29 * sqrt(0.001479) ~= 626
        // account should have lost cca. 550 rUSD

        // execute Dutch liquidation
        {
            uint128[] memory marketIds = new uint128[](2);
            marketIds[0] = 3;
            marketIds[1] = 4;

            bytes[] memory inputs = new bytes[](2);
            inputs[0] = abi.encode(sd(-30e18), ud(0));
            inputs[1] = abi.encode(sd(-40_000e18), ud(0));

            Command_Core[] memory commands = new Command_Core[](1);
            commands[0] = Command_Core({
                commandType: uint8(CommandType.DutchLiquidation),
                inputs: abi.encode(
                    DutchLiquidationInput({
                        liquidatableAccountId: accountId,
                        quoteCollateral: sec.rusd,
                        marketIds: marketIds,
                        inputs: inputs
                    })
                ),
                marketId: 0,
                exchangeId: 0
            });

            vm.prank(liquidator);
            ICoreProxy(sec.core).execute(liquidatorAccountId, commands);
        }

        // check information post-liquidation
        // account
        {
            MarginInfo memory marginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
            assertEq(marginInfo.liquidationMarginRequirement, 0);

            PerpPosition memory position3 = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(3, accountId);
            assertEq(position3.base, 0);

            PerpPosition memory position4 = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(4, accountId);
            assertEq(position4.base, 0);
        }

        // liquidator
        {
            MarginInfo memory marginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(liquidatorAccountId);
            assertGt(marginInfo.liquidationMarginRequirement, 0);

            PerpPosition memory position3 = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(3, liquidatorAccountId);
            assertEq(position3.base, 30e18);

            PerpPosition memory position4 = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(4, liquidatorAccountId);
            assertEq(position4.base, 40_000e18);
        }
    }

    function check_BackstopLiquidation() internal {
        // move down price for market ID 3 (SOL) to 190
        mockFreshPrice(sec.solUsdcStorkMarkNodeId, 190e18);

        // move down price for market ID 4 (ARB) to 0.29
        mockFreshPrice(sec.arbUsdcStorkMarkNodeId, 0.29e18);

        // after the prices decreased:
        // LMR post-trade = 30 * 190 * sqrt(0.000947) + 40000 * 0.29 * sqrt(0.001479) ~= 621
        // account should have lost cca. 700 rUSD

        PerpPosition memory poolPosition3PreBackstop =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(3, sec.passivePoolAccountId);
        PerpPosition memory poolPosition4PreBackstop =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(4, sec.passivePoolAccountId);

        // execute Backstop liquidation
        vm.prank(liquidator);
        ICoreProxy(sec.core).executeBackstopLiquidation(accountId, liquidatorAccountId, sec.rusd, 1e18);

        // check information post-liquidation
        // account
        {
            MarginInfo memory marginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
            assertEq(marginInfo.liquidationMarginRequirement, 0);

            PerpPosition memory position3 = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(3, accountId);
            assertEq(position3.base, 0);

            PerpPosition memory position4 = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(4, accountId);
            assertEq(position4.base, 0);
        }

        // passive pool
        PerpPosition memory poolPosition3PostBackstop =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(3, sec.passivePoolAccountId);
        PerpPosition memory poolPosition4PostBackstop =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(4, sec.passivePoolAccountId);

        assertEq(poolPosition3PostBackstop.base, poolPosition3PreBackstop.base + 30e18);
        assertEq(poolPosition4PostBackstop.base, poolPosition4PreBackstop.base + 40_000e18);
    }
}
