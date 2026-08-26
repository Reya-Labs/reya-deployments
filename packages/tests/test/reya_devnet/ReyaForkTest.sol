pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";

import { BaseReyaForkTest } from "../reya_common/BaseReyaForkTest.sol";
import "../reya_common/DataTypes.sol";

import { IOracleManagerProxy } from "../../src/interfaces/IOracleManagerProxy.sol";
import { IPassivePoolProxy } from "../../src/interfaces/IPassivePoolProxy.sol";
import {
    IOracleAdaptersProxy, StorkSignedPayload, StorkPricePayload
} from "../../src/interfaces/IOracleAdaptersProxy.sol";

/**
 * @title ReyaForkTest (Devnet)
 * @notice Devnet environment configuration for perpOB fork tests
 * @dev Shares the Cronos testnet chain (chainId 89346162) but uses fresh proxy deployments.
 *      Minimal setup: 1 perp market (ETH), 2 spot markets (WETHRUSD enabled,
 *      SRUSDRUSD created+configured but not orderbook-enabled — mirrors
 *      cronos/mainnet), 3 collaterals (rUSD, wETH, sRUSD).
 *      devnet runs its OWN PassivePool and sRUSD (not Cronos's), so it has a
 *      real pool counterparty; the backstop LP is still a standalone margin
 *      account (see cp1Rusd_backstopLpAccountId in the devnet omnibus).
 *
 */
