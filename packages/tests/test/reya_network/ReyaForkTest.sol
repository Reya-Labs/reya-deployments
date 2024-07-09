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
        sec.periphery = payable(0xCd2869d1eb1BC8991Bc55de9E9B779e912faF736);
        sec.ordersGateway = payable(0xfc8c96bE87Da63CeCddBf54abFA7B13ee8044739);
        sec.exchangePass = 0x76e3f2667aC55d502e26e59C5A6B46e7079217c7;
        sec.accountNft = 0x0354e71e0444d08e0Ce5E49EB91531A1Cac61144;
        sec.rusd = 0xa9F32a851B1800742e47725DA54a09A7Ef2556A3;
        sec.usdc = 0x3B860c0b53f2e8bd5264AA7c3451d41263C933F2;
        sec.weth = 0x6B48C2e6A32077ec17e8Ba0d98fFc676dfab1A30;
        sec.wbtc = 0xa6Cf523f856f4a0aaB78848e251C1b042E6406d5;
        sec.ethUsdNodeId = 0x7bb5195bd6b7c7bd928da2b52cae900a5f6262eb32b992ac4d97b4f2c322422c;
        sec.btcUsdNodeId = 0x2973a5fc60ce7fd59c68e20eade5cbb56d3f22516f5dbd78d09654de5070df8e;
        sec.solUsdNodeId = 0x6d0ac400d77f1a54799718b343e7704512491357d23c8c2cdf768620f0309518;
        sec.ethUsdcNodeId = 0xd47353c2b593083048dc9eb3f58c89553c5cafc5065d65774e5614daa8f37b47;
        sec.btcUsdcNodeId = 0x9a2f8b104c6d9f675d4f756a6d54c4cb9fbbfdb999c77cc6e69003bcbc561476;
        sec.solUsdcNodeId = 0xd661618c38acddf411cf3795c026257232914b09245bc00ae23333667732e20c;
        sec.rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
        sec.usdcUsdNodeId = 0x7c1a73684de34b95f492a9ee72c0d8e1589714eeba4a457f766b84bd1c2f240f;
        sec.passivePoolId = 1;
        sec.passivePoolAccountId = 2;
        sec.ownerUpgradeModule = 0x70230eE0CcA326A559410DCEd74F2972306D1e1e;
        sec.mainChainId = ethereumChainId;

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

        try vm.activeFork() { }
        catch {
            vm.createSelectFork(sec.REYA_RPC);
        }
    }
}
