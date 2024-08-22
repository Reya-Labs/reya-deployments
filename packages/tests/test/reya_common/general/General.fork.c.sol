pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { IOwnerUpgradeModule } from "../../../src/interfaces/IOwnerUpgradeModule.sol";
import { IOracleManagerProxy, NodeOutput, NodeDefinition } from "../../../src/interfaces/IOracleManagerProxy.sol";

struct LocalState {
    bytes32[] nodeIds;
    uint256[] meanPrices;
    uint256[] maxDeviations;

    uint256 meanPriceETH;
    uint256 maxDeviationETH;

    uint256 meanPriceBTC;
    uint256 maxDeviationBTC;

    uint256 meanPriceSOL;
    uint256 maxDeviationSOL;

    uint256 meanPriceARB;
    uint256 maxDeviationARB;

    uint256 meanPriceOP;
    uint256 maxDeviationOP;

    uint256 meanPriceAVAX;
    uint256 maxDeviationAVAX;

    uint256 meanPriceMKR;
    uint256 maxDeviationMKR;

    uint256 meanPriceLINK;
    uint256 maxDeviationLINK;

    uint256 meanPriceStableCoin;
    uint256 maxDeviationStableCoin;
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
        ls.meanPriceETH = 3500e18;
        ls.maxDeviationETH = 2000e18;

        ls.meanPriceBTC = 65_000e18;
        ls.maxDeviationBTC = 20_000e18;

        ls.meanPriceSOL = 150e18;
        ls.maxDeviationSOL = 100e18;

        ls.meanPriceARB = 0.7e18;
        ls.maxDeviationARB = 0.3e18;

        ls.meanPriceOP = 1.7e18;
        ls.maxDeviationOP = 1e18;

        ls.meanPriceAVAX = 28e18;
        ls.maxDeviationAVAX = 14e18;

        ls.meanPriceMKR = 2000e18;
        ls.maxDeviationMKR = 1000e18;

        ls.meanPriceLINK = 15e18;
        ls.maxDeviationLINK = 10e18;

        ls.meanPriceStableCoin = 1e18;
        ls.maxDeviationStableCoin = 0.01e18;

        ls.nodeIds.push(sec.rusdUsdNodeId);
        ls.meanPrices.push(1e18);
        ls.maxDeviations.push(0);

        ls.nodeIds.push(sec.usdcUsdNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin);

        ls.nodeIds.push(sec.usdcUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin);

        ls.nodeIds.push(sec.ethUsdNodeId);
        ls.meanPrices.push(ls.meanPriceETH);
        ls.maxDeviations.push(ls.maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdcNodeId);
        ls.meanPrices.push(ls.meanPriceETH);
        ls.maxDeviations.push(ls.maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceETH);
        ls.maxDeviations.push(ls.maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceETH);
        ls.maxDeviations.push(ls.maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdcStorkFallbackNodeId);
        ls.meanPrices.push(ls.meanPriceETH);
        ls.maxDeviations.push(ls.maxDeviationETH);

        ls.nodeIds.push(sec.btcUsdNodeId);
        ls.meanPrices.push(ls.meanPriceBTC);
        ls.maxDeviations.push(ls.maxDeviationBTC);

        ls.nodeIds.push(sec.btcUsdcNodeId);
        ls.meanPrices.push(ls.meanPriceBTC);
        ls.maxDeviations.push(ls.maxDeviationBTC);

        ls.nodeIds.push(sec.btcUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceBTC);
        ls.maxDeviations.push(ls.maxDeviationBTC);

        ls.nodeIds.push(sec.btcUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceBTC);
        ls.maxDeviations.push(ls.maxDeviationBTC);

        ls.nodeIds.push(sec.btcUsdcStorkFallbackNodeId);
        ls.meanPrices.push(ls.meanPriceBTC);
        ls.maxDeviations.push(ls.maxDeviationBTC);

        ls.nodeIds.push(sec.solUsdNodeId);
        ls.meanPrices.push(ls.meanPriceSOL);
        ls.maxDeviations.push(ls.maxDeviationSOL);

        ls.nodeIds.push(sec.solUsdcNodeId);
        ls.meanPrices.push(ls.meanPriceSOL);
        ls.maxDeviations.push(ls.maxDeviationSOL);

        ls.nodeIds.push(sec.solUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceSOL);
        ls.maxDeviations.push(ls.maxDeviationSOL);

        ls.nodeIds.push(sec.solUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceSOL);
        ls.maxDeviations.push(ls.maxDeviationSOL);

        ls.nodeIds.push(sec.solUsdcStorkFallbackNodeId);
        ls.meanPrices.push(ls.meanPriceSOL);
        ls.maxDeviations.push(ls.maxDeviationSOL);

        ls.nodeIds.push(sec.arbUsdNodeId);
        ls.meanPrices.push(ls.meanPriceARB);
        ls.maxDeviations.push(ls.maxDeviationARB);

