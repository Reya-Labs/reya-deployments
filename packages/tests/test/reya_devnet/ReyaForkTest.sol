pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";

import { BaseReyaForkTest } from "../reya_common/BaseReyaForkTest.sol";
import "../reya_common/DataTypes.sol";

import { IOracleManagerProxy } from "../../src/interfaces/IOracleManagerProxy.sol";

/**
 * @title ReyaForkTest (Devnet)
 * @notice Devnet environment configuration for perpOB fork tests
 * @dev Shares the Cronos testnet chain (chainId 89346162) but uses fresh proxy deployments.
 *      Minimal setup: 1 perp market (ETH), 1 spot market (WETH), 2 collaterals (rUSD, wETH).
 *      No passive pool counterparty — uses dedicated backstop liquidator account.
 *
 */
contract ReyaForkTest is BaseReyaForkTest {
    constructor() {
        string memory rpcKey = vm.envString("RPC_KEY");
        // network (same chain as cronos testnet)
        sec.REYA_RPC = string.concat("https://rpc.reya-cronos.gelato.digital/", rpcKey);
        sec.MAINNET_RPC = "https://gateway.tenderly.co/public/sepolia";

        // other (external) chain id
        sec.destinationChainId = ethereumSepoliaChainId;

        // multisigs (devnet owner)
        sec.multisig = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;

        // Reya contracts (deterministic CREATE2 addresses from devnet cannon deployment)
        sec.core = payable(0xC33D0A4FC05aF98447126f1680cA7316de29e5d4);
        sec.pool = payable(0x9A3A664987b88790A6FDC1632e3b607813fd94fF); // reused Cronos PassivePool
        sec.perp = payable(0x6f42DB6d75Da0B85bDd386b96Cbfb73416AB37A4);
        sec.oracleManager = 0x689f13829e9b218841a0Cf59f44bD5c92F0d64eA; // reused Cronos
        sec.periphery = payable(0xDEDbde7e82B66E499b8FC8a472a5E857be1494DE);
        sec.ordersGateway = payable(0x7Ec89E555c771D2B5939aBE5C4E4291852633D4D);
        sec.oracleAdaptersProxy = payable(0xc501A2356703CD351703D68963c6F4136120f7CF); // reused Cronos
        sec.exchangePass = 0x1Acd15A57Aff698440262A2A13AE22F8Ff2FA0cB; // reused Cronos
        sec.accountNft = 0x73e29C9EeE1db0725A6c352D705137416870E870;

        // Reya tokens (reuse Cronos testnet token deployments)
        sec.rusd = 0x9DE724e7b3facF87Ce39465D3D712717182e3e55;
        sec.usdc = 0xfA27c7c6051344263533cc365274d9569b0272A8;
        sec.weth = 0x2CF56315ACC7E791B1A0135c09d8D5C8dBCD2F14;

        // Reya variables
        sec.passivePoolId = 1;
        sec.passivePoolAccountId = 0; // no passive pool counterparty in devnet

        // Reya bots
        sec.coExecutionBot = 0xc9A01c03AEE926B89b83F7781b15B822807E1d33;
        sec.setMarketZeroFeeBot = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;

        // Spot oracle node ids (reuse Cronos Stork nodes for ETH spot price)
        sec.ethUsdStorkNodeId = 0x6f1442b15af1cde852d45cdd67336b330257c9df23834909159097b25b57936c;
        sec.ethUsdcStorkNodeId = 0xb19e4d8ea5f0a3752fbd19515075063f7486e6954b8aa2b3d462c61726c46619;
        sec.rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
        sec.usdcUsdStorkNodeId = 0x28c79729ca502a5cd2565613c087a3bda098a1c78e3f3f45733d03c3482f099d;

        // Mark price node ids (ETH only — may differ from cronos after perpOB deploy)
        sec.ethUsdStorkMarkNodeId = 0x3f4c9f3d5efcbd98002f057a6c0acd0313aa63ab20334e611a30261b89acc1fa;
        sec.ethUsdcStorkMarkNodeId = 0x14dba23a7f8775bceefeedb4266fbe135b949ae40fe08e491f2a476d3448c66f;

        // Socket variables (reuse Cronos socket deployments for token bridging)
        dec.socketController[sec.usdc] = 0xf565F766EcafEE809EBaF0c71dCd60ad5EfE0F9e;
        dec.socketExecutionHelper[sec.usdc] = 0x605C8aeB0ED6c51C8A288eCC90d4A3749e4596EE;

        dec.socketController[sec.weth] = 0x1529413F38b95cE156f54C34471528B6d0Daf2eb;
        dec.socketExecutionHelper[sec.weth] = 0xF1e0f8B07Eb4928922448CBD6f77ac5918f8e032;

        // create fork
        try vm.activeFork() { }
        catch {
            vm.createSelectFork(sec.REYA_RPC);
        }
    }
}
