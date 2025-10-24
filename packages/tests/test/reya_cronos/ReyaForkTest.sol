pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";

import { BaseReyaForkTest } from "../reya_common/BaseReyaForkTest.sol";
import "../reya_common/DataTypes.sol";

import { IPeripheryProxy, DepositPassivePoolInputs } from "../../src/interfaces/IPeripheryProxy.sol";
import { ICoreProxy } from "../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy } from "../../src/interfaces/IPassivePerpProxy.sol";

import { ISocketExecutionHelper } from "../../src/interfaces/ISocketExecutionHelper.sol";
import { IOracleManagerProxy } from "../../src/interfaces/IOracleManagerProxy.sol";

contract ReyaForkTest is BaseReyaForkTest {
    constructor() {
        string memory rpcKey = vm.envString("RPC_KEY");
        // network
        sec.REYA_RPC = string.concat("https://rpc.reya-cronos.gelato.digital/", rpcKey);
        sec.MAINNET_RPC = "https://gateway.tenderly.co/public/sepolia";

        // other (external) chain id
        sec.destinationChainId = ethereumSepoliaChainId;

        // multisigs
        sec.multisig = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;

        // Reya contracts
        sec.core = payable(0xC6fB022962e1426F4e0ec9D2F8861c57926E9f72);
        sec.pool = payable(0x9A3A664987b88790A6FDC1632e3b607813fd94fF);
        sec.perp = payable(0x9EC177fed042eF2307928BE2F5CDbf663B20244B);
        sec.oracleManager = 0x689f13829e9b218841a0Cf59f44bD5c92F0d64eA;
        sec.periphery = payable(0x94ccAe812f1647696754412082dd6684C2366A7f);
        sec.ordersGateway = payable(0x5A0aC2f89E0BDeaFC5C549e354842210A3e87CA5);
        sec.oracleAdaptersProxy = payable(0xc501A2356703CD351703D68963c6F4136120f7CF);
        sec.exchangePass = 0x1Acd15A57Aff698440262A2A13AE22F8Ff2FA0cB;
        sec.accountNft = 0xeA13E7dA71E018160019A296Eca4184Ddc53aeB1;

        // Reya tokens
        sec.rusd = 0x9DE724e7b3facF87Ce39465D3D712717182e3e55;
        sec.usdc = 0xfA27c7c6051344263533cc365274d9569b0272A8;
        sec.weth = 0x2CF56315ACC7E791B1A0135c09d8D5C8dBCD2F14;
        sec.wbtc = 0x459374F3f3E92728bCa838DfA8C95E706FE67E8a;
        sec.usde = 0xDca6971c26fDEE0536Fdff076D063643f7810621;
        sec.susde = 0x08A766935478A1632FA776DCEbD3E75Ce88A1034;
        sec.deusd = 0x3b9D28dC180813a106d26778135Ac2A674F89957;
        sec.sdeusd = 0xbEB316680B6fcd2dC3aF1fC933B3A27a2513d89D;
        sec.rselini = 0xbA8ae4D2A147c54c3aBA123e8e01937AF505FC3c;
        sec.ramber = 0x125FD68Ec0ab65ce9606DeD99e8F19C286f9E534;
        sec.rhedge = 0xFB9eeD7a6F3100dB35c94B214917a0A64AEC1a97;
        sec.srusd = 0xb9F531A54Fc0E9AdCa1b931d9533B4e49bB2fAD6;
        sec.wsteth = 0xDF52410A19298FE168c900513e762adaD00C42b1;

        // Elixir tokens on Mainnet (Ethereum Sepolia)
        sec.elixirSdeusd = 0x97D3e518029c622015afa7aD20036EbEF60A7A4e;

        // Reya modules
        sec.ownerUpgradeModule = 0x3fa74FfE7B278a25877E16f00e73d5F5FA499183;

        // Reya variables
        sec.passivePoolId = 1;
        sec.passivePoolAccountId = 4;

        // Reya bots
        sec.coExecutionBot = 0xB6EaF546b84E1f917579FC4FD3d7082DfE2ba212;
        sec.poolRebalancer = 0xe8AaBC33a41d63FE4a0aD13ce815279391dD069E;
        sec.rseliniCustodian = 0x45556408e543158f74403e882E3C8c23eCD9f732;
        sec.rseliniSubscriber = 0xe8AaBC33a41d63FE4a0aD13ce815279391dD069E;
        sec.rseliniRedeemer = 0xe8AaBC33a41d63FE4a0aD13ce815279391dD069E;
        sec.ramberCustodian = 0x45556408e543158f74403e882E3C8c23eCD9f732;
        sec.ramberSubscriber = 0xe8AaBC33a41d63FE4a0aD13ce815279391dD069E;
        sec.ramberRedeemer = 0xe8AaBC33a41d63FE4a0aD13ce815279391dD069E;
        sec.rhedgeCustodian = 0x45556408e543158f74403e882E3C8c23eCD9f732;
        sec.rhedgeSubscriber = 0xe8AaBC33a41d63FE4a0aD13ce815279391dD069E;
        sec.rhedgeRedeemer = 0xe8AaBC33a41d63FE4a0aD13ce815279391dD069E;
        sec.aeLiquidator1 = 0xF39f72E8E8D16833601C3f1ac33835ca5C69f6E4;
        sec.setMarketZeroFeeBot = 0x6b5E482fCE86F0C95cAe69CAC2788EA8610a84c6;

        // node ids for spot prices
        sec.rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
        sec.usdcUsdStorkNodeId = 0x28c79729ca502a5cd2565613c087a3bda098a1c78e3f3f45733d03c3482f099d;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.rusdUsdNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.usdcUsdStorkNodeId, 10_000);

        sec.ethUsdStorkNodeId = 0x6f1442b15af1cde852d45cdd67336b330257c9df23834909159097b25b57936c;
        sec.ethUsdcStorkNodeId = 0xb19e4d8ea5f0a3752fbd19515075063f7486e6954b8aa2b3d462c61726c46619;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ethUsdStorkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ethUsdcStorkNodeId, 10_000);

        sec.usdeUsdStorkNodeId = 0x2b30e0b99d6cfb46e7743a6fc93cee722bc36e94b48d99059de050e40294a005;
        sec.usdeUsdcStorkNodeId = 0xf37654fe7d50f92914ddb32104e82b81220be6e73257ef21ac8a49b9dc68193c;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.usdeUsdStorkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.usdeUsdcStorkNodeId, 10_000);

        sec.susdeUsdStorkNodeId = 0x6497f91ed5f0057fcc55c01ddb28210776431a7e87035393cff808e98eb70d55;
        sec.susdeUsdcStorkNodeId = 0x1f12d26562a7ed66f142fcc9574045808ff6b0fece27a061ef4f7b5039902735;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.susdeUsdStorkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.susdeUsdcStorkNodeId, 10_000);

        sec.wstethUsdStorkNodeId = 0x435559595373b3ee357aeadd75c5cc059cf42a4ca65a0e16370b44268d368609;
        sec.wstethUsdcStorkNodeId = 0x12a06740d009d5b9ef52aed0b7ee139ba9d38635f993c99f71c76b9747e0451c;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.wstethUsdStorkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.wstethUsdcStorkNodeId, 10_000);

        sec.deusdUsdStorkNodeId = 0x466cc622a5f9a753472566bcbdf38ce938ee1d0a87a3fa8ae073ad714b60f89d;
        sec.deusdUsdcStorkNodeId = 0x6b346cf521e6a90d532adf6a9413c0634c37ebcae8c7786de0d163ad26be8cbe;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.deusdUsdStorkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.deusdUsdcStorkNodeId, 10_000);

        sec.sdeusdDeusdStorkNodeId = 0x2c14164e11064f9666096a57f2502ef935bc2aaa0a21efd326b1652e47cf8cdc;
        sec.sdeusdUsdcStorkNodeId = 0x4a600800dcd1db78bbc2880174df4e886a8a67e418f065e27ca5866e11b5f886;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.sdeusdDeusdStorkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.sdeusdUsdcStorkNodeId, 10_000);

        sec.srusdRusd_RRStorkNodeId = 0xcc867342fbbfce6e175732b29429746f7116343e9aa1813471105e5d2e3061bd;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.srusdRusd_RRStorkNodeId, 10_000);

        sec.rseliniUsdcReyaLmNodeId = 0x8831605e4b3e4d533b9123c50106de11623f1188975d107029a4534bfd5acfd2;
        sec.ramberUsdcReyaLmNodeId = 0xa7feb4d88a1b9a17b11f5d24de36c942f2de2fd3a772b3a05b41f2fdfa45f770;
        sec.rhedgeUsdcReyaLmNodeId = 0xbd07fcdc9f8128e15f88ea40ade2d54e3e6ac19fee580b33b86022a86e7784d4;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.rseliniUsdcReyaLmNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ramberUsdcReyaLmNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.rhedgeUsdcReyaLmNodeId, 10_000);

        sec.srusdUsdcPoolNodeId = 0xc380c1273590e190bc15a196fdb2b5750abdd0eeb868cc8385dd384761e21ddb;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.srusdUsdcPoolNodeId, 10_000);

        // node ids for mark prices
        sec.ethUsdStorkMarkNodeId = 0x3f4c9f3d5efcbd98002f057a6c0acd0313aa63ab20334e611a30261b89acc1fa;
        sec.ethUsdcStorkMarkNodeId = 0x14dba23a7f8775bceefeedb4266fbe135b949ae40fe08e491f2a476d3448c66f;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ethUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ethUsdcStorkMarkNodeId, 10_000);

        sec.btcUsdStorkMarkNodeId = 0x22cc8b806bf8c6761ade13f0f07e7442f3447f5f19115ef16e679e2633a9a99b;
        sec.btcUsdcStorkMarkNodeId = 0xf07b080f0f2546b188eab2a367041bf02293ab2484e3b700700daa05a2bd36da;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.btcUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.btcUsdcStorkMarkNodeId, 10_000);

        sec.solUsdStorkMarkNodeId = 0xf9145aaf4f398421afb433b3c0ab5d7507fb9c9eac58f5be0ce4d7868c207b31;
        sec.solUsdcStorkMarkNodeId = 0xfd68d8ff3f6a78957c7f6ebbcc8ed5ed5d49b4ba89a4a6b806ceb459b19f833a;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.solUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.solUsdcStorkMarkNodeId, 10_000);

        sec.arbUsdStorkMarkNodeId = 0x1529a451b9a30854039881f704059ba0de48f5fee2a56a070826aff37748e91a;
        sec.arbUsdcStorkMarkNodeId = 0x03038f283a2c622701d2a80e720273c3fde14af6e6c2153d911fe5403bf4ce93;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.arbUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.arbUsdcStorkMarkNodeId, 10_000);

        sec.opUsdStorkMarkNodeId = 0x31489adab3911d4377faf88912fd7c9507aa49f7eb80a9a8b25f40021e0a708b;
        sec.opUsdcStorkMarkNodeId = 0xfc4347fdd16540a3386624e641440040b91987e664bff6b4ff72e9e68415d4d6;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.opUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.opUsdcStorkMarkNodeId, 10_000);

        sec.avaxUsdStorkMarkNodeId = 0x504509f270d28c1b0732f22b8f07d7a0818f7ad5091292d89c2c9a25c7ee6f8c;
        sec.avaxUsdcStorkMarkNodeId = 0x8dc0d3487e7a5ba2dbeb8589e42775d3cd070ffc85b0ef13d2eff62d85fb699c;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.avaxUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.avaxUsdcStorkMarkNodeId, 10_000);

        sec.mkrUsdStorkMarkNodeId = 0xc4d8c893a0abab8d741a8e472bfff013332a8553d1a78b0f1a1b8038d45ef601;
        sec.mkrUsdcStorkMarkNodeId = 0x0f6f0722363cd9acba72eec13b265415756e3b4194204d36c3e6db7b3cfa68d6;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.mkrUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.mkrUsdcStorkMarkNodeId, 10_000);

        sec.linkUsdStorkMarkNodeId = 0x56ab4776a8a68d0528cfcd9ac1692788367008f5aff1f036202172b9606abd21;
        sec.linkUsdcStorkMarkNodeId = 0x7a29582bdeee69f780aa7cc9958377fc09d915606f0a2bdb44305eaf3c0f271b;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.linkUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.linkUsdcStorkMarkNodeId, 10_000);

        sec.aaveUsdStorkMarkNodeId = 0xd8925d75e07cdbbdbf014acad19441d82516746863000543da4755e94d38a08c;
        sec.aaveUsdcStorkMarkNodeId = 0xb63d0cd61644a24718427dd1ab9759bd2d4ec5441c5b26c43b5b9c82473caca5;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.aaveUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.aaveUsdcStorkMarkNodeId, 10_000);

        sec.crvUsdStorkMarkNodeId = 0x3cae607a8cf2a313032f6a77459085f9c93aab4180cced4f386a6f00512a6878;
        sec.crvUsdcStorkMarkNodeId = 0x24131e9cde7f76bfc6c06cff3f2c7254deab73059e9b84a2347751ab98c0b119;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.crvUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.crvUsdcStorkMarkNodeId, 10_000);

        sec.uniUsdStorkMarkNodeId = 0xfcf6909d7ebcdc880537b6e25d39f115a4bbc7668ebf4f574cf3c68fb121d837;
        sec.uniUsdcStorkMarkNodeId = 0x716919be64d79e3f8f00a322cd9bb2d93b97c90b193da582dc6dd1ec695988ec;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.uniUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.uniUsdcStorkMarkNodeId, 10_000);

        sec.suiUsdStorkMarkNodeId = 0x9d69e66f5154712f519ed497b77a17e2b05a00005b224fdb71079fa31693ba01;
        sec.suiUsdcStorkMarkNodeId = 0xf98d3bcfe6f1b250ab323441c19451b02b392759c3bd71d25d7853c62d54d721;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.suiUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.suiUsdcStorkMarkNodeId, 10_000);

        sec.tiaUsdStorkMarkNodeId = 0xdbb78b17e0930f034715df6da1da364b071b8420071633a31c5301c1efefc12e;
        sec.tiaUsdcStorkMarkNodeId = 0x8781a9a038ef7154ae74bf74091c585b3e20369cb4839deda466a3f3870fe4ad;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.tiaUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.tiaUsdcStorkMarkNodeId, 10_000);

        sec.seiUsdStorkMarkNodeId = 0xac6a7fe4a2f8ccc19af80e1730c8c927531d18c5d91f0cf22f223a56349a956c;
        sec.seiUsdcStorkMarkNodeId = 0xdb25cea8bc16e7c103c7c91353121aee4c1602a6bdca69b8f3345e82cf072fb8;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.seiUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.seiUsdcStorkMarkNodeId, 10_000);

        sec.zroUsdStorkMarkNodeId = 0x0e7f69e62451c924600c52667620204ca4860d5b99aaffa89586272fd2dfac0d;
        sec.zroUsdcStorkMarkNodeId = 0xb226eaf59843b14dc270fb7f5acf8f35f2efae874559467e18d662839d719d45;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.zroUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.zroUsdcStorkMarkNodeId, 10_000);

        sec.xrpUsdStorkMarkNodeId = 0x8b5c5d6f1392d2f60781513541c47ea5bbfe069fd26e0e3e24728855bad26204;
        sec.xrpUsdcStorkMarkNodeId = 0x021f89de11ff88f0ba2b13191b1d487c52f4e3e974ef39c16ccf4a80e51c5585;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.xrpUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.xrpUsdcStorkMarkNodeId, 10_000);

        sec.wifUsdStorkMarkNodeId = 0xacf9baf8aa41dfae2ae0b267c56b4921a7d282b75c68320959c733fbaabcacfd;
        sec.wifUsdcStorkMarkNodeId = 0x4ac04d3e0f18863b0e8f49c181693dd9fd5baf743d0bdad2abf331ad8f23a2c1;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.wifUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.wifUsdcStorkMarkNodeId, 10_000);

        sec.pepe1kUsdStorkMarkNodeId = 0x9480bba93e2d31cf8225c037294c01cf053b70e1dba05e50d6e0adf28bb061d0;
        sec.pepe1kUsdcStorkMarkNodeId = 0xc83f9dc9ca01e26963e91390144f58e2f059076ef856b26a69b2e8ff654f83dd;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.pepe1kUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.pepe1kUsdcStorkMarkNodeId, 10_000);

        sec.popcatUsdStorkMarkNodeId = 0xb7c8b3bda89cf1add7e3a32abe7887df69a652e5e90d2dddd1d6175dd2659eec;
        sec.popcatUsdcStorkMarkNodeId = 0xd6d19fa9bc0b52d65304b0922eefbd2a9801992a2b248a25d23de4a96b44945f;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.popcatUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.popcatUsdcStorkMarkNodeId, 10_000);

        sec.dogeUsdStorkMarkNodeId = 0xca4f6c1c2afb5c1d58dcf6ff2c317e438698105752b4b4a8ec5146b16b3231b0;
        sec.dogeUsdcStorkMarkNodeId = 0xab1a9978c5f4ddfed2ed6de03fd9a494b8a408fe0a6f8315d7037a214408b64a;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.dogeUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.dogeUsdcStorkMarkNodeId, 10_000);

        sec.kshibUsdStorkMarkNodeId = 0xef275763e813c07a465155af735a70c5fbf67bdcf307eb264e94fa6ed153f456;
        sec.kshibUsdcStorkMarkNodeId = 0x02cc3b32fb0a99c478d6eff8afd94660b0058a57481032de5388c879b96ad130;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.kshibUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.kshibUsdcStorkMarkNodeId, 10_000);

        sec.kbonkUsdStorkMarkNodeId = 0x9eb4beb27bbd482517d29de0fda06c31cb85af89f381f79963bf419a189aeb23;
        sec.kbonkUsdcStorkMarkNodeId = 0x6e7bb4132d6106b8c94e668fa726b5b2e7aad1a7e2520f71db936e6f2b3ab999;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.kbonkUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.kbonkUsdcStorkMarkNodeId, 10_000);

        sec.aptUsdStorkMarkNodeId = 0xb5cfb09144ed6628bd580dc9106de39f3fefb4c8ffd88dfbc8786706e6af6a8f;
        sec.aptUsdcStorkMarkNodeId = 0xea5a9fd16aba5c1c587c431e1fc24db9e2d0625736427e15cd348596af730c48;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.aptUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.aptUsdcStorkMarkNodeId, 10_000);

        sec.bnbUsdStorkMarkNodeId = 0x8ba0a5ed52a142701c13973f37589b6eb9d649c5f57b40bbaf5792c28bc597d9;
        sec.bnbUsdcStorkMarkNodeId = 0x90930907f3859ac1c6db5688efa087135aae0fe59d937e343ead694062b17bfa;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.bnbUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.bnbUsdcStorkMarkNodeId, 10_000);

        sec.jtoUsdStorkMarkNodeId = 0x0e46e740d3a975debc6c27df2b7184284f0cc3e997296098f0aefeb9e617607c;
        sec.jtoUsdcStorkMarkNodeId = 0xe1c6251c1cc58f1a96dc7ba3e8a798487870027319ecb2b866539eb0d57c6d98;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.jtoUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.jtoUsdcStorkMarkNodeId, 10_000);

        sec.adaUsdStorkMarkNodeId = 0x2b1f5e0505e2b216d4a5e439372945daae700cc3b076fada483e0a55abeb70bd;
        sec.adaUsdcStorkMarkNodeId = 0x3ce452f23348c4a1df1c884ef1f0947bb9211d414ef0658c50baf8083e89eab2;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.adaUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.adaUsdcStorkMarkNodeId, 10_000);

        sec.ldoUsdStorkMarkNodeId = 0x1480d0da2f8ebf18e343cd243095b6ff3f6c654b307a7bfef11db916f99e8f80;
        sec.ldoUsdcStorkMarkNodeId = 0x630a05deb69084919f4eae95ef7ebcf7fa34c13e6beed982c6efd9586e73aa7d;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ldoUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ldoUsdcStorkMarkNodeId, 10_000);

        sec.polUsdStorkMarkNodeId = 0xa05eb1786f15f188fe512b28cb3454214334d9405649d424703588cd8401b983;
        sec.polUsdcStorkMarkNodeId = 0xfdb6b666648fd03913c626d194a8e45fd9597d1f6dfd7ca0d37e1de34a9e8a44;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.polUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.polUsdcStorkMarkNodeId, 10_000);

        sec.nearUsdStorkMarkNodeId = 0xc25d299810d171e98fe8a797965eb6664a019f0181724d3cac7d995a7aab9a45;
        sec.nearUsdcStorkMarkNodeId = 0x8c208770d94d827d3fbf0d4e290b807016114aad7c2366e1988995debe8f7935;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.nearUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.nearUsdcStorkMarkNodeId, 10_000);

        // sec.ftmUsdStorkMarkNodeId = 0x76c6895cb63ebd6819a0d63a279d215b28d00dd86ca9144ff0f65e43f96fc2b2;
        // sec.ftmUsdcStorkMarkNodeId = 0xa8e375325d43a550400fe1b9162d43125fd40ab19a39fd142fdb8e352d519a14;
        // vm.prank(sec.multisig);
        // IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ftmUsdStorkMarkNodeId, 10_000);
        // vm.prank(sec.multisig);
        // IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ftmUsdcStorkMarkNodeId, 10_000);

        sec.ftmUsdStorkNodeId = 0x2ebe4d2efbad85f25593a6b340e9cda8ff3d6d88ec5f58cfc781b675eb359f04;
        sec.ftmUsdcStorkNodeId = 0x80199db114f6df2e80694014ed766d5dd81473fb64647287784a17007d2b8796;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ftmUsdStorkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ftmUsdcStorkNodeId, 10_000);

        sec.enaUsdStorkMarkNodeId = 0x8894b428e86881563f6d0cc02f1ebbc0c51dcfac9f04854933dcbafe9a091286;
        sec.enaUsdcStorkMarkNodeId = 0x05baa2ab9655f3f75826acfdc58b493cfb3f9e317170d1e814f6f06daa3d5b14;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.enaUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.enaUsdcStorkMarkNodeId, 10_000);

        sec.eigenUsdStorkMarkNodeId = 0x64ebd12f7caf3158fa64bba08486585a1ee2ab53c67b2508d75963cd59b25d29;
        sec.eigenUsdcStorkMarkNodeId = 0xf86dcc555840a7e61e914538041f091fe3c52b8e8ce392c8ecdb765053953137;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.eigenUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.eigenUsdcStorkMarkNodeId, 10_000);

        sec.pendleUsdStorkMarkNodeId = 0x819e7518f839034c03e68e7753cf045025d9a5a8a526c2d2504d3710c6e6cda8;
        sec.pendleUsdcStorkMarkNodeId = 0xa995ce577688bc12726d237e977e66829cbb99e09fac99a9719d86996898a7cc;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.pendleUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.pendleUsdcStorkMarkNodeId, 10_000);

        sec.goatUsdStorkMarkNodeId = 0x1c4414fcfbce931a22a3a4604fe64e60765692713e06ad919c76958159bdbae4;
        sec.goatUsdcStorkMarkNodeId = 0xafa3dbc8ac85789e782cc5cafc5286660e27ff31729a7135fe616157062304cb;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.goatUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.goatUsdcStorkMarkNodeId, 10_000);

        sec.grassUsdStorkMarkNodeId = 0xd3e85eb7e7c817ee36c2c377eb1c1e6a94b56259f3abfd688042d5d0ece19970;
        sec.grassUsdcStorkMarkNodeId = 0x4e1d074f4e4be6a9c0cfa1f5d858881515936dcebfd8306c366d14708f2e9190;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.grassUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.grassUsdcStorkMarkNodeId, 10_000);

        sec.kneiroUsdStorkMarkNodeId = 0x79509bac2a12e47b0cf7c1511c7f8689096e7a8fc1772808d2866c19c5470f4d;
        sec.kneiroUsdcStorkMarkNodeId = 0xa0bc615fdfbda6cb321b19b2eae8e7b164f41fc10c8393dbdc92ab32f98485fa;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.kneiroUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.kneiroUsdcStorkMarkNodeId, 10_000);

        sec.dotUsdStorkMarkNodeId = 0xb4022a1691f5c8c5b3a09f0b6990454b378448a8d7d624f1eb5ad0b374019ac1;
        sec.dotUsdcStorkMarkNodeId = 0x0f181ed704b343d57ca93d683f1675b9e5a0f3de10e5f579c4fb179b6819045c;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.dotUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.dotUsdcStorkMarkNodeId, 10_000);

        sec.ltcUsdStorkMarkNodeId = 0x16577e7f8dd6431c989a1eef7abc1b0d2062c085b9b4c21b57b05c37732f462e;
        sec.ltcUsdcStorkMarkNodeId = 0x5fe9a27d7bcd215343c19f7f4e89c6a01a9d45b383e084a64c7b175383d9edc2;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ltcUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ltcUsdcStorkMarkNodeId, 10_000);

        sec.pythUsdStorkMarkNodeId = 0x2710537a21c6b2bd8f6dd1170dcc95558e048ef4a549413de9fade6d01b23ff0;
        sec.pythUsdcStorkMarkNodeId = 0xb9089452619f661064443b747273b4cbf94d44de456996276d62cf4e155cc0ed;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.pythUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.pythUsdcStorkMarkNodeId, 10_000);

        sec.jupUsdStorkMarkNodeId = 0xa037efb159c65f7aa7e87494144ae9658f97fd4cf9128b1422c5124b4016148e;
        sec.jupUsdcStorkMarkNodeId = 0x40883d2df144b70606d33f1328197e2627656faa271557f4a31acd733c96379d;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.jupUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.jupUsdcStorkMarkNodeId, 10_000);

        sec.penguUsdStorkMarkNodeId = 0x70713196edbccbb0656594528b434ecfae5dfe47dd375e4fb56274a6e4ebf1fc;
        sec.penguUsdcStorkMarkNodeId = 0x29cfe9e8e20c5c0bdadbb6c884e49e83aa3e46415e6b45b5bb247f72969c990b;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.penguUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.penguUsdcStorkMarkNodeId, 10_000);

        sec.trumpUsdStorkMarkNodeId = 0xf42a67b3f1243214f978cbc4cef886c2e81875145416f3bbb7bd27971fed9e95;
        sec.trumpUsdcStorkMarkNodeId = 0xecd68e5bcfa749395b1b062168b07697918965af15b98428bde2de12fe97e3c8;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.trumpUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.trumpUsdcStorkMarkNodeId, 10_000);

        sec.hypeUsdStorkMarkNodeId = 0xead1efd32fe0933e548b545cc493e4fa0fd84bfef7a35b63a8b54762c492fa5e;
        sec.hypeUsdcStorkMarkNodeId = 0xd676c03848e1bed665a0cdb5a9c0f779a3e05932b3b3e172e60e82ae32e0fb2a;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.hypeUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.hypeUsdcStorkMarkNodeId, 10_000);

        sec.virtualUsdStorkMarkNodeId = 0xeb1ac4c2f76d6a1f7dc9425a08244d8e38ac382158ca15f7abcf452790acb1f8;
        sec.virtualUsdcStorkMarkNodeId = 0x4dfb2b23ea7bf61c2e857df8e4b0f5896617aaba3fcc631f6c8d464101d43ff6;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.virtualUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.virtualUsdcStorkMarkNodeId, 10_000);

        sec.ai16zUsdStorkMarkNodeId = 0x4c375e5ddad34ef7cbdc60fef0641e7ec65c7a8a766f441beaab9747993c8a9a;
        sec.ai16zUsdcStorkMarkNodeId = 0x2c775a3ae4ad1f1114281028b6d18d0484e1877980c35322885cbc3e2bd49770;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ai16zUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ai16zUsdcStorkMarkNodeId, 10_000);

        sec.aixbtUsdStorkMarkNodeId = 0x3eefe4d068948e9d567c841e67d614ce96ba4d131c9ad3fc38f6bcb9bb3b08ff;
        sec.aixbtUsdcStorkMarkNodeId = 0x7bd274a58a43c605234d64d60323be4996e7d0a494063f95ac3eb06cec2bb566;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.aixbtUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.aixbtUsdcStorkMarkNodeId, 10_000);

        sec.sonicUsdStorkMarkNodeId = 0xc3d57ef53e9afea34fad01eba3021a3ed33d362fa2e176716d3213d6fd7da1b0;
        sec.sonicUsdcStorkMarkNodeId = 0xc2677d595a7159ba0d451eab4b6d2bf34918b9ae9ee54c8b680778b00d86e39b;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.sonicUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.sonicUsdcStorkMarkNodeId, 10_000);

        sec.fartcoinUsdStorkMarkNodeId = 0x743cb9ec187bbeae3dc7130e930887b4b5a32de4f7c36a2c915e45c25e92cc60;
        sec.fartcoinUsdcStorkMarkNodeId = 0xd6a7c94b15ca430bab03e4f7fa06485fff89fa85474d13922b43892ec6a8fe80;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.fartcoinUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.fartcoinUsdcStorkMarkNodeId, 10_000);

        sec.griffainUsdStorkMarkNodeId = 0xfa4af4ea5d2238d1fa9c8c6735b166e81908b16d80f03ea7ca4fe786777c629d;
        sec.griffainUsdcStorkMarkNodeId = 0x8d39580b274245a40849b7e33e955252fff843700d819b2c1392b1150674208a;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.griffainUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.griffainUsdcStorkMarkNodeId, 10_000);

        sec.wldUsdStorkMarkNodeId = 0xd7901c508bfbdef85f1cda0414fbd689627f0a31581934cf03893cc6d818fae7;
        sec.wldUsdcStorkMarkNodeId = 0x4d759a96963f6db950df6f180bd3368e58ed335f4afd88e730fe7598419cc76f;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.wldUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.wldUsdcStorkMarkNodeId, 10_000);

        sec.atomUsdStorkMarkNodeId = 0x1d732b62a03c21063d302ef79d29654dc2214da93fdf2cba7539b7568324dcd7;
        sec.atomUsdcStorkMarkNodeId = 0x9f0830fd7a009bc1b3296af09aecda984e3917a5319a5dd8308693d8e5e9d7cf;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.atomUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.atomUsdcStorkMarkNodeId, 10_000);

        sec.apeUsdStorkMarkNodeId = 0xbcce14d1b28b4a6f3909e5fc348155aec4dc9aec4cf3a35b525fb15590b600e0;
        sec.apeUsdcStorkMarkNodeId = 0xc1eed93b5101fb39ca7b80ccc07fe0ab5e76d01881c2bc77af412cc753166d44;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.apeUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.apeUsdcStorkMarkNodeId, 10_000);

        sec.tonUsdStorkMarkNodeId = 0x5219f953773566ab88b4ea5c5e892cc537f4ec6c41ee0e3fe05f01e5efefa1b2;
        sec.tonUsdcStorkMarkNodeId = 0x95f69d27844376c6fce9af2850aa32feecd6530294065c7bef2a7644d28e456f;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.tonUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.tonUsdcStorkMarkNodeId, 10_000);

        sec.ondoUsdStorkMarkNodeId = 0xe6ae89ba88295df9efa6ad4facef67f76db2d33e91f6fff5383c711eb456870b;
        sec.ondoUsdcStorkMarkNodeId = 0xbc2fcb2a52604995f02eabc1ed159c379aac9ca253e67cd357370259c86fac8e;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ondoUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ondoUsdcStorkMarkNodeId, 10_000);

        sec.trxUsdStorkMarkNodeId = 0x3022e8ddfccbee79a13bc8815704b328d569247f34ea2c1198418f4ab7238038;
        sec.trxUsdcStorkMarkNodeId = 0x038e502bf9bf88c351a024b02d65279d6aa8794072530ecdd7cae6e25448541e;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.trxUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.trxUsdcStorkMarkNodeId, 10_000);

        sec.injUsdStorkMarkNodeId = 0x43ceaba5a1b6f85b37ad4337035a5362530b6b6202f076b71216fa1a7275806b;
        sec.injUsdcStorkMarkNodeId = 0x97a0cc1aa18bb21d3c56e735979235f3b321eaac77507eac7ca447a4a06813e8;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.injUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.injUsdcStorkMarkNodeId, 10_000);

        sec.moveUsdStorkMarkNodeId = 0x9218f695dbe45c4122f5ad9f7e27e49b33a9532dea4eeb9372a179d96be4d576;
        sec.moveUsdcStorkMarkNodeId = 0xa5e2a329e4fe870643700a5feb7cd029af49db11a647332275da15728861093b;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.moveUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.moveUsdcStorkMarkNodeId, 10_000);

        sec.beraUsdStorkMarkNodeId = 0xa409a3555a1798a6cd8a28069d341cb54251ee74d17fde864f3f5b3a833e250e;
        sec.beraUsdcStorkMarkNodeId = 0x25b8709fbb45817bf5c6bc2bbfda38639056e2f126b12432aed8891cee03137c;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.beraUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.beraUsdcStorkMarkNodeId, 10_000);

        sec.layerUsdStorkMarkNodeId = 0x42704988d91b163d22875f4fd14f63b4d06fa5a3b10c2e2f7d2fea1c80d01912;
        sec.layerUsdcStorkMarkNodeId = 0x5ed91d0e17c928c1a92286547f627ab70d529dfc44ac075c699f3cfd6be04f27;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.layerUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.layerUsdcStorkMarkNodeId, 10_000);

        sec.taoUsdStorkMarkNodeId = 0x50dc1149bb0526ad1a972e30dc9351e055d1d293acd9d73dd02536678dd3eb50;
        sec.taoUsdcStorkMarkNodeId = 0x4835a6eacc67e2e6cdb64dcda71b8fd4acb85529bb752a891b923bffcc52113e;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.taoUsdStorkMarkNodeId, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.taoUsdcStorkMarkNodeId, 10_000);

        sec.ipUsdMarkNodeIdStork = 0x4d3212bbae56fb95e9b75824d0710e1f7806b7c51179c477d51443e298dcc820;
        sec.ipUsdcMarkNodeIdStork = 0x8873e737081324542be053cf6b5a5085bea0b286b213179655605c61b00972f2;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ipUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.ipUsdcMarkNodeIdStork, 10_000);

        sec.meUsdMarkNodeIdStork = 0xfae3a2446e9839f011c994926ab86942fd60a1a322f942c6cc2e37bc7330311b;
        sec.meUsdcMarkNodeIdStork = 0x731c6c47852578c54f107abe801341a0caa4fe98994737074889b5ae99dbca56;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.meUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.meUsdcMarkNodeIdStork, 10_000);

        sec.pumpUsdMarkNodeIdStork = 0x41eeb8e2c1649ec2ebc5175419a94800923b34871606a1e01e75f34e37ad7d7e;
        sec.pumpUsdcMarkNodeIdStork = 0x23d928fc7a615aa1bc5815a73cc8b0adbcf0c558fa059db6f88ec8b5ca374200;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.pumpUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.pumpUsdcMarkNodeIdStork, 10_000);

        sec.morphoUsdMarkNodeIdStork = 0x699392cebf37e2500e14a7cbad54fc7ae2f570930457bbf4e72354a30f738047;
        sec.morphoUsdcMarkNodeIdStork = 0xbe88e544892eb03fdad7f2d1140a3f556775ef7bbabe4da623bfb963cdd20cea;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.morphoUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.morphoUsdcMarkNodeIdStork, 10_000);

        sec.syrupUsdMarkNodeIdStork = 0x3b777e5a60ea1dd694226967f00f3184b64357657a2208dce62192946e99cc11;
        sec.syrupUsdcMarkNodeIdStork = 0xcd01e77046da17263279ad95b0fd7aad13a860a8dac6783da8dced7ea28b7668;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.syrupUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.syrupUsdcMarkNodeIdStork, 10_000);

        sec.aeroUsdMarkNodeIdStork = 0x0667dc694be98bc6f0fa21920a4b5f706e37f0bf469dda61101988cab4f12d58;
        sec.aeroUsdcMarkNodeIdStork = 0x2254751e98de2c6a6995583467b45855da56b0648dd774b7ed634b2c25f3c3b7;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.aeroUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.aeroUsdcMarkNodeIdStork, 10_000);

        sec.kaitoUsdMarkNodeIdStork = 0xd235f8756a7eef30cccc6b3cfbe4c3f59003202e2f59453315ff25bc70b54f8f;
        sec.kaitoUsdcMarkNodeIdStork = 0x60ff2f24b73a84a40d798042ec653279fba4cfe87bc1f9f88f01fd1d2f725fe0;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.kaitoUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.kaitoUsdcMarkNodeIdStork, 10_000);

        sec.zoraUsdMarkNodeIdStork = 0xd5ce52aad6b86aaa17674000fbccb274d806ec365b2456f5a6e10d062e657640;
        sec.zoraUsdcMarkNodeIdStork = 0x0b7179bfa70d8222d66269db095744b693bb325991de7dea122d65f14ce9921b;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.zoraUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.zoraUsdcMarkNodeIdStork, 10_000);

        sec.proveUsdMarkNodeIdStork = 0xd37f0f083fc9f5bdf4f928fcbbe208e39acf9ef4dd009427cb1cd4cb3c79f4fa;
        sec.proveUsdcMarkNodeIdStork = 0x39facb5fbda497e571b3bbcc584c5b3eddf167237d4b53f857ff1260677e34d8;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.proveUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.proveUsdcMarkNodeIdStork, 10_000);

        sec.paxgUsdMarkNodeIdStork = 0x2e6591ec8e9fb9861d789658211823dbda7b3aa3360ad9f5fc13a139bb87232d;
        sec.paxgUsdcMarkNodeIdStork = 0x18337cb0109e2c6d07e67a2c5d96d08e654489215a7dadac0353f8b017442002;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.paxgUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.paxgUsdcMarkNodeIdStork, 10_000);

        sec.yzyUsdMarkNodeIdStork = 0x71e96471cf338021a9874ef5ba07eeb143d98e8e252ae880bad2fbe9d3f6efe3;
        sec.yzyUsdcMarkNodeIdStork = 0x7697d915eca3e123dd7de6092905d7c4b25058d319266589aa57bc1d527548e2;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.yzyUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.yzyUsdcMarkNodeIdStork, 10_000);

        sec.xplUsdMarkNodeIdStork = 0x76714848e44fa36c28fa261de6ddd76bd61691dfb47ffcb5668dea4364ec4b0f;
        sec.xplUsdcMarkNodeIdStork = 0x25032cbd90ea9c4562e77fcba3f81b823a1f322feb5157ef6d10077fb859e8cc;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.xplUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.xplUsdcMarkNodeIdStork, 10_000);

        sec.wlfiUsdMarkNodeIdStork = 0x7b8b2e305057a36f32dd6db465e850d343c8e1f1fb8338d063922676e79da6f6;
        sec.wlfiUsdcMarkNodeIdStork = 0xf37e6547466075fdc42562174669b88d0940d64db76abfd79518d4d5cb455486;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.wlfiUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.wlfiUsdcMarkNodeIdStork, 10_000);

        sec.lineaUsdMarkNodeIdStork = 0xafff16d3d921bfbd2143af0772237e3436f78fd56e53b941a11c96239e30dd4a;
        sec.lineaUsdcMarkNodeIdStork = 0x37f452dd0ccadedb5b0729674feb1a5007adca3d9e99fd71be2a7f2b472aae98;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.lineaUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.lineaUsdcMarkNodeIdStork, 10_000);

        sec.megaUsdMarkNodeIdStork = 0x3ae1be8518f8794a1d60624977021e7e10375ccda21d0daf628b77340ca6d778;
        sec.megaUsdcMarkNodeIdStork = 0xfd68e2ce436bd0708139c10e54c1024602253f5f254c97bcf569b6b18aaad30f;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.megaUsdMarkNodeIdStork, 10_000);
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.megaUsdcMarkNodeIdStork, 10_000);

        // Socket variables
        dec.socketController[sec.usdc] = 0xf565F766EcafEE809EBaF0c71dCd60ad5EfE0F9e;
        dec.socketExecutionHelper[sec.usdc] = 0x605C8aeB0ED6c51C8A288eCC90d4A3749e4596EE;
        dec.socketConnector[sec.usdc][ethereumSepoliaChainId] = 0x79B607E711853F83002d0649DcCeCA73Bef3F3A7;
        dec.socketConnector[sec.usdc][arbitrumSepoliaChainId] = 0x41CC670dae3f91160f6B64AF46e939223E5C99F9;
        dec.socketConnector[sec.usdc][optimismSepoliaChainId] = 0xc18463EcAC98d34196E098cd2678E688Ef7dE759;

        dec.socketController[sec.weth] = 0x1529413F38b95cE156f54C34471528B6d0Daf2eb;
        dec.socketExecutionHelper[sec.weth] = 0xF1e0f8B07Eb4928922448CBD6f77ac5918f8e032;
        dec.socketConnector[sec.weth][ethereumSepoliaChainId] = 0xD69619c745aD7AaB060727bDC5D46b4E702dEc6F;
        dec.socketConnector[sec.weth][arbitrumSepoliaChainId] = 0xD927149f1fa5E8844464ab7F3C84c77F7ebD0aa8;
        dec.socketConnector[sec.weth][optimismSepoliaChainId] = 0x3395f0c1546DC5eE16EC021523B3E8c0DB861E00;

        dec.socketController[sec.wbtc] = 0x48995c8Cd604B6d473fC094d9BFA936dA962E2Be;
        dec.socketExecutionHelper[sec.wbtc] = 0x38989141D21f6b607a0aE6b626b470d36AceFA84;
        dec.socketConnector[sec.wbtc][ethereumSepoliaChainId] = 0x45B8F521862433c67fEf5d684e259e02A805861F;
        dec.socketConnector[sec.wbtc][arbitrumSepoliaChainId] = 0x6Fa3fD6C9bc223F0E270B28169E3B70f046EcF6b;
        dec.socketConnector[sec.wbtc][optimismSepoliaChainId] = 0x44064CEF6D51d8131dce3ce059844Eaa059d8773;

        dec.socketController[sec.usde] = 0x9f1f05Be3A595C93B604a8d5582B6ba8ED057b74;
        dec.socketExecutionHelper[sec.usde] = 0xFEe7b6deAF61D2b04F6e05c80c2593BF29706410;
        dec.socketConnector[sec.usde][ethereumSepoliaChainId] = 0x6c28616D6bBF8aa79b87C97509f97Af3F362f329;
        dec.socketConnector[sec.usde][arbitrumSepoliaChainId] = 0x4F0A10029d1A7b2266773F598C26E67792320c94;
        dec.socketConnector[sec.usde][optimismSepoliaChainId] = 0x0B5e406e7F6BaB8Cf205bC583a0504135b11D6bB;

        dec.socketController[sec.susde] = 0x23e8Bf0eA7581d0BF82Ff918ea831b96fc62f718;
        dec.socketExecutionHelper[sec.susde] = 0xe06D0387ead9198A013007DB2979104128462772;
        dec.socketConnector[sec.susde][ethereumSepoliaChainId] = 0x98d6E43d66c6F9d824D1B56CF1C77583d7e7793f;
        dec.socketConnector[sec.susde][arbitrumSepoliaChainId] = 0xF79f6c0BadA41F395CDe3a357B1c239D6aBA1B84;
        dec.socketConnector[sec.susde][optimismSepoliaChainId] = 0x502fBd9322a65A1a5a897cfDFB8f179A92b73300;

        dec.socketController[sec.deusd] = 0x3A76507b4493866A161c948f44e696122762f14a;
        dec.socketExecutionHelper[sec.deusd] = 0x7Bbd35e35065a29A6B6DDf2Fe087880567f47655;
        dec.socketConnector[sec.deusd][ethereumSepoliaChainId] = 0x5878357eB1d12f2a3F36D299C9eF6dd3A6B4d29a;

        dec.socketController[sec.sdeusd] = 0x8b798242936f528F53c6c93f045D808367CD01fD;
        dec.socketExecutionHelper[sec.sdeusd] = 0xFaA0313F2a7a48Cc995e01ADC68cb3aAD130Bdaa;
        dec.socketConnector[sec.sdeusd][ethereumSepoliaChainId] = 0x596c0Bb29466cE75A4d1296657AE9275fD4b0912;

        dec.socketController[sec.wsteth] = 0x7C43B88F6AefFD221816436357FB1510c62EF513;
        dec.socketExecutionHelper[sec.wsteth] = 0xA2687d5ff962eF398965680D0200831c484d2C3C;
        dec.socketConnector[sec.wsteth][ethereumSepoliaChainId] = 0x767f02881891453218f4144EbFd2F39b5C8d3B59;
        dec.socketConnector[sec.wsteth][arbitrumSepoliaChainId] = 0x424a422558986C95a8E0E578e4443Afe5358c238;
        dec.socketConnector[sec.wsteth][optimismSepoliaChainId] = 0x5BD8C70073575F30E060c4751672A3d462CdAc8a;

        // create fork
        try vm.activeFork() { }
        catch {
            vm.createSelectFork(sec.REYA_RPC);
        }

        // setup
        // (*) deposit 50m rUSD into the passive pool
        DepositPassivePoolInputs memory inputs =
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: vm.addr(2), minShares: 0 });
        deal(sec.usdc, sec.periphery, 50_000_000e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(50_000_000e6)
        );
        IPeripheryProxy(sec.periphery).depositPassivePool(inputs);

        // (*) allow anyone to publish match orders
        vm.prank(sec.multisig);
        ICoreProxy(sec.core).setFeatureFlagAllowAll(keccak256(bytes("matchOrderPublisher")), true);

        // (*) unpause markets with IDs 17 and 62
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).setFeatureFlagAllowAll(
            0x1e7fed13f60f1960fdaf304238873e3216743817f5d35b1b5ba1d877e2092be3, true
        );
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).setFeatureFlagAllowAll(
            0xd94fe6b0d28029e9b0bc2853dfd3d4ebeaf71dc48257f547d22f3fb421c01ee8, true
        );
    }
}
