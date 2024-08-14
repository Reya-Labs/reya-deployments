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
        check_OracleNodePrices(true);
    }

    // function mockStaleStork() private {
    //     vm.mockCall(
    //         sec.oracleAdaptersProxy,
    //         abi.encodeCall(IOracleAdaptersProxy.getLatestPricePayload, ("SOLUSD")),
    //         abi.encode(
    //             StorkPricePayload({
    //                 assetPairId: "SOLUSD",
    //                 timestamp: block.timestamp - ONE_MINUTE_IN_SECONDS - 1,
    //                 price: 1000e18
    //             })
    //         )
    //     );

    //     vm.mockCall(
    //         sec.oracleAdaptersProxy,
    //         abi.encodeCall(IOracleAdaptersProxy.getLatestPricePayload, ("USDCUSD")),
    //         abi.encode(StorkPricePayload({ assetPairId: "USDCUSD", timestamp: block.timestamp, price: 1e18 }))
    //     );
    // }

    // function mockStaleRedstone() private {
    //     NodeDefinition.Data memory solUsdNodeDefinition =
    //         IOracleManagerProxy(sec.oracleManager).getNode(sec.solUsdNodeId);
    //     (address solUsdRedstone,) = abi.decode(solUsdNodeDefinition.parameters, (address, uint256));

    // vm.mockCall(
    //     solUsdRedstone,
    //     abi.encodeCall(IAggregatorV3Interface.latestRoundData, ()),
    //     abi.encode(0, 1000e8, 0, block.timestamp - 90 - 1, 0)
    // );

    //     NodeDefinition.Data memory usdcUsdNodeDefinition =
    //         IOracleManagerProxy(sec.oracleManager).getNode(sec.usdcUsdNodeId);
    //     (address usdcUsdRedstone,) = abi.decode(usdcUsdNodeDefinition.parameters, (address, uint256));

    //     vm.mockCall(
    //         usdcUsdRedstone,
    //         abi.encodeCall(IAggregatorV3Interface.latestRoundData, ()),
    //         abi.encode(0, 1e8, 0, block.timestamp, 0)
    //     );
    // }

    // function test_FallbackOracleNode_StaleStork() public {
    //     mockStaleStork();

    //     NodeOutput.Data memory nodeOutput =
    //         IOracleManagerProxy(sec.oracleManager).process(sec.solUsdcStorkFallbackNodeId);

    //     NodeOutput.Data memory nodeOutputRedstone =
    // IOracleManagerProxy(sec.oracleManager).process(sec.solUsdcNodeId);

    //     assertEq(nodeOutput.price, nodeOutputRedstone.price);
    //     assertEq(nodeOutput.timestamp, nodeOutputRedstone.timestamp);
    // }

    // function test_FallbackOracleNode_StaleStorkAndRedstone() public {
    //     mockStaleStork();
    //     mockStaleRedstone();

    //     vm.expectRevert(abi.encodeWithSelector(IOracleManagerProxy.StalePriceDetected.selector, sec.solUsdcNodeId));
    //     IOracleManagerProxy(sec.oracleManager).process(sec.solUsdcStorkFallbackNodeId);
    // }
}
