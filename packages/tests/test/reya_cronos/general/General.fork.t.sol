pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { GeneralForkCheck } from "../../reya_common/general/General.fork.c.sol";

import "../../reya_common/DataTypes.sol";
import { IPeripheryProxy, GlobalConfiguration } from "../../../src/interfaces/IPeripheryProxy.sol";
import { IOracleManagerProxy, NodeOutput, NodeDefinition } from "../../../src/interfaces/IOracleManagerProxy.sol";

contract GeneralForkTest is ReyaForkTest, GeneralForkCheck {
    function testFuzz_Cronos_ProxiesOwnerAndUpgrades(address attacker) public {
        vm.assume(attacker != sec.multisig);
        checkFuzz_ProxiesOwnerAndUpgrades(attacker);
    }

    function test_Cronos_Periphery() public view {
        GlobalConfiguration.Data memory globalConfig = IPeripheryProxy(sec.periphery).getGlobalConfiguration();
        assertEq(globalConfig.coreProxy, sec.core);
        assertEq(globalConfig.rUSDProxy, sec.rusd);
        assertEq(globalConfig.passivePoolProxy, sec.pool);

        assertEq(IPeripheryProxy(sec.periphery).getTokenController(sec.usdc), dec.socketController[sec.usdc]);
        assertEq(IPeripheryProxy(sec.periphery).getTokenExecutionHelper(sec.usdc), dec.socketExecutionHelper[sec.usdc]);
        assertEq(
            IPeripheryProxy(sec.periphery).getTokenChainConnector(sec.usdc, ethereumSepoliaChainId),
            dec.socketConnector[sec.usdc][ethereumSepoliaChainId]
        );
        assertEq(
            IPeripheryProxy(sec.periphery).getTokenChainConnector(sec.usdc, arbitrumSepoliaChainId),
            dec.socketConnector[sec.usdc][arbitrumSepoliaChainId]
        );
        assertEq(
            IPeripheryProxy(sec.periphery).getTokenChainConnector(sec.usdc, optimismSepoliaChainId),
            dec.socketConnector[sec.usdc][optimismSepoliaChainId]
        );
    }

    function test_Cronos_OracleManager() public {
        check_OracleNodePriceValues();
    }

    function test_Cronos_MarketsPrices() public {
        check_marketsPrices();
    }

    function test_MarketsOrderMaxStaleDuration() public view {
        check_marketsOrderMaxStaleDuration(11);
    }

    function test_MarketsMaxOiAndOi() public view {
        uint128[] memory reduceOnlyMarkets = new uint128[](41);
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
        // markets decided to be closed on 7 Jul 2026
        reduceOnlyMarkets[11] = 34; // GOAT
        reduceOnlyMarkets[12] = 36; // KNEIRO
        reduceOnlyMarkets[13] = 46; // AIXBT
        reduceOnlyMarkets[14] = 49; // GRIFFAIN
        reduceOnlyMarkets[15] = 52; // APE
        reduceOnlyMarkets[16] = 61; // IP
        // Group A of the compressed 5-week plan — set to reduce-only in W1 (10-14 Aug 2026), force-closed in W2.
        // The first nine were briefly reduce-only from 17 Jul and reverted on 7 Aug (#502) when the waves were
        // re-cut; that revert dropped them from the omnibus but left them in this list, so this test was red on
        // main. They are back in reduce-only here, as part of Group A.
        reduceOnlyMarkets[17] = 19; // POPCAT
        reduceOnlyMarkets[18] = 21; // kSHIB
        reduceOnlyMarkets[19] = 47; // S (Sonic)
        reduceOnlyMarkets[20] = 48; // FARTCOIN
        reduceOnlyMarkets[21] = 51; // ATOM
        reduceOnlyMarkets[22] = 63; // PUMP
        reduceOnlyMarkets[23] = 64; // MORPHO
        reduceOnlyMarkets[24] = 65; // SYRUP
        reduceOnlyMarkets[25] = 75; // MEGA
        reduceOnlyMarkets[26] = 9; // AAVE
        reduceOnlyMarkets[27] = 10; // CRV
        reduceOnlyMarkets[28] = 14; // SEI
        reduceOnlyMarkets[29] = 17; // WIF
        reduceOnlyMarkets[30] = 32; // EIGEN
        reduceOnlyMarkets[31] = 39; // PYTH
        reduceOnlyMarkets[32] = 40; // JUP
        reduceOnlyMarkets[33] = 41; // PENGU
        reduceOnlyMarkets[34] = 42; // TRUMP
        reduceOnlyMarkets[35] = 44; // VIRTUAL
        reduceOnlyMarkets[36] = 54; // ONDO
        reduceOnlyMarkets[37] = 55; // TRX
        reduceOnlyMarkets[38] = 56; // INJ
        reduceOnlyMarkets[39] = 60; // TAO
        reduceOnlyMarkets[40] = 67; // KAITO
        // kBONK (22) is Group A too, but it is already fully inactive on cronos — it stays in `inactiveMarkets`.
        uint128[] memory inactiveMarkets = new uint128[](1);
        inactiveMarkets[0] = 22; // kBONK
        check_marketsMaxOiAndOi(reduceOnlyMarkets, inactiveMarkets);
    }

    function test_CheckSDEUSDPrice() public view {
        check_sdeusd_price();
    }

    function test_CheckSDEUSDPrice_AgainstMainnet() public {
        check_sdeusd_deusd_price();
    }

    function test_Cronos_PeripherySrusdBalance() public view {
        check_periphery_srusd_balance();
    }
}
