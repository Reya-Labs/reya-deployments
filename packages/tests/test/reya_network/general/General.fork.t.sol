pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { GeneralForkCheck } from "../../reya_common/general/General.fork.c.sol";

import "../../reya_common/DataTypes.sol";
import { IPeripheryProxy, GlobalConfiguration } from "../../../src/interfaces/IPeripheryProxy.sol";
import { IOracleManagerProxy, NodeOutput, NodeDefinition } from "../../../src/interfaces/IOracleManagerProxy.sol";
import { IOracleAdaptersProxy, StorkPricePayload } from "../../../src/interfaces/IOracleAdaptersProxy.sol";
import { IAggregatorV3Interface } from "../../../src/interfaces/IAggregatorV3Interface.sol";

contract GeneralForkTest is ReyaForkTest, GeneralForkCheck {
    function testFuzz_ProxiesOwnerAndUpgrades(address attacker) public {
        vm.assume(attacker != sec.multisig);
        checkFuzz_ProxiesOwnerAndUpgrades(attacker);
    }

    function test_Periphery() public view {
        GlobalConfiguration.Data memory globalConfig = IPeripheryProxy(sec.periphery).getGlobalConfiguration();
        assertEq(globalConfig.coreProxy, sec.core);
        assertEq(globalConfig.rUSDProxy, sec.rusd);
        assertEq(globalConfig.passivePoolProxy, sec.pool);
        assertEq(globalConfig.sREYAProxy, sec.sreya);
        assertEq(globalConfig.REYAProxy, sec.reya);
        assertEq(globalConfig.layerZeroEndpoint, sec.layerZeroEndpoint);

        assertEq(IPeripheryProxy(sec.periphery).getTokenController(sec.usdc), dec.socketController[sec.usdc]);
        assertEq(IPeripheryProxy(sec.periphery).getTokenExecutionHelper(sec.usdc), dec.socketExecutionHelper[sec.usdc]);
        assertEq(
            IPeripheryProxy(sec.periphery).getTokenChainConnector(sec.usdc, ethereumChainId),
            dec.socketConnector[sec.usdc][ethereumChainId]
        );
        assertEq(
            IPeripheryProxy(sec.periphery).getTokenChainConnector(sec.usdc, arbitrumChainId),
            dec.socketConnector[sec.usdc][arbitrumChainId]
        );
        assertEq(
            IPeripheryProxy(sec.periphery).getTokenChainConnector(sec.usdc, optimismChainId),
            dec.socketConnector[sec.usdc][optimismChainId]
        );
        assertEq(
            IPeripheryProxy(sec.periphery).getTokenChainConnector(sec.usdc, polygonChainId),
            dec.socketConnector[sec.usdc][polygonChainId]
        );
        assertEq(
            IPeripheryProxy(sec.periphery).getTokenChainConnector(sec.usdc, baseChainId),
            dec.socketConnector[sec.usdc][baseChainId]
        );
    }

    function test_OracleManager() public {
        check_OracleNodePriceValues();
    }

    // function test_OracleNodePriceStaleness() public {
    //     check_OracleNodePriceStaleness();
    // }

    function test_MarketsPrices() public {
        check_marketsPrices();
    }

    function test_MarketsOrderMaxStaleDuration() public view {
        check_marketsOrderMaxStaleDuration(11);
    }

    function test_MarketsMaxOiAndOi() public view {
        uint128[] memory reduceOnlyMarkets = new uint128[](43);
        reduceOnlyMarkets[0] = 45; // AI16Z
        reduceOnlyMarkets[1] = 58; // BERA
        reduceOnlyMarkets[2] = 25; // JTO
        reduceOnlyMarkets[3] = 57; // MOVE
        reduceOnlyMarkets[4] = 69; // PROVE
        reduceOnlyMarkets[5] = 73; // WLFI
        reduceOnlyMarkets[6] = 72; // XPL
        reduceOnlyMarkets[7] = 71; // YZY
        reduceOnlyMarkets[8] = 68; // ZORA
        reduceOnlyMarkets[9] = 15; // ZRO
        reduceOnlyMarkets[10] = 53; // TON
        reduceOnlyMarkets[11] = 7; // MKR (network-only: reduce-only on reya_network, active on cronos)
        // markets decided to be closed on 7 Jul 2026
        reduceOnlyMarkets[12] = 34; // GOAT
        reduceOnlyMarkets[13] = 36; // KNEIRO
        reduceOnlyMarkets[14] = 46; // AIXBT
        reduceOnlyMarkets[15] = 49; // GRIFFAIN
        reduceOnlyMarkets[16] = 52; // APE
        reduceOnlyMarkets[17] = 61; // IP
        // Group A — reduce-only since #507.
        reduceOnlyMarkets[18] = 9; // AAVE
        reduceOnlyMarkets[19] = 10; // CRV
        reduceOnlyMarkets[20] = 14; // SEI
        reduceOnlyMarkets[21] = 17; // WIF
        reduceOnlyMarkets[22] = 19; // POPCAT
        reduceOnlyMarkets[23] = 21; // kSHIB
        reduceOnlyMarkets[24] = 22; // kBONK
        reduceOnlyMarkets[25] = 32; // EIGEN
        reduceOnlyMarkets[26] = 39; // PYTH
        reduceOnlyMarkets[27] = 40; // JUP
        reduceOnlyMarkets[28] = 41; // PENGU
        reduceOnlyMarkets[29] = 42; // TRUMP
        reduceOnlyMarkets[30] = 44; // VIRTUAL
        reduceOnlyMarkets[31] = 47; // S (Sonic)
        reduceOnlyMarkets[32] = 48; // FARTCOIN
        reduceOnlyMarkets[33] = 51; // ATOM
        reduceOnlyMarkets[34] = 54; // ONDO
        reduceOnlyMarkets[35] = 55; // TRX
        reduceOnlyMarkets[36] = 56; // INJ
        reduceOnlyMarkets[37] = 60; // TAO
        reduceOnlyMarkets[38] = 63; // PUMP
        reduceOnlyMarkets[39] = 64; // MORPHO
        reduceOnlyMarkets[40] = 65; // SYRUP
        reduceOnlyMarkets[41] = 67; // KAITO
        reduceOnlyMarkets[42] = 75; // MEGA
        // todo: add markets here after they are fully closed
        uint128[] memory inactiveMarkets = new uint128[](0);
        check_marketsMaxOiAndOi(reduceOnlyMarkets, inactiveMarkets);
    }

    function test_CheckSDEUSDPrice() public view {
        check_sdeusd_price();
    }

    function test_CheckSDEUSDPrice_AgainstMainnet() public {
        check_sdeusd_deusd_price();
    }

    function test_PeripherySrusdBalance() public view {
        check_periphery_srusd_balance();
    }

    function test_srUSD_feeds() public view {
        check_srUSD_feeds();
    }

    function test_ActiveMarkets() public view {
        uint128[] memory activeMarkets = getActiveMarkets();
        uint128 lastMarketIdd = lastMarketId();

        // 28 (POL) and 37 (DOT) are disabled independently of this batch, so they are always asserted.
        //
        // The 17 W1-closed markets (15 ZRO, 25 JTO, 34 GOAT, 36 kNEIRO, 45 AI16Z, 49 GRIFFAIN, 52 APE, 53 TON,
        // 57 MOVE, 58 BERA, 61 IP, 67 KAITO, 68 ZORA, 69 PROVE, 71 YZY, 72 XPL, 73 WLFI) end the constructor
        // disabled: `ReyaForkTest` replays the on-mainnet force-close batch, whose second sub-CALL per market
        // is `setFeatureFlagDenyAll(marketEnabled, true)`. `test_W1MarketsAreClosed` owns the frozen/disabled
        // end state; here we just account for them so the sequential active-list walk lines up.
        //
        // AIXBT (46) is left untouched by the two replayed batches — the on-mainnet enable/freeze/disable
        // dance isn't reproduced here — so it keeps whatever state the fork is pinned at. Asserting either
        // direction breaks in the other environment; probe it live.
        bool aixbtPaused = !isMarketActive(46);

        // Sorted ascending — the loop below advances a sequential pointer through `pausedMarkets`.
        uint128[] memory pausedMarkets = new uint128[](aixbtPaused ? 20 : 19);
        uint256 n = 0;
        pausedMarkets[n++] = 15; // ZRO
        pausedMarkets[n++] = 25; // JTO
        pausedMarkets[n++] = 28; // POL
        pausedMarkets[n++] = 34; // GOAT
        pausedMarkets[n++] = 36; // kNEIRO
        pausedMarkets[n++] = 37; // DOT
        pausedMarkets[n++] = 45; // AI16Z
        if (aixbtPaused) {
            pausedMarkets[n++] = 46; // AIXBT
        }
        pausedMarkets[n++] = 49; // GRIFFAIN
        pausedMarkets[n++] = 52; // APE
        pausedMarkets[n++] = 53; // TON
        pausedMarkets[n++] = 57; // MOVE
        pausedMarkets[n++] = 58; // BERA
        pausedMarkets[n++] = 61; // IP
        pausedMarkets[n++] = 67; // KAITO
        pausedMarkets[n++] = 68; // ZORA
        pausedMarkets[n++] = 69; // PROVE
        pausedMarkets[n++] = 71; // YZY
        pausedMarkets[n++] = 72; // XPL
        pausedMarkets[n++] = 73; // WLFI

        assertEq(activeMarkets.length, lastMarketIdd - pausedMarkets.length);

        uint128 a = 0;
        uint128 b = 0;

        for (uint256 i = 1; i <= lastMarketIdd; i++) {
            if (b < pausedMarkets.length && pausedMarkets[b] == i) {
                b++;
                continue;
            }

            assertEq(activeMarkets[a], i);
            a++;
        }
    }
}
