pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";

import { BaseReyaForkTest } from "../reya_common/BaseReyaForkTest.sol";
import "../reya_common/DataTypes.sol";

import { IPeripheryProxy, DepositPassivePoolInputs } from "../../src/interfaces/IPeripheryProxy.sol";

import { ISocketExecutionHelper } from "../../src/interfaces/ISocketExecutionHelper.sol";

contract ReyaForkTest is BaseReyaForkTest {
    constructor() {
        sec.REYA_RPC = "https://rpc.reya-cronos.gelato.digital";
        sec.multisig = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;
        sec.core = payable(0xC6fB022962e1426F4e0ec9D2F8861c57926E9f72);
        sec.pool = payable(0x9A3A664987b88790A6FDC1632e3b607813fd94fF);
        sec.perp = payable(0x9EC177fed042eF2307928BE2F5CDbf663B20244B);
        sec.oracleManager = 0x689f13829e9b218841a0Cf59f44bD5c92F0d64eA;
        sec.oracleAdaptersProxy = payable(0xc501A2356703CD351703D68963c6F4136120f7CF);
        sec.periphery = payable(0x94ccAe812f1647696754412082dd6684C2366A7f);
        sec.ordersGateway = payable(0x5A0aC2f89E0BDeaFC5C549e354842210A3e87CA5);
        sec.exchangePass = 0x1Acd15A57Aff698440262A2A13AE22F8Ff2FA0cB;
        sec.accountNft = 0xeA13E7dA71E018160019A296Eca4184Ddc53aeB1;
        sec.rusd = 0x9DE724e7b3facF87Ce39465D3D712717182e3e55;
        sec.usdc = 0xfA27c7c6051344263533cc365274d9569b0272A8;
        sec.weth = 0x2CF56315ACC7E791B1A0135c09d8D5C8dBCD2F14;
        sec.usde = 0xDca6971c26fDEE0536Fdff076D063643f7810621;
        sec.wbtc = 0x459374F3f3E92728bCa838DfA8C95E706FE67E8a;
        sec.susde = 0x08A766935478A1632FA776DCEbD3E75Ce88A1034;
        sec.deusd = 0x3b9D28dC180813a106d26778135Ac2A674F89957;
        sec.sdeusd = 0xbEB316680B6fcd2dC3aF1fC933B3A27a2513d89D;
        sec.passivePoolId = 1;
        sec.passivePoolAccountId = 4;
        sec.ownerUpgradeModule = 0x3fa74FfE7B278a25877E16f00e73d5F5FA499183;
        sec.mainChainId = ethereumSepoliaChainId;

        sec.rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
        // sec.usdcUsdNodeId = 0x11aa53901ced174bb9f60b47d2c2c9a0ed7d51916caf0a072cf96842a800acc3;
        sec.usdcUsdStorkNodeId = 0x28c79729ca502a5cd2565613c087a3bda098a1c78e3f3f45733d03c3482f099d;

        // sec.ethUsdNodeId = 0x82eef5437e9009ecf7691ffdae182e5463438c99963d0da9ac8512d0a3679a95;
        // sec.ethUsdcNodeId = 0xd0eec92140b39ef035b9b88f0e9a63355f8d60246115a84c439179b46904e841;
        sec.ethUsdStorkNodeId = 0x6f1442b15af1cde852d45cdd67336b330257c9df23834909159097b25b57936c;
        sec.ethUsdcStorkNodeId = 0xb19e4d8ea5f0a3752fbd19515075063f7486e6954b8aa2b3d462c61726c46619;
        // sec.ethUsdcStorkFallbackNodeId = 0x0f0a2e1036f9102c8ebad9d0c19e2dee774bcdefd459f5552058167e144ed3ca;
        sec.ethUsdStorkMarkNodeId = 0x3f4c9f3d5efcbd98002f057a6c0acd0313aa63ab20334e611a30261b89acc1fa;
        sec.ethUsdcStorkMarkNodeId = 0x14dba23a7f8775bceefeedb4266fbe135b949ae40fe08e491f2a476d3448c66f;

        // sec.btcUsdNodeId = 0x9b535a03d6bfaa6d85a3026580f42349e9e26a7067714732d977fc9c1b2c8668;
        // sec.btcUsdcNodeId = 0x931f2bb3837fb35ca01ac69b2bdf9ebd60972dca7c1698d377ae243049a9f2c7;
        // sec.btcUsdStorkNodeId = 0xc232870be8422ed7d9f74df9dd227b4f53b1f682e14b6b594a41893226a76e84;
        // sec.btcUsdcStorkNodeId = 0xc03b30c42ae5497a9b0062d503ae84cc83a9c282b92b0354dfcf80db949bc4dd;
        // sec.btcUsdcStorkFallbackNodeId = 0xe83d3a85208a01a94fa56266b73f29ec4d897eb4477659aea702a477a97c7bf1;
        sec.btcUsdStorkMarkNodeId = 0x22cc8b806bf8c6761ade13f0f07e7442f3447f5f19115ef16e679e2633a9a99b;
        sec.btcUsdcStorkMarkNodeId = 0xf07b080f0f2546b188eab2a367041bf02293ab2484e3b700700daa05a2bd36da;

        // sec.solUsdNodeId = 0x124ba4123aa9d8663863554253e5859480211d1a0160257ccf5d12315aaacce1;
        // sec.solUsdcNodeId = 0x5f04732bb640020dd447ac06ef47eae461717fbc6b3ba2f71b3a95e00445a502;
        // sec.solUsdStorkNodeId = 0x556ff41dece77a2461e7dd72258a29e46ffc7ac5c6d0edf8001867d551ab21d2;
        // sec.solUsdcStorkNodeId = 0xa456e0f61bd6068a3a73176ab1c58b840e57e0a272ca29974d3f0bd709fc96c4;
        // sec.solUsdcStorkFallbackNodeId = 0xbc20afac3a933b7c7f814fc8fe08344d5dabe3d154b0584461b677b8568553c8;
        sec.solUsdStorkMarkNodeId = 0xf9145aaf4f398421afb433b3c0ab5d7507fb9c9eac58f5be0ce4d7868c207b31;
        sec.solUsdcStorkMarkNodeId = 0xfd68d8ff3f6a78957c7f6ebbcc8ed5ed5d49b4ba89a4a6b806ceb459b19f833a;

        // sec.arbUsdNodeId = 0xcc34b2231b502f570ed6c70ba8f7ed657d08aade237bcae7625ae7b8516fddab;
        // sec.arbUsdcNodeId = 0x4e568ee2ffcbcb5dd5e37027dc98939e7be9d12c4ff61780c2efbb8e3e57128e;
        // sec.arbUsdStorkNodeId = 0x6dd5ac4d5502d0f6e0ebf25a1743ba7e99522070b665e51363d1455d95e6dbfa;
        // sec.arbUsdcStorkNodeId = 0xe8f7ec437b0cf8d38198532b389189b2535e902d397e4d6877e9b77d24a5250b;
        // sec.arbUsdcStorkFallbackNodeId = 0xf4e627ab5747d3d0ac0f98f4b6eb35a716e666c19087509f7686fa9f835f688a;
        sec.arbUsdStorkMarkNodeId = 0x1529a451b9a30854039881f704059ba0de48f5fee2a56a070826aff37748e91a;
        sec.arbUsdcStorkMarkNodeId = 0x03038f283a2c622701d2a80e720273c3fde14af6e6c2153d911fe5403bf4ce93;

        // sec.opUsdNodeId = 0x7bb5195bd6b7c7bd928da2b52cae900a5f6262eb32b992ac4d97b4f2c322422c;
        // sec.opUsdcNodeId = 0xc0e6ecd826e2c4e4da4aba2af6b0851a23123c50f98d56e9bde32b1af6ad51a2;
        // sec.opUsdStorkNodeId = 0x0cbccc1a5534cea8494ee4974ba5f58339ce3b1a26857fc4d3aa4e54e773bd49;
        // sec.opUsdcStorkNodeId = 0xbfcb55865b2c2646c494e75d6267d897216b241fb67c28a23658f428bdbadc88;
        // sec.opUsdcStorkFallbackNodeId = 0xa209578cbe54887fa0ad99be2fed9a9f5a0678ac2718d00584c6bd541c75b878;
        sec.opUsdStorkMarkNodeId = 0x31489adab3911d4377faf88912fd7c9507aa49f7eb80a9a8b25f40021e0a708b;
        sec.opUsdcStorkMarkNodeId = 0xfc4347fdd16540a3386624e641440040b91987e664bff6b4ff72e9e68415d4d6;

        // sec.avaxUsdNodeId = 0x2973a5fc60ce7fd59c68e20eade5cbb56d3f22516f5dbd78d09654de5070df8e;
        // sec.avaxUsdcNodeId = 0xa0d3a59fa11788b208ecddbbfe823a52b15af75d8a2260e7ae05e08f860e0d55;
        // sec.avaxUsdStorkNodeId = 0x38a286a7e435fa4638bcd32620c5ae070b4be9cd905e696c696f1145b7a5e790;
        // sec.avaxUsdcStorkNodeId = 0x242ea32dfc4f37b7d3065d40b8d514718b1f9dbe15bae07e31dd6ec525ca0f20;
        // sec.avaxUsdcStorkFallbackNodeId = 0x6d3e9bb53f658df1e64b36627f5f49b07bc516ddf2e247a479ce57ec72cc10af;
        sec.avaxUsdStorkMarkNodeId = 0x504509f270d28c1b0732f22b8f07d7a0818f7ad5091292d89c2c9a25c7ee6f8c;
        sec.avaxUsdcStorkMarkNodeId = 0x8dc0d3487e7a5ba2dbeb8589e42775d3cd070ffc85b0ef13d2eff62d85fb699c;

        // sec.usdeUsdNodeId = 0xbe0af1b6d97a67ac965623147c5df0eb768600fe656fb64e933d6ebbde9b20a3;
        // sec.usdeUsdcNodeId = 0xd37e1ea5c381faeadb7df088eb07d98b5f6804e1a876225932c8dd4627116320;
        sec.usdeUsdStorkNodeId = 0x2b30e0b99d6cfb46e7743a6fc93cee722bc36e94b48d99059de050e40294a005;
        sec.usdeUsdcStorkNodeId = 0xf37654fe7d50f92914ddb32104e82b81220be6e73257ef21ac8a49b9dc68193c;
        // sec.usdeUsdcStorkFallbackNodeId = 0xc821dc92f6dca0def7db09a186f641c6945cc1d13fb81879434350b77e97d7ac;

        // sec.mkrUsdNodeId = 0x7912d76ccc24fcaaae642938aa800060eb51a417f78bfbd2614e704a5e1c654d;
        // sec.mkrUsdcNodeId = 0xb6d5c17643033a9fdd9f7c334eff669b5ac7d24078a2f7fd0a1c6c9492656314;
        // sec.mkrUsdStorkNodeId = 0xfe7405e631e85b6639d2b367910f5eb4b9fb20f3e63f6994615a3ca4c59673e0;
        // sec.mkrUsdcStorkNodeId = 0x57c7f9c7e4149f3f0d0d52ccf2e16773f30f7d86ce2238835b6b21a4369de9b6;
        // sec.mkrUsdcStorkFallbackNodeId = 0xbceafdc09744bd3f28d96be29b8681078b7ce2d5f56b5c4b9a376b3302864def;
        sec.mkrUsdStorkMarkNodeId = 0xc4d8c893a0abab8d741a8e472bfff013332a8553d1a78b0f1a1b8038d45ef601;
        sec.mkrUsdcStorkMarkNodeId = 0x0f6f0722363cd9acba72eec13b265415756e3b4194204d36c3e6db7b3cfa68d6;

        // sec.linkUsdNodeId = 0x4fd9b8fefdedd721960f645a094ed2440a8c66a2fe2155850c906cd11584d96c;
        // sec.linkUsdcNodeId = 0x7310324711693666d0af13f17be5aa6a35944f4b26378de1c2145e9603974fc4;
        // sec.linkUsdStorkNodeId = 0x3e969ab77d54bfdc9035abd97390ed6e8877c69a41241c15e833805fa863b010;
        // sec.linkUsdcStorkNodeId = 0xf47e4aaaaa8da8abe2d41c74a53490ca2c2937c6a541f4a3c74383b4b3ad63eb;
        // sec.linkUsdcStorkFallbackNodeId = 0xcb3098ea289c21ee1fb27a37b9a3fa7dd8ed86c2dbde2e948342510b32fecf1b;
        sec.linkUsdStorkMarkNodeId = 0x56ab4776a8a68d0528cfcd9ac1692788367008f5aff1f036202172b9606abd21;
        sec.linkUsdcStorkMarkNodeId = 0x7a29582bdeee69f780aa7cc9958377fc09d915606f0a2bdb44305eaf3c0f271b;

        // sec.aaveUsdNodeId = 0x52b638c5eb43dc48a5a6894d3b99548bd20c6c24d82e8c32f4e392f4a37729d9;
        // sec.aaveUsdcNodeId = 0xf48d83445dc0007a52c6181f70459a003368796132feed02347627b9d555f363;
        // sec.aaveUsdStorkNodeId = 0xeb4102b6e24d4f3446be08989c92709eb4c1660661686f815cf0272376890bec;
        // sec.aaveUsdcStorkNodeId = 0x725ae24c374c3a2530285b2a27dbc5b946b6dbc8706c4bb436b0be1698666b8b;
        // sec.aaveUsdcStorkFallbackNodeId = 0x983afacbf92b5aab21b4927cc7516af24e56cfa500ac477da89f56b8ba7fe999;
        sec.aaveUsdStorkMarkNodeId = 0xd8925d75e07cdbbdbf014acad19441d82516746863000543da4755e94d38a08c;
        sec.aaveUsdcStorkMarkNodeId = 0xb63d0cd61644a24718427dd1ab9759bd2d4ec5441c5b26c43b5b9c82473caca5;

        // sec.crvUsdNodeId = 0x0a2b8aa034752df828605194f02ec6227a84ad26e452d23203a90e8bbb864bb8;
        // sec.crvUsdcNodeId = 0xe791c83f95269f70f5f07c0aa698e10d804b386e94f7f15006eda496237eb04a;
        // sec.crvUsdStorkNodeId = 0xd8bef3655106c404f35eaefcc644b4982945622d73feaf13d75384f0f8ef7767;
        // sec.crvUsdcStorkNodeId = 0xba95f5cb01117ab4ef95361c8ed3e5d14ca978151d86c5b780476e09fedfcd96;
        // sec.crvUsdcStorkFallbackNodeId = 0x168a4c6d873dafb9887009f8bde06de6a9e2a17efaeeb7a7ff4fd6d0d61dfefa;
        sec.crvUsdStorkMarkNodeId = 0x3cae607a8cf2a313032f6a77459085f9c93aab4180cced4f386a6f00512a6878;
        sec.crvUsdcStorkMarkNodeId = 0x24131e9cde7f76bfc6c06cff3f2c7254deab73059e9b84a2347751ab98c0b119;

        // sec.uniUsdNodeId = 0xe696757f37d427a9a75879336ba46b647057c4a06c70a4d755897e03d7baac5c;
        // sec.uniUsdcNodeId = 0x638ac95f3b619ce7aadc3ce45f5b50fc7edb34d698b854016ab2b84898364cab;
        // sec.uniUsdStorkNodeId = 0x048c9edf714da7ffd6db911b0850c19d5e01a99e672e07ca7f2e69d9b5895b1e;
        // sec.uniUsdcStorkNodeId = 0xc9394a17ca789f672ec03fd364427a79ecaa752f1ccd17635e1cbbb73df3cd21;
        // sec.uniUsdcStorkFallbackNodeId = 0x69210ee3b4c66560b3d5e5dde8943cc8b2a112afdb7e21b55863c95c6b2c36fb;
        sec.uniUsdStorkMarkNodeId = 0xfcf6909d7ebcdc880537b6e25d39f115a4bbc7668ebf4f574cf3c68fb121d837;
        sec.uniUsdcStorkMarkNodeId = 0x716919be64d79e3f8f00a322cd9bb2d93b97c90b193da582dc6dd1ec695988ec;

        sec.suiUsdStorkMarkNodeId = 0x9d69e66f5154712f519ed497b77a17e2b05a00005b224fdb71079fa31693ba01;
        sec.suiUsdcStorkMarkNodeId = 0xf98d3bcfe6f1b250ab323441c19451b02b392759c3bd71d25d7853c62d54d721;

        sec.tiaUsdStorkMarkNodeId = 0xdbb78b17e0930f034715df6da1da364b071b8420071633a31c5301c1efefc12e;
        sec.tiaUsdcStorkMarkNodeId = 0x8781a9a038ef7154ae74bf74091c585b3e20369cb4839deda466a3f3870fe4ad;

        sec.seiUsdStorkMarkNodeId = 0xac6a7fe4a2f8ccc19af80e1730c8c927531d18c5d91f0cf22f223a56349a956c;
        sec.seiUsdcStorkMarkNodeId = 0xdb25cea8bc16e7c103c7c91353121aee4c1602a6bdca69b8f3345e82cf072fb8;

        sec.zroUsdStorkMarkNodeId = 0x0e7f69e62451c924600c52667620204ca4860d5b99aaffa89586272fd2dfac0d;
        sec.zroUsdcStorkMarkNodeId = 0xb226eaf59843b14dc270fb7f5acf8f35f2efae874559467e18d662839d719d45;

        sec.xrpUsdStorkMarkNodeId = 0x8b5c5d6f1392d2f60781513541c47ea5bbfe069fd26e0e3e24728855bad26204;
        sec.xrpUsdcStorkMarkNodeId = 0x021f89de11ff88f0ba2b13191b1d487c52f4e3e974ef39c16ccf4a80e51c5585;

        sec.wifUsdStorkMarkNodeId = 0xacf9baf8aa41dfae2ae0b267c56b4921a7d282b75c68320959c733fbaabcacfd;
        sec.wifUsdcStorkMarkNodeId = 0x4ac04d3e0f18863b0e8f49c181693dd9fd5baf743d0bdad2abf331ad8f23a2c1;

        sec.pepe1kUsdStorkMarkNodeId = 0x9480bba93e2d31cf8225c037294c01cf053b70e1dba05e50d6e0adf28bb061d0;
        sec.pepe1kUsdcStorkMarkNodeId = 0xc83f9dc9ca01e26963e91390144f58e2f059076ef856b26a69b2e8ff654f83dd;

        // sec.susdeUsdNodeId = 0x49d06a2cb959600d11400d550d9e3755e0a936565dfec5f29e6b02dfc96ac6a4;
        // sec.susdeUsdcNodeId = 0xd7275f9d50b4d64655b3a0150ad151368db0d2cac51dc0b185df99c3141324da;
        sec.susdeUsdStorkNodeId = 0x6497f91ed5f0057fcc55c01ddb28210776431a7e87035393cff808e98eb70d55;
        sec.susdeUsdcStorkNodeId = 0x1f12d26562a7ed66f142fcc9574045808ff6b0fece27a061ef4f7b5039902735;
        // sec.susdeUsdcStorkFallbackNodeId = 0x8cfa7cb4d7e1144ce9259ffe5c9c557ef199ec8e65fa7cf856c1e57a4858d600;

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

        try vm.activeFork() { }
        catch {
            vm.createSelectFork(sec.REYA_RPC);
        }

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
    }
}
