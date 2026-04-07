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
 *      IMPORTANT: The devnet deploys fresh Core/Perp/OrdersGateway but reuses the Cronos
 *      Periphery. Since the Periphery's global config points to the Cronos Core (not devnet
 *      Core), all deposits must go through the direct deposit path (deal + approve + deposit)
 *      rather than the periphery path.
 */
contract ReyaForkTest is BaseReyaForkTest {
    constructor() {
        // All deposits go through the direct path (deal + approve + deposit on devnet Core)
        // because the shared Cronos Periphery points to the wrong Core.
        useDirectDeposit = true;

        string memory rpcKey = vm.envString("RPC_KEY");
        // network (same chain as cronos testnet)
        sec.REYA_RPC = string.concat("https://rpc.reya-cronos.gelato.digital/", rpcKey);
        sec.MAINNET_RPC = "https://gateway.tenderly.co/public/sepolia";

        // other (external) chain id
        sec.destinationChainId = ethereumSepoliaChainId;

        // multisigs (devnet owner)
        sec.multisig = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;

        // Reya contracts (deterministic CREATE2 addresses from devnet cannon deployment)
        sec.core = payable(0xa351bC9ae59AD5Becc4428884c4Aa4d5951E02ba);
        sec.pool = payable(0x9A3A664987b88790A6FDC1632e3b607813fd94fF); // reused Cronos PassivePool
        sec.perp = payable(0x57DDC64bf7e36A6f812A1CDCFfAe2f4E6d712F40);
        sec.oracleManager = 0x689f13829e9b218841a0Cf59f44bD5c92F0d64eA; // reused Cronos
        sec.periphery = payable(0x94ccAe812f1647696754412082dd6684C2366A7f); // reused Cronos
        sec.ordersGateway = payable(0x8748D534997a822278BD2288aad74e448eFfBd91);
        sec.oracleAdaptersProxy = payable(0xc501A2356703CD351703D68963c6F4136120f7CF); // reused Cronos
        sec.exchangePass = 0x1Acd15A57Aff698440262A2A13AE22F8Ff2FA0cB; // reused Cronos
        sec.accountNft = 0xeA13E7dA71E018160019A296Eca4184Ddc53aeB1; // reused Cronos

        // Reya tokens (reuse Cronos testnet token deployments)
        sec.rusd = 0x9DE724e7b3facF87Ce39465D3D712717182e3e55;
        sec.usdc = 0xfA27c7c6051344263533cc365274d9569b0272A8;
        sec.weth = 0x2CF56315ACC7E791B1A0135c09d8D5C8dBCD2F14;

        // Reya variables
        sec.passivePoolId = 1;
        sec.passivePoolAccountId = 0; // no passive pool counterparty in devnet

        // Reya bots
        sec.coExecutionBot = 0xB6EaF546b84E1f917579FC4FD3d7082DfE2ba212;
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
    }
}
