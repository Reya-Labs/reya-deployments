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

    function test_Cronos_OracleManager() public view {
        NodeOutput.Data memory ethUsdNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdNodeId);
        NodeOutput.Data memory btcUsdNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.btcUsdNodeId);
        NodeOutput.Data memory solUsdNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.solUsdNodeId);
        NodeOutput.Data memory ethUsdcNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdcNodeId);
        NodeOutput.Data memory btcUsdcNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.btcUsdcNodeId);
        NodeOutput.Data memory solUsdcNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.solUsdcNodeId);
        NodeOutput.Data memory rusdUsdNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.rusdUsdNodeId);
        NodeOutput.Data memory usdcUsdNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.usdcUsdNodeId);

        assertLe(ethUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(ethUsdNodeOutput.price, 3500e18, 2000e18, 18);

        assertLe(btcUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(btcUsdNodeOutput.price, 65_000e18, 20_000e18, 18);

        assertLe(solUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(solUsdNodeOutput.price, 150e18, 100e18, 18);

        assertLe(ethUsdcNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(ethUsdcNodeOutput.price, 3500e18, 2000e18, 18);

        assertLe(btcUsdcNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(btcUsdcNodeOutput.price, 65_000e18, 20_000e18, 18);

        assertLe(solUsdcNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(solUsdcNodeOutput.price, 150e18, 100e18, 18);

        assertLe(rusdUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(rusdUsdNodeOutput.price, 1e18, 0, 18);

        assertLe(usdcUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(usdcUsdNodeOutput.price, 1e18, 0.01e18, 18);

        // todo: move these oracle node IDs to ecosystem config
        bytes32 solUsdcStorkFallbackNodeId = bytes32(0xbc20afac3a933b7c7f814fc8fe08344d5dabe3d154b0584461b677b8568553c8);
        NodeOutput.Data memory solUsdcStorkFallbackNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(solUsdcStorkFallbackNodeId);
        assertApproxEqAbsDecimal(solUsdcStorkFallbackNodeOutput.price, 150e18, 100e18, 18);

        bytes32 solUsdcStorkNodeId = bytes32(0xa456e0f61bd6068a3a73176ab1c58b840e57e0a272ca29974d3f0bd709fc96c4);
        NodeOutput.Data memory solUsdcStorkNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(solUsdcStorkNodeId);
        assertApproxEqAbsDecimal(solUsdcStorkNodeOutput.price, 150e18, 100e18, 18);

        bytes32 usdcUsdStorkNodeId = bytes32(0x28c79729ca502a5cd2565613c087a3bda098a1c78e3f3f45733d03c3482f099d);
        NodeOutput.Data memory usdcUsdStorkNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(usdcUsdStorkNodeId);
        assertApproxEqAbsDecimal(usdcUsdStorkNodeOutput.price, 1e18, 0.01e18, 18);
    }
}
