pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { GeneralForkCheck } from "../../reya_common/general/General.fork.c.sol";

import "../../reya_common/DataTypes.sol";
import { IPeripheryProxy, GlobalConfiguration } from "../../../src/interfaces/IPeripheryProxy.sol";
import { IOracleManagerProxy, NodeOutput, NodeDefinition } from "../../../src/interfaces/IOracleManagerProxy.sol";

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

    function test_OracleManager() public view {
        NodeOutput.Data memory ethUsdNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdNodeId);
        NodeOutput.Data memory btcUsdNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.btcUsdNodeId);
        NodeOutput.Data memory ethUsdcNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdcNodeId);
        NodeOutput.Data memory btcUsdcNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.btcUsdcNodeId);
        NodeOutput.Data memory rusdUsdNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.rusdUsdNodeId);
        NodeOutput.Data memory usdcUsdNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.usdcUsdNodeId);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, ethUsdNodeOutput.timestamp);
        assertLe(ethUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(ethUsdNodeOutput.price, 3500e18, 1000e18, 18);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, btcUsdNodeOutput.timestamp);
        assertLe(btcUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(btcUsdNodeOutput.price, 65_000e18, 10_000e18, 18);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, ethUsdcNodeOutput.timestamp);
        assertLe(ethUsdcNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(ethUsdcNodeOutput.price, 3500e18, 1000e18, 18);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, btcUsdcNodeOutput.timestamp);
        assertLe(btcUsdcNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(btcUsdcNodeOutput.price, 65_000e18, 10_000e18, 18);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, rusdUsdNodeOutput.timestamp);
        assertLe(rusdUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(rusdUsdNodeOutput.price, 1e18, 0, 18);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, usdcUsdNodeOutput.timestamp);
        assertLe(usdcUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(usdcUsdNodeOutput.price, 1e18, 0.01e18, 18);

        NodeDefinition.Data memory ethUsdNodeDefinition =
            IOracleManagerProxy(sec.oracleManager).getNode(sec.ethUsdNodeId);
        NodeDefinition.Data memory btcUsdNodeDefinition =
            IOracleManagerProxy(sec.oracleManager).getNode(sec.btcUsdNodeId);
        NodeDefinition.Data memory ethUsdcNodeDefinition =
            IOracleManagerProxy(sec.oracleManager).getNode(sec.ethUsdcNodeId);
        NodeDefinition.Data memory btcUsdcNodeDefinition =
            IOracleManagerProxy(sec.oracleManager).getNode(sec.btcUsdcNodeId);
        NodeDefinition.Data memory rusdUsdNodeDefinition =
            IOracleManagerProxy(sec.oracleManager).getNode(sec.rusdUsdNodeId);
        NodeDefinition.Data memory usdcUsdNodeDefinition =
            IOracleManagerProxy(sec.oracleManager).getNode(sec.usdcUsdNodeId);

        assertEq(ethUsdNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(btcUsdNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(ethUsdcNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(btcUsdcNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(rusdUsdNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(usdcUsdNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
    }
}