contract ReyaForkTest is BaseReyaForkTest {
    constructor() {
        string memory rpcKey = vm.envString("RPC_KEY");
        // network (same chain as cronos testnet)
        sec.REYA_RPC = string.concat("https://rpc-reya-cronos.t.conduit.xyz/", rpcKey);
        sec.MAINNET_RPC = "https://gateway.tenderly.co/public/sepolia";

        // other (external) chain id
        sec.destinationChainId = ethereumSepoliaChainId;

        // multisigs (devnet owner)
        sec.multisig = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;

        // Reya contracts (deterministic CREATE2 addresses from devnet cannon deployment)
        sec.core = payable(0xC33D0A4FC05aF98447126f1680cA7316de29e5d4);
        sec.pool = payable(0x9fDba948aC22448C310B15C04D9A3DCB4bA8abA2); // devnet's own (CREATE2, passive-pool-devnet3)
        sec.perp = payable(0x6f42DB6d75Da0B85bDd386b96Cbfb73416AB37A4);
        sec.oracleManager = 0xEA0F138fa958a7beeA2b448C5a27141056c45A97; // devnet's own (CREATE2,
            // oracle-manager-devnet3)
        sec.periphery = payable(0xDEDbde7e82B66E499b8FC8a472a5E857be1494DE);
        sec.ordersGateway = payable(0x7Ec89E555c771D2B5939aBE5C4E4291852633D4D);
        sec.oracleAdaptersProxy = payable(0x689D019d351688895858dAB41C3d5CDAea8Aa1a5); // devnet's own (CREATE2,
            // oracle-adapters-devnet3)
        sec.exchangePass = 0x1Acd15A57Aff698440262A2A13AE22F8Ff2FA0cB; // reused Cronos
        sec.accountNft = 0x73e29C9EeE1db0725A6c352D705137416870E870;

        // Reya tokens (rUSD / USDC / wETH reuse the Cronos testnet deployments)
        sec.rusd = 0x9DE724e7b3facF87Ce39465D3D712717182e3e55;
        sec.usdc = 0xfA27c7c6051344263533cc365274d9569b0272A8;
        sec.weth = 0x2CF56315ACC7E791B1A0135c09d8D5C8dBCD2F14;
        // sRUSD is devnet's OWN token, not the Cronos one: its supply
        // represents claims on exactly one pool, so it could not stay shared
        // once devnet stopped borrowing the Cronos pool.
        sec.srusd = 0x8A04495Ed90DE2cC1e0e620F01210c6A6fE63bdb; // devnet's own (CREATE2, srusd-devnet3)

        // Mainnet collateral mirror: the existing Cronos deployments of the
        // tokens mainnet accepts as collateral. Symbol and decimals verified
        // on-chain -- wBTC is 8 decimals, the rest 18, and the omnibus scales
        // every cap through parseUnits(.., <token>TokenDecimals) accordingly.
        // The three LM tokens (rSelini/rAmber/rHedge) are deliberately absent:
        // their REYALM# nodes do not resolve here. See CollateralMirror.
        sec.wbtc = 0x459374F3f3E92728bCa838DfA8C95E706FE67E8a;
        sec.wsteth = 0xDF52410A19298FE168c900513e762adaD00C42b1;
        sec.usde = 0xDca6971c26fDEE0536Fdff076D063643f7810621;
        sec.susde = 0x08A766935478A1632FA776DCEbD3E75Ce88A1034;
        sec.deusd = 0x3b9D28dC180813a106d26778135Ac2A674F89957;
        sec.sdeusd = 0xbEB316680B6fcd2dC3aF1fC933B3A27a2513d89D;

        // Reya variables
        sec.passivePoolId = 1;
        // passivePoolAccountId is resolved on-chain in setUp(), not hardcoded.
        // Core account ids are sequential state, not deterministic CREATE2: the
        // id devnet's pool gets depends on how many accounts exist when the
        // deployment actually runs, and devnet1 accumulates accounts
        // continuously (perpOB load fleets create them by the hundred). A
        // literal captured from a simulation goes stale before it deploys.

        // Reya bots
        sec.coExecutionBot = 0xc9A01c03AEE926B89b83F7781b15B822807E1d33;
        sec.setMarketZeroFeeBot = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;
        // perp-ob mark/funding pushers: write to PassivePerp.pushOracleData,
        // gated by its oraclePushers flag (NOT adapters executors).
        sec.oraclePusher1 = 0x61548af5B40Ee331a30aBecA9Ff2237D6C753462;
        sec.oraclePusher2 = 0xa91Cc8B9109B5A1DBBb453CaaE63630BDCa09Fd3;
        // adapters pushers = the oracle-update-onchain task keys, the only
        // wallets in the adapters' subSecondExecutors allowlist.
        sec.oracleUpdater1 = 0xe97ad1AC9b001920EF9A2a96a8437a676Dd3Fa24;
        sec.oracleUpdater2 = 0xD337938a74f707BAEf728Ef694d9aA55d9ce4dEA;

        // Spot oracle node ids — registered on devnet's OWN OracleManager.
        // Node ids are keccak of (type, params, parents); the stork params
        // embed the adapters address, so every stork id changed with the new
        // adapters instance. rusdUsd is a constant node (no adapters in its
        // params) and keeps the same id as Cronos.
        sec.ethUsdStorkNodeId = 0xeb5886347879cc2497571f36a89c3a62b62da0fe2a5599d1cbe41bac44db041a;
        sec.ethUsdcStorkNodeId = 0xd2de21b980e97d72e706548c6be1972993347dc5c046c9ed05766a21e60a319b;
        sec.rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
        sec.usdcUsdStorkNodeId = 0x76198d2abe821744bfde51ad90bae8c01223a679080456c90bec798f19f55b40;

        // sRUSD parent-collateral pool oracle: the SAME shared Stork-lookup
        // registration mainnet uses (REYAPOOL#1 against devnet's adapters).
        // REYAPOOL# pairs need no pusher — the adapters compute the price
        // live from PassivePool.getSharePrice at read time, stamped
        // block.timestamp, so the node is always fresh and always equal to
        // the actual share price of devnet's own pool.
        sec.srusdUsdcPoolNodeId = 0x76f80a6a7a5b76465f117c56f41ecdcb7fe9fde5d817693fd12672e4508b4e12;
        // Stork SRUSDRUSD_RR on devnet's own adapters — the sRUSD margin
        // oracle (mainnet parity); the pool node above stays the share-price
        // reference.
        //
        // DO NOT wire the shared `check_srUSD_feeds()` here. It asserts the RR
        // feed tracks the pool share price within 0.001, which holds on
        // mainnet (one pool, one feed) but is FALSE on devnet: the RR pair is
        // published against the CRONOS pool (~1.0745) while devnet's own pool
        // sits at 1.000 — a ~0.0745 gap, ~74x that tolerance. The divergence
        // is deliberate and margin-safe (Core and the ME both read RR, so they
        // agree with each other; the 10% haircut dominates the skew), and it
        // resolves only if Stork publishes a devnet-pool pair.
        sec.srusdRusd_RRStorkNodeId = 0x310cce1f355711c4398bc6c506679e714b38cb1bcb616a71a7d6b86c090465a1;

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

    /// Seed devnet's OracleAdapters with the base Stork pairs.
    ///
    /// Unlike cronos and mainnet, devnet's adapters are a FRESH instance that
    /// no real pusher has ever written to, so every STORK_OFFCHAIN_LOOKUP node
    /// reads zero until one does. That is not a problem the existing helpers
    /// can solve: {mockFreshPrices} re-stamps an EXISTING price, and it calls
    /// `process` to read that price first — which is precisely where a
    /// div-reducer whose denominator is zero reverts with `InvalidPrice()`.
    /// So the prices have to exist before any test touches the node graph.
    ///
    /// Only the base pairs are published. Every derived node on devnet is a
    /// div-reducer over these (e.g. ethUsdcMark = ETHUSDMARK / USDCUSD), so
    /// seeding the leaves resolves the whole graph. Values are nominal: no
    /// devnet test asserts an absolute price, only relative behaviour.
    function setUp() public virtual {
        // Check for code first. A staticcall to an address with no code returns
        // empty, and decoding that reverts before any require below can run --
        // surfacing as a bare "EvmError: Revert" in setUp across every suite,
        // which says nothing about the cause. The pool genuinely can be absent
        // here: a flaked package fetch skips clone.reyaPassivePoolRouter and
        // silently takes the whole pool deployment with it.
        require(
            sec.pool.code.length > 0,
            "devnet PassivePool has no code -- pool deployment was skipped (check the build log for skipped steps)"
        );
        sec.passivePoolAccountId = IPassivePoolProxy(sec.pool).getPoolAccountId(sec.passivePoolId);
        require(sec.passivePoolAccountId != 0, "devnet pool is deployed but has no Core account");

        // Deployment-config assertion, made here because it must read PRISTINE
        // post-cannon state: devnet deploys 180s staleness on every stork node
        // (mainnet enforces 60s; cronos disables the check with 0).
        require(
            IOracleManagerProxy(sec.oracleManager).getNode(sec.ethUsdStorkNodeId).maxStaleDuration == 180,
            "devnet stork nodes should deploy with 180s maxStaleDuration"
        );

        // With the 180s deployment staleness asserted above, relax it for the
        // test run: several suites warp hours-to-days and re-stamp prices via
        // vm.mockCall, but any UNMOCKED process() of a stork node after a warp
        // would revert StalePriceDetected. Same prank-bump pattern the cronos
        // fixture uses. Constant and pool nodes need no bump (they report
        // block.timestamp).
        bytes32[6] memory stalenessBumped = [
            sec.ethUsdStorkNodeId,
            sec.usdcUsdStorkNodeId,
            sec.ethUsdcStorkNodeId,
            sec.ethUsdStorkMarkNodeId,
            sec.ethUsdcStorkMarkNodeId,
            // sRUSD margin oracle (SRUSDRUSD_RR) — in every collateral walk
            // since the mainnet-parity re-point; time-warping tests go stale
            // without this, same as the pairs above.
            sec.srusdRusd_RRStorkNodeId
        ];
        for (uint256 i = 0; i < stalenessBumped.length; i++) {
            vm.prank(sec.multisig);
            IOracleManagerProxy(sec.oracleManager).setMaxStaleDuration(stalenessBumped[i], 30 days);
        }

        (address publisher, uint256 publisherPK) = makeAddrAndKey("devnetSeedPublisher");
        vm.prank(sec.multisig);
        IOracleAdaptersProxy(sec.oracleAdaptersProxy).addToFeatureFlagAllowlist(
            keccak256(bytes("publishers")), publisher
        );

        string[3] memory pairs = ["USDCUSD", "ETHUSD", "ETHUSDMARK"];
        uint256[3] memory prices = [uint256(1e18), 3000e18, 3000e18];
        for (uint256 i = 0; i < pairs.length; i++) {
            seedStorkPrice(publisher, publisherPK, pairs[i], prices[i]);
        }
    }

    function seedStorkPrice(
        address publisher,
        uint256 publisherPK,
        string memory assetPairId,
        uint256 price
    )
        internal
    {
        StorkPricePayload memory pricePayload =
            StorkPricePayload({ assetPairId: assetPairId, timestamp: block.timestamp, price: price });
        bytes32 digest = calculatePricePayloadDigest(publisher, pricePayload);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(publisherPK, digest);
        IOracleAdaptersProxy(sec.oracleAdaptersProxy).fulfillOracleQuery(
            abi.encode(StorkSignedPayload({ oraclePubKey: publisher, pricePayload: pricePayload, r: r, s: s, v: v }))
        );
    }
}
