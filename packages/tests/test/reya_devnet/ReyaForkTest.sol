pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";

import { BaseReyaForkTest } from "../reya_common/BaseReyaForkTest.sol";
import "../reya_common/DataTypes.sol";

import { IOracleManagerProxy } from "../../src/interfaces/IOracleManagerProxy.sol";

/**
 * @title ReyaForkTest (Devnet)
 * @notice Devnet environment configuration for perpOB fork tests
 * @dev Shares the Cronos testnet chain (chainId 89346162) but uses fresh proxy deployments.
 *      Minimal setup: 1 perp market (ETH), 2 spot markets (WETHRUSD enabled,
 *      SRUSDRUSD created+configured but not orderbook-enabled — mirrors
 *      cronos/mainnet), 3 collaterals (rUSD, wETH, sRUSD).
 *      No passive pool counterparty — uses dedicated backstop liquidator account.
 *
 */
contract ReyaForkTest is BaseReyaForkTest {
    constructor() {
        string memory rpcKey = vm.envString("CONDUIT_RPC_KEY");
        // network (same chain as cronos testnet)
        sec.REYA_RPC = string.concat("https://rpc-reya-cronos.t.conduit.xyz/", rpcKey);
        sec.MAINNET_RPC = "https://gateway.tenderly.co/public/sepolia";

        // other (external) chain id
        sec.destinationChainId = ethereumSepoliaChainId;

        // multisigs (devnet owner)
        sec.multisig = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;

        // Reya contracts (deterministic CREATE2 addresses from devnet cannon deployment)
        sec.core = payable(0xC33D0A4FC05aF98447126f1680cA7316de29e5d4);
        sec.pool = payable(0x9A3A664987b88790A6FDC1632e3b607813fd94fF); // reused Cronos PassivePool
        sec.perp = payable(0x6f42DB6d75Da0B85bDd386b96Cbfb73416AB37A4);
        sec.oracleManager = 0xEA0F138fa958a7beeA2b448C5a27141056c45A97; // devnet's own (CREATE2, oracle-manager-devnet3)
        sec.periphery = payable(0xDEDbde7e82B66E499b8FC8a472a5E857be1494DE);
        sec.ordersGateway = payable(0x7Ec89E555c771D2B5939aBE5C4E4291852633D4D);
        sec.oracleAdaptersProxy = payable(0x689D019d351688895858dAB41C3d5CDAea8Aa1a5); // devnet's own (CREATE2, oracle-adapters-devnet3)
        sec.exchangePass = 0x1Acd15A57Aff698440262A2A13AE22F8Ff2FA0cB; // reused Cronos
        sec.accountNft = 0x73e29C9EeE1db0725A6c352D705137416870E870;

        // Reya tokens (reuse Cronos testnet token deployments)
        sec.rusd = 0x9DE724e7b3facF87Ce39465D3D712717182e3e55;
        sec.usdc = 0xfA27c7c6051344263533cc365274d9569b0272A8;
        sec.weth = 0x2CF56315ACC7E791B1A0135c09d8D5C8dBCD2F14;
        sec.srusd = 0xb9F531A54Fc0E9AdCa1b931d9533B4e49bB2fAD6;

        // Reya variables
        sec.passivePoolId = 1;
        sec.passivePoolAccountId = 0; // no passive pool counterparty in devnet

        // Reya bots
        sec.coExecutionBot = 0xc9A01c03AEE926B89b83F7781b15B822807E1d33;
        sec.setMarketZeroFeeBot = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;
        sec.oraclePusher1 = 0x61548af5B40Ee331a30aBecA9Ff2237D6C753462;
        sec.oraclePusher2 = 0xa91Cc8B9109B5A1DBBb453CaaE63630BDCa09Fd3;

        // Spot oracle node ids — registered on devnet's OWN OracleManager.
        // Node ids are keccak of (type, params, parents); the stork params
        // embed the adapters address, so every stork id changed with the new
        // adapters instance. rusdUsd is a constant node (no adapters in its
        // params) and keeps the same id as Cronos.
        sec.ethUsdStorkNodeId = 0xeb5886347879cc2497571f36a89c3a62b62da0fe2a5599d1cbe41bac44db041a;
        sec.ethUsdcStorkNodeId = 0xd2de21b980e97d72e706548c6be1972993347dc5c046c9ed05766a21e60a319b;
        sec.rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
        sec.usdcUsdStorkNodeId = 0x76198d2abe821744bfde51ad90bae8c01223a679080456c90bec798f19f55b40;

        // sRUSD parent-collateral pool oracle, registered on devnet's own
        // manager (see devnet/oracle_manager/pool_srusd_usdc.toml). Staleness
        // bumped to 10_000s so the fork (which may be pointed at an older
        // block) doesn't trip OracleStale.
        sec.srusdUsdcPoolNodeId = 0x76f80a6a7a5b76465f117c56f41ecdcb7fe9fde5d817693fd12672e4508b4e12;
        vm.prank(sec.multisig);
        IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(sec.srusdUsdcPoolNodeId, 10_000);

        // Mark price node ids — devnet's own registrations.
        sec.ethUsdStorkMarkNodeId = 0x219a6c2e6d962bc56fc11095c36c345d3b6071844e66aa48310c098aea07016b;
        sec.ethUsdcStorkMarkNodeId = 0xe6f7d670990c134af7d1811041c691729e0770a38af6c79a8c13b0c984aa7a63;

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
