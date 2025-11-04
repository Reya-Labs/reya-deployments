pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { GeneralForkCheck } from "../../reya_common/general/General.fork.c.sol";

import "../../reya_common/DataTypes.sol";
import { IPeripheryProxy, GlobalConfiguration } from "../../../src/interfaces/IPeripheryProxy.sol";
import { IOracleManagerProxy, NodeOutput, NodeDefinition } from "../../../src/interfaces/IOracleManagerProxy.sol";
import { IOracleAdaptersProxy, StorkPricePayload } from "../../../src/interfaces/IOracleAdaptersProxy.sol";
import { IAggregatorV3Interface } from "../../../src/interfaces/IAggregatorV3Interface.sol";
import {
    IPassivePoolProxy,
    RebalanceAmounts,
    AutoRebalanceInput,
    AllocationConfigurationData
} from "../../../src/interfaces/IPassivePoolProxy.sol";
import { IShareTokenProxy } from "../../../src/interfaces/IShareTokenProxy.sol";
import { console2 } from "forge-std/console2.sol";
import {
    CollateralConfig,
    ParentCollateralConfig,
    ICoreProxy,
    GlobalCollateralConfig
} from "../../../src/interfaces/ICoreProxy.sol";
import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

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

        uint128[] memory pausedMarkets = new uint128[](3);
        pausedMarkets[0] = 28;
        pausedMarkets[1] = 37;
        pausedMarkets[2] = 46;

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

    function test_rebalance_rhedge() public {
        // mainnet
        address lmMultisig = 0xf39e89D97B3EEffbF110Dea3110e1DAF74B9C0Ed;

        deal(sec.rusd, address(this), 10e11);
        ITokenProxy(sec.rusd).approve(sec.core, 10e11);
        ICoreProxy(sec.core).deposit({ accountId: 2, collateral: sec.rusd, amount: 10e11 });

        // vm.prank(sec.multisig);
        // IPassivePoolProxy(sec.pool).setAllocationConfiguration(
        //     1, AllocationConfigurationData({ quoteTokenTargetRatio: 0.4e18 })
        // );

        // vm.prank(ownerMultisig);
        // IPassivePoolProxy(pool).setTargetRatioPostQuote(1, rhedge, 0.002e18);

        // vm.prank(sec.multisig);
        // IPassivePoolProxy(sec.pool).setTargetRatioPostQuote(1, sec.sdeusd, 0);

        // vm.prank(sec.multisig);
        // IPassivePoolProxy(sec.pool).setTargetRatioPostQuote(1, sec.rhedge, 0.8e18);

        // vm.prank(sec.multisig);
        // IPassivePoolProxy(sec.pool).setTargetRatioPostQuote(1, sec.rselini, 0.1e18);

        // vm.prank(sec.multisig);
        // IPassivePoolProxy(sec.pool).setTargetRatioPostQuote(1, sec.ramber, 0.1e18);

        // vm.prank(sec.multisig);
        // ICoreProxy(sec.core).setGlobalCollateralConfig(sec.sdeusd, GlobalCollateralConfig({
        //     collateralAdapter: address(0),
        //     withdrawalWindowSize: 86400,
        //     withdrawalTvlPercentageLimit: 1e18
        // }));

        uint256 rhedgeAmount = 39_676_607 * 1e18;
        // {
        //     (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
        //     ICoreProxy(sec.core).getCollateralConfig(1, sec.rhedge);

        //     vm.prank(sec.multisig);
        //     collateralConfig.cap = collateralConfig.cap + rhedgeAmount;
        //     console2.log("cap: ", collateralConfig.cap);
        //     ICoreProxy(sec.core).setCollateralConfig(1, sec.rhedge, collateralConfig, parentCollateralConfig);
        // }

        vm.prank(lmMultisig);
        IShareTokenProxy(sec.rhedge).mint(0x25E028A45a6012763A76145d7CEEa3587015e990, rhedgeAmount);

        vm.prank(0x25E028A45a6012763A76145d7CEEa3587015e990);
        IShareTokenProxy(sec.rhedge).approve(sec.pool, rhedgeAmount);

        vm.prank(0x25E028A45a6012763A76145d7CEEa3587015e990);
        RebalanceAmounts memory amounts = IPassivePoolProxy(sec.pool).triggerAutoRebalance(
            1,
            AutoRebalanceInput({
                tokenIn: sec.rhedge,
                amountIn: rhedgeAmount,
                tokenOut: sec.sdeusd,
                minPrice: 0,
                receiverAddress: 0x25E028A45a6012763A76145d7CEEa3587015e990
            })
        );

        console2.log(amounts.amountIn);
        console2.log(amounts.amountOut);
        console2.log(amounts.priceInToOut);
    }
}
