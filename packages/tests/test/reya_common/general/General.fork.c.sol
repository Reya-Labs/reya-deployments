pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { IOwnerUpgradeModule } from "../../../src/interfaces/IOwnerUpgradeModule.sol";
import { IOracleManagerProxy, NodeOutput, NodeDefinition } from "../../../src/interfaces/IOracleManagerProxy.sol";
import { IPassivePerpProxy, MarketConfigurationData } from "../../../src/interfaces/IPassivePerpProxy.sol";
import { IElixirSdeusd } from "../../../src/interfaces/IElixirSdeusd.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";
import { uintToString, bytes32ToHexString } from "../../../src/utils/ToString.sol";

import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";

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
    uint256 meanPricePUMP;
    uint256 maxDeviationPUMP;
    uint256 meanPriceMORPHO;
    uint256 maxDeviationMORPHO;
    uint256 meanPriceSYRUP;
    uint256 maxDeviationSYRUP;
    uint256 meanPriceAERO;
    uint256 maxDeviationAERO;
    uint256 meanPriceKAITO;
    uint256 maxDeviationKAITO;
    uint256 meanPriceZORA;
    uint256 maxDeviationZORA;
    uint256 meanPricePROVE;
    uint256 maxDeviationPROVE;
    uint256 meanPricePAXG;
    uint256 maxDeviationPAXG;
    uint256 meanPriceYZY;
    uint256 maxDeviationYZY;
    uint256 meanPriceXPL;
    uint256 maxDeviationXPL;
    uint256 meanPriceWLFI;
    uint256 maxDeviationWLFI;
    uint256 meanPriceLINEA;
    uint256 maxDeviationLINEA;
    uint256 meanPriceMEGA;
    uint256 maxDeviationMEGA;
    uint256 meanPriceSUSDE;
    uint256 maxDeviationSUSDE;
    uint256 meanPriceWSTETH;
    uint256 maxDeviationWSTETH;
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

        ls.meanPriceETH = 3040 * 1e18;
        ls.maxDeviationETH = ls.meanPriceETH / 2;
        ls.meanPriceMarket.push(ls.meanPriceETH);
        ls.maxDeviationMarket.push(ls.maxDeviationETH);

        ls.meanPriceBTC = 90000 * 1e18;
        ls.maxDeviationBTC = ls.meanPriceBTC / 2;
        ls.meanPriceMarket.push(ls.meanPriceBTC);
        ls.maxDeviationMarket.push(ls.maxDeviationBTC);

        ls.meanPriceSOL = 132 * 1e18;
        ls.maxDeviationSOL = ls.meanPriceSOL / 2;
        ls.meanPriceMarket.push(ls.meanPriceSOL);
        ls.maxDeviationMarket.push(ls.maxDeviationSOL);

        ls.meanPriceARB = 0.2 * 1e18;
        ls.maxDeviationARB = ls.meanPriceARB / 2;
        ls.meanPriceMarket.push(ls.meanPriceARB);
        ls.maxDeviationMarket.push(ls.maxDeviationARB);

        ls.meanPriceOP = 0.31 * 1e18;
        ls.maxDeviationOP = ls.meanPriceOP / 2;
        ls.meanPriceMarket.push(ls.meanPriceOP);
        ls.maxDeviationMarket.push(ls.maxDeviationOP);

        ls.meanPriceAVAX = 13.358 * 1e18;
        ls.maxDeviationAVAX = ls.meanPriceAVAX / 2;
        ls.meanPriceMarket.push(ls.meanPriceAVAX);
        ls.maxDeviationMarket.push(ls.maxDeviationAVAX);

        ls.meanPriceMKR = 1847 * 1e18;
        ls.maxDeviationMKR = ls.meanPriceMKR / 2;
        ls.meanPriceMarket.push(ls.meanPriceMKR);
        ls.maxDeviationMarket.push(ls.maxDeviationMKR);

        ls.meanPriceLINK = 13.8 * 1e18;
        ls.maxDeviationLINK = ls.meanPriceLINK / 2;
        ls.meanPriceMarket.push(ls.meanPriceLINK);
        ls.maxDeviationMarket.push(ls.maxDeviationLINK);

        ls.meanPriceAAVE = 188 * 1e18;
        ls.maxDeviationAAVE = ls.meanPriceAAVE / 2;
        ls.meanPriceMarket.push(ls.meanPriceAAVE);
        ls.maxDeviationMarket.push(ls.maxDeviationAAVE);

        ls.meanPriceCRV = 0.38 * 1e18;
        ls.maxDeviationCRV = ls.meanPriceCRV / 2;
        ls.meanPriceMarket.push(ls.meanPriceCRV);
        ls.maxDeviationMarket.push(ls.maxDeviationCRV);

        ls.meanPriceUNI = 5.5 * 1e18;
        ls.maxDeviationUNI = ls.meanPriceUNI / 2;
        ls.meanPriceMarket.push(ls.meanPriceUNI);
        ls.maxDeviationMarket.push(ls.maxDeviationUNI);

        ls.meanPriceSUI = 1.57 * 1e18;
        ls.maxDeviationSUI = ls.meanPriceSUI / 2;
        ls.meanPriceMarket.push(ls.meanPriceSUI);
        ls.maxDeviationMarket.push(ls.maxDeviationSUI);

        ls.meanPriceTIA = 0.57 * 1e18;
        ls.maxDeviationTIA = ls.meanPriceTIA / 2;
        ls.meanPriceMarket.push(ls.meanPriceTIA);
        ls.maxDeviationMarket.push(ls.maxDeviationTIA);

        ls.meanPriceSEI = 0.12 * 1e18;
        ls.maxDeviationSEI = ls.meanPriceSEI / 2;
        ls.meanPriceMarket.push(ls.meanPriceSEI);
        ls.maxDeviationMarket.push(ls.maxDeviationSEI);

        ls.meanPriceZRO = 1.38 * 1e18;
        ls.maxDeviationZRO = ls.meanPriceZRO / 2;
        ls.meanPriceMarket.push(ls.meanPriceZRO);
        ls.maxDeviationMarket.push(ls.maxDeviationZRO);

        ls.meanPriceXRP = 2.04 * 1e18;
        ls.maxDeviationXRP = ls.meanPriceXRP / 2;
        ls.meanPriceMarket.push(ls.meanPriceXRP);
        ls.maxDeviationMarket.push(ls.maxDeviationXRP);

        ls.meanPriceWIF = 0.37 * 1e18;
        ls.maxDeviationWIF = ls.meanPriceWIF / 2;
        ls.meanPriceMarket.push(ls.meanPriceWIF);
        ls.maxDeviationMarket.push(ls.maxDeviationWIF);

        ls.meanPrice1000PEPE = 0.0044 * 1e18;
        ls.maxDeviation1000PEPE = ls.meanPrice1000PEPE / 2;
        ls.meanPriceMarket.push(ls.meanPrice1000PEPE);
        ls.maxDeviationMarket.push(ls.maxDeviation1000PEPE);

        ls.meanPricePOPCAT = 0.1 * 1e18;
        ls.maxDeviationPOPCAT = ls.meanPricePOPCAT / 2;
        ls.meanPriceMarket.push(ls.meanPricePOPCAT);
        ls.maxDeviationMarket.push(ls.maxDeviationPOPCAT);

        ls.meanPriceDOGE = 0.14 * 1e18;
        ls.maxDeviationDOGE = ls.meanPriceDOGE / 2;
        ls.meanPriceMarket.push(ls.meanPriceDOGE);
        ls.maxDeviationMarket.push(ls.maxDeviationDOGE);

        ls.meanPriceKSHIB = 0.008 * 1e18;
        ls.maxDeviationKSHIB = ls.meanPriceKSHIB / 2;
        ls.meanPriceMarket.push(ls.meanPriceKSHIB);
        ls.maxDeviationMarket.push(ls.maxDeviationKSHIB);

        ls.meanPriceKBONK = 0.009 * 1e18;
        ls.maxDeviationKBONK = ls.meanPriceKBONK / 2;
        ls.meanPriceMarket.push(ls.meanPriceKBONK);
        ls.maxDeviationMarket.push(ls.maxDeviationKBONK);

        ls.meanPriceAPT = 1.71 * 1e18;
        ls.maxDeviationAPT = ls.meanPriceAPT / 2;
        ls.meanPriceMarket.push(ls.meanPriceAPT);
        ls.maxDeviationMarket.push(ls.maxDeviationAPT);

        ls.meanPriceBNB = 890 * 1e18;
        ls.maxDeviationBNB = ls.meanPriceBNB / 2;
        ls.meanPriceMarket.push(ls.meanPriceBNB);
        ls.maxDeviationMarket.push(ls.maxDeviationBNB);

        ls.meanPriceJTO = 0.44 * 1e18;
        ls.maxDeviationJTO = ls.meanPriceJTO / 2;
        ls.meanPriceMarket.push(ls.meanPriceJTO);
        ls.maxDeviationMarket.push(ls.maxDeviationJTO);

        ls.meanPriceADA = 0.41 * 1e18;
        ls.maxDeviationADA = ls.meanPriceADA / 2;
        ls.meanPriceMarket.push(ls.meanPriceADA);
        ls.maxDeviationMarket.push(ls.maxDeviationADA);

        ls.meanPriceLDO = 0.58 * 1e18;
        ls.maxDeviationLDO = ls.meanPriceLDO / 2;
        ls.meanPriceMarket.push(ls.meanPriceLDO);
        ls.maxDeviationMarket.push(ls.maxDeviationLDO);

        ls.meanPricePOL = 0.12 * 1e18;
        ls.maxDeviationPOL = ls.meanPricePOL / 2;
        ls.meanPriceMarket.push(ls.meanPricePOL);
        ls.maxDeviationMarket.push(ls.maxDeviationPOL);

        ls.meanPriceNEAR = 1.68 * 1e18;
        ls.maxDeviationNEAR = ls.meanPriceNEAR / 2;
        ls.meanPriceMarket.push(ls.meanPriceNEAR);
        ls.maxDeviationMarket.push(ls.maxDeviationNEAR);

        // deprecated
        ls.meanPriceFTM = 0;
        ls.maxDeviationFTM = ls.meanPriceFTM / 2;
        ls.meanPriceMarket.push(ls.meanPriceFTM);
        ls.maxDeviationMarket.push(ls.maxDeviationFTM);

        ls.meanPriceENA = 0.25 * 1e18;
        ls.maxDeviationENA = ls.meanPriceENA / 2;
        ls.meanPriceMarket.push(ls.meanPriceENA);
        ls.maxDeviationMarket.push(ls.maxDeviationENA);

        ls.meanPriceEIGEN = 0.5 * 1e18;
        ls.maxDeviationEIGEN = ls.meanPriceEIGEN / 2;
        ls.meanPriceMarket.push(ls.meanPriceEIGEN);
        ls.maxDeviationMarket.push(ls.maxDeviationEIGEN);

        ls.meanPricePENDLE = 2.4 * 1e18;
        ls.maxDeviationPENDLE = ls.meanPricePENDLE / 2;
        ls.meanPriceMarket.push(ls.meanPricePENDLE);
        ls.maxDeviationMarket.push(ls.maxDeviationPENDLE);

        ls.meanPriceGOAT = 0.04 * 1e18;
        ls.maxDeviationGOAT = ls.meanPriceGOAT / 2;
        ls.meanPriceMarket.push(ls.meanPriceGOAT);
        ls.maxDeviationMarket.push(ls.maxDeviationGOAT);

        ls.meanPriceGRASS = 0.32 * 1e18;
        ls.maxDeviationGRASS = ls.meanPriceGRASS / 2;
        ls.meanPriceMarket.push(ls.meanPriceGRASS);
        ls.maxDeviationMarket.push(ls.maxDeviationGRASS);

        ls.meanPriceKNEIRO = 0.13 * 1e18;
        ls.maxDeviationKNEIRO = ls.meanPriceKNEIRO / 2;
        ls.meanPriceMarket.push(ls.meanPriceKNEIRO);
        ls.maxDeviationMarket.push(ls.maxDeviationKNEIRO);

        ls.meanPriceDOT = 2.09 * 1e18;
        ls.maxDeviationDOT = ls.meanPriceDOT / 2;
        ls.meanPriceMarket.push(ls.meanPriceDOT);
        ls.maxDeviationMarket.push(ls.maxDeviationDOT);

        ls.meanPriceLTC = 82 * 1e18;
        ls.maxDeviationLTC = ls.meanPriceLTC / 2;
        ls.meanPriceMarket.push(ls.meanPriceLTC);
        ls.maxDeviationMarket.push(ls.maxDeviationLTC);

        ls.meanPricePYTH = 0.07 * 1e18;
        ls.maxDeviationPYTH = ls.meanPricePYTH / 2;
        ls.meanPriceMarket.push(ls.meanPricePYTH);
        ls.maxDeviationMarket.push(ls.maxDeviationPYTH);

        ls.meanPriceJUP = 0.22 * 1e18;
        ls.maxDeviationJUP = ls.meanPriceJUP / 2;
        ls.meanPriceMarket.push(ls.meanPriceJUP);
        ls.maxDeviationMarket.push(ls.maxDeviationJUP);

        ls.meanPricePENGU = 0.012 * 1e18;
        ls.maxDeviationPENGU = ls.meanPricePENGU / 2;
        ls.meanPriceMarket.push(ls.meanPricePENGU);
        ls.maxDeviationMarket.push(ls.maxDeviationPENGU);

        ls.meanPriceTRUMP = 5.66 * 1e18;
        ls.maxDeviationTRUMP = ls.meanPriceTRUMP / 2;
        ls.meanPriceMarket.push(ls.meanPriceTRUMP);
        ls.maxDeviationMarket.push(ls.maxDeviationTRUMP);

        ls.meanPriceHYPE = 30 * 1e18;
        ls.maxDeviationHYPE = ls.meanPriceHYPE / 2;
        ls.meanPriceMarket.push(ls.meanPriceHYPE);
        ls.maxDeviationMarket.push(ls.maxDeviationHYPE);

        ls.meanPriceVIRTUAL = 0.83 * 1e18;
        ls.maxDeviationVIRTUAL = ls.meanPriceVIRTUAL / 2;
        ls.meanPriceMarket.push(ls.meanPriceVIRTUAL);
        ls.maxDeviationMarket.push(ls.maxDeviationVIRTUAL);

        ls.meanPriceAI16Z = 0.035 * 1e18;
        ls.maxDeviationAI16Z = ls.meanPriceAI16Z / 2;
        ls.meanPriceMarket.push(ls.meanPriceAI16Z);
        ls.maxDeviationMarket.push(ls.maxDeviationAI16Z);

        ls.meanPriceAIXBT = 0.04 * 1e18;
        ls.maxDeviationAIXBT = ls.meanPriceAIXBT / 2;
        ls.meanPriceMarket.push(ls.meanPriceAIXBT);
        ls.maxDeviationMarket.push(ls.maxDeviationAIXBT);

        ls.meanPriceSONIC = 0.1 * 1e18;
        ls.maxDeviationSONIC = ls.meanPriceSONIC / 2;
        ls.meanPriceMarket.push(ls.meanPriceSONIC);
        ls.maxDeviationMarket.push(ls.maxDeviationSONIC);

        ls.meanPriceFARTCOIN = 0.36 * 1e18;
        ls.maxDeviationFARTCOIN = ls.meanPriceFARTCOIN / 2;
        ls.meanPriceMarket.push(ls.meanPriceFARTCOIN);
        ls.maxDeviationMarket.push(ls.maxDeviationFARTCOIN);

        ls.meanPriceGRIFFAIN = 0.021 * 1e18;
        ls.maxDeviationGRIFFAIN = ls.meanPriceGRIFFAIN / 2;
        ls.meanPriceMarket.push(ls.meanPriceGRIFFAIN);
        ls.maxDeviationMarket.push(ls.maxDeviationGRIFFAIN);

        ls.meanPriceWLD = 0.57 * 1e18;
        ls.maxDeviationWLD = ls.meanPriceWLD / 2;
        ls.meanPriceMarket.push(ls.meanPriceWLD);
        ls.maxDeviationMarket.push(ls.maxDeviationWLD);

        ls.meanPriceATOM = 2.2 * 1e18;
        ls.maxDeviationATOM = ls.meanPriceATOM / 2;
        ls.meanPriceMarket.push(ls.meanPriceATOM);
        ls.maxDeviationMarket.push(ls.maxDeviationATOM);

        ls.meanPriceAPE = 0.23 * 1e18;
        ls.maxDeviationAPE = ls.meanPriceAPE / 2;
        ls.meanPriceMarket.push(ls.meanPriceAPE);
        ls.maxDeviationMarket.push(ls.maxDeviationAPE);

        ls.meanPriceTON = 1.6 * 1e18;
        ls.maxDeviationTON = ls.meanPriceTON / 2;
        ls.meanPriceMarket.push(ls.meanPriceTON);
        ls.maxDeviationMarket.push(ls.maxDeviationTON);

        ls.meanPriceONDO = 0.46 * 1e18;
        ls.maxDeviationONDO = ls.meanPriceONDO / 2;
        ls.meanPriceMarket.push(ls.meanPriceONDO);
        ls.maxDeviationMarket.push(ls.maxDeviationONDO);

        ls.meanPriceTRX = 0.28 * 1e18;
        ls.maxDeviationTRX = ls.meanPriceTRX / 2;
        ls.meanPriceMarket.push(ls.meanPriceTRX);
        ls.maxDeviationMarket.push(ls.maxDeviationTRX);

        ls.meanPriceINJ = 4.48 * 1e18;
        ls.maxDeviationINJ = ls.meanPriceINJ / 2;
        ls.meanPriceMarket.push(ls.meanPriceINJ);
        ls.maxDeviationMarket.push(ls.maxDeviationINJ);

        ls.meanPriceMOVE = 0.04 * 1e18;
        ls.maxDeviationMOVE = ls.meanPriceMOVE / 2;
        ls.meanPriceMarket.push(ls.meanPriceMOVE);
        ls.maxDeviationMarket.push(ls.maxDeviationMOVE);

        ls.meanPriceBERA = 0.86 * 1e18;
        ls.maxDeviationBERA = ls.meanPriceBERA / 2;
        ls.meanPriceMarket.push(ls.meanPriceBERA);
        ls.maxDeviationMarket.push(ls.maxDeviationBERA);

        // market is currently closed
        ls.meanPriceLAYER = 0.2 * 1e18;
        ls.maxDeviationLAYER = ls.meanPriceLAYER / 2;
        ls.meanPriceMarket.push(ls.meanPriceLAYER);
        ls.maxDeviationMarket.push(ls.maxDeviationLAYER);

        ls.meanPriceTAO = 282 * 1e18;
        ls.maxDeviationTAO = ls.meanPriceTAO / 2;
        ls.meanPriceMarket.push(ls.meanPriceTAO);
        ls.maxDeviationMarket.push(ls.maxDeviationTAO);

        ls.meanPriceIP = 2.21 * 1e18;
        ls.maxDeviationIP = ls.meanPriceIP / 2;
        ls.meanPriceMarket.push(ls.meanPriceIP);
        ls.maxDeviationMarket.push(ls.maxDeviationIP);

        ls.meanPriceME = 0.32 * 1e18;
        ls.maxDeviationME = ls.meanPriceME / 2;
        ls.meanPriceMarket.push(ls.meanPriceME);
        ls.maxDeviationMarket.push(ls.maxDeviationME);

        ls.meanPricePUMP = 0.003 * 1e18;
        ls.maxDeviationPUMP = ls.meanPricePUMP / 2;
        ls.meanPriceMarket.push(ls.meanPricePUMP);
        ls.maxDeviationMarket.push(ls.maxDeviationPUMP);

        ls.meanPriceMORPHO = 1.22 * 1e18;
        ls.maxDeviationMORPHO = ls.meanPriceMORPHO / 2;
        ls.meanPriceMarket.push(ls.meanPriceMORPHO);
        ls.maxDeviationMarket.push(ls.maxDeviationMORPHO);

        ls.meanPriceSYRUP = 0.28 * 1e18;
        ls.maxDeviationSYRUP = ls.meanPriceSYRUP / 2;
        ls.meanPriceMarket.push(ls.meanPriceSYRUP);
        ls.maxDeviationMarket.push(ls.maxDeviationSYRUP);

        ls.meanPriceAERO = 0.66 * 1e18;
        ls.maxDeviationAERO = ls.meanPriceAERO / 2;
        ls.meanPriceMarket.push(ls.meanPriceAERO);
        ls.maxDeviationMarket.push(ls.maxDeviationAERO);

        ls.meanPriceKAITO = 0.63 * 1e18;
        ls.maxDeviationKAITO = ls.meanPriceKAITO / 2;
        ls.meanPriceMarket.push(ls.meanPriceKAITO);
        ls.maxDeviationMarket.push(ls.maxDeviationKAITO);

        ls.meanPriceZORA = 0.047 * 1e18;
        ls.maxDeviationZORA = ls.meanPriceZORA / 2;
        ls.meanPriceMarket.push(ls.meanPriceZORA);
        ls.maxDeviationMarket.push(ls.maxDeviationZORA);

        ls.meanPricePROVE = 0.43 * 1e18;
        ls.maxDeviationPROVE = ls.meanPricePROVE / 2;
        ls.meanPriceMarket.push(ls.meanPricePROVE);
        ls.maxDeviationMarket.push(ls.maxDeviationPROVE);

        ls.meanPricePAXG = 4212 * 1e18;
        ls.maxDeviationPAXG = ls.meanPricePAXG / 2;
        ls.meanPriceMarket.push(ls.meanPricePAXG);
        ls.maxDeviationMarket.push(ls.maxDeviationPAXG);

        ls.meanPriceYZY = 0.36 * 1e18;
        ls.maxDeviationYZY = ls.meanPriceYZY / 2;
        ls.meanPriceMarket.push(ls.meanPriceYZY);
        ls.maxDeviationMarket.push(ls.maxDeviationYZY);

        ls.meanPriceXPL = 0.17 * 1e18;
        ls.maxDeviationXPL = ls.meanPriceXPL / 2;
        ls.meanPriceMarket.push(ls.meanPriceXPL);
        ls.maxDeviationMarket.push(ls.maxDeviationXPL);

        ls.meanPriceWLFI = 0.15 * 1e18;
        ls.maxDeviationWLFI = ls.meanPriceWLFI / 2;
        ls.meanPriceMarket.push(ls.meanPriceWLFI);
        ls.maxDeviationMarket.push(ls.maxDeviationWLFI);

        ls.meanPriceLINEA = 0.008 * 1e18;
        ls.maxDeviationLINEA = ls.meanPriceLINEA / 2;
        ls.meanPriceMarket.push(ls.meanPriceLINEA);
        ls.maxDeviationMarket.push(ls.maxDeviationLINEA);

        ls.meanPriceMEGA = 0.3 * 1e18;
        ls.maxDeviationMEGA = ls.meanPriceMEGA / 2;
        ls.meanPriceMarket.push(ls.meanPriceMEGA);
        ls.maxDeviationMarket.push(ls.maxDeviationMEGA);

        ls.meanPriceSUSDE = 1.17 * 1e18;
        ls.maxDeviationSUSDE = 0.05 * 1e18;

        ls.meanPriceWSTETH = 4406 * 1e18;
        ls.maxDeviationWSTETH = ls.meanPriceWSTETH / 2;

        if (sec.destinationChainId == 1) {
            ls.meanPriceSRUSD = 1.09 * 1e18;
            ls.maxDeviationSRUSD = 0.02 * 1e18;

            ls.meanPriceRSELINI = 1.07 * 1e18;
            ls.maxDeviationRSELINI = 0.02 * 1e18;

            ls.meanPriceRAMBER = 1.15 * 1e18;
            ls.maxDeviationRAMBER = 0.05 * 1e18;

            ls.meanPriceRHEDGE = 0.5 * 1e18;
            ls.maxDeviationRHEDGE = 0.3 * 1e18;
        } else {
            ls.meanPriceSRUSD = 11.11 * 1e18;
            ls.maxDeviationSRUSD = 11 * 1e18;

            ls.meanPriceRSELINI = 1 * 1e18;
            ls.maxDeviationRSELINI = 0.9 * 1e18;

            ls.meanPriceRAMBER = 1 * 1e18;
            ls.maxDeviationRAMBER = 0.9 * 1e18;

            ls.meanPriceRHEDGE = 1 * 1e18;
            ls.maxDeviationRHEDGE = 0.9 * 1e18;
        }

        ls.meanPriceStableCoin = 1 * 1e18;
        ls.maxDeviationStableCoin = 0.01 * 1e18;

        ls.meanPriceSDEUSD = 1 * 1e18;
        ls.maxDeviationSDEUSD = 1 * 1e18;

        ls.nodeIds.push(sec.rusdUsdNodeId);
        ls.meanPrices.push(1 * 1e18);
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

        ls.nodeIds.push(sec.pumpUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPricePUMP);
        ls.maxDeviations.push(ls.maxDeviationPUMP);

        ls.nodeIds.push(sec.pumpUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPricePUMP);
        ls.maxDeviations.push(ls.maxDeviationPUMP);

        ls.nodeIds.push(sec.morphoUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceMORPHO);
        ls.maxDeviations.push(ls.maxDeviationMORPHO);

        ls.nodeIds.push(sec.morphoUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceMORPHO);
        ls.maxDeviations.push(ls.maxDeviationMORPHO);

        ls.nodeIds.push(sec.syrupUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceSYRUP);
        ls.maxDeviations.push(ls.maxDeviationSYRUP);

        ls.nodeIds.push(sec.syrupUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceSYRUP);
        ls.maxDeviations.push(ls.maxDeviationSYRUP);

        ls.nodeIds.push(sec.aeroUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceAERO);
        ls.maxDeviations.push(ls.maxDeviationAERO);

        ls.nodeIds.push(sec.aeroUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceAERO);
        ls.maxDeviations.push(ls.maxDeviationAERO);

        ls.nodeIds.push(sec.kaitoUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceKAITO);
        ls.maxDeviations.push(ls.maxDeviationKAITO);

        ls.nodeIds.push(sec.kaitoUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceKAITO);
        ls.maxDeviations.push(ls.maxDeviationKAITO);

        ls.nodeIds.push(sec.zoraUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceZORA);
        ls.maxDeviations.push(ls.maxDeviationZORA);

        ls.nodeIds.push(sec.zoraUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceZORA);
        ls.maxDeviations.push(ls.maxDeviationZORA);

        ls.nodeIds.push(sec.proveUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPricePROVE);
        ls.maxDeviations.push(ls.maxDeviationPROVE);

        ls.nodeIds.push(sec.proveUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPricePROVE);
        ls.maxDeviations.push(ls.maxDeviationPROVE);

        ls.nodeIds.push(sec.paxgUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPricePAXG);
        ls.maxDeviations.push(ls.maxDeviationPAXG);

        ls.nodeIds.push(sec.paxgUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPricePAXG);
        ls.maxDeviations.push(ls.maxDeviationPAXG);

        ls.nodeIds.push(sec.yzyUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceYZY);
        ls.maxDeviations.push(ls.maxDeviationYZY);

        ls.nodeIds.push(sec.yzyUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceYZY);
        ls.maxDeviations.push(ls.maxDeviationYZY);

        ls.nodeIds.push(sec.xplUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceXPL);
        ls.maxDeviations.push(ls.maxDeviationXPL);

        ls.nodeIds.push(sec.xplUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceXPL);
        ls.maxDeviations.push(ls.maxDeviationXPL);

        ls.nodeIds.push(sec.wlfiUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceWLFI);
        ls.maxDeviations.push(ls.maxDeviationWLFI);

        ls.nodeIds.push(sec.wlfiUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceWLFI);
        ls.maxDeviations.push(ls.maxDeviationWLFI);

        ls.nodeIds.push(sec.lineaUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceLINEA);
        ls.maxDeviations.push(ls.maxDeviationLINEA);

        ls.nodeIds.push(sec.lineaUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceLINEA);
        ls.maxDeviations.push(ls.maxDeviationLINEA);

        ls.nodeIds.push(sec.megaUsdMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceMEGA);
        ls.maxDeviations.push(ls.maxDeviationMEGA);

        ls.nodeIds.push(sec.megaUsdcMarkNodeIdStork);
        ls.meanPrices.push(ls.meanPriceMEGA);
        ls.maxDeviations.push(ls.maxDeviationMEGA);

        ls.nodeIds.push(sec.susdeUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceSUSDE);
        ls.maxDeviations.push(ls.maxDeviationSUSDE);

        ls.nodeIds.push(sec.susdeUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceSUSDE);
        ls.maxDeviations.push(ls.maxDeviationSUSDE);

        ls.nodeIds.push(sec.wstethUsdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceWSTETH);
        ls.maxDeviations.push(ls.maxDeviationWSTETH);

        ls.nodeIds.push(sec.wstethUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceWSTETH);
        ls.maxDeviations.push(ls.maxDeviationWSTETH);

        ls.nodeIds.push(sec.deusdUsdStorkNodeId);
        ls.meanPrices.push(1e18);
        ls.maxDeviations.push(1e18);

        ls.nodeIds.push(sec.deusdUsdcStorkNodeId);
        ls.meanPrices.push(1e18);
        ls.maxDeviations.push(1e18);

        ls.nodeIds.push(sec.sdeusdDeusdStorkNodeId);
        ls.meanPrices.push(ls.meanPriceSDEUSD);
        ls.maxDeviations.push(ls.maxDeviationSDEUSD);

        ls.nodeIds.push(sec.sdeusdUsdcStorkNodeId);
        ls.meanPrices.push(ls.meanPriceSDEUSD);
        ls.maxDeviations.push(ls.maxDeviationSDEUSD);

        // Stork is connected to mainnet
        ls.nodeIds.push(sec.srusdRusd_RRStorkNodeId);
        ls.meanPrices.push(1.09 * 1e18);
        ls.maxDeviations.push(0.02 * 1e18);

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

    function check_OracleNodePriceValues() public {
        setupOracleNodePriceParams();
        string memory mismatches;

        for (uint256 i = 0; i < ls.nodeIds.length; i++) {
            NodeOutput.Data memory nodeOutput = IOracleManagerProxy(sec.oracleManager).process(ls.nodeIds[i]);

            int256 dPrice = int256(nodeOutput.price) - int256(ls.meanPrices[i]);
            int256 maxdPrice = int256(ls.maxDeviations[i]);

            if (!(-maxdPrice <= dPrice && dPrice <= maxdPrice)) {
                if (bytes(mismatches).length == 0) {
                    mismatches = string.concat(
                        "Prices do not match for the following node IDs: ", bytes32ToHexString(ls.nodeIds[i])
                    );
                } else {
                    mismatches = string.concat(mismatches, ", ", bytes32ToHexString(ls.nodeIds[i]));
                }
            }
        }

        vm.assertEq(bytes(mismatches).length, 0, mismatches);
    }

    function check_OracleNodePriceStaleness() public {
        setupOracleNodePriceParams();

        for (uint256 i = 0; i < ls.nodeIds.length; i++) {
            NodeOutput.Data memory nodeOutput = IOracleManagerProxy(sec.oracleManager).process(ls.nodeIds[i]);
            NodeDefinition.Data memory nodeDefinition = IOracleManagerProxy(sec.oracleManager).getNode(ls.nodeIds[i]);

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

            assertLe(nodeOutput.timestamp, block.timestamp);
            assertLe(block.timestamp - max_stale_duration, nodeOutput.timestamp);
            assertEq(nodeDefinition.maxStaleDuration, max_stale_duration);
        }
    }

    function check_marketsPrices() public {
        setupOracleNodePriceParams();
        string memory mismatches;

        for (uint128 i = lastMarketId(); i >= 1; i--) {
            // FTM, LAYER, MKR are currently set to constant node
            bool inactiveMarket = i == 30 || i == 59 || i == 7;

            if (inactiveMarket) {
                continue;
            }

            MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(i);
            bytes32 nodeId = marketConfig.oracleNodeId;

            NodeOutput.Data memory nodeOutput = IOracleManagerProxy(sec.oracleManager).process(nodeId);

            int256 dPrice = int256(nodeOutput.price) - int256(ls.meanPriceMarket[i]);
            int256 maxdPrice = int256(ls.maxDeviationMarket[i]);

            if (!(-maxdPrice <= dPrice && dPrice <= maxdPrice)) {
                if (bytes(mismatches).length == 0) {
                    mismatches = string.concat("Prices do not match for the following market IDs: ", uintToString(i));
                } else {
                    mismatches = string.concat(mismatches, ", ", uintToString(i));
                }
            }
        }

        vm.assertEq(bytes(mismatches).length, 0, mismatches);
    }

    function check_marketsOrderMaxStaleDuration(uint256 orderMaxStaleDuration) public view {
        string memory mismatches;
        for (uint128 i = lastMarketId(); i >= 1; i--) {
            MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(i);

            // FTM, LAYER, MKR are currently set to constant node
            bool inactiveMarket = i == 30 || i == 59 || i == 7;

            if (inactiveMarket) {
                continue;
            }

            if (!(marketConfig.marketOrderMaxStaleDuration == orderMaxStaleDuration)) {
                if (bytes(mismatches).length == 0) {
                    mismatches = string.concat(
                        "Staleness durations do not match for the following market IDs: ", uintToString(i)
                    );
                } else {
                    mismatches = string.concat(mismatches, ", ", uintToString(i));
                }
            }
        }

        vm.assertEq(bytes(mismatches).length, 0, mismatches);
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

    function check_srUSD_feeds() public view {
        uint256 poolSRUSDPrice = IPassivePoolProxy(sec.pool).getSharePrice(1);

        NodeOutput.Data memory liveSRUSDFeed = IOracleManagerProxy(sec.oracleManager).process(sec.srusdUsdcPoolNodeId);

        NodeOutput.Data memory storkSRUSDFeed =
            IOracleManagerProxy(sec.oracleManager).process(sec.srusdRusd_RRStorkNodeId);

        assertEq(liveSRUSDFeed.price, poolSRUSDPrice, "liveSRUSDFeed.price");
        assertEq(liveSRUSDFeed.timestamp, block.timestamp, "liveSRUSDFeed.timestamp");

        assertApproxEqAbs(storkSRUSDFeed.price, poolSRUSDPrice, 0.001e18, "storkSRUSDFeed.price");
    }
}
