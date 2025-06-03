pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { IOwnerUpgradeModule } from "../../../src/interfaces/IOwnerUpgradeModule.sol";
import { IOracleManagerProxy, NodeOutput, NodeDefinition } from "../../../src/interfaces/IOracleManagerProxy.sol";
import { IPassivePerpProxy, MarketConfigurationData } from "../../../src/interfaces/IPassivePerpProxy.sol";
import { IElixirSdeusd } from "../../../src/interfaces/IElixirSdeusd.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

import { ud } from "@prb/math/UD60x18.sol";

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
    uint256 meanPriceAPT;
    uint256 maxDeviationAPT;
    uint256 meanPriceBNB;
    uint256 maxDeviationBNB;
    uint256 meanPriceJTO;
    uint256 maxDeviationJTO;
    uint256 meanPriceADA;
    uint256 maxDeviationADA;
    uint256 meanPriceLDO;
    uint256 maxDeviationLDO;
    uint256 meanPricePOL;
    uint256 maxDeviationPOL;
    uint256 meanPriceNEAR;
    uint256 maxDeviationNEAR;
    uint256 meanPriceFTM;
    uint256 maxDeviationFTM;
    uint256 meanPriceENA;
    uint256 maxDeviationENA;
    uint256 meanPriceEIGEN;
    uint256 maxDeviationEIGEN;
    uint256 meanPricePENDLE;
    uint256 maxDeviationPENDLE;
    uint256 meanPriceGOAT;
    uint256 maxDeviationGOAT;
    uint256 meanPriceGRASS;
    uint256 maxDeviationGRASS;
    uint256 meanPriceKNEIRO;
    uint256 maxDeviationKNEIRO;
    uint256 meanPriceDOT;
    uint256 maxDeviationDOT;
    uint256 meanPriceLTC;
    uint256 maxDeviationLTC;
    uint256 meanPricePYTH;
    uint256 maxDeviationPYTH;
    uint256 meanPriceJUP;
    uint256 maxDeviationJUP;
    uint256 meanPricePENGU;
    uint256 maxDeviationPENGU;
    uint256 meanPriceTRUMP;
    uint256 maxDeviationTRUMP;
    uint256 meanPriceHYPE;
    uint256 maxDeviationHYPE;
    uint256 meanPriceVIRTUAL;
    uint256 maxDeviationVIRTUAL;
    uint256 meanPriceAI16Z;
    uint256 maxDeviationAI16Z;
    uint256 meanPriceAIXBT;
    uint256 maxDeviationAIXBT;
    uint256 meanPriceSONIC;
    uint256 maxDeviationSONIC;
    uint256 meanPriceFARTCOIN;
    uint256 maxDeviationFARTCOIN;
    uint256 meanPriceGRIFFAIN;
    uint256 maxDeviationGRIFFAIN;
    uint256 meanPriceWLD;
    uint256 maxDeviationWLD;
    uint256 meanPriceATOM;
    uint256 maxDeviationATOM;
    uint256 meanPriceAPE;
    uint256 maxDeviationAPE;
    uint256 meanPriceTON;
    uint256 maxDeviationTON;
    uint256 meanPriceONDO;
    uint256 maxDeviationONDO;
    uint256 meanPriceTRX;
    uint256 maxDeviationTRX;
    uint256 meanPriceINJ;
    uint256 maxDeviationINJ;
    uint256 meanPriceMOVE;
    uint256 maxDeviationMOVE;
    uint256 meanPriceBERA;
    uint256 maxDeviationBERA;
    uint256 meanPriceLAYER;
    uint256 maxDeviationLAYER;
    uint256 meanPriceTAO;
    uint256 maxDeviationTAO;
    uint256 meanPriceIP;
    uint256 maxDeviationIP;
    uint256 meanPriceME;
    uint256 maxDeviationME;
    uint256 meanPriceSUSDE;
    uint256 maxDeviationSUSDE;
    uint256 meanPriceDEUSD;
    uint256 maxDeviationDEUSD;
    uint256 meanPriceSDEUSD;
    uint256 maxDeviationSDEUSD;
    uint256 meanPriceRSELINI;
    uint256 maxDeviationRSELINI;
    uint256 meanPriceRAMBER;
    uint256 maxDeviationRAMBER;
    uint256 meanPriceRHEDGE;
    uint256 maxDeviationRHEDGE;
    uint256 meanPriceSRUSD;
    uint256 maxDeviationSRUSD;
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

        ls.meanPriceETH = 2650e18;
        ls.maxDeviationETH = 2000e18;
        ls.meanPriceMarket.push(ls.meanPriceETH);
        ls.maxDeviationMarket.push(ls.maxDeviationETH);

        ls.meanPriceBTC = 103_000e18;
        ls.maxDeviationBTC = 20_000e18;
        ls.meanPriceMarket.push(ls.meanPriceBTC);
        ls.maxDeviationMarket.push(ls.maxDeviationBTC);

        ls.meanPriceSOL = 160e18;
        ls.maxDeviationSOL = 70e18;
        ls.meanPriceMarket.push(ls.meanPriceSOL);
        ls.maxDeviationMarket.push(ls.maxDeviationSOL);

        ls.meanPriceARB = 0.4e18;
        ls.maxDeviationARB = 0.25e18;
        ls.meanPriceMarket.push(ls.meanPriceARB);
        ls.maxDeviationMarket.push(ls.maxDeviationARB);

        ls.meanPriceOP = 0.7e18;
        ls.maxDeviationOP = 0.5e18;
        ls.meanPriceMarket.push(ls.meanPriceOP);
        ls.maxDeviationMarket.push(ls.maxDeviationOP);

        ls.meanPriceAVAX = 25e18;
        ls.maxDeviationAVAX = 15e18;
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

        ls.meanPriceAAVE = 250e18;
        ls.maxDeviationAAVE = 150e18;
        ls.meanPriceMarket.push(ls.meanPriceAAVE);
        ls.maxDeviationMarket.push(ls.maxDeviationAAVE);

        ls.meanPriceCRV = 0.7e18;
        ls.maxDeviationCRV = 0.35e18;
        ls.meanPriceMarket.push(ls.meanPriceCRV);
        ls.maxDeviationMarket.push(ls.maxDeviationCRV);

        ls.meanPriceUNI = 6e18;
        ls.maxDeviationUNI = 4e18;
        ls.meanPriceMarket.push(ls.meanPriceUNI);
        ls.maxDeviationMarket.push(ls.maxDeviationUNI);

        ls.meanPriceSUI = 3.55e18;
        ls.maxDeviationSUI = 2e18;
        ls.meanPriceMarket.push(ls.meanPriceSUI);
        ls.maxDeviationMarket.push(ls.maxDeviationSUI);

        ls.meanPriceTIA = 2.8e18;
        ls.maxDeviationTIA = 2.5e18;
        ls.meanPriceMarket.push(ls.meanPriceTIA);
        ls.maxDeviationMarket.push(ls.maxDeviationTIA);

        ls.meanPriceSEI = 0.2e18;
        ls.maxDeviationSEI = 0.15e18;
        ls.meanPriceMarket.push(ls.meanPriceSEI);
        ls.maxDeviationMarket.push(ls.maxDeviationSEI);

        ls.meanPriceZRO = 2.75e18;
        ls.maxDeviationZRO = 1.5e18;
        ls.meanPriceMarket.push(ls.meanPriceZRO);
        ls.maxDeviationMarket.push(ls.maxDeviationZRO);

        ls.meanPriceXRP = 2.3e18;
        ls.maxDeviationXRP = 1.4e18;
        ls.meanPriceMarket.push(ls.meanPriceXRP);
        ls.maxDeviationMarket.push(ls.maxDeviationXRP);

        ls.meanPriceWIF = 1e18;
        ls.maxDeviationWIF = 0.5e18;
        ls.meanPriceMarket.push(ls.meanPriceWIF);
        ls.maxDeviationMarket.push(ls.maxDeviationWIF);

        ls.meanPrice1000PEPE = 0.013e18;
        ls.maxDeviation1000PEPE = 0.005e18;
        ls.meanPriceMarket.push(ls.meanPrice1000PEPE);
        ls.maxDeviationMarket.push(ls.maxDeviation1000PEPE);

        ls.meanPricePOPCAT = 0.42e18;
        ls.maxDeviationPOPCAT = 0.25e18;
        ls.meanPriceMarket.push(ls.meanPricePOPCAT);
        ls.maxDeviationMarket.push(ls.maxDeviationPOPCAT);

        ls.meanPriceDOGE = 0.2e18;
        ls.maxDeviationDOGE = 0.18e18;
        ls.meanPriceMarket.push(ls.meanPriceDOGE);
        ls.maxDeviationMarket.push(ls.maxDeviationDOGE);

        ls.meanPriceKSHIB = 0.013e18;
        ls.maxDeviationKSHIB = 0.006e18;
        ls.meanPriceMarket.push(ls.meanPriceKSHIB);
        ls.maxDeviationMarket.push(ls.maxDeviationKSHIB);

        ls.meanPriceKBONK = 0.02e18;
        ls.maxDeviationKBONK = 0.006e18;
        ls.meanPriceMarket.push(ls.meanPriceKBONK);
        ls.maxDeviationMarket.push(ls.maxDeviationKBONK);

        ls.meanPriceAPT = 5.6e18;
        ls.maxDeviationAPT = 4.5e18;
        ls.meanPriceMarket.push(ls.meanPriceAPT);
        ls.maxDeviationMarket.push(ls.maxDeviationAPT);

        ls.meanPriceBNB = 630e18;
        ls.maxDeviationBNB = 300e18;
        ls.meanPriceMarket.push(ls.meanPriceBNB);
        ls.maxDeviationMarket.push(ls.maxDeviationBNB);

        ls.meanPriceJTO = 1.9e18;
        ls.maxDeviationJTO = 1.1e18;
        ls.meanPriceMarket.push(ls.meanPriceJTO);
        ls.maxDeviationMarket.push(ls.maxDeviationJTO);

        ls.meanPriceADA = 0.78e18;
        ls.maxDeviationADA = 0.3e18;
        ls.meanPriceMarket.push(ls.meanPriceADA);
        ls.maxDeviationMarket.push(ls.maxDeviationADA);

        ls.meanPriceLDO = 1.01e18;
        ls.maxDeviationLDO = 0.6e18;
        ls.meanPriceMarket.push(ls.meanPriceLDO);
        ls.maxDeviationMarket.push(ls.maxDeviationLDO);

        ls.meanPricePOL = 0.25e18;
        ls.maxDeviationPOL = 0.12e18;
        ls.meanPriceMarket.push(ls.meanPricePOL);
        ls.maxDeviationMarket.push(ls.maxDeviationPOL);

        ls.meanPriceNEAR = 2.85e18;
        ls.maxDeviationNEAR = 1.4e18;
        ls.meanPriceMarket.push(ls.meanPriceNEAR);
        ls.maxDeviationMarket.push(ls.maxDeviationNEAR);

        // deprecated
        ls.meanPriceFTM = 0e18;
        ls.maxDeviationFTM = 0e18;
        ls.meanPriceMarket.push(ls.meanPriceFTM);
        ls.maxDeviationMarket.push(ls.maxDeviationFTM);

        ls.meanPriceENA = 0.36e18;
        ls.maxDeviationENA = 0.18e18;
        ls.meanPriceMarket.push(ls.meanPriceENA);
        ls.maxDeviationMarket.push(ls.maxDeviationENA);

        ls.meanPriceEIGEN = 1.6e18;
        ls.maxDeviationEIGEN = 0.75e18;
        ls.meanPriceMarket.push(ls.meanPriceEIGEN);
        ls.maxDeviationMarket.push(ls.maxDeviationEIGEN);

        ls.meanPricePENDLE = 4.3e18;
        ls.maxDeviationPENDLE = 2e18;
        ls.meanPriceMarket.push(ls.meanPricePENDLE);
        ls.maxDeviationMarket.push(ls.maxDeviationPENDLE);

        ls.meanPriceGOAT = 0.15e18;
        ls.maxDeviationGOAT = 0.05e18;
        ls.meanPriceMarket.push(ls.meanPriceGOAT);
        ls.maxDeviationMarket.push(ls.maxDeviationGOAT);

        ls.meanPriceGRASS = 2.11e18;
        ls.maxDeviationGRASS = 2e18;
        ls.meanPriceMarket.push(ls.meanPriceGRASS);
        ls.maxDeviationMarket.push(ls.maxDeviationGRASS);

        ls.meanPriceKNEIRO = 0.52e18;
        ls.maxDeviationKNEIRO = 0.25e18;
        ls.meanPriceMarket.push(ls.meanPriceKNEIRO);
        ls.maxDeviationMarket.push(ls.maxDeviationKNEIRO);

        ls.meanPriceDOT = 4.6e18;
        ls.maxDeviationDOT = 3e18;
        ls.meanPriceMarket.push(ls.meanPriceDOT);
        ls.maxDeviationMarket.push(ls.maxDeviationDOT);

        ls.meanPriceLTC = 98e18;
        ls.maxDeviationLTC = 60e18;
        ls.meanPriceMarket.push(ls.meanPriceLTC);
        ls.maxDeviationMarket.push(ls.maxDeviationLTC);

        ls.meanPricePYTH = 0.17e18;
        ls.maxDeviationPYTH = 0.15e18;
        ls.meanPriceMarket.push(ls.meanPricePYTH);
        ls.maxDeviationMarket.push(ls.maxDeviationPYTH);

        ls.meanPriceJUP = 0.5e18;
        ls.maxDeviationJUP = 0.48e18;
        ls.meanPriceMarket.push(ls.meanPriceJUP);
        ls.maxDeviationMarket.push(ls.maxDeviationJUP);

        ls.meanPricePENGU = 0.01e18;
        ls.maxDeviationPENGU = 0.005e18;
        ls.meanPriceMarket.push(ls.meanPricePENGU);
        ls.maxDeviationMarket.push(ls.maxDeviationPENGU);

        ls.meanPriceTRUMP = 12e18;
        ls.maxDeviationTRUMP = 7e18;
        ls.meanPriceMarket.push(ls.meanPriceTRUMP);
        ls.maxDeviationMarket.push(ls.maxDeviationTRUMP);

        ls.meanPriceHYPE = 32e18;
        ls.maxDeviationHYPE = 16e18;
        ls.meanPriceMarket.push(ls.meanPriceHYPE);
        ls.maxDeviationMarket.push(ls.maxDeviationHYPE);

        ls.meanPriceVIRTUAL = 2.01e18;
        ls.maxDeviationVIRTUAL = 1e18;
        ls.meanPriceMarket.push(ls.meanPriceVIRTUAL);
        ls.maxDeviationMarket.push(ls.maxDeviationVIRTUAL);

        ls.meanPriceAI16Z = 0.27e18;
        ls.maxDeviationAI16Z = 0.2e18;
        ls.meanPriceMarket.push(ls.meanPriceAI16Z);
        ls.maxDeviationMarket.push(ls.maxDeviationAI16Z);

        ls.meanPriceAIXBT = 0.22e18;
        ls.maxDeviationAIXBT = 0.1e18;
        ls.meanPriceMarket.push(ls.meanPriceAIXBT);
        ls.maxDeviationMarket.push(ls.maxDeviationAIXBT);

        ls.meanPriceSONIC = 0.44e18;
        ls.maxDeviationSONIC = 0.42e18;
        ls.meanPriceMarket.push(ls.meanPriceSONIC);
        ls.maxDeviationMarket.push(ls.maxDeviationSONIC);

        ls.meanPriceFARTCOIN = 1.3e18;
        ls.maxDeviationFARTCOIN = 0.65e18;
        ls.meanPriceMarket.push(ls.meanPriceFARTCOIN);
        ls.maxDeviationMarket.push(ls.maxDeviationFARTCOIN);

        ls.meanPriceGRIFFAIN = 0.08e18;
        ls.maxDeviationGRIFFAIN = 0.07e18;
        ls.meanPriceMarket.push(ls.meanPriceGRIFFAIN);
        ls.maxDeviationMarket.push(ls.maxDeviationGRIFFAIN);

        ls.meanPriceWLD = 1.32e18;
        ls.maxDeviationWLD = 0.8e18;
        ls.meanPriceMarket.push(ls.meanPriceWLD);
        ls.maxDeviationMarket.push(ls.maxDeviationWLD);

        ls.meanPriceATOM = 4.8e18;
        ls.maxDeviationATOM = 2.9e18;
        ls.meanPriceMarket.push(ls.meanPriceATOM);
        ls.maxDeviationMarket.push(ls.maxDeviationATOM);

        ls.meanPriceAPE = 0.7e18;
        ls.maxDeviationAPE = 0.45e18;
        ls.meanPriceMarket.push(ls.meanPriceAPE);
        ls.maxDeviationMarket.push(ls.maxDeviationAPE);

        ls.meanPriceTON = 3.2e18;
        ls.maxDeviationTON = 2.3e18;
        ls.meanPriceMarket.push(ls.meanPriceTON);
        ls.maxDeviationMarket.push(ls.maxDeviationTON);

        ls.meanPriceONDO = 0.9e18;
        ls.maxDeviationONDO = 0.7e18;
        ls.meanPriceMarket.push(ls.meanPriceONDO);
        ls.maxDeviationMarket.push(ls.maxDeviationONDO);

        ls.meanPriceTRX = 0.25e18;
        ls.maxDeviationTRX = 0.13e18;
        ls.meanPriceMarket.push(ls.meanPriceTRX);
        ls.maxDeviationMarket.push(ls.maxDeviationTRX);

        ls.meanPriceINJ = 14e18;
        ls.maxDeviationINJ = 9e18;
        ls.meanPriceMarket.push(ls.meanPriceINJ);
        ls.maxDeviationMarket.push(ls.maxDeviationINJ);

        ls.meanPriceMOVE = 0.17e18;
        ls.maxDeviationMOVE = 0.16e18;
        ls.meanPriceMarket.push(ls.meanPriceMOVE);
        ls.maxDeviationMarket.push(ls.maxDeviationMOVE);

        ls.meanPriceBERA = 2.8e18;
        ls.maxDeviationBERA = 2.6e18;
        ls.meanPriceMarket.push(ls.meanPriceBERA);
        ls.maxDeviationMarket.push(ls.maxDeviationBERA);

        // market is currently closed
        ls.meanPriceLAYER = 0.9e18;
        ls.maxDeviationLAYER = 0.7e18;
        ls.meanPriceMarket.push(ls.meanPriceLAYER);
        ls.maxDeviationMarket.push(ls.maxDeviationLAYER);

        ls.meanPriceTAO = 427e18;
        ls.maxDeviationTAO = 150e18;
        ls.meanPriceMarket.push(ls.meanPriceTAO);
        ls.maxDeviationMarket.push(ls.maxDeviationTAO);

        ls.meanPriceIP = 4.6e18;
        ls.maxDeviationIP = 2e18;
        ls.meanPriceMarket.push(ls.meanPriceIP);
        ls.maxDeviationMarket.push(ls.maxDeviationIP);

        ls.meanPriceME = 1.05e18;
        ls.maxDeviationME = 0.7e18;
        ls.meanPriceMarket.push(ls.meanPriceME);
        ls.maxDeviationMarket.push(ls.maxDeviationME);

        ls.meanPriceSUSDE = 1.17e18;
        ls.maxDeviationSUSDE = 0.05e18;

        ls.meanPriceRSELINI = 1.04e18;
        ls.maxDeviationRSELINI = 0.05e18;

        ls.meanPriceRAMBER = 1.04e18;
        ls.maxDeviationRAMBER = 0.05e18;

        if (sec.destinationChainId == 1) {
            ls.meanPriceSRUSD = 1.04e18;
            ls.maxDeviationSRUSD = 0.05e18;
        } else {
            ls.meanPriceSRUSD = 11.11e18;
            ls.maxDeviationSRUSD = 11e18;
        }

        ls.meanPriceRHEDGE = 1e18;
        ls.maxDeviationRHEDGE = 0.1e18;

        ls.meanPriceStableCoin = 1e18;
        ls.maxDeviationStableCoin = 0.01e18;

        ls.meanPriceSDEUSD = 1.03e18;
        ls.maxDeviationSDEUSD = 0.05e18;

        ls.nodeIds.push(sec.rusdUsdNodeId);
        ls.meanPrices.push(1e18);
        ls.maxDeviations.push(0);

        ls.nodeIds.push(sec.usdcUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin);

        ls.nodeIds.push(sec.ethUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceETH);
        ls.maxDeviations.push(ls.maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceETH);
        ls.maxDeviations.push(ls.maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceETH);
        ls.maxDeviations.push(ls.maxDeviationETH);

        ls.nodeIds.push(sec.ethUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceETH);
        ls.maxDeviations.push(ls.maxDeviationETH);

        ls.nodeIds.push(sec.btcUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceBTC);
        ls.maxDeviations.push(ls.maxDeviationBTC);

        ls.nodeIds.push(sec.btcUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceBTC);
        ls.maxDeviations.push(ls.maxDeviationBTC);

        ls.nodeIds.push(sec.solUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceSOL);
        ls.maxDeviations.push(ls.maxDeviationSOL);

        ls.nodeIds.push(sec.solUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceSOL);
        ls.maxDeviations.push(ls.maxDeviationSOL);

        ls.nodeIds.push(sec.arbUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceARB);
        ls.maxDeviations.push(ls.maxDeviationARB);

        ls.nodeIds.push(sec.arbUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceARB);
        ls.maxDeviations.push(ls.maxDeviationARB);

        ls.nodeIds.push(sec.opUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceOP);
        ls.maxDeviations.push(ls.maxDeviationOP);

        ls.nodeIds.push(sec.opUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceOP);
        ls.maxDeviations.push(ls.maxDeviationOP);

        ls.nodeIds.push(sec.avaxUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAVAX);
        ls.maxDeviations.push(ls.maxDeviationAVAX);

        ls.nodeIds.push(sec.avaxUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAVAX);
        ls.maxDeviations.push(ls.maxDeviationAVAX);

        ls.nodeIds.push(sec.usdeUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.usdeUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.mkrUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceMKR);
        ls.maxDeviations.push(ls.maxDeviationMKR);

        ls.nodeIds.push(sec.mkrUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceMKR);
        ls.maxDeviations.push(ls.maxDeviationMKR);

        ls.nodeIds.push(sec.linkUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceLINK);
        ls.maxDeviations.push(ls.maxDeviationLINK);

        ls.nodeIds.push(sec.linkUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceLINK);
        ls.maxDeviations.push(ls.maxDeviationLINK);

        ls.nodeIds.push(sec.aaveUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAAVE);
        ls.maxDeviations.push(ls.maxDeviationAAVE);

        ls.nodeIds.push(sec.aaveUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAAVE);
        ls.maxDeviations.push(ls.maxDeviationAAVE);

        ls.nodeIds.push(sec.crvUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceCRV);
        ls.maxDeviations.push(ls.maxDeviationCRV);

        ls.nodeIds.push(sec.crvUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceCRV);
        ls.maxDeviations.push(ls.maxDeviationCRV);

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

        ls.nodeIds.push(sec.popcatUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPricePOPCAT);
        ls.maxDeviations.push(ls.maxDeviationPOPCAT);

        ls.nodeIds.push(sec.popcatUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPricePOPCAT);
        ls.maxDeviations.push(ls.maxDeviationPOPCAT);

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

        ls.nodeIds.push(sec.aptUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAPT);
        ls.maxDeviations.push(ls.maxDeviationAPT);

        ls.nodeIds.push(sec.aptUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAPT);
        ls.maxDeviations.push(ls.maxDeviationAPT);

        ls.nodeIds.push(sec.bnbUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceBNB);
        ls.maxDeviations.push(ls.maxDeviationBNB);

        ls.nodeIds.push(sec.bnbUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceBNB);
        ls.maxDeviations.push(ls.maxDeviationBNB);

        ls.nodeIds.push(sec.jtoUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceJTO);
        ls.maxDeviations.push(ls.maxDeviationJTO);

        ls.nodeIds.push(sec.jtoUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceJTO);
        ls.maxDeviations.push(ls.maxDeviationJTO);

        ls.nodeIds.push(sec.adaUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceADA);
        ls.maxDeviations.push(ls.maxDeviationADA);

        ls.nodeIds.push(sec.adaUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceADA);
        ls.maxDeviations.push(ls.maxDeviationADA);

        ls.nodeIds.push(sec.ldoUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceLDO);
        ls.maxDeviations.push(ls.maxDeviationLDO);

        ls.nodeIds.push(sec.ldoUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceLDO);
        ls.maxDeviations.push(ls.maxDeviationLDO);

        ls.nodeIds.push(sec.polUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPricePOL);
        ls.maxDeviations.push(ls.maxDeviationPOL);

        ls.nodeIds.push(sec.polUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPricePOL);
        ls.maxDeviations.push(ls.maxDeviationPOL);

        ls.nodeIds.push(sec.nearUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceNEAR);
        ls.maxDeviations.push(ls.maxDeviationNEAR);

        ls.nodeIds.push(sec.nearUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceNEAR);
        ls.maxDeviations.push(ls.maxDeviationNEAR);

        // deprecated
        // ls.nodeIds.push(sec.ftmUsdStorkNodeId);
        // ls.meanPrices.push(0);
        // ls.maxDeviations.push(0);

        // deprecated
        // ls.nodeIds.push(sec.ftmUsdcStorkNodeId);
        // ls.meanPrices.push(0);
        // ls.maxDeviations.push(0);

        ls.nodeIds.push(sec.enaUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceENA);
        ls.maxDeviations.push(ls.maxDeviationENA);

        ls.nodeIds.push(sec.enaUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceENA);
        ls.maxDeviations.push(ls.maxDeviationENA);

        ls.nodeIds.push(sec.eigenUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceEIGEN);
        ls.maxDeviations.push(ls.maxDeviationEIGEN);

        ls.nodeIds.push(sec.eigenUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceEIGEN);
        ls.maxDeviations.push(ls.maxDeviationEIGEN);

        ls.nodeIds.push(sec.pendleUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPricePENDLE);
        ls.maxDeviations.push(ls.maxDeviationPENDLE);

        ls.nodeIds.push(sec.pendleUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPricePENDLE);
        ls.maxDeviations.push(ls.maxDeviationPENDLE);

        ls.nodeIds.push(sec.goatUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceGOAT);
        ls.maxDeviations.push(ls.maxDeviationGOAT);

        ls.nodeIds.push(sec.goatUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceGOAT);
        ls.maxDeviations.push(ls.maxDeviationGOAT);

        ls.nodeIds.push(sec.grassUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceGRASS);
        ls.maxDeviations.push(ls.maxDeviationGRASS);

        ls.nodeIds.push(sec.grassUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceGRASS);
        ls.maxDeviations.push(ls.maxDeviationGRASS);

        ls.nodeIds.push(sec.kneiroUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceKNEIRO);
        ls.maxDeviations.push(ls.maxDeviationKNEIRO);

        ls.nodeIds.push(sec.kneiroUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceKNEIRO);
        ls.maxDeviations.push(ls.maxDeviationKNEIRO);

        ls.nodeIds.push(sec.dotUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceDOT);
        ls.maxDeviations.push(ls.maxDeviationDOT);

        ls.nodeIds.push(sec.dotUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceDOT);
        ls.maxDeviations.push(ls.maxDeviationDOT);

        ls.nodeIds.push(sec.ltcUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceLTC);
        ls.maxDeviations.push(ls.maxDeviationLTC);

        ls.nodeIds.push(sec.ltcUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceLTC);
        ls.maxDeviations.push(ls.maxDeviationLTC);

        ls.nodeIds.push(sec.pythUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPricePYTH);
        ls.maxDeviations.push(ls.maxDeviationPYTH);

        ls.nodeIds.push(sec.pythUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPricePYTH);
        ls.maxDeviations.push(ls.maxDeviationPYTH);

        ls.nodeIds.push(sec.jupUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceJUP);
        ls.maxDeviations.push(ls.maxDeviationJUP);

        ls.nodeIds.push(sec.jupUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceJUP);
        ls.maxDeviations.push(ls.maxDeviationJUP);

        ls.nodeIds.push(sec.penguUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPricePENGU);
        ls.maxDeviations.push(ls.maxDeviationPENGU);

        ls.nodeIds.push(sec.penguUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPricePENGU);
        ls.maxDeviations.push(ls.maxDeviationPENGU);

        ls.nodeIds.push(sec.trumpUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceTRUMP);
        ls.maxDeviations.push(ls.maxDeviationTRUMP);

        ls.nodeIds.push(sec.trumpUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceTRUMP);
        ls.maxDeviations.push(ls.maxDeviationTRUMP);

        ls.nodeIds.push(sec.hypeUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceHYPE);
        ls.maxDeviations.push(ls.maxDeviationHYPE);

        ls.nodeIds.push(sec.hypeUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceHYPE);
        ls.maxDeviations.push(ls.maxDeviationHYPE);

        ls.nodeIds.push(sec.virtualUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceVIRTUAL);
        ls.maxDeviations.push(ls.maxDeviationVIRTUAL);

        ls.nodeIds.push(sec.virtualUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceVIRTUAL);
        ls.maxDeviations.push(ls.maxDeviationVIRTUAL);

        ls.nodeIds.push(sec.ai16zUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAI16Z);
        ls.maxDeviations.push(ls.maxDeviationAI16Z);

        ls.nodeIds.push(sec.ai16zUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAI16Z);
        ls.maxDeviations.push(ls.maxDeviationAI16Z);

        ls.nodeIds.push(sec.aixbtUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAIXBT);
        ls.maxDeviations.push(ls.maxDeviationAIXBT);

        ls.nodeIds.push(sec.aixbtUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAIXBT);
        ls.maxDeviations.push(ls.maxDeviationAIXBT);

        ls.nodeIds.push(sec.sonicUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceSONIC);
        ls.maxDeviations.push(ls.maxDeviationSONIC);

        ls.nodeIds.push(sec.sonicUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceSONIC);
        ls.maxDeviations.push(ls.maxDeviationSONIC);

        ls.nodeIds.push(sec.fartcoinUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceFARTCOIN);
        ls.maxDeviations.push(ls.maxDeviationFARTCOIN);

        ls.nodeIds.push(sec.fartcoinUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceFARTCOIN);
        ls.maxDeviations.push(ls.maxDeviationFARTCOIN);

        ls.nodeIds.push(sec.griffainUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceGRIFFAIN);
        ls.maxDeviations.push(ls.maxDeviationGRIFFAIN);

        ls.nodeIds.push(sec.griffainUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceGRIFFAIN);
        ls.maxDeviations.push(ls.maxDeviationGRIFFAIN);

        ls.nodeIds.push(sec.wldUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceWLD);
        ls.maxDeviations.push(ls.maxDeviationWLD);

        ls.nodeIds.push(sec.wldUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceWLD);
        ls.maxDeviations.push(ls.maxDeviationWLD);

        ls.nodeIds.push(sec.atomUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceATOM);
        ls.maxDeviations.push(ls.maxDeviationATOM);

        ls.nodeIds.push(sec.atomUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceATOM);
        ls.maxDeviations.push(ls.maxDeviationATOM);

        ls.nodeIds.push(sec.apeUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAPE);
        ls.maxDeviations.push(ls.maxDeviationAPE);

        ls.nodeIds.push(sec.apeUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceAPE);
        ls.maxDeviations.push(ls.maxDeviationAPE);

        ls.nodeIds.push(sec.tonUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceTON);
        ls.maxDeviations.push(ls.maxDeviationTON);

        ls.nodeIds.push(sec.tonUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceTON);
        ls.maxDeviations.push(ls.maxDeviationTON);

        ls.nodeIds.push(sec.ondoUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceONDO);
        ls.maxDeviations.push(ls.maxDeviationONDO);

        ls.nodeIds.push(sec.ondoUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceONDO);
        ls.maxDeviations.push(ls.maxDeviationONDO);

        ls.nodeIds.push(sec.trxUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceTRX);
        ls.maxDeviations.push(ls.maxDeviationTRX);

        ls.nodeIds.push(sec.trxUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceTRX);
        ls.maxDeviations.push(ls.maxDeviationTRX);

        ls.nodeIds.push(sec.injUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceINJ);
        ls.maxDeviations.push(ls.maxDeviationINJ);

        ls.nodeIds.push(sec.injUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceINJ);
        ls.maxDeviations.push(ls.maxDeviationINJ);

        ls.nodeIds.push(sec.moveUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceMOVE);
        ls.maxDeviations.push(ls.maxDeviationMOVE);

        ls.nodeIds.push(sec.moveUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceMOVE);
        ls.maxDeviations.push(ls.maxDeviationMOVE);

        ls.nodeIds.push(sec.beraUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceBERA);
        ls.maxDeviations.push(ls.maxDeviationBERA);

        ls.nodeIds.push(sec.beraUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceBERA);
        ls.maxDeviations.push(ls.maxDeviationBERA);

        ls.nodeIds.push(sec.layerUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceLAYER);
        ls.maxDeviations.push(ls.maxDeviationLAYER);

        ls.nodeIds.push(sec.layerUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceLAYER);
        ls.maxDeviations.push(ls.maxDeviationLAYER);

        ls.nodeIds.push(sec.taoUsdStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceTAO);
        ls.maxDeviations.push(ls.maxDeviationTAO);

        ls.nodeIds.push(sec.taoUsdcStorkMarkNodeId);
        ls.meanPrices.push(ls.meanPriceTAO);
        ls.maxDeviations.push(ls.maxDeviationTAO);

        ls.nodeIds.push(sec.ipUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceIP);
        ls.maxDeviations.push(ls.maxDeviationIP);

        ls.nodeIds.push(sec.ipUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceIP);
        ls.maxDeviations.push(ls.maxDeviationIP);

        ls.nodeIds.push(sec.meUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceME);
        ls.maxDeviations.push(ls.maxDeviationME);

        ls.nodeIds.push(sec.meUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceME);
        ls.maxDeviations.push(ls.maxDeviationME);

        ls.nodeIds.push(sec.susdeUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceSUSDE);
        ls.maxDeviations.push(ls.maxDeviationSUSDE);

        ls.nodeIds.push(sec.susdeUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceSUSDE);
        ls.maxDeviations.push(ls.maxDeviationSUSDE);

        ls.nodeIds.push(sec.deusdUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.deusdUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceStableCoin);
        ls.maxDeviations.push(ls.maxDeviationStableCoin * 2);

        ls.nodeIds.push(sec.sdeusdDeusdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceSDEUSD);
        ls.maxDeviations.push(ls.maxDeviationSDEUSD);

        ls.nodeIds.push(sec.sdeusdUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceSDEUSD);
        ls.maxDeviations.push(ls.maxDeviationSDEUSD);

        ls.nodeIds.push(sec.rseliniUsdcReyaLmNodeId);
        ls.meanPrices.push(ls.meanPriceRSELINI);
        ls.maxDeviations.push(ls.maxDeviationRSELINI);

        ls.nodeIds.push(sec.ramberUsdcReyaLmNodeId);
        ls.meanPrices.push(ls.meanPriceRAMBER);
        ls.maxDeviations.push(ls.maxDeviationRAMBER);

        ls.nodeIds.push(sec.rhedgeUsdcReyaLmNodeId);
        ls.meanPrices.push(ls.meanPriceRHEDGE);
        ls.maxDeviations.push(ls.maxDeviationRHEDGE);

        ls.nodeIds.push(sec.srusdUsdcPoolNodeId);
        ls.meanPrices.push(ls.meanPriceSRUSD);
        ls.maxDeviations.push(ls.maxDeviationSRUSD);
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
        }
    }

    function check_marketsPrices() public {
        setupOracleNodePriceParams();
        for (uint128 i = lastMarketId(); i >= 1; i--) {
            // FTM and LAYER are currently out of circuit
            bool inactiveMarket = i == 30 || i == 59;

            if (inactiveMarket) {
                continue;
            }

            MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(i);
            bytes32 nodeId = marketConfig.oracleNodeId;

            NodeOutput.Data memory nodeOutput = IOracleManagerProxy(sec.oracleManager).process(nodeId);

            assertApproxEqAbsDecimal(nodeOutput.price, ls.meanPriceMarket[i], ls.maxDeviationMarket[i], 18);
        }
    }

    function check_marketsOrderMaxStaleDuration(uint256 orderMaxStaleDuration) public view {
        for (uint128 i = lastMarketId(); i >= 1; i--) {
            MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(i);

            // FTM and LAYER are currently out of circuit
            bool inactiveMarket = i == 30 || i == 59;

            if (!inactiveMarket) {
                assertEq(marketConfig.marketOrderMaxStaleDuration, orderMaxStaleDuration);
            }
        }
    }

    function check_sdeusd_price() public view {
        NodeOutput.Data memory sdeusdUsdcOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.sdeusdUsdcStorkNodeId);

        NodeOutput.Data memory sdeusdDeusdOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.sdeusdDeusdStorkNodeId);

        NodeOutput.Data memory deusdUsdcOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.deusdUsdcStorkNodeId);

        uint256 reconstructedSdeusdUsdcPrice = ud(sdeusdDeusdOutput.price).mul(ud(deusdUsdcOutput.price)).unwrap();
        assertApproxEqAbsDecimal(sdeusdUsdcOutput.price, reconstructedSdeusdUsdcPrice, 10, 18);
    }

    function check_sdeusd_deusd_price() public {
        NodeOutput.Data memory sdeusdDeusdOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.sdeusdDeusdStorkNodeId);

        vm.createSelectFork(sec.MAINNET_RPC);
        uint256 originalSdeusdDeusdPrice = IElixirSdeusd(sec.elixirSdeusd).convertToAssets(1e18);

        assertLe(sdeusdDeusdOutput.price, originalSdeusdDeusdPrice);
    }

    function check_periphery_srusd_balance() public view {
        assertEq(ITokenProxy(sec.srusd).balanceOf(sec.periphery), 0);
    }
}
