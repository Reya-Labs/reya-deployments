pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { IOracleManagerProxy, NodeDefinition, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";
import {
    IOracleAdaptersProxy,
    StorkSignedPayload,
    StorkPricePayload
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

    /// The sRUSD parent-collateral node must return a usable price without
    /// any pusher having run. On devnet it is a CONSTANT 1.0 node (see
    /// devnet/oracle_manager/pool_srusd_usdc.toml); on cronos/mainnet it is
    /// the Stork REYAPOOL#1 lookup, which serves whatever the pool-price
    /// publisher last wrote. Either way `process` must succeed and return a
    /// non-zero price — a node that reverts here mis-prices sRUSD collateral
    /// on collateral pool 1 at liquidation time.
    function check_srusdPoolNode_producesPrice() public view {
        NodeOutput.Data memory out = IOracleManagerProxy(sec.oracleManager).process(sec.srusdUsdcPoolNodeId);
        require(out.price > 0, "srusdUsdcPool node produced a zero price");
        require(out.timestamp > 0, "srusdUsdcPool node produced a zero timestamp");
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

        vm.prank(sec.oraclePusher1);
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
        address[2] memory pushers = [sec.oraclePusher1, sec.oraclePusher2];
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
