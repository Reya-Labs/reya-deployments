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
        sec.wbtc = 0x459374F3f3E92728bCa838DfA8C95E706FE67E8a;
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
