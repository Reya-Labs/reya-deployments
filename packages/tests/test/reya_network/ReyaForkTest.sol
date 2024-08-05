pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";

import { StorageReyaForkTest } from "../reya_common/StorageReyaForkTest.sol";
import "../reya_common/DataTypes.sol";

contract ReyaForkTest is StorageReyaForkTest {
    constructor() {
        sec.REYA_RPC = "https://rpc.reya.network";
        sec.multisig = 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9;
        sec.core = payable(0xA763B6a5E09378434406C003daE6487FbbDc1a80);
        sec.pool = payable(0xB4B77d6180cc14472A9a7BDFF01cc2459368D413);
        sec.perp = payable(0x27E5cb712334e101B3c232eB0Be198baaa595F5F);
        sec.oracleManager = 0xC67316Ed17E0C793041CFE12F674af250a294aab;
        sec.oracleAdaptersProxy = payable(0x32edABC058C1207fE0Ec5F8557643c28E4FF379e);
        sec.periphery = payable(0xCd2869d1eb1BC8991Bc55de9E9B779e912faF736);
        sec.ordersGateway = payable(0xfc8c96bE87Da63CeCddBf54abFA7B13ee8044739);
        sec.exchangePass = 0x76e3f2667aC55d502e26e59C5A6B46e7079217c7;
        sec.accountNft = 0x0354e71e0444d08e0Ce5E49EB91531A1Cac61144;
        sec.rusd = 0xa9F32a851B1800742e47725DA54a09A7Ef2556A3;
        sec.usdc = 0x3B860c0b53f2e8bd5264AA7c3451d41263C933F2;
        sec.weth = 0x6B48C2e6A32077ec17e8Ba0d98fFc676dfab1A30;
        sec.wbtc = 0xa6Cf523f856f4a0aaB78848e251C1b042E6406d5;
        sec.usde = 0xAAB18B45467eCe5e47F85CA6d3dc4DF2a350fd42;
        sec.passivePoolId = 1;
        sec.passivePoolAccountId = 2;
        sec.ownerUpgradeModule = 0x70230eE0CcA326A559410DCEd74F2972306D1e1e;
        sec.mainChainId = ethereumChainId;

        sec.rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
        sec.usdcUsdNodeId = 0x7c1a73684de34b95f492a9ee72c0d8e1589714eeba4a457f766b84bd1c2f240f;
        sec.usdcUsdStorkNodeId = 0xc392c001dcf7749e4cdb7967e7ecac04628dea34555b1963bab626b9ef79d63f;

        sec.ethUsdcNodeId = 0xd47353c2b593083048dc9eb3f58c89553c5cafc5065d65774e5614daa8f37b47;
        sec.ethUsdNodeId = 0x7bb5195bd6b7c7bd928da2b52cae900a5f6262eb32b992ac4d97b4f2c322422c;
        sec.ethUsdStorkNodeId = 0xf7f69911b541015e987116388896c1b92743e0d07b7fbe4f247b441f132359e7;
        sec.ethUsdcStorkNodeId = 0x5b964bee06e9f94df6484d38dea687e67ec10326208bec16f89dfdb6cd95c6fc;
        sec.ethUsdcStorkFallbackNodeId = 0xfce9e06b00c48b2cad4f40201b0204059259018efe9d55ed24d2fef1c0d5e838;

        sec.btcUsdNodeId = 0x2973a5fc60ce7fd59c68e20eade5cbb56d3f22516f5dbd78d09654de5070df8e;
        sec.btcUsdcNodeId = 0x9a2f8b104c6d9f675d4f756a6d54c4cb9fbbfdb999c77cc6e69003bcbc561476;
        sec.btcUsdStorkNodeId = 0x5ecb66506ae6766ea166c179eebfbe9e70a255aeecc9ff93ad842415bd081a40;
        sec.btcUsdcStorkNodeId = 0x8664e2f734e25cff2b0e425af71bcdabe7a7d7b25a6bf5b888b2593aa7fd7c5e;
        sec.btcUsdcStorkFallbackNodeId = 0x5abe1e27c2d243399ded65115a86eb3ebbfff10475729fed46582f7ddf4bc7a8;

        sec.solUsdNodeId = 0x6d0ac400d77f1a54799718b343e7704512491357d23c8c2cdf768620f0309518;
        sec.solUsdcNodeId = 0xd661618c38acddf411cf3795c026257232914b09245bc00ae23333667732e20c;
        sec.solUsdStorkNodeId = 0xdee981b6607d86960d2e6086c1b1d8c78a4c6dbccf7ff02e22494c1980867687;
        sec.solUsdcStorkNodeId = 0x223cb61408708c4a535649cab964e092739f340fc09b52c141ff4c2a353f1465;
        sec.solUsdcStorkFallbackNodeId = 0x97c5aab791da0de5ccd0db4771c9179984569c4d303aa7d970888a3644276c63;

        sec.arbUsdNodeId = 0x35c750375b58ef608f409207712bec33346147bd26f3c3499cc82707d2378465;
        sec.arbUsdcNodeId = 0xdd9fd2b638bac66ff9b4a5e1fbff7156ab50a2215b76b760b275c62b25356fb8;
        sec.arbUsdStorkNodeId = 0x97bc525f6997b23d40b02e6a99e843440b26604dc7abbd08061beec040a14a66;
        sec.arbUsdcStorkNodeId = 0x80b5f5454eb1ae854b8b671fc972d4f16a3bae5a858c1a67e13c4a81cef22b24;
        sec.arbUsdcStorkFallbackNodeId = 0xcdc956a0eedd03d1705f5248910042d5da21cbe3fb362d0203dd7a4852b23bda;

        sec.opUsdNodeId = 0x5fc5346a561a540caf96e191e354318c3e8402ed9c53aa486125432ce9e688f5;
        sec.opUsdcNodeId = 0x088389bce6df469303cc410a355755589d6bdff5c8591ee741e608fb82d0283b;
        sec.opUsdStorkNodeId = 0xeaeed5aaf31bdcaf14cb1c0b76c13c37ca2d8ebebbccfb9ff14fbb78d194a5ca;
        sec.opUsdcStorkNodeId = 0x9170ec8398399d25c597d445755f31ccb362ce4ea9aa8857db7fc44338ddeb82;
        sec.opUsdcStorkFallbackNodeId = 0xf6a2fa7f2e9742e14f5e5f8b9e073119b21f3cafc913882b07cf3b0d73f6708a;

        sec.avaxUsdNodeId = 0x67807778d0d04792bb8d89b677e27752eba2c474fbd521ee80174a56ab02a65a;
        sec.avaxUsdcNodeId = 0x0b476cd1d4719245c4a80f469d510c4b3ee7647fee09ae3f3de05ab25de34c8f;
        sec.avaxUsdStorkNodeId = 0xa4e8be8233388eb3eb394e612a719cc92ab41901a242bf1a409407f3deb71357;
        sec.avaxUsdcStorkNodeId = 0x23d809b84561e4b046e5ccfc6769d23fbea8335fbfe3f5652f461cde297308fa;
        sec.avaxUsdcStorkFallbackNodeId = 0x26a55771eb5f177ada6287e21726763856097495089e1e6c229098563585bfe9;

        sec.usdeUsdStorkNodeId = 0xd9769cc38a8c1db7761cbb398785c85a4db42608b8ff2273b4146ccd73178851;
        sec.usdeUsdcStorkNodeId = 0xa17767ed077b64b1099fe31491143f856b9ebf5249c9fe23dab93b21a1689663;

        dec.socketController[sec.usdc] = 0x1d43076909Ca139BFaC4EbB7194518bE3638fc76;
        dec.socketExecutionHelper[sec.usdc] = 0x9ca48cAF8AD2B081a0b633d6FCD803076F719fEa;
        dec.socketConnector[sec.usdc][ethereumChainId] = 0x807B2e8724cDf346c87EEFF4E309bbFCb8681eC1;
        dec.socketConnector[sec.usdc][arbitrumChainId] = 0x663dc7E91157c58079f55C1BF5ee1BdB6401Ca7a;
        dec.socketConnector[sec.usdc][optimismChainId] = 0xe48AE3B68f0560d4aaA312E12fD687630C948561;
        dec.socketConnector[sec.usdc][polygonChainId] = 0x54CAA0946dA179425e1abB169C020004284d64D3;
        dec.socketConnector[sec.usdc][baseChainId] = 0x3694Ab37011764fA64A648C2d5d6aC0E9cD5F98e;

        dec.socketController[sec.weth] = 0xF0E49Dafc687b5ccc8B31b67d97B5985D1cAC4CB;
        dec.socketExecutionHelper[sec.weth] = 0xBE35E24dde70aFc6e07DF7e7BD8Ce723e1712771;
        dec.socketConnector[sec.weth][ethereumChainId] = 0x7dE4937420935c7C8767b06eCd7F7dC54e2D7C9b;
        dec.socketConnector[sec.weth][arbitrumChainId] = 0xd95c5254Df051f378696100a7D7f29505e5cF5c9;
        dec.socketConnector[sec.weth][optimismChainId] = 0xDee306Cf6C908d5F4f2c4A92d6Dc19035fE552EC;
        dec.socketConnector[sec.weth][polygonChainId] = 0x530654F6e96198bC269074156b321d8B91d10366;
        dec.socketConnector[sec.weth][baseChainId] = 0x2b3A8ABa1E055e879594cB2767259e80441E0497;

        dec.socketController[sec.wbtc] = 0xBF839f4dfF854F7a363A033D57ec872dC8556693;
        dec.socketExecutionHelper[sec.wbtc] = 0xd947Dd2f18366F3FD1f2a707d3CA58F762D60519;
        dec.socketConnector[sec.wbtc][ethereumChainId] = 0xD71629697B71E2Df26B4194f43F6eaed3B367ac0;
        dec.socketConnector[sec.wbtc][arbitrumChainId] = 0x42229a5DDC5E32149311265F6F4BC016EaB778FC;
        dec.socketConnector[sec.wbtc][optimismChainId] = 0xA6BFB87A0db4693a4145df4F627c8FEe30aC7eDF;
        dec.socketConnector[sec.wbtc][polygonChainId] = 0xA30e479EbfD576EDd69afB636d16926a05214149;

        dec.socketController[sec.usde] = 0xF5D4ea96d2efbdAB9C63fA85d2c45e8B75dF640c;
        dec.socketExecutionHelper[sec.usde] = 0xC53D91C6D595b4259fa5649d77e1e31E648202A3;
        dec.socketConnector[sec.usde][ethereumChainId] = 0xc2dE372337308cEd2754d8d9bC0AB1A1B004C3be;

        try vm.activeFork() { }
        catch {
            vm.createSelectFork(sec.REYA_RPC);
        }
    }
}
