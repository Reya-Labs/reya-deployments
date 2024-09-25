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
        sec.susde = 0x2339D41f410EA761F346a14c184385d15f7266c4;
        sec.passivePoolId = 1;
        sec.passivePoolAccountId = 2;
        sec.ownerUpgradeModule = 0x70230eE0CcA326A559410DCEd74F2972306D1e1e;
        sec.mainChainId = ethereumChainId;

        sec.rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
        // sec.usdcUsdNodeId = 0x7c1a73684de34b95f492a9ee72c0d8e1589714eeba4a457f766b84bd1c2f240f;
        sec.usdcUsdStorkNodeId = 0xc392c001dcf7749e4cdb7967e7ecac04628dea34555b1963bab626b9ef79d63f;

        // sec.ethUsdcNodeId = 0xd47353c2b593083048dc9eb3f58c89553c5cafc5065d65774e5614daa8f37b47;
        // sec.ethUsdNodeId = 0x7bb5195bd6b7c7bd928da2b52cae900a5f6262eb32b992ac4d97b4f2c322422c;
        sec.ethUsdStorkNodeId = 0xf7f69911b541015e987116388896c1b92743e0d07b7fbe4f247b441f132359e7;
        sec.ethUsdcStorkNodeId = 0x5b964bee06e9f94df6484d38dea687e67ec10326208bec16f89dfdb6cd95c6fc;
        // sec.ethUsdcStorkFallbackNodeId = 0xfce9e06b00c48b2cad4f40201b0204059259018efe9d55ed24d2fef1c0d5e838;

        // sec.btcUsdNodeId = 0x2973a5fc60ce7fd59c68e20eade5cbb56d3f22516f5dbd78d09654de5070df8e;
        // sec.btcUsdcNodeId = 0x9a2f8b104c6d9f675d4f756a6d54c4cb9fbbfdb999c77cc6e69003bcbc561476;
        sec.btcUsdStorkNodeId = 0x5ecb66506ae6766ea166c179eebfbe9e70a255aeecc9ff93ad842415bd081a40;
        sec.btcUsdcStorkNodeId = 0x8664e2f734e25cff2b0e425af71bcdabe7a7d7b25a6bf5b888b2593aa7fd7c5e;
        // sec.btcUsdcStorkFallbackNodeId = 0x5abe1e27c2d243399ded65115a86eb3ebbfff10475729fed46582f7ddf4bc7a8;

        // sec.solUsdNodeId = 0x6d0ac400d77f1a54799718b343e7704512491357d23c8c2cdf768620f0309518;
        // sec.solUsdcNodeId = 0xd661618c38acddf411cf3795c026257232914b09245bc00ae23333667732e20c;
        sec.solUsdStorkNodeId = 0xdee981b6607d86960d2e6086c1b1d8c78a4c6dbccf7ff02e22494c1980867687;
        sec.solUsdcStorkNodeId = 0x223cb61408708c4a535649cab964e092739f340fc09b52c141ff4c2a353f1465;
        // sec.solUsdcStorkFallbackNodeId = 0x97c5aab791da0de5ccd0db4771c9179984569c4d303aa7d970888a3644276c63;

        // sec.arbUsdNodeId = 0x35c750375b58ef608f409207712bec33346147bd26f3c3499cc82707d2378465;
        // sec.arbUsdcNodeId = 0xdd9fd2b638bac66ff9b4a5e1fbff7156ab50a2215b76b760b275c62b25356fb8;
        sec.arbUsdStorkNodeId = 0x97bc525f6997b23d40b02e6a99e843440b26604dc7abbd08061beec040a14a66;
        sec.arbUsdcStorkNodeId = 0x80b5f5454eb1ae854b8b671fc972d4f16a3bae5a858c1a67e13c4a81cef22b24;
        // sec.arbUsdcStorkFallbackNodeId = 0xcdc956a0eedd03d1705f5248910042d5da21cbe3fb362d0203dd7a4852b23bda;

        // sec.opUsdNodeId = 0x5fc5346a561a540caf96e191e354318c3e8402ed9c53aa486125432ce9e688f5;
        // sec.opUsdcNodeId = 0x088389bce6df469303cc410a355755589d6bdff5c8591ee741e608fb82d0283b;
        sec.opUsdStorkNodeId = 0xeaeed5aaf31bdcaf14cb1c0b76c13c37ca2d8ebebbccfb9ff14fbb78d194a5ca;
        sec.opUsdcStorkNodeId = 0x9170ec8398399d25c597d445755f31ccb362ce4ea9aa8857db7fc44338ddeb82;
        // sec.opUsdcStorkFallbackNodeId = 0xf6a2fa7f2e9742e14f5e5f8b9e073119b21f3cafc913882b07cf3b0d73f6708a;

        // sec.avaxUsdNodeId = 0x67807778d0d04792bb8d89b677e27752eba2c474fbd521ee80174a56ab02a65a;
        // sec.avaxUsdcNodeId = 0x0b476cd1d4719245c4a80f469d510c4b3ee7647fee09ae3f3de05ab25de34c8f;
        sec.avaxUsdStorkNodeId = 0xa4e8be8233388eb3eb394e612a719cc92ab41901a242bf1a409407f3deb71357;
        sec.avaxUsdcStorkNodeId = 0x23d809b84561e4b046e5ccfc6769d23fbea8335fbfe3f5652f461cde297308fa;
        // sec.avaxUsdcStorkFallbackNodeId = 0x26a55771eb5f177ada6287e21726763856097495089e1e6c229098563585bfe9;

        // sec.usdeUsdNodeId = 0xac63c0c9dbfe155f07ca193ab5a01f5eeffe492815d6d5740c772fefc4229757;
        // sec.usdeUsdcNodeId = 0x6ec653a1df527c25ef3cc1e87372eb2ff734e1ac71f9f32a51ed6524dc5b548f;
        sec.usdeUsdStorkNodeId = 0xd9769cc38a8c1db7761cbb398785c85a4db42608b8ff2273b4146ccd73178851;
        sec.usdeUsdcStorkNodeId = 0xa17767ed077b64b1099fe31491143f856b9ebf5249c9fe23dab93b21a1689663;
        // sec.usdeUsdcStorkFallbackNodeId = 0xc4db67624c26a4402184f1c7f05491a5f591aad71ad19df3640bc182ae9bc639;

        // sec.mkrUsdNodeId = 0xe547fab20d2771b88029331ad08c8596f9844005a0b0d3206e08749adfa16331;
        // sec.mkrUsdcNodeId = 0x90cc9adb23f43634de27cbc265d47d09a76b058a583f606ce8c5d4bfb795d7c4;
        sec.mkrUsdStorkNodeId = 0x2071b01ccaf322c8cccb898a9066faca23736fdcb64a2eb6dc702fc089fbcce9;
        sec.mkrUsdcStorkNodeId = 0x1e67ff7817955ed81fd88401a5b95601ae250694a80d33de0e043730f46adb8c;
        // sec.mkrUsdcStorkFallbackNodeId = 0x8798b1f9936835c043e326c5388f9fe7e54c88629007f5b7d64034bcbee73729;

        // sec.linkUsdNodeId = 0x81de1f39c947ca3ae0ad73a70b1495b8acff5c228a6cbcd6594540cb4967101a;
        // sec.linkUsdcNodeId = 0x02006cec1cc2a16a726c27de1bea8a5c5ebcf4d1fff519630c05cbf0727c44f2;
        sec.linkUsdStorkNodeId = 0x4fb08da4acfc44a2c889d183ac85658d66e281a024412e136eae35c36c112dc8;
        sec.linkUsdcStorkNodeId = 0xd6c6f4e29c74e5e8114381e0f86669170d2f7a000dcf2d56c7964e05eeeb67c6;
        // sec.linkUsdcStorkFallbackNodeId = 0xf5c986f3faca6f8bf6e6ca3eee87747d2f3891ad7b034900a776458886324475;

        // sec.aaveUsdNodeId = 0x897616a404ac7a2bfa5e575216a8e3667a36cd18524e8ebc21ebc572e7d483d0;
        // sec.aaveUsdcNodeId = 0xb868436de0acc7812ac8ad2c7f02e1ab15630b23b39d204a5841f941462d479e;
        sec.aaveUsdStorkNodeId = 0x10d7428d63e9ed046e08c49570dc922176e14410afd663650334c835515e8db4;
        sec.aaveUsdcStorkNodeId = 0x6e520ec9980e70b7026a03dbec1a2b1430b2452f06041fb531cb6ab7e50c134f;
        // sec.aaveUsdcStorkFallbackNodeId = 0x9cb12295f8a947f49ab6ddf510b337039c73ecdaad8a3db6a151141eaea37825;

        // sec.crvUsdNodeId = 0x6ae1106c80120adbc1a45835d07ecf7535064bd21b2cdcc3638f407135d2a0c1;
        // sec.crvUsdcNodeId = 0x266abd1aaf24e9c730eab7934010cff85eb82b7de036a57b88e6674973f15dd5;
        sec.crvUsdStorkNodeId = 0x49b49ce9d08e5744ea6f72d2ae5f5312a1da9be917aba8aecb2afbd475fbd838;
        sec.crvUsdcStorkNodeId = 0x6cc8e3f80a1293e4c156c70f95ac2f522682de5491172fbdf94d0bc2745cef46;
        // sec.crvUsdcStorkFallbackNodeId = 0x4fdb54d561889019c01695d48315a61109d09492dc0228fc265b51fb43f83fbe;

        // sec.uniUsdNodeId = 0x39b83dbb4ee83725d885d0e2f0e90510b7ae2575022bf6db23fe73ce3e3b2bc9;
        // sec.uniUsdcNodeId = 0x5a52c8855ca52058fc8ad861e6fde368036ff81ba48a8b43173323ad27d864ad;
        // sec.uniUsdStorkNodeId = 0xddbd920a138237d11cfa2813d89f4d232cda42d539887d91389db1c7f81cff31;
        // sec.uniUsdcStorkNodeId = 0x2e40e5f57ae4688e7168a2bfa5e32bd6b04dc2b3fafbdfe8f25208673dce06f5;
        // sec.uniUsdcStorkFallbackNodeId = 0x8bcb5d4f7d30020b794a872e79f0efa5f7dc58e7b48d9b18903d9519aca0e4ea;
        sec.uniUsdStorkMarkNodeId = 0x9dfccb2a42862c7f15df103018135c7dd725bde418de4aac5f240fac54a5a4ff;
        sec.uniUsdcStorkMarkNodeId = 0x71a2b4ab9766edca50373e43e54dcea91b2a43ebfe390c098b2a76ac75da8d64;

        // sec.susdeUsdNodeId = 0xca59e8ff5f899c7117a1e82a1e915ede07c45835e8d02b10535a9f58058be10c;
        // sec.susdeUsdcNodeId = 0x46effa5a7464c0e305d73ca20fb965d985e543e37f9cf3f0eacd680936c4c5e0;
        sec.susdeUsdStorkNodeId = 0x5176edbcbb7126ba8fe024a930aaa5a88bfd8a5f0de4c823e19f439d5f6c5c59;
        sec.susdeUsdcStorkNodeId = 0x4886cf0e120ecc44a7218921cfdf8f5dc2ff36d70ecc6f2857031e572dad65e7;
        // sec.susdeUsdcStorkFallbackNodeId = 0x77c5a8870d9474f1efc1822bd18bb3aa8e724bc836e0a61c9aee82fdbacfbcb6;

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
        dec.socketConnector[sec.usde][ethereumChainId] = 0xf004c4c51b6c026247B5910706Ee78134299eaBD;

        dec.socketController[sec.susde] = 0x3379f120917fb67728d6Db6065d9fDBBd1507A7B;
        dec.socketExecutionHelper[sec.susde] = 0x9e51CDbD0dC54E314B6b17C69ED34a98B8259A16;
        dec.socketConnector[sec.susde][ethereumChainId] = 0x888f5426Bf4E387770A225d0097f0716aF98e7b5;
        dec.socketConnector[sec.susde][arbitrumChainId] = 0x4f471ff392733b722992F012e40728e36c5e9848;
        dec.socketConnector[sec.susde][optimismChainId] = 0x79C06E5BD8e7a4dc151D7591eba71C2a5D49e2B6;
        dec.socketConnector[sec.susde][baseChainId] = 0xE71b58F3324d06786cA70b3c9695df23EEaaF630;

        try vm.activeFork() { }
        catch {
            vm.createSelectFork(sec.REYA_RPC);
        }
    }
}
