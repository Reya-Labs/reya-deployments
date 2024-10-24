pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { IOwnerUpgradeModule } from "../../../src/interfaces/IOwnerUpgradeModule.sol";
import { IOracleManagerProxy, NodeOutput, NodeDefinition } from "../../../src/interfaces/IOracleManagerProxy.sol";
import { IPassivePerpProxy, MarketConfigurationData } from "../../../src/interfaces/IPassivePerpProxy.sol";

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
    uint256 meanPriceAAVE;
    uint256 maxDeviationAAVE;
    uint256 meanPriceCRV;
    uint256 maxDeviationCRV;
    uint256 meanPriceUNI;
    uint256 maxDeviationUNI;
    uint256 meanPriceSUI;
    uint256 maxDeviationSUI;
    uint256 meanPriceTIA;
    uint256 maxDeviationTIA;
    uint256 meanPriceSEI;
    uint256 maxDeviationSEI;
    uint256 meanPriceZRO;
    uint256 maxDeviationZRO;
    uint256 meanPriceXRP;
    uint256 maxDeviationXRP;
    uint256 meanPriceWIF;
    uint256 maxDeviationWIF;
    uint256 meanPrice1000PEPE;
    uint256 maxDeviation1000PEPE;
    uint256 meanPricePOPCAT;
    uint256 maxDeviationPOPCAT;
    uint256 meanPriceDOGE;
    uint256 maxDeviationDOGE;
    uint256 meanPriceKSHIB;
    uint256 maxDeviationKSHIB;
    uint256 meanPriceKBONK;
    uint256 maxDeviationKBONK;
    uint256 meanPriceSUSDE;
    uint256 maxDeviationSUSDE;
    uint256 meanPriceStableCoin;
    uint256 maxDeviationStableCoin;
    uint256[] meanPriceMarket;
    uint256[] maxDeviationMarket;
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

    function setupOracleNodePriceParams() private {
        ls.meanPriceMarket.push(0);
        ls.maxDeviationMarket.push(0);

        ls.meanPriceETH = 3500e18;
        ls.maxDeviationETH = 2000e18;
        ls.meanPriceMarket.push(ls.meanPriceETH);
        ls.maxDeviationMarket.push(ls.maxDeviationETH);

        ls.meanPriceBTC = 65_000e18;
        ls.maxDeviationBTC = 20_000e18;
        ls.meanPriceMarket.push(ls.meanPriceBTC);
        ls.maxDeviationMarket.push(ls.maxDeviationBTC);

        ls.meanPriceSOL = 150e18;
        ls.maxDeviationSOL = 100e18;
        ls.meanPriceMarket.push(ls.meanPriceSOL);
        ls.maxDeviationMarket.push(ls.maxDeviationSOL);

        ls.meanPriceARB = 0.7e18;
        ls.maxDeviationARB = 0.3e18;
        ls.meanPriceMarket.push(ls.meanPriceARB);
        ls.maxDeviationMarket.push(ls.maxDeviationARB);

        ls.meanPriceOP = 1.7e18;
        ls.maxDeviationOP = 1e18;
        ls.meanPriceMarket.push(ls.meanPriceOP);
        ls.maxDeviationMarket.push(ls.maxDeviationOP);

        ls.meanPriceAVAX = 28e18;
        ls.maxDeviationAVAX = 14e18;
        ls.meanPriceMarket.push(ls.meanPriceAVAX);
        ls.maxDeviationMarket.push(ls.maxDeviationAVAX);

        ls.meanPriceMKR = 2000e18;
        ls.maxDeviationMKR = 1000e18;
        ls.meanPriceMarket.push(ls.meanPriceMKR);
        ls.maxDeviationMarket.push(ls.maxDeviationMKR);

        ls.meanPriceLINK = 15e18;
        ls.maxDeviationLINK = 10e18;
        ls.meanPriceMarket.push(ls.meanPriceLINK);
        ls.maxDeviationMarket.push(ls.maxDeviationLINK);

        ls.meanPriceAAVE = 130e18;
        ls.maxDeviationAAVE = 50e18;
        ls.meanPriceMarket.push(ls.meanPriceAAVE);
        ls.maxDeviationMarket.push(ls.maxDeviationAAVE);

        ls.meanPriceCRV = 0.3e18;
        ls.maxDeviationCRV = 0.15e18;
        ls.meanPriceMarket.push(ls.meanPriceCRV);
        ls.maxDeviationMarket.push(ls.maxDeviationCRV);

        ls.meanPriceUNI = 7e18;
        ls.maxDeviationUNI = 3e18;
        ls.meanPriceMarket.push(ls.meanPriceUNI);
        ls.maxDeviationMarket.push(ls.maxDeviationUNI);

        ls.meanPriceSUI = 1.6e18;
        ls.maxDeviationSUI = 0.8e18;
        ls.meanPriceMarket.push(ls.meanPriceSUI);
        ls.maxDeviationMarket.push(ls.maxDeviationSUI);

        ls.meanPriceTIA = 6.3e18;
        ls.maxDeviationTIA = 3.5e18;
        ls.meanPriceMarket.push(ls.meanPriceTIA);
        ls.maxDeviationMarket.push(ls.maxDeviationTIA);

        ls.meanPriceSEI = 0.45e18;
        ls.maxDeviationSEI = 0.2e18;
        ls.meanPriceMarket.push(ls.meanPriceSEI);
        ls.maxDeviationMarket.push(ls.maxDeviationSEI);

        ls.meanPriceZRO = 4.5e18;
        ls.maxDeviationZRO = 2.5e18;
        ls.meanPriceMarket.push(ls.meanPriceZRO);
        ls.maxDeviationMarket.push(ls.maxDeviationZRO);

        ls.meanPriceXRP = 0.55e18;
        ls.maxDeviationXRP = 0.2e18;
        ls.meanPriceMarket.push(ls.meanPriceXRP);
        ls.maxDeviationMarket.push(ls.maxDeviationXRP);

        ls.meanPriceWIF = 2.7e18;
        ls.maxDeviationWIF = 1.5e18;
        ls.meanPriceMarket.push(ls.meanPriceWIF);
        ls.maxDeviationMarket.push(ls.maxDeviationWIF);

        ls.meanPrice1000PEPE = 0.0105e18;
        ls.maxDeviation1000PEPE = 0.007e18;
        ls.meanPriceMarket.push(ls.meanPrice1000PEPE);
        ls.maxDeviationMarket.push(ls.maxDeviation1000PEPE);

        ls.meanPricePOPCAT = 1.3e18;
        ls.maxDeviationPOPCAT = 0.6e18;
        ls.meanPriceMarket.push(ls.meanPricePOPCAT);
        ls.maxDeviationMarket.push(ls.maxDeviationPOPCAT);

        ls.meanPriceDOGE = 0.15e18;
        ls.maxDeviationDOGE = 0.07e18;
        ls.meanPriceMarket.push(ls.meanPriceDOGE);
        ls.maxDeviationMarket.push(ls.maxDeviationDOGE);

        ls.meanPriceKSHIB = 0.018e18;
        ls.maxDeviationKSHIB = 0.009e18;
        ls.meanPriceMarket.push(ls.meanPriceKSHIB);
        ls.maxDeviationMarket.push(ls.maxDeviationKSHIB);

        ls.meanPriceKBONK = 0.023e18;
        ls.maxDeviationKBONK = 0.012e18;
        ls.meanPriceMarket.push(ls.meanPriceKBONK);
        ls.maxDeviationMarket.push(ls.maxDeviationKBONK);

        ls.meanPriceSUSDE = 1.11e18;
        ls.maxDeviationSUSDE = 0.01e18;

        ls.meanPriceStableCoin = 1e18;
        ls.maxDeviationStableCoin = 0.01e18;

        ls.nodeIds.push(sec.rusdUsdNodeId);
        ls.meanPrices.push(1e18);
        ls.maxDeviations.push(0);

        // ls.nodeIds.push(sec.usdcUsdNodeId);
        // ls.meanPrices.push(meanPriceStableCoin);
        // ls.maxDeviations.push(maxDeviationStableCoin);

        ls.nodeIds.push(sec.usdcUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin);

        // ls.nodeIds.push(sec.ethUsdNodeId);
        // ls.meanPrices.push(meanPriceETH);
        // ls.maxDeviations.push(maxDeviationETH);

        // ls.nodeIds.push(sec.ethUsdcNodeId);
        // ls.meanPrices.push(meanPriceETH);
        // ls.maxDeviations.push(maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceETH);
        ls.maxDeviations.push(ls.maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceETH);
        ls.maxDeviations.push(ls.maxDeviationETH);

        // ls.nodeIds.push(sec.ethUsdcStorkFallbackNodeId);
        // ls.meanPrices.push(meanPriceETH);
        // ls.maxDeviations.push(maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceETH);
        ls.maxDeviations.push(ls.maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceETH);
        ls.maxDeviations.push(ls.maxDeviationETH);

        // ls.nodeIds.push(sec.btcUsdNodeId);
        // ls.meanPrices.push(meanPriceBTC);
        // ls.maxDeviations.push(maxDeviationBTC);

        // ls.nodeIds.push(sec.btcUsdcNodeId);
        // ls.meanPrices.push(meanPriceBTC);
        // ls.maxDeviations.push(maxDeviationBTC);

        // ls.nodeIds.push(sec.btcUsdStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceBTC);
        // ls.maxDeviations.push(ls.maxDeviationBTC);

        // ls.nodeIds.push(sec.btcUsdcStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceBTC);
        // ls.maxDeviations.push(ls.maxDeviationBTC);

        // ls.nodeIds.push(sec.btcUsdcStorkFallbackNodeId);
        // ls.meanPrices.push(meanPriceBTC);
        // ls.maxDeviations.push(maxDeviationBTC);

        ls.nodeIds.push(sec.btcUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceBTC);
        ls.maxDeviations.push(ls.maxDeviationBTC);

        ls.nodeIds.push(sec.btcUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceBTC);
        ls.maxDeviations.push(ls.maxDeviationBTC);

        // ls.nodeIds.push(sec.solUsdNodeId);
        // ls.meanPrices.push(meanPriceSOL);
        // ls.maxDeviations.push(maxDeviationSOL);

        // ls.nodeIds.push(sec.solUsdcNodeId);
        // ls.meanPrices.push(meanPriceSOL);
        // ls.maxDeviations.push(maxDeviationSOL);

        // ls.nodeIds.push(sec.solUsdStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceSOL);
        // ls.maxDeviations.push(ls.maxDeviationSOL);

        // ls.nodeIds.push(sec.solUsdcStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceSOL);
        // ls.maxDeviations.push(ls.maxDeviationSOL);

        // ls.nodeIds.push(sec.solUsdcStorkFallbackNodeId);
        // ls.meanPrices.push(meanPriceSOL);
        // ls.maxDeviations.push(maxDeviationSOL);

        ls.nodeIds.push(sec.solUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceSOL);
        ls.maxDeviations.push(ls.maxDeviationSOL);

        ls.nodeIds.push(sec.solUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceSOL);
        ls.maxDeviations.push(ls.maxDeviationSOL);

        // ls.nodeIds.push(sec.arbUsdNodeId);
        // ls.meanPrices.push(meanPriceARB);
        // ls.maxDeviations.push(maxDeviationARB);

        // ls.nodeIds.push(sec.arbUsdcNodeId);
        // ls.meanPrices.push(meanPriceARB);
        // ls.maxDeviations.push(maxDeviationARB);

        // ls.nodeIds.push(sec.arbUsdStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceARB);
        // ls.maxDeviations.push(ls.maxDeviationARB);

        // ls.nodeIds.push(sec.arbUsdcStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceARB);
        // ls.maxDeviations.push(ls.maxDeviationARB);

        // ls.nodeIds.push(sec.arbUsdcStorkFallbackNodeId);
        // ls.meanPrices.push(meanPriceARB);
        // ls.maxDeviations.push(maxDeviationARB);

        ls.nodeIds.push(sec.arbUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceARB);
        ls.maxDeviations.push(ls.maxDeviationARB);

        ls.nodeIds.push(sec.arbUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceARB);
        ls.maxDeviations.push(ls.maxDeviationARB);

        // ls.nodeIds.push(sec.opUsdNodeId);
        // ls.meanPrices.push(meanPriceOP);
        // ls.maxDeviations.push(maxDeviationOP);

        // ls.nodeIds.push(sec.opUsdcNodeId);
        // ls.meanPrices.push(meanPriceOP);
        // ls.maxDeviations.push(maxDeviationOP);

        // ls.nodeIds.push(sec.opUsdStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceOP);
        // ls.maxDeviations.push(ls.maxDeviationOP);

        // ls.nodeIds.push(sec.opUsdcStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceOP);
        // ls.maxDeviations.push(ls.maxDeviationOP);

        // ls.nodeIds.push(sec.opUsdcStorkFallbackNodeId);
        // ls.meanPrices.push(meanPriceOP);
        // ls.maxDeviations.push(maxDeviationOP);

        ls.nodeIds.push(sec.opUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceOP);
        ls.maxDeviations.push(ls.maxDeviationOP);

        ls.nodeIds.push(sec.opUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceOP);
        ls.maxDeviations.push(ls.maxDeviationOP);

        // ls.nodeIds.push(sec.avaxUsdNodeId);
        // ls.meanPrices.push(meanPriceAVAX);
        // ls.maxDeviations.push(maxDeviationAVAX);

        // ls.nodeIds.push(sec.avaxUsdcNodeId);
        // ls.meanPrices.push(meanPriceAVAX);
        // ls.maxDeviations.push(maxDeviationAVAX);

        // ls.nodeIds.push(sec.avaxUsdStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceAVAX);
        // ls.maxDeviations.push(ls.maxDeviationAVAX);

        // ls.nodeIds.push(sec.avaxUsdcStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceAVAX);
        // ls.maxDeviations.push(ls.maxDeviationAVAX);

        // ls.nodeIds.push(sec.avaxUsdcStorkFallbackNodeId);
        // ls.meanPrices.push(meanPriceAVAX);
        // ls.maxDeviations.push(maxDeviationAVAX);

        ls.nodeIds.push(sec.avaxUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAVAX);
        ls.maxDeviations.push(ls.maxDeviationAVAX);

        ls.nodeIds.push(sec.avaxUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAVAX);
        ls.maxDeviations.push(ls.maxDeviationAVAX);

        // ls.nodeIds.push(sec.usdeUsdNodeId);
        // ls.meanPrices.push(meanPriceStableCoin);
        // ls.maxDeviations.push(maxDeviationStableCoin * 2);

        // ls.nodeIds.push(sec.usdeUsdcNodeId);
        // ls.meanPrices.push(meanPriceStableCoin);
        // ls.maxDeviations.push(maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.usdeUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.usdeUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin * 2);

        // ls.nodeIds.push(sec.usdeUsdcStorkFallbackNodeId);
        // ls.meanPrices.push(ls.meanPriceStableCoin);
        // ls.maxDeviations.push(ls.maxDeviationStableCoin * 2);

        // ls.nodeIds.push(sec.mkrUsdNodeId);
        // ls.meanPrices.push(ls.meanPriceMKR);
        // ls.maxDeviations.push(ls.maxDeviationMKR);

        // ls.nodeIds.push(sec.mkrUsdcNodeId);
        // ls.meanPrices.push(ls.meanPriceMKR);
        // ls.maxDeviations.push(ls.maxDeviationMKR);

        // ls.nodeIds.push(sec.mkrUsdStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceMKR);
        // ls.maxDeviations.push(ls.maxDeviationMKR);

        // ls.nodeIds.push(sec.mkrUsdcStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceMKR);
        // ls.maxDeviations.push(ls.maxDeviationMKR);

        // ls.nodeIds.push(sec.mkrUsdcStorkFallbackNodeId);
        // ls.meanPrices.push(ls.meanPriceMKR);
        // ls.maxDeviations.push(ls.maxDeviationMKR);

        ls.nodeIds.push(sec.mkrUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceMKR);
        ls.maxDeviations.push(ls.maxDeviationMKR);

        ls.nodeIds.push(sec.mkrUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceMKR);
        ls.maxDeviations.push(ls.maxDeviationMKR);

        // ls.nodeIds.push(sec.linkUsdNodeId);
        // ls.meanPrices.push(ls.meanPriceLINK);
        // ls.maxDeviations.push(ls.maxDeviationLINK);

        // ls.nodeIds.push(sec.linkUsdcNodeId);
        // ls.meanPrices.push(ls.meanPriceLINK);
        // ls.maxDeviations.push(ls.maxDeviationLINK);

        // ls.nodeIds.push(sec.linkUsdStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceLINK);
        // ls.maxDeviations.push(ls.maxDeviationLINK);

        // ls.nodeIds.push(sec.linkUsdcStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceLINK);
        // ls.maxDeviations.push(ls.maxDeviationLINK);

        // ls.nodeIds.push(sec.linkUsdcStorkFallbackNodeId);
        // ls.meanPrices.push(ls.meanPriceLINK);
        // ls.maxDeviations.push(ls.maxDeviationLINK);

        ls.nodeIds.push(sec.linkUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceLINK);
        ls.maxDeviations.push(ls.maxDeviationLINK);

        ls.nodeIds.push(sec.linkUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceLINK);
        ls.maxDeviations.push(ls.maxDeviationLINK);

        // ls.nodeIds.push(sec.aaveUsdNodeId);
        // ls.meanPrices.push(ls.meanPriceAAVE);
        // ls.maxDeviations.push(ls.maxDeviationAAVE);

        // ls.nodeIds.push(sec.aaveUsdcNodeId);
        // ls.meanPrices.push(ls.meanPriceAAVE);
        // ls.maxDeviations.push(ls.maxDeviationAAVE);

        // ls.nodeIds.push(sec.aaveUsdStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceAAVE);
        // ls.maxDeviations.push(ls.maxDeviationAAVE);

        // ls.nodeIds.push(sec.aaveUsdcStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceAAVE);
        // ls.maxDeviations.push(ls.maxDeviationAAVE);

        // ls.nodeIds.push(sec.aaveUsdcStorkFallbackNodeId);
        // ls.meanPrices.push(ls.meanPriceAAVE);
        // ls.maxDeviations.push(ls.maxDeviationAAVE);

        ls.nodeIds.push(sec.aaveUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAAVE);
        ls.maxDeviations.push(ls.maxDeviationAAVE);

        ls.nodeIds.push(sec.aaveUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAAVE);
        ls.maxDeviations.push(ls.maxDeviationAAVE);

        // ls.nodeIds.push(sec.crvUsdNodeId);
        // ls.meanPrices.push(ls.meanPriceCRV);
        // ls.maxDeviations.push(ls.maxDeviationCRV);

        // ls.nodeIds.push(sec.crvUsdcNodeId);
        // ls.meanPrices.push(ls.meanPriceCRV);
        // ls.maxDeviations.push(ls.maxDeviationCRV);

        // ls.nodeIds.push(sec.crvUsdStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceCRV);
        // ls.maxDeviations.push(ls.maxDeviationCRV);

        // ls.nodeIds.push(sec.crvUsdcStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceCRV);
        // ls.maxDeviations.push(ls.maxDeviationCRV);

        // ls.nodeIds.push(sec.crvUsdcStorkFallbackNodeId);
        // ls.meanPrices.push(ls.meanPriceCRV);
        // ls.maxDeviations.push(ls.maxDeviationCRV);

        ls.nodeIds.push(sec.crvUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceCRV);
        ls.maxDeviations.push(ls.maxDeviationCRV);

        ls.nodeIds.push(sec.crvUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceCRV);
        ls.maxDeviations.push(ls.maxDeviationCRV);

        // ls.nodeIds.push(sec.uniUsdNodeId);
        // ls.meanPrices.push(ls.meanPriceUNI);
        // ls.maxDeviations.push(ls.maxDeviationUNI);

        // ls.nodeIds.push(sec.uniUsdcNodeId);
        // ls.meanPrices.push(ls.meanPriceUNI);
        // ls.maxDeviations.push(ls.maxDeviationUNI);

        // ls.nodeIds.push(sec.uniUsdStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceUNI);
        // ls.maxDeviations.push(ls.maxDeviationUNI);

        // ls.nodeIds.push(sec.uniUsdcStorkNodeId);
        // ls.meanPrices.push(ls.meanPriceUNI);
        // ls.maxDeviations.push(ls.maxDeviationUNI);

        // ls.nodeIds.push(sec.uniUsdcStorkFallbackNodeId);
        // ls.meanPrices.push(ls.meanPriceUNI);
        // ls.maxDeviations.push(ls.maxDeviationUNI);

        ls.nodeIds.push(sec.uniUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceUNI);
        ls.maxDeviations.push(ls.maxDeviationUNI);

        ls.nodeIds.push(sec.uniUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceUNI);
        ls.maxDeviations.push(ls.maxDeviationUNI);

        ls.nodeIds.push(sec.suiUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceSUI);
        ls.maxDeviations.push(ls.maxDeviationSUI);

        ls.nodeIds.push(sec.suiUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceSUI);
        ls.maxDeviations.push(ls.maxDeviationSUI);

        ls.nodeIds.push(sec.tiaUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceTIA);
        ls.maxDeviations.push(ls.maxDeviationTIA);

        ls.nodeIds.push(sec.tiaUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceTIA);
        ls.maxDeviations.push(ls.maxDeviationTIA);

        ls.nodeIds.push(sec.seiUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceSEI);
        ls.maxDeviations.push(ls.maxDeviationSEI);

        ls.nodeIds.push(sec.seiUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceSEI);
        ls.maxDeviations.push(ls.maxDeviationSEI);

        ls.nodeIds.push(sec.zroUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceZRO);
        ls.maxDeviations.push(ls.maxDeviationZRO);

        ls.nodeIds.push(sec.zroUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceZRO);
        ls.maxDeviations.push(ls.maxDeviationZRO);

        ls.nodeIds.push(sec.xrpUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceXRP);
        ls.maxDeviations.push(ls.maxDeviationXRP);

        ls.nodeIds.push(sec.xrpUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceXRP);
        ls.maxDeviations.push(ls.maxDeviationXRP);

        ls.nodeIds.push(sec.wifUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceWIF);
        ls.maxDeviations.push(ls.maxDeviationWIF);

        ls.nodeIds.push(sec.wifUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceWIF);
        ls.maxDeviations.push(ls.maxDeviationWIF);

        ls.nodeIds.push(sec.pepe1kUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPrice1000PEPE);
        ls.maxDeviations.push(ls.maxDeviation1000PEPE);

        ls.nodeIds.push(sec.pepe1kUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPrice1000PEPE);
        ls.maxDeviations.push(ls.maxDeviation1000PEPE);

        // ls.nodeIds.push(sec.popcatUsdStorkMarkNodeId);
        // ls.meanPrices.push(ls.meanPricePOPCAT);
        // ls.maxDeviations.push(ls.maxDeviationPOPCAT);

        // ls.nodeIds.push(sec.popcatUsdcStorkMarkNodeId);
        // ls.meanPrices.push(ls.meanPricePOPCAT);
        // ls.maxDeviations.push(ls.maxDeviationPOPCAT);

        ls.nodeIds.push(sec.dogeUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceDOGE);
        ls.maxDeviations.push(ls.maxDeviationDOGE);

        ls.nodeIds.push(sec.dogeUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceDOGE);
        ls.maxDeviations.push(ls.maxDeviationDOGE);

        ls.nodeIds.push(sec.kshibUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceKSHIB);
        ls.maxDeviations.push(ls.maxDeviationKSHIB);

        ls.nodeIds.push(sec.kshibUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceKSHIB);
        ls.maxDeviations.push(ls.maxDeviationKSHIB);

        ls.nodeIds.push(sec.kbonkUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceKBONK);
        ls.maxDeviations.push(ls.maxDeviationKBONK);

        ls.nodeIds.push(sec.kbonkUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceKBONK);
        ls.maxDeviations.push(ls.maxDeviationKBONK);

        // ls.nodeIds.push(sec.susdeUsdNodeId);
        // ls.meanPrices.push(ls.meanPriceSUSDE);
        // ls.maxDeviations.push(ls.maxDeviationSUSDE);

        // ls.nodeIds.push(sec.susdeUsdcNodeId);
        // ls.meanPrices.push(ls.meanPriceSUSDE);
        // ls.maxDeviations.push(ls.maxDeviationSUSDE);

        ls.nodeIds.push(sec.susdeUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceSUSDE);
        ls.maxDeviations.push(ls.maxDeviationSUSDE);

        ls.nodeIds.push(sec.susdeUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceSUSDE);
        ls.maxDeviations.push(ls.maxDeviationSUSDE);

        // ls.nodeIds.push(sec.susdeUsdcStorkFallbackNodeId);
        // ls.meanPrices.push(ls.meanPriceSUSDE);
        // ls.maxDeviations.push(ls.maxDeviationSUSDE);
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

    function check_marketsPrices() public {
        setupOracleNodePriceParams();
        for (uint128 i = 1; i <= lastMarketId(); i++) {
            if (i == 19) {
                continue;
            }

            MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(i);
            bytes32 nodeId = marketConfig.oracleNodeId;

            NodeOutput.Data memory nodeOutput = IOracleManagerProxy(sec.oracleManager).process(nodeId);

            assertApproxEqAbsDecimal(nodeOutput.price, ls.meanPriceMarket[i], ls.maxDeviationMarket[i], 18);
        }
    }

    function check_marketsOrderMaxStaleDuration(uint256 orderMaxStaleDuration) public view {
        for (uint128 i = 1; i <= lastMarketId(); i += 1) {
            MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(i);

            assertEq(marketConfig.marketOrderMaxStaleDuration, orderMaxStaleDuration);
        }
    }
}