        ls.nodeIds.push(sec.arbUsdcNodeId);
        ls.meanPrices.push(ls.meanPriceARB);
        ls.maxDeviations.push(ls.maxDeviationARB);

        ls.nodeIds.push(sec.arbUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceARB);
        ls.maxDeviations.push(ls.maxDeviationARB);

        ls.nodeIds.push(sec.arbUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceARB);
        ls.maxDeviations.push(ls.maxDeviationARB);

        ls.nodeIds.push(sec.arbUsdcStorkFallbackNodeId);
        ls.meanPrices.push(ls.meanPriceARB);
        ls.maxDeviations.push(ls.maxDeviationARB);

        ls.nodeIds.push(sec.opUsdNodeId);
        ls.meanPrices.push(ls.meanPriceOP);
        ls.maxDeviations.push(ls.maxDeviationOP);

        ls.nodeIds.push(sec.opUsdcNodeId);
        ls.meanPrices.push(ls.meanPriceOP);
        ls.maxDeviations.push(ls.maxDeviationOP);

        ls.nodeIds.push(sec.opUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceOP);
        ls.maxDeviations.push(ls.maxDeviationOP);

        ls.nodeIds.push(sec.opUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceOP);
        ls.maxDeviations.push(ls.maxDeviationOP);

        ls.nodeIds.push(sec.opUsdcStorkFallbackNodeId);
        ls.meanPrices.push(ls.meanPriceOP);
        ls.maxDeviations.push(ls.maxDeviationOP);

        ls.nodeIds.push(sec.avaxUsdNodeId);
        ls.meanPrices.push(ls.meanPriceAVAX);
        ls.maxDeviations.push(ls.maxDeviationAVAX);

        ls.nodeIds.push(sec.avaxUsdcNodeId);
        ls.meanPrices.push(ls.meanPriceAVAX);
        ls.maxDeviations.push(ls.maxDeviationAVAX);

        ls.nodeIds.push(sec.avaxUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceAVAX);
        ls.maxDeviations.push(ls.maxDeviationAVAX);

        ls.nodeIds.push(sec.avaxUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceAVAX);
        ls.maxDeviations.push(ls.maxDeviationAVAX);

        ls.nodeIds.push(sec.avaxUsdcStorkFallbackNodeId);
        ls.meanPrices.push(ls.meanPriceAVAX);
        ls.maxDeviations.push(ls.maxDeviationAVAX);

        ls.nodeIds.push(sec.usdeUsdNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.usdeUsdcNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.usdeUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.usdeUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.usdeUsdcStorkFallbackNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.mkrUsdNodeId);
        ls.meanPrices.push(ls.meanPriceMKR);
        ls.maxDeviations.push(ls.maxDeviationMKR);

        ls.nodeIds.push(sec.mkrUsdcNodeId);
        ls.meanPrices.push(ls.meanPriceMKR);
        ls.maxDeviations.push(ls.maxDeviationMKR);

        ls.nodeIds.push(sec.mkrUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceMKR);
        ls.maxDeviations.push(ls.maxDeviationMKR);

        ls.nodeIds.push(sec.mkrUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceMKR);
        ls.maxDeviations.push(ls.maxDeviationMKR);

        ls.nodeIds.push(sec.mkrUsdcStorkFallbackNodeId);
        ls.meanPrices.push(ls.meanPriceMKR);
        ls.maxDeviations.push(ls.maxDeviationMKR);

        ls.nodeIds.push(sec.linkUsdNodeId);
        ls.meanPrices.push(ls.meanPriceLINK);
        ls.maxDeviations.push(ls.maxDeviationLINK);

        ls.nodeIds.push(sec.linkUsdcNodeId);
        ls.meanPrices.push(ls.meanPriceLINK);
        ls.maxDeviations.push(ls.maxDeviationLINK);

        ls.nodeIds.push(sec.linkUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceLINK);
        ls.maxDeviations.push(ls.maxDeviationLINK);

        ls.nodeIds.push(sec.linkUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceLINK);
        ls.maxDeviations.push(ls.maxDeviationLINK);

        ls.nodeIds.push(sec.linkUsdcStorkFallbackNodeId);
        ls.meanPrices.push(ls.meanPriceLINK);
        ls.maxDeviations.push(ls.maxDeviationLINK);
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
                uint256 max_stale_duration = 0;
                if (nodeDefinition.nodeType == 1) {
                    // it can be 60 or 90 depending on redstone/stork
                    max_stale_duration = nodeDefinition.maxStaleDuration;
                    assert(max_stale_duration == 60 || max_stale_duration == 90);
                } else if (nodeDefinition.nodeType == 2 || nodeDefinition.nodeType == 5) {
                    max_stale_duration = 90;
                } else if (nodeDefinition.nodeType == 3 || nodeDefinition.nodeType == 4) {
                    max_stale_duration = ONE_MINUTE_IN_SECONDS;
                }
                assertLe(block.timestamp - max_stale_duration, nodeOutput.timestamp);
                assertEq(nodeDefinition.maxStaleDuration, max_stale_duration);
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
