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
        sec.ethUsdNodeId = 0xe535c0a694829043f5ceb1ae7ca31e59131c2baebcfed471948825fab5847908;
        sec.btcUsdNodeId = 0xc3872a0f0ad19df9507958fc853aa2eeb8c310ebf41d8b896f8f04bef28b4a71;
        sec.ethUsdcNodeId = 0xb923a96f82aa7d451bfd4535cc6d69d562ff14a9ca3313c0e1b0ce2a8d437e6e;
        sec.btcUsdcNodeId = 0xb80df122e81265b25592e717208f7b581ba4c9d1283169118b0b7a0dbd71a432;
        sec.rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
        sec.usdcUsdNodeId = 0x79f38fc54e618dd0f51d93019b49ac198fe3bcbe3242a3ab5c182e0f015fb2df;
        sec.passivePoolId = 1;
        sec.passivePoolAccountId = 4;
        sec.ownerUpgradeModule = 0x3fa74FfE7B278a25877E16f00e73d5F5FA499183;
        sec.mainChainId = ethereumSepoliaChainId;

        dec.socketController[sec.usdc] = 0x0000000000000000000000000000000000000001;
        dec.socketExecutionHelper[sec.usdc] = 0x0000000000000000000000000000000000000001;
        dec.socketConnector[sec.usdc][ethereumSepoliaChainId] = 0x0000000000000000000000000000000000000001;
        dec.socketConnector[sec.usdc][polygonMumbaiChainId] = 0x0000000000000000000000000000000000000001;
        dec.socketConnector[sec.usdc][arbitrumSepoliaChainId] = 0x0000000000000000000000000000000000000001;
        dec.socketConnector[sec.usdc][optimismSepoliaChainId] = 0x0000000000000000000000000000000000000001;

        dec.socketController[sec.weth] = 0x0000000000000000000000000000000000000001;
        dec.socketExecutionHelper[sec.weth] = 0x0000000000000000000000000000000000000001;
        dec.socketConnector[sec.weth][ethereumSepoliaChainId] = 0x0000000000000000000000000000000000000001;
        dec.socketConnector[sec.weth][polygonMumbaiChainId] = 0x0000000000000000000000000000000000000001;
        dec.socketConnector[sec.weth][arbitrumSepoliaChainId] = 0x0000000000000000000000000000000000000001;
        dec.socketConnector[sec.weth][optimismSepoliaChainId] = 0x0000000000000000000000000000000000000001;

        dec.socketController[sec.wbtc] = 0x0000000000000000000000000000000000000001;
        dec.socketExecutionHelper[sec.wbtc] = 0x0000000000000000000000000000000000000001;
        dec.socketConnector[sec.wbtc][ethereumSepoliaChainId] = 0x0000000000000000000000000000000000000001;
        dec.socketConnector[sec.wbtc][polygonMumbaiChainId] = 0x0000000000000000000000000000000000000001;
        dec.socketConnector[sec.wbtc][arbitrumSepoliaChainId] = 0x0000000000000000000000000000000000000001;
        dec.socketConnector[sec.wbtc][optimismSepoliaChainId] = 0x0000000000000000000000000000000000000001;

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
