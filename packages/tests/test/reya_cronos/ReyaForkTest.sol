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
        sec.periphery = payable(0x94ccAe812f1647696754412082dd6684C2366A7f);
        sec.exchangePass = 0x1Acd15A57Aff698440262A2A13AE22F8Ff2FA0cB;
        sec.accountNft = 0xeA13E7dA71E018160019A296Eca4184Ddc53aeB1;
        sec.rusd = 0x9DE724e7b3facF87Ce39465D3D712717182e3e55;
        sec.usdc = 0xfA27c7c6051344263533cc365274d9569b0272A8;
        sec.weth = 0x2CF56315ACC7E791B1A0135c09d8D5C8dBCD2F14;
        sec.wbtc = 0x459374F3f3E92728bCa838DfA8C95E706FE67E8a;
        sec.ethUsdNodeId = 0x82eef5437e9009ecf7691ffdae182e5463438c99963d0da9ac8512d0a3679a95;
        sec.btcUsdNodeId = 0x9b535a03d6bfaa6d85a3026580f42349e9e26a7067714732d977fc9c1b2c8668;
        sec.solUsdNodeId = 0x124ba4123aa9d8663863554253e5859480211d1a0160257ccf5d12315aaacce1;
        sec.ethUsdcNodeId = 0xd0eec92140b39ef035b9b88f0e9a63355f8d60246115a84c439179b46904e841;
        sec.btcUsdcNodeId = 0x931f2bb3837fb35ca01ac69b2bdf9ebd60972dca7c1698d377ae243049a9f2c7;
        sec.solUsdcNodeId = 0x5f04732bb640020dd447ac06ef47eae461717fbc6b3ba2f71b3a95e00445a502;
        sec.rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
        sec.usdcUsdNodeId = 0x11aa53901ced174bb9f60b47d2c2c9a0ed7d51916caf0a072cf96842a800acc3;
        sec.passivePoolId = 1;
        sec.passivePoolAccountId = 4;
        sec.ownerUpgradeModule = 0x3fa74FfE7B278a25877E16f00e73d5F5FA499183;
        sec.mainChainId = ethereumSepoliaChainId;

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
