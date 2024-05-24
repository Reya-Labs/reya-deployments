pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

import { IPeripheryProxy, GlobalConfiguration } from "../../../src/interfaces/IPeripheryProxy.sol";

import { IOracleManagerProxy, NodeOutput, NodeDefinition } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { IOwnerUpgradeModule } from "../../../src/interfaces/IOwnerUpgradeModule.sol";

contract GeneralForkTest is ReyaForkTest {
    function testFuzz_ProxiesOwnerAndUpgrades(address attacker) public {
        vm.assume(attacker != multisig);

        address ownerUpgradeModule = 0x70230eE0CcA326A559410DCEd74F2972306D1e1e;

        address[] memory proxies = new address[](6);
        proxies[0] = core;
        proxies[1] = pool;
        proxies[2] = perp;
        proxies[3] = oracleManager;
        proxies[4] = periphery;
        proxies[5] = exchangePass;

        for (uint256 i = 0; i < proxies.length; i += 1) {
            address proxy = proxies[i];

            assertEq(IOwnerUpgradeModule(proxy).owner(), multisig);

            vm.prank(attacker);
            vm.expectRevert();
            IOwnerUpgradeModule(proxy).upgradeTo(ownerUpgradeModule);

            vm.prank(multisig);
            IOwnerUpgradeModule(proxy).upgradeTo(ownerUpgradeModule);
        }

        assertEq(IOwnerUpgradeModule(accountNft).owner(), core);
    }

    function test_Periphery() public view {
        GlobalConfiguration.Data memory globalConfig = IPeripheryProxy(periphery).getGlobalConfiguration();
        assertEq(globalConfig.coreProxy, core);
        assertEq(globalConfig.rUSDProxy, rusd);
        assertEq(globalConfig.passivePoolProxy, pool);

        assertEq(IPeripheryProxy(periphery).getTokenController(usdc), socketController[usdc]);
        assertEq(IPeripheryProxy(periphery).getTokenExecutionHelper(usdc), socketExecutionHelper[usdc]);
        assertEq(
            IPeripheryProxy(periphery).getTokenChainConnector(usdc, ethereumChainId),
            socketConnector[usdc][ethereumChainId]
        );
        assertEq(
            IPeripheryProxy(periphery).getTokenChainConnector(usdc, arbitrumChainId),
            socketConnector[usdc][arbitrumChainId]
        );
        assertEq(
            IPeripheryProxy(periphery).getTokenChainConnector(usdc, optimismChainId),
            socketConnector[usdc][optimismChainId]
        );
        assertEq(
            IPeripheryProxy(periphery).getTokenChainConnector(usdc, polygonChainId),
            socketConnector[usdc][polygonChainId]
        );
        assertEq(
            IPeripheryProxy(periphery).getTokenChainConnector(usdc, baseChainId), socketConnector[usdc][baseChainId]
        );
    }

    function test_OracleManager() public view {
        NodeOutput.Data memory ethUsdNodeOutput = IOracleManagerProxy(oracleManager).process(ethUsdNodeId);
        NodeOutput.Data memory btcUsdNodeOutput = IOracleManagerProxy(oracleManager).process(btcUsdNodeId);
        NodeOutput.Data memory ethUsdcNodeOutput = IOracleManagerProxy(oracleManager).process(ethUsdcNodeId);
        NodeOutput.Data memory btcUsdcNodeOutput = IOracleManagerProxy(oracleManager).process(btcUsdcNodeId);
        NodeOutput.Data memory rusdUsdNodeOutput = IOracleManagerProxy(oracleManager).process(rusdUsdNodeId);
        NodeOutput.Data memory usdcUsdNodeOutput = IOracleManagerProxy(oracleManager).process(usdcUsdNodeId);

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

        NodeDefinition.Data memory ethUsdNodeDefinition = IOracleManagerProxy(oracleManager).getNode(ethUsdNodeId);
        NodeDefinition.Data memory btcUsdNodeDefinition = IOracleManagerProxy(oracleManager).getNode(btcUsdNodeId);
        NodeDefinition.Data memory ethUsdcNodeDefinition = IOracleManagerProxy(oracleManager).getNode(ethUsdcNodeId);
        NodeDefinition.Data memory btcUsdcNodeDefinition = IOracleManagerProxy(oracleManager).getNode(btcUsdcNodeId);
        NodeDefinition.Data memory rusdUsdNodeDefinition = IOracleManagerProxy(oracleManager).getNode(rusdUsdNodeId);
        NodeDefinition.Data memory usdcUsdNodeDefinition = IOracleManagerProxy(oracleManager).getNode(usdcUsdNodeId);

        assertEq(ethUsdNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(btcUsdNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(ethUsdcNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(btcUsdcNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(rusdUsdNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(usdcUsdNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
    }
}
