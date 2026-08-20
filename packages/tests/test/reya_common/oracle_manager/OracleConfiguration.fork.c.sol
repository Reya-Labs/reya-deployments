pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { IOracleManagerProxy, NodeDefinition, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";
import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";
import { ICoreProxy, ParentCollateralConfig } from "../../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";
import {
    IOracleAdaptersProxy,
    StorkSignedPayload,
    StorkPricePayload,
    LmTokenPriceConfigurationData
} from "../../../src/interfaces/IOracleAdaptersProxy.sol";

interface IOwnable {
    function owner() external view returns (address);
}

/// Configuration invariants for an environment's OWN oracle stack. Written
/// for the devnet cutover from the borrowed Cronos OracleManager to a
/// per-environment deployment, but environment-agnostic: everything is read
/// from `sec`.
contract OracleConfigurationForkCheck is BaseReyaForkTest {
    /// The manager and adapters are real deployed contracts owned by this
    /// environment's multisig — not EOAs, not zero, not somebody else's.
    function check_oracleStack_deployedAndOwned() public view {
        require(sec.oracleManager.code.length > 0, "oracle manager has no code");
        require(sec.oracleAdaptersProxy.code.length > 0, "oracle adapters has no code");
        require(IOracleManagerProxy(sec.oracleManager).owner() == sec.multisig, "manager owner != multisig");
        require(IOwnable(sec.oracleAdaptersProxy).owner() == sec.multisig, "adapters owner != multisig");
    }

    /// Every node id the environment's collateral and market configuration
    /// references must be REGISTERED on this manager. A node id resolved
    /// against the wrong manager instance reverts with NodeNotRegistered only
    /// at use-time; this catches it at configuration-time.
    function check_criticalNodes_registeredOnThisManager() public view {
        bytes32[4] memory nodeIds =
            [sec.rusdUsdNodeId, sec.ethUsdcStorkNodeId, sec.ethUsdcStorkMarkNodeId, sec.srusdUsdcPoolNodeId];
        string[4] memory names = ["rusdUsd", "ethUsdc", "ethUsdcMark", "srusdUsdcPool"];
        for (uint256 i = 0; i < nodeIds.length; i++) {
            require(nodeIds[i] != bytes32(0), string.concat(names[i], ": node id unset"));
            NodeDefinition.Data memory node = IOracleManagerProxy(sec.oracleManager).getNode(nodeIds[i]);
            require(node.nodeType != 0, string.concat(names[i], ": not registered on this manager"));
        }
    }

    /// CONFIG-CLOSURE WALK. The check above pins four node ids by name; this
    /// one derives the set from LIVE ON-CHAIN CONFIG and asserts every node
    /// the margin path can reach both resolves on this manager and produces
    /// a usable price.
    ///
    /// Why it matters: Core walks the collateral set on EVERY margin
    /// computation (AccountExposure iterates
    /// supportingCollaterals[quoteCollateral]), so a single unresolvable
    /// parent oracle bricks every fill, liquidation and funding accrual for
    /// every account — regardless of who holds that collateral. That is
    /// exactly how the legacy Cronos sRUSD entry took the whole environment
    /// down, and a name-pinned check could not see it because nobody had
    /// added the legacy entry to the list.
    ///
    /// Because the set comes from chain, every collateral and market added
    /// later — the ~9 remaining mainnet-mirror collaterals included — is
    /// covered with no edit to this test.
    function check_configClosure_allNodesResolve() public view {
        address quoteCollateral = IPassivePoolProxy(sec.pool).getPoolQuoteToken(sec.passivePoolId);
        uint128 collateralPoolId = ICoreProxy(sec.core).getCollateralPoolIdOfAccount(sec.passivePoolAccountId);

        // 1. Every SUPPORTING collateral's parent oracle.
        address[] memory supporting = ICoreProxy(sec.core).getSupportingCollaterals(collateralPoolId, quoteCollateral);
        require(supporting.length > 0, "config closure: no supporting collaterals found");
        for (uint256 i = 0; i < supporting.length; i++) {
            (, ParentCollateralConfig memory parent,) =
                ICoreProxy(sec.core).getCollateralConfig(collateralPoolId, supporting[i]);
            require(
                parent.oracleNodeId != bytes32(0),
                string.concat("config closure: zero oracle node for collateral ", vm.toString(supporting[i]))
            );
            NodeOutput.Data memory out = IOracleManagerProxy(sec.oracleManager).process(parent.oracleNodeId);
            require(
                out.price > 0,
                string.concat("config closure: zero price for collateral ", vm.toString(supporting[i]))
            );
        }

        // 2. Every MARKET's oracle node (the mark-price path).
        for (uint128 marketId = 1; marketId <= lastMarketId(); marketId++) {
            bytes32 marketNode = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId).oracleNodeId;
            require(
                marketNode != bytes32(0),
                string.concat("config closure: zero oracle node for market ", vm.toString(uint256(marketId)))
            );
            NodeOutput.Data memory out = IOracleManagerProxy(sec.oracleManager).process(marketNode);
            require(
                out.price > 0, string.concat("config closure: zero price for market ", vm.toString(uint256(marketId)))
            );
        }
    }

    /// The shared OracleAdapters config set must have actually been APPLIED to
    /// this adapters instance, not merely wired into the include list.
    ///
    /// This is the check that a file-level include comparison cannot make.
    /// cannon skips a failing step with a warning rather than failing the
    /// build, so a config can be correctly included and still silently no-op —
    /// which is exactly how passive_perp_global_config stayed broken, and how
    /// setAllocationConfiguration is dead on every environment today. Asserting
    /// the on-chain effect catches both that and a config never wired up at all.
    ///
    /// global_config is deliberately not re-asserted here: it is already
    /// covered transitively, since signature verification in
    /// {check_criticalNodes_priceThroughThisAdapters} reverts if the Stork
    /// verify contract was never set.
    function check_adaptersSharedConfig_applied() public view {
        // configs/feature_flags.toml
        require(
            IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowAll(keccak256(bytes("global"))),
            "adapters: global feature flag not opened (feature_flags.toml did not take)"
        );
        require(
            IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowlist(
                keccak256(bytes("lmTokenPriceUpdaters"))
            ).length > 0,
            "adapters: lmTokenPriceUpdaters allowlist empty (feature_flags.toml did not take)"
        );

        // configs/set_publishers.toml — assert the exact Stork signer keys.
        // A length>0 check is false-green here: the devnet fixture's setUp
        // seeds a synthetic publisher before every test body, so a non-empty
        // allowlist proves nothing about the deployment. These six keys are
        // Stork's payload-signing keys, identical on mainnet, cronos and
        // devnet (verified against all three omnibus files), so asserting
        // membership is environment-agnostic and unaffected by any
        // test-only publisher the fixture adds alongside them.
        address[6] memory storkPublishers = [
            0xa3C28D4e939cE2927D3B29b7bF53d3AeaAb09350,
            0xb91C675E0c0Ecfd4c16f97B110376C3C224061d8,
            0x51aa9e9C781F85a2C0636A835EB80114c4553098,
            0xF024A9AA110798e5CD0d698FBA6523113Eaa7FB2,
            0xF2e72022EB19352f488526E835c4b17248Aa6c03,
            0x0a803F9b1CCe32e2773e0d2e98b37E0775cA5d44
        ];
        for (uint256 i = 0; i < storkPublishers.length; i++) {
            require(
                IOracleAdaptersProxy(sec.oracleAdaptersProxy).isFeatureAllowed(
                    keccak256(bytes("publishers")), storkPublishers[i]
                ),
                "adapters: a Stork signer key is missing (set_publishers.toml did not take)"
            );
        }

        // configs/allow_all_executors.toml
        require(
            IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowAll(keccak256(bytes("executors"))),
            "adapters: executors not allow-all (allow_all_executors.toml did not take)"
        );

        // configs/init_lm_token_prices.toml -- same pair ids on every environment
        string[3] memory lmPairs = ["REYALM#SELINIUSDC", "REYALM#AMBERUSDC", "REYALM#HEDGEUSDC"];
        for (uint256 i = 0; i < lmPairs.length; i++) {
            LmTokenPriceConfigurationData memory cfg =
                IOracleAdaptersProxy(sec.oracleAdaptersProxy).getLmTokenPriceConfiguration(lmPairs[i]);
            require(
                cfg.priceUpperBound > cfg.priceLowerBound,
                string.concat(
                    "adapters: no LM price bounds for ", lmPairs[i], " (init_lm_token_prices.toml did not take)"
                )
            );
        }
    }

    /// The sRUSD parent-collateral node must serve THE POOL'S ACTUAL share
    /// price, not merely a price. REYAPOOL# pairs are never pushed: the
    /// adapters compute them live from PassivePool.getSharePrice at read
    /// time, so a working node equals the pool by construction — and a node
    /// wired to the wrong pool, the wrong adapters, or replaced by a stub
    /// fails the equality. This is the margin/liquidation price of sRUSD
    /// collateral on collateral pool 1.
    function check_srusdPoolNode_producesPrice() public view {
        NodeOutput.Data memory out = IOracleManagerProxy(sec.oracleManager).process(sec.srusdUsdcPoolNodeId);
        require(out.price > 0, "srusdUsdcPool node produced a zero price");
        require(out.timestamp > 0, "srusdUsdcPool node produced a zero timestamp");
        require(
            out.price == IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId),
            "srusdUsdcPool node price != pool.getSharePrice (node is not reading this pool)"
        );
    }

    /// The registered nodes must actually produce prices through THIS
    /// adapters instance: publish a signed payload for the exact asset-pair
    /// id the node was registered with ("ETHUSD" — the node params embed the
    /// pair id AND this adapters address), then process the node on the
    /// manager. Proves adapters -> manager plumbing, not that a pusher
    /// happened to run recently.
    function check_criticalNodes_priceThroughThisAdapters() public {
        (address publisher, uint256 publisherPK) = makeAddrAndKey("cfgCheckPublisher");
        vm.prank(sec.multisig);
        IOracleAdaptersProxy(sec.oracleAdaptersProxy).addToFeatureFlagAllowlist(
            keccak256(bytes("publishers")), publisher
        );

        StorkPricePayload memory pricePayload =
            StorkPricePayload({ assetPairId: "ETHUSD", timestamp: block.timestamp, price: 3000e18 });
        bytes32 digest = calculatePricePayloadDigest(publisher, pricePayload);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(publisherPK, digest);
        StorkSignedPayload memory signedPayload =
            StorkSignedPayload({ oraclePubKey: publisher, pricePayload: pricePayload, r: r, s: s, v: v });

        vm.prank(sec.oracleUpdater1);
        IOracleAdaptersProxy(sec.oracleAdaptersProxy).fulfillOracleQuery(abi.encode(signedPayload));

        NodeOutput.Data memory out = IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdStorkNodeId);
        require(out.price == 3000e18, "ethUsd node did not surface the published price");
        require(out.timestamp > 0, "ethUsd timestamp is zero through this stack");
    }

    /// The environment's pusher wallets must be AUTHORIZED EXECUTORS on this
    /// adapters instance (via the allowlist or executors-allow-all). NOTE:
    /// "publishers" gates payload SIGNERS (Stork's keys) — pushers are
    /// executors; asserting pushers-in-publishers was this check's own first
    /// bug. Verified behaviourally: a fulfil submitted from each pusher must
    /// pass the executor gate (the payload is signed by a test publisher the
    /// multisig authorizes, so only the executor gate is under test).
    function check_oraclePushers_areAuthorizedExecutors() public {
        (address publisher, uint256 publisherPK) = makeAddrAndKey("execCheckPublisher");
        vm.prank(sec.multisig);
        IOracleAdaptersProxy(sec.oracleAdaptersProxy).addToFeatureFlagAllowlist(
            keccak256(bytes("publishers")), publisher
        );
        address[2] memory pushers = [sec.oracleUpdater1, sec.oracleUpdater2];
        // The adapter rejects timestamps beyond block.timestamp, and re-submits
        // at the stored timestamp are only accepted from subSecondExecutors, so
        // round 1 exercises the executor gate and round 2 the sub-second gate.
        for (uint256 round = 0; round < 2; round++) {
            for (uint256 i = 0; i < pushers.length; i++) {
                vm.prank(pushers[i]);
                IOracleAdaptersProxy(sec.oracleAdaptersProxy).fulfillOracleQuery(
                    abi.encode(createSignedPricePayload(publisher, publisherPK, block.timestamp))
                );
            }
        }
    }
}
