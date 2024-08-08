pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { IOwnerUpgradeModule } from "../../../src/interfaces/IOwnerUpgradeModule.sol";
import { IOracleManagerProxy, NodeOutput, NodeDefinition } from "../../../src/interfaces/IOracleManagerProxy.sol";

struct LocalState {
    bytes32[] nodeIds;
    uint256[] meanPrices;
    uint256[] maxDeviations;
}

contract GeneralForkCheck is BaseReyaForkTest {
    LocalState private ls;

    function checkFuzz_ProxiesOwnerAndUpgrades(address attacker) public {
        address[] memory proxies = new address[](6);
        proxies[0] = sec.core;
        proxies[1] = sec.pool;
        proxies[2] = sec.perp;
        proxies[3] = sec.oracleManager;
        proxies[4] = sec.periphery;
        proxies[5] = sec.exchangePass;

        for (uint256 i = 0; i < proxies.length; i += 1) {
            address proxy = proxies[i];

            assertEq(IOwnerUpgradeModule(proxy).owner(), sec.multisig);

            vm.prank(attacker);
            vm.expectRevert();
            IOwnerUpgradeModule(proxy).upgradeTo(sec.ownerUpgradeModule);

            vm.prank(sec.multisig);
            IOwnerUpgradeModule(proxy).upgradeTo(sec.ownerUpgradeModule);
        }

        assertEq(IOwnerUpgradeModule(sec.accountNft).owner(), sec.core);
    }

    function setupOracleNodePriceParams() public {
        uint256 meanPriceETH = 3500e18;
        uint256 maxDeviationETH = 2000e18;

        uint256 meanPriceBTC = 65_000e18;
        uint256 maxDeviationBTC = 20_000e18;

        uint256 meanPriceSOL = 150e18;
        uint256 maxDeviationSOL = 100e18;

        uint256 meanPriceARB = 0.7e18;
        uint256 maxDeviationARB = 0.3e18;

        uint256 meanPriceOP = 1.7e18;
        uint256 maxDeviationOP = 1e18;

        uint256 meanPriceAVAX = 28e18;
        uint256 maxDeviationAVAX = 14e18;

        uint256 meanPriceStableCoin = 1e18;
        uint256 maxDeviationStableCoin = 0.01e18;

        ls.nodeIds.push(sec.rusdUsdNodeId);
        ls.meanPrices.push(1e18);
        ls.maxDeviations.push(0);

        ls.nodeIds.push(sec.usdcUsdNodeId);
        ls.meanPrices.push(meanPriceStableCoin);
        ls.maxDeviations.push(maxDeviationStableCoin);

        ls.nodeIds.push(sec.usdcUsdStorkNodeId);
        ls.meanPrices.push(meanPriceStableCoin);
        ls.maxDeviations.push(maxDeviationStableCoin);

        ls.nodeIds.push(sec.ethUsdNodeId);
        ls.meanPrices.push(meanPriceETH);
        ls.maxDeviations.push(maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdcNodeId);
        ls.meanPrices.push(meanPriceETH);
        ls.maxDeviations.push(maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdStorkNodeId);
        ls.meanPrices.push(meanPriceETH);
        ls.maxDeviations.push(maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdcStorkNodeId);
        ls.meanPrices.push(meanPriceETH);
        ls.maxDeviations.push(maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdcStorkFallbackNodeId);
        ls.meanPrices.push(meanPriceETH);
        ls.maxDeviations.push(maxDeviationETH);

        ls.nodeIds.push(sec.btcUsdNodeId);
        ls.meanPrices.push(meanPriceBTC);
        ls.maxDeviations.push(maxDeviationBTC);

        ls.nodeIds.push(sec.btcUsdcNodeId);
        ls.meanPrices.push(meanPriceBTC);
        ls.maxDeviations.push(maxDeviationBTC);

        ls.nodeIds.push(sec.btcUsdStorkNodeId);
        ls.meanPrices.push(meanPriceBTC);
        ls.maxDeviations.push(maxDeviationBTC);

        ls.nodeIds.push(sec.btcUsdcStorkNodeId);
        ls.meanPrices.push(meanPriceBTC);
        ls.maxDeviations.push(maxDeviationBTC);

        ls.nodeIds.push(sec.btcUsdcStorkFallbackNodeId);
        ls.meanPrices.push(meanPriceBTC);
        ls.maxDeviations.push(maxDeviationBTC);

        ls.nodeIds.push(sec.solUsdNodeId);
        ls.meanPrices.push(meanPriceSOL);
        ls.maxDeviations.push(maxDeviationSOL);

        ls.nodeIds.push(sec.solUsdcNodeId);
        ls.meanPrices.push(meanPriceSOL);
        ls.maxDeviations.push(maxDeviationSOL);

        ls.nodeIds.push(sec.solUsdStorkNodeId);
        ls.meanPrices.push(meanPriceSOL);
        ls.maxDeviations.push(maxDeviationSOL);

        ls.nodeIds.push(sec.solUsdcStorkNodeId);
        ls.meanPrices.push(meanPriceSOL);
        ls.maxDeviations.push(maxDeviationSOL);

        ls.nodeIds.push(sec.solUsdcStorkFallbackNodeId);
        ls.meanPrices.push(meanPriceSOL);
        ls.maxDeviations.push(maxDeviationSOL);

        ls.nodeIds.push(sec.arbUsdNodeId);
        ls.meanPrices.push(meanPriceARB);
        ls.maxDeviations.push(maxDeviationARB);

        ls.nodeIds.push(sec.arbUsdcNodeId);
        ls.meanPrices.push(meanPriceARB);
        ls.maxDeviations.push(maxDeviationARB);

        ls.nodeIds.push(sec.arbUsdStorkNodeId);
        ls.meanPrices.push(meanPriceARB);
        ls.maxDeviations.push(maxDeviationARB);

        ls.nodeIds.push(sec.arbUsdcStorkNodeId);
        ls.meanPrices.push(meanPriceARB);
        ls.maxDeviations.push(maxDeviationARB);

        ls.nodeIds.push(sec.arbUsdcStorkFallbackNodeId);
        ls.meanPrices.push(meanPriceARB);
        ls.maxDeviations.push(maxDeviationARB);

        ls.nodeIds.push(sec.opUsdNodeId);
        ls.meanPrices.push(meanPriceOP);
        ls.maxDeviations.push(maxDeviationOP);

        ls.nodeIds.push(sec.opUsdcNodeId);
        ls.meanPrices.push(meanPriceOP);
        ls.maxDeviations.push(maxDeviationOP);

        ls.nodeIds.push(sec.opUsdStorkNodeId);
        ls.meanPrices.push(meanPriceOP);
        ls.maxDeviations.push(maxDeviationOP);

        ls.nodeIds.push(sec.opUsdcStorkNodeId);
        ls.meanPrices.push(meanPriceOP);
        ls.maxDeviations.push(maxDeviationOP);

        ls.nodeIds.push(sec.opUsdcStorkFallbackNodeId);
        ls.meanPrices.push(meanPriceOP);
        ls.maxDeviations.push(maxDeviationOP);

        ls.nodeIds.push(sec.avaxUsdNodeId);
        ls.meanPrices.push(meanPriceAVAX);
        ls.maxDeviations.push(maxDeviationAVAX);

        ls.nodeIds.push(sec.avaxUsdcNodeId);
        ls.meanPrices.push(meanPriceAVAX);
        ls.maxDeviations.push(maxDeviationAVAX);

        ls.nodeIds.push(sec.avaxUsdStorkNodeId);
        ls.meanPrices.push(meanPriceAVAX);
        ls.maxDeviations.push(maxDeviationAVAX);

        ls.nodeIds.push(sec.avaxUsdcStorkNodeId);
        ls.meanPrices.push(meanPriceAVAX);
        ls.maxDeviations.push(maxDeviationAVAX);

        ls.nodeIds.push(sec.avaxUsdcStorkFallbackNodeId);
        ls.meanPrices.push(meanPriceAVAX);
        ls.maxDeviations.push(maxDeviationAVAX);

        ls.nodeIds.push(sec.usdeUsdNodeId);
        ls.meanPrices.push(meanPriceStableCoin);
        ls.maxDeviations.push(maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.usdeUsdcNodeId);
        ls.meanPrices.push(meanPriceStableCoin);
        ls.maxDeviations.push(maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.usdeUsdStorkNodeId);
        ls.meanPrices.push(meanPriceStableCoin);
        ls.maxDeviations.push(maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.usdeUsdcStorkNodeId);
        ls.meanPrices.push(meanPriceStableCoin);
        ls.maxDeviations.push(maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.usdeUsdcStorkFallbackNodeId);
        ls.meanPrices.push(meanPriceStableCoin);
        ls.maxDeviations.push(maxDeviationStableCoin * 2);
    }

    function check_OracleNodePrices(bool flagCheckStaleness) public {
        setupOracleNodePriceParams();

        for (uint256 i = 0; i < ls.nodeIds.length; i++) {
            NodeOutput.Data memory nodeOutput = IOracleManagerProxy(sec.oracleManager).process(ls.nodeIds[i]);
            NodeDefinition.Data memory nodeDefinition = IOracleManagerProxy(sec.oracleManager).getNode(ls.nodeIds[i]);

            assertLe(nodeOutput.timestamp, block.timestamp);
            assertApproxEqAbsDecimal(nodeOutput.price, ls.meanPrices[i], ls.maxDeviations[i], 18);

            // note: in the case of it is not one minute staleness for all oracle nodes, create individual values,
            // similar to meanPrices
            if (flagCheckStaleness) {
                assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, nodeOutput.timestamp);
                assertEq(nodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
            }

            // if redstone node, check that the owner of the price feed is the multisig
            if (nodeDefinition.nodeType == 2) {
                (address priceFeed,) = abi.decode(nodeDefinition.parameters, (address, uint256));
                address owner = IOwnerUpgradeModule(priceFeed).owner();
                assertEq(owner, sec.multisig);
            }
        }
    }
}
