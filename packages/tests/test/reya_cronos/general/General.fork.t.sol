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
        // Reduce-only but not yet closed: Group A (closes in W2). kBONK (22) is already fully inactive on
        // cronos, so it sits in `inactiveMarkets` instead.
        uint128[] memory reduceOnlyMarkets = new uint128[](23);
        reduceOnlyMarkets[0] = 9; // AAVE
        reduceOnlyMarkets[1] = 10; // CRV
        reduceOnlyMarkets[2] = 14; // SEI
        reduceOnlyMarkets[3] = 17; // WIF
        reduceOnlyMarkets[4] = 19; // POPCAT
        reduceOnlyMarkets[5] = 21; // kSHIB
        reduceOnlyMarkets[6] = 32; // EIGEN
        reduceOnlyMarkets[7] = 39; // PYTH
        reduceOnlyMarkets[8] = 40; // JUP
        reduceOnlyMarkets[9] = 41; // PENGU
        reduceOnlyMarkets[10] = 42; // TRUMP
        reduceOnlyMarkets[11] = 44; // VIRTUAL
        reduceOnlyMarkets[12] = 47; // S (Sonic)
        reduceOnlyMarkets[13] = 48; // FARTCOIN
        reduceOnlyMarkets[14] = 51; // ATOM
        reduceOnlyMarkets[15] = 54; // ONDO
        reduceOnlyMarkets[16] = 55; // TRX
        reduceOnlyMarkets[17] = 56; // INJ
        reduceOnlyMarkets[18] = 60; // TAO
        reduceOnlyMarkets[19] = 63; // PUMP
        reduceOnlyMarkets[20] = 64; // MORPHO
        reduceOnlyMarkets[21] = 65; // SYRUP
        reduceOnlyMarkets[22] = 75; // MEGA

        // Force-closed and deactivated by the W1 batch, plus kBONK which was already inactive.
        uint128[] memory inactiveMarkets = new uint128[](19);
        inactiveMarkets[0] = 22; // kBONK (pre-existing)
        inactiveMarkets[1] = 15; // ZRO
        inactiveMarkets[2] = 25; // JTO
        inactiveMarkets[3] = 45; // AI16Z
        inactiveMarkets[4] = 53; // TON
        inactiveMarkets[5] = 57; // MOVE
        inactiveMarkets[6] = 58; // BERA
        inactiveMarkets[7] = 68; // ZORA
        inactiveMarkets[8] = 69; // PROVE
        inactiveMarkets[9] = 71; // YZY
        inactiveMarkets[10] = 72; // XPL
        inactiveMarkets[11] = 73; // WLFI
        inactiveMarkets[12] = 34; // GOAT
        inactiveMarkets[13] = 36; // KNEIRO
        inactiveMarkets[14] = 46; // AIXBT
        inactiveMarkets[15] = 49; // GRIFFAIN
        inactiveMarkets[16] = 52; // APE
        inactiveMarkets[17] = 61; // IP
        inactiveMarkets[18] = 67; // KAITO
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
