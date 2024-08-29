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
        sec.passivePoolId = 1;
        sec.passivePoolAccountId = 4;
        sec.ownerUpgradeModule = 0x3fa74FfE7B278a25877E16f00e73d5F5FA499183;
        sec.mainChainId = ethereumSepoliaChainId;

        sec.rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
        sec.usdcUsdNodeId = 0x11aa53901ced174bb9f60b47d2c2c9a0ed7d51916caf0a072cf96842a800acc3;
        sec.usdcUsdStorkNodeId = 0x28c79729ca502a5cd2565613c087a3bda098a1c78e3f3f45733d03c3482f099d;

        sec.ethUsdNodeId = 0x82eef5437e9009ecf7691ffdae182e5463438c99963d0da9ac8512d0a3679a95;
        sec.ethUsdcNodeId = 0xd0eec92140b39ef035b9b88f0e9a63355f8d60246115a84c439179b46904e841;
        sec.ethUsdStorkNodeId = 0x6f1442b15af1cde852d45cdd67336b330257c9df23834909159097b25b57936c;
        sec.ethUsdcStorkNodeId = 0xb19e4d8ea5f0a3752fbd19515075063f7486e6954b8aa2b3d462c61726c46619;
        sec.ethUsdcStorkFallbackNodeId = 0x0f0a2e1036f9102c8ebad9d0c19e2dee774bcdefd459f5552058167e144ed3ca;

        sec.btcUsdNodeId = 0x9b535a03d6bfaa6d85a3026580f42349e9e26a7067714732d977fc9c1b2c8668;
        sec.btcUsdcNodeId = 0x931f2bb3837fb35ca01ac69b2bdf9ebd60972dca7c1698d377ae243049a9f2c7;
        sec.btcUsdStorkNodeId = 0xc232870be8422ed7d9f74df9dd227b4f53b1f682e14b6b594a41893226a76e84;
        sec.btcUsdcStorkNodeId = 0xc03b30c42ae5497a9b0062d503ae84cc83a9c282b92b0354dfcf80db949bc4dd;
        sec.btcUsdcStorkFallbackNodeId = 0xe83d3a85208a01a94fa56266b73f29ec4d897eb4477659aea702a477a97c7bf1;

        sec.solUsdNodeId = 0x124ba4123aa9d8663863554253e5859480211d1a0160257ccf5d12315aaacce1;
        sec.solUsdcNodeId = 0x5f04732bb640020dd447ac06ef47eae461717fbc6b3ba2f71b3a95e00445a502;
        sec.solUsdStorkNodeId = 0x556ff41dece77a2461e7dd72258a29e46ffc7ac5c6d0edf8001867d551ab21d2;
        sec.solUsdcStorkNodeId = 0xa456e0f61bd6068a3a73176ab1c58b840e57e0a272ca29974d3f0bd709fc96c4;
        sec.solUsdcStorkFallbackNodeId = 0xbc20afac3a933b7c7f814fc8fe08344d5dabe3d154b0584461b677b8568553c8;

        sec.arbUsdNodeId = 0xcc34b2231b502f570ed6c70ba8f7ed657d08aade237bcae7625ae7b8516fddab;
        sec.arbUsdcNodeId = 0x4e568ee2ffcbcb5dd5e37027dc98939e7be9d12c4ff61780c2efbb8e3e57128e;
        sec.arbUsdStorkNodeId = 0x6dd5ac4d5502d0f6e0ebf25a1743ba7e99522070b665e51363d1455d95e6dbfa;
        sec.arbUsdcStorkNodeId = 0xe8f7ec437b0cf8d38198532b389189b2535e902d397e4d6877e9b77d24a5250b;
        sec.arbUsdcStorkFallbackNodeId = 0xf4e627ab5747d3d0ac0f98f4b6eb35a716e666c19087509f7686fa9f835f688a;

        sec.opUsdNodeId = 0x7bb5195bd6b7c7bd928da2b52cae900a5f6262eb32b992ac4d97b4f2c322422c;
        sec.opUsdcNodeId = 0xc0e6ecd826e2c4e4da4aba2af6b0851a23123c50f98d56e9bde32b1af6ad51a2;
        sec.opUsdStorkNodeId = 0x0cbccc1a5534cea8494ee4974ba5f58339ce3b1a26857fc4d3aa4e54e773bd49;
        sec.opUsdcStorkNodeId = 0xbfcb55865b2c2646c494e75d6267d897216b241fb67c28a23658f428bdbadc88;
        sec.opUsdcStorkFallbackNodeId = 0xa209578cbe54887fa0ad99be2fed9a9f5a0678ac2718d00584c6bd541c75b878;

        sec.avaxUsdNodeId = 0x2973a5fc60ce7fd59c68e20eade5cbb56d3f22516f5dbd78d09654de5070df8e;
        sec.avaxUsdcNodeId = 0xa0d3a59fa11788b208ecddbbfe823a52b15af75d8a2260e7ae05e08f860e0d55;
        sec.avaxUsdStorkNodeId = 0x38a286a7e435fa4638bcd32620c5ae070b4be9cd905e696c696f1145b7a5e790;
        sec.avaxUsdcStorkNodeId = 0x242ea32dfc4f37b7d3065d40b8d514718b1f9dbe15bae07e31dd6ec525ca0f20;
        sec.avaxUsdcStorkFallbackNodeId = 0x6d3e9bb53f658df1e64b36627f5f49b07bc516ddf2e247a479ce57ec72cc10af;

        sec.usdeUsdNodeId = 0xbe0af1b6d97a67ac965623147c5df0eb768600fe656fb64e933d6ebbde9b20a3;
        sec.usdeUsdcNodeId = 0xd37e1ea5c381faeadb7df088eb07d98b5f6804e1a876225932c8dd4627116320;
        sec.usdeUsdStorkNodeId = 0x2b30e0b99d6cfb46e7743a6fc93cee722bc36e94b48d99059de050e40294a005;
        sec.usdeUsdcStorkNodeId = 0xf37654fe7d50f92914ddb32104e82b81220be6e73257ef21ac8a49b9dc68193c;
        sec.usdeUsdcStorkFallbackNodeId = 0xc821dc92f6dca0def7db09a186f641c6945cc1d13fb81879434350b77e97d7ac;

        sec.mkrUsdNodeId = 0x7912d76ccc24fcaaae642938aa800060eb51a417f78bfbd2614e704a5e1c654d;
        sec.mkrUsdcNodeId = 0xb6d5c17643033a9fdd9f7c334eff669b5ac7d24078a2f7fd0a1c6c9492656314;
        sec.mkrUsdStorkNodeId = 0xfe7405e631e85b6639d2b367910f5eb4b9fb20f3e63f6994615a3ca4c59673e0;
        sec.mkrUsdcStorkNodeId = 0x57c7f9c7e4149f3f0d0d52ccf2e16773f30f7d86ce2238835b6b21a4369de9b6;
        sec.mkrUsdcStorkFallbackNodeId = 0xbceafdc09744bd3f28d96be29b8681078b7ce2d5f56b5c4b9a376b3302864def;

        sec.linkUsdNodeId = 0x4fd9b8fefdedd721960f645a094ed2440a8c66a2fe2155850c906cd11584d96c;
        sec.linkUsdcNodeId = 0x7310324711693666d0af13f17be5aa6a35944f4b26378de1c2145e9603974fc4;
        sec.linkUsdStorkNodeId = 0x3e969ab77d54bfdc9035abd97390ed6e8877c69a41241c15e833805fa863b010;
        sec.linkUsdcStorkNodeId = 0xf47e4aaaaa8da8abe2d41c74a53490ca2c2937c6a541f4a3c74383b4b3ad63eb;
        sec.linkUsdcStorkFallbackNodeId = 0xcb3098ea289c21ee1fb27a37b9a3fa7dd8ed86c2dbde2e948342510b32fecf1b;

        sec.aaveUsdNodeId = 0x52b638c5eb43dc48a5a6894d3b99548bd20c6c24d82e8c32f4e392f4a37729d9;
        sec.aaveUsdcNodeId = 0xf48d83445dc0007a52c6181f70459a003368796132feed02347627b9d555f363;
        sec.aaveUsdStorkNodeId = 0xeb4102b6e24d4f3446be08989c92709eb4c1660661686f815cf0272376890bec;
        sec.aaveUsdcStorkNodeId = 0x725ae24c374c3a2530285b2a27dbc5b946b6dbc8706c4bb436b0be1698666b8b;
        sec.aaveUsdcStorkFallbackNodeId = 0x983afacbf92b5aab21b4927cc7516af24e56cfa500ac477da89f56b8ba7fe999;

        sec.crvUsdNodeId = 0x0a2b8aa034752df828605194f02ec6227a84ad26e452d23203a90e8bbb864bb8;
        sec.crvUsdcNodeId = 0xe791c83f95269f70f5f07c0aa698e10d804b386e94f7f15006eda496237eb04a;
        sec.crvUsdStorkNodeId = 0xd8bef3655106c404f35eaefcc644b4982945622d73feaf13d75384f0f8ef7767;
        sec.crvUsdcStorkNodeId = 0xba95f5cb01117ab4ef95361c8ed3e5d14ca978151d86c5b780476e09fedfcd96;
        sec.crvUsdcStorkFallbackNodeId = 0x168a4c6d873dafb9887009f8bde06de6a9e2a17efaeeb7a7ff4fd6d0d61dfefa;

        sec.uniUsdNodeId = 0xe696757f37d427a9a75879336ba46b647057c4a06c70a4d755897e03d7baac5c;
        sec.uniUsdcNodeId = 0x638ac95f3b619ce7aadc3ce45f5b50fc7edb34d698b854016ab2b84898364cab;
        sec.uniUsdStorkNodeId = 0x048c9edf714da7ffd6db911b0850c19d5e01a99e672e07ca7f2e69d9b5895b1e;
        sec.uniUsdcStorkNodeId = 0xc9394a17ca789f672ec03fd364427a79ecaa752f1ccd17635e1cbbb73df3cd21;
        sec.uniUsdcStorkFallbackNodeId = 0x69210ee3b4c66560b3d5e5dde8943cc8b2a112afdb7e21b55863c95c6b2c36fb;

        sec.susdeUsdNodeId = 0x49d06a2cb959600d11400d550d9e3755e0a936565dfec5f29e6b02dfc96ac6a4;
        sec.susdeUsdcNodeId = 0xd7275f9d50b4d64655b3a0150ad151368db0d2cac51dc0b185df99c3141324da;
        sec.susdeUsdStorkNodeId = 0x6497f91ed5f0057fcc55c01ddb28210776431a7e87035393cff808e98eb70d55;
        sec.susdeUsdcStorkNodeId = 0x1f12d26562a7ed66f142fcc9574045808ff6b0fece27a061ef4f7b5039902735;
        sec.susdeUsdcStorkFallbackNodeId = 0x8cfa7cb4d7e1144ce9259ffe5c9c557ef199ec8e65fa7cf856c1e57a4858d600;

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
