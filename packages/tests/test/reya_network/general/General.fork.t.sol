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
        // Reduce-only but not yet closed: MKR, plus Group A (closes in W2).
        uint128[] memory reduceOnlyMarkets = new uint128[](25);
        reduceOnlyMarkets[0] = 7; // MKR (network-only: reduce-only on reya_network, active on cronos)
        reduceOnlyMarkets[1] = 9; // AAVE
        reduceOnlyMarkets[2] = 10; // CRV
        reduceOnlyMarkets[3] = 14; // SEI
        reduceOnlyMarkets[4] = 17; // WIF
        reduceOnlyMarkets[5] = 19; // POPCAT
        reduceOnlyMarkets[6] = 21; // kSHIB
        reduceOnlyMarkets[7] = 22; // kBONK
        reduceOnlyMarkets[8] = 32; // EIGEN
        reduceOnlyMarkets[9] = 39; // PYTH
        reduceOnlyMarkets[10] = 40; // JUP
        reduceOnlyMarkets[11] = 41; // PENGU
        reduceOnlyMarkets[12] = 42; // TRUMP
        reduceOnlyMarkets[13] = 44; // VIRTUAL
        reduceOnlyMarkets[14] = 47; // S (Sonic)
        reduceOnlyMarkets[15] = 48; // FARTCOIN
        reduceOnlyMarkets[16] = 51; // ATOM
        reduceOnlyMarkets[17] = 54; // ONDO
        reduceOnlyMarkets[18] = 55; // TRX
        reduceOnlyMarkets[19] = 56; // INJ
        reduceOnlyMarkets[20] = 60; // TAO
        reduceOnlyMarkets[21] = 63; // PUMP
        reduceOnlyMarkets[22] = 64; // MORPHO
        reduceOnlyMarkets[23] = 65; // SYRUP
        reduceOnlyMarkets[24] = 75; // MEGA

        // Force-closed and deactivated by the W1 batch — open interest must be zero.
        uint128[] memory inactiveMarkets = new uint128[](18);
        // Group 0 - reduce-only since June
        inactiveMarkets[0] = 15; // ZRO
        inactiveMarkets[1] = 25; // JTO
        inactiveMarkets[2] = 45; // AI16Z
        inactiveMarkets[3] = 53; // TON
        inactiveMarkets[4] = 57; // MOVE
        inactiveMarkets[5] = 58; // BERA
        inactiveMarkets[6] = 68; // ZORA
        inactiveMarkets[7] = 69; // PROVE
        inactiveMarkets[8] = 71; // YZY
        inactiveMarkets[9] = 72; // XPL
        inactiveMarkets[10] = 73; // WLFI
        inactiveMarkets[11] = 34; // GOAT
        inactiveMarkets[12] = 36; // KNEIRO
        inactiveMarkets[13] = 46; // AIXBT
        inactiveMarkets[14] = 49; // GRIFFAIN
        inactiveMarkets[15] = 52; // APE
        inactiveMarkets[16] = 61; // IP
        inactiveMarkets[17] = 67; // KAITO
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

        // 28 (POL) and 37 (DOT) were already disabled; the 17 force-closed markets are disabled by this
        // batch, right after each close. AIXBT (46) is disabled by the FREEZE batch, not this one: at
        // open interest 0 in reduce-only there is nothing to unwind, so freezing its price and disabling
        // it there is the whole of its closure and this batch does not touch it. Must stay sorted
        // ascending.
        uint128[] memory pausedMarkets = new uint128[](20);
        pausedMarkets[0] = 15; // ZRO
        pausedMarkets[1] = 25; // JTO
        pausedMarkets[2] = 28; // POL (pre-existing)
        pausedMarkets[3] = 34; // GOAT
        pausedMarkets[4] = 36; // KNEIRO
        pausedMarkets[5] = 37; // DOT (pre-existing)
        pausedMarkets[6] = 45; // AI16Z
        pausedMarkets[7] = 46; // AIXBT
        pausedMarkets[8] = 49; // GRIFFAIN
        pausedMarkets[9] = 52; // APE
        pausedMarkets[10] = 53; // TON
        pausedMarkets[11] = 57; // MOVE
        pausedMarkets[12] = 58; // BERA
        pausedMarkets[13] = 61; // IP
        pausedMarkets[14] = 67; // KAITO
        pausedMarkets[15] = 68; // ZORA
        pausedMarkets[16] = 69; // PROVE
        pausedMarkets[17] = 71; // YZY
        pausedMarkets[18] = 72; // XPL
        pausedMarkets[19] = 73; // WLFI

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
