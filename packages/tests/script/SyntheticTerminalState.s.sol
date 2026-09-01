// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Script, console2 } from "forge-std/Script.sol";

import {
    CachedCollateralConfig,
    CollateralConfig,
    ICoreProxy,
    MarginInfo,
    ParentCollateralConfig
} from "../src/interfaces/ICoreProxy.sol";
import { IMarketCloseModule } from "../src/interfaces/IMarketCloseModule.sol";
import { IOracleManagerProxy, NodeDefinition, NodeOutput } from "../src/interfaces/IOracleManagerProxy.sol";
import {
    EIP712Signature as PerpEIP712Signature,
    IPassivePerpProxy,
    PerpPosition
} from "../src/interfaces/IPassivePerpProxy.sol";
import {
    IPassivePerpProxyV2,
    MarketConfigurationDataV2,
    OracleDataPayload,
    OracleDataType
} from "../src/interfaces/IPassivePerpProxyV2.sol";
import { OracleDataPayloadHashing } from "../src/utils/OracleDataPayloadHashing.sol";
import { ud } from "@prb/math/UD60x18.sol";

/// @title PRO-656 synthetic terminal-state rehearsal
/// @notice Mutates only an explicitly disposable, already-upgraded fork. The account fixture is reconstructed from
///         historical mainnet indexing state and cross-checked against on-chain OI at block 218,500,000.
/// @dev Every output is SYNTHETIC REHEARSAL evidence. It MUST NOT satisfy a PRO-656 acceptance criterion or be used
///      as the RET-21 production close payload. Governance is impersonated and oracle staleness is relaxed on-fork.
contract SyntheticTerminalState is Script {
    string internal constant LABEL = "SYNTHETIC REHEARSAL - NOT PRO-656 ACCEPTANCE EVIDENCE";
    uint256 internal constant EXPECTED_FORK_BLOCK = 218_500_000;
    uint256 internal constant EXPECTED_MARKET_COUNT = 50;
    uint256 internal constant REHEARSAL_MAX_STALE_DURATION = 365 days;
    uint256 internal constant REHEARSAL_MARK_STALE_DURATION = 2 hours;
    // Anvil's first disposable account. Using its known rehearsal-only key lets Forge broadcast the synthetic oracle
    // pushes while governance calls continue to use anvil_impersonateAccount for the mainnet multisig.
    uint256 internal constant ORACLE_PUBLISHER_PK = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    bytes32 internal constant ORACLE_PUSHERS_FLAG = keccak256(bytes("oraclePushers"));
    bytes32 internal constant ORACLE_PUBLISHERS_FLAG = keccak256(bytes("oraclePublishers"));

    address internal constant MULTISIG = 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9;
    ICoreProxy internal constant CORE = ICoreProxy(payable(0xA763B6a5E09378434406C003daE6487FbbDc1a80));
    IPassivePerpProxy internal constant PERP = IPassivePerpProxy(payable(0x27E5cb712334e101B3c232eB0Be198baaa595F5F));
    IPassivePerpProxyV2 internal constant PERP_V2 = IPassivePerpProxyV2(0x27E5cb712334e101B3c232eB0Be198baaa595F5F);
    IOracleManagerProxy internal constant ORACLE = IOracleManagerProxy(0xC67316Ed17E0C793041CFE12F674af250a294aab);
    mapping(bytes32 => bool) internal freshenedNodes;
    mapping(uint128 => bool) internal marginCached;
    mapping(uint128 => int256) internal liquidationDeltaByAccount;
    mapping(uint128 => int256) internal initialDeltaByAccount;

    struct MarketInput {
        // vm.parseJson ABI-encodes object values by lexicographically sorted key, so keep the struct fields in the
        // same order as accountIds, marketId.
        uint128[] accountIds;
        uint128 marketId;
    }

    struct Readiness {
        uint256 openInterest;
        uint256 closedLong;
        uint256 closedShort;
        uint256 residualNet;
        uint256 residualOi;
        uint256 exactMaxResidual;
        uint256 baseSpacing;
        uint256 belowLmrCount;
        uint256 belowImrCount;
        uint256 zeroBaseFixtureCount;
    }

    function run() external {
        string memory path = string.concat(vm.projectRoot(), "/script/data/pro656-synthetic-terminal-218500000.json");
        string memory json = vm.readFile(path);
        uint256 fixtureBlock = abi.decode(vm.parseJson(json, ".forkBlock"), (uint256));
        MarketInput[] memory markets = abi.decode(vm.parseJson(json, ".markets"), (MarketInput[]));

        require(fixtureBlock == EXPECTED_FORK_BLOCK, "unexpected synthetic fixture block");
        require(markets.length == EXPECTED_MARKET_COUNT, "unexpected synthetic market count");

        console2.log(LABEL);
        console2.log("fixture fork block:", fixtureBlock);
        console2.log("target markets:", markets.length);

        require(_freshenCollateralOracles(), "failed to freshen collateral oracle tree");
        address oraclePublisher = vm.addr(ORACLE_PUBLISHER_PK);
        require(
            _send(
                address(PERP),
                abi.encodeCall(PERP.addToFeatureFlagAllowlist, (ORACLE_PUSHERS_FLAG, oraclePublisher)),
                "allow synthetic oracle pusher"
            ),
            "failed to allow synthetic oracle pusher"
        );
        require(
            _send(
                address(PERP),
                abi.encodeCall(PERP.addToFeatureFlagAllowlist, (ORACLE_PUBLISHERS_FLAG, oraclePublisher)),
                "allow synthetic oracle publisher"
            ),
            "failed to allow synthetic oracle publisher"
        );
        // Margin checks traverse every carried position, including the two markets that remain live. Their pushed
        // marks must therefore be fresh before evaluating the LMR gate for any terminal market.
        MarketConfigurationDataV2[2] memory carriedConfigs;
        for (uint128 carriedMarketId = 1; carriedMarketId <= 2; carriedMarketId++) {
            // Read twice deliberately. Assigning a memory struct into a memory array aliases its backing data;
            // mutating that same local afterwards would also mutate the "original" used by the restore step.
            carriedConfigs[carriedMarketId - 1] = PERP_V2.getMarketConfiguration(carriedMarketId);
            MarketConfigurationDataV2 memory carriedConfig = PERP_V2.getMarketConfiguration(carriedMarketId);
            carriedConfig.markPriceMaxStaleDuration = REHEARSAL_MARK_STALE_DURATION;
            require(
                _send(
                    address(PERP_V2),
                    abi.encodeCall(PERP_V2.setMarketConfiguration, (carriedMarketId, carriedConfig)),
                    "set synthetic carried-market mark window"
                ) && _freshenOracleTree(carriedConfig.oracleNodeId, 0)
                    && _pushFreshMark(carriedMarketId, carriedConfig.oracleNodeId),
                "failed to push carried-market mark"
            );
        }
        // getUsdNodeMarginInfo traverses every position held by an account, not only the market being closed. Seed
        // all terminal-market marks up front so an account shared by multiple markets has a fully priceable margin.
        for (uint256 i = 0; i < markets.length; i++) {
            MarketConfigurationDataV2 memory terminalConfig = PERP_V2.getMarketConfiguration(markets[i].marketId);
            terminalConfig.markPriceMaxStaleDuration = REHEARSAL_MARK_STALE_DURATION;
            require(
                _send(
                    address(PERP_V2),
                    abi.encodeCall(PERP_V2.setMarketConfiguration, (markets[i].marketId, terminalConfig)),
                    "set synthetic terminal-market mark window"
                ) && _freshenOracleTree(terminalConfig.oracleNodeId, 0)
                    && _pushFreshMark(markets[i].marketId, terminalConfig.oracleNodeId),
                "failed to push terminal-market mark"
            );
        }

        Readiness[] memory readinessByMarket = new Readiness[](markets.length);
        bool[] memory readyToClose = new bool[](markets.length);
        uint256 failedCount = 0;
        for (uint256 i = 0; i < markets.length; i++) {
            (readyToClose[i], readinessByMarket[i]) = _prepareMarket(markets[i]);
            if (!readyToClose[i]) failedCount++;
        }

        // The PRO-394 readiness gate is a pre-close snapshot. Evaluate every account before mutating any position;
        // otherwise an earlier close could make a later account appear healthier than it was at the cutover boundary.
        uint256 closedCount = 0;
        for (uint256 i = 0; i < markets.length; i++) {
            if (!readyToClose[i]) continue;
            if (_closeMarket(markets[i], readinessByMarket[i])) closedCount++;
            else failedCount++;
        }
        failedCount += _enforceTerminalReadbacks();
        failedCount += _restoreCarriedConfigs(carriedConfigs);

        console2.log("SYNTHETIC_REHEARSAL_CLOSED_MARKETS", closedCount);
        console2.log("SYNTHETIC_REHEARSAL_FAILED_MARKETS", failedCount);
        console2.log(LABEL);
        // Do not revert here: broadcasting successful markets and preserving every per-market failure in the log is
        // the direct RET-21 rehearsal output. The outer lane requires CLOSED_MARKETS=50 and fails after saving it.
    }

    function _prepareMarket(MarketInput memory input) internal returns (bool ready, Readiness memory readiness) {
        uint128 marketId = input.marketId;
        console2.log("SYNTHETIC_REHEARSAL_MARKET_BEGIN", uint256(marketId));

        uint256 oiBefore = PERP.getOpenBaseInterest(marketId);
        if (oiBefore == 0) {
            console2.log("SYNTHETIC_REHEARSAL_FAILURE_ZERO_STARTING_OI", uint256(marketId));
            return (false, readiness);
        }

        MarketConfigurationDataV2 memory config = PERP_V2.getMarketConfiguration(marketId);
        if (!_freshenOracleTree(config.oracleNodeId, 0)) {
            console2.log("SYNTHETIC_REHEARSAL_FAILURE_ORACLE_FRESHEN", uint256(marketId));
            return (false, readiness);
        }
        // forceCloseMarket requires enabled + reduce-only. Restore terminal inactivity after the close.
        if (!_setMarketEnabled(marketId, true)) return (false, readiness);
        config.maxOpenBase = 0;
        if (!_send(address(PERP_V2), abi.encodeCall(PERP_V2.setMarketConfiguration, (marketId, config)), "reduce-only"))
        {
            console2.log("SYNTHETIC_REHEARSAL_FAILURE_REDUCE_ONLY", uint256(marketId));
            return (false, readiness);
        }
        if (
            !_send(
                address(PERP),
                abi.encodeCall(IMarketCloseModule.freezeMarketForClosure, (marketId)),
                "freezeMarketForClosure"
            )
        ) {
            console2.log("SYNTHETIC_REHEARSAL_FAILURE_FREEZE", uint256(marketId));
            return (false, readiness);
        }

        readiness = _readiness(input);
        _printReadiness(marketId, input.accountIds.length, readiness);
        if (readiness.belowLmrCount != 0) {
            console2.log("SYNTHETIC_REHEARSAL_FAILURE_LMR_GATE", uint256(marketId));
            return (false, readiness);
        }
        if (readiness.zeroBaseFixtureCount != 0) {
            console2.log("SYNTHETIC_REHEARSAL_FAILURE_STALE_ACCOUNT_FIXTURE", uint256(marketId));
            return (false, readiness);
        }
        if (readiness.exactMaxResidual >= readiness.baseSpacing) {
            console2.log("SYNTHETIC_REHEARSAL_FAILURE_DUST_GATE", uint256(marketId));
            return (false, readiness);
        }

        console2.log("SYNTHETIC_REHEARSAL_MARKET_READY", uint256(marketId));
        return (true, readiness);
    }

    function _closeMarket(MarketInput memory input, Readiness memory readiness) internal returns (bool) {
        uint128 marketId = input.marketId;
        if (
            !_send(
                address(PERP),
                abi.encodeCall(
                    IMarketCloseModule.forceCloseMarket, (marketId, input.accountIds, ud(readiness.exactMaxResidual))
                ),
                "forceCloseMarket"
            )
        ) {
            console2.log("SYNTHETIC_REHEARSAL_FAILURE_FORCE_CLOSE", uint256(marketId));
            return false;
        }
        if (!_setMarketEnabled(marketId, false)) return false;

        if (PERP.getOpenBaseInterest(marketId) != 0 || _isMarketEnabled(marketId)) {
            console2.log("SYNTHETIC_REHEARSAL_FAILURE_TERMINAL_READBACK", uint256(marketId));
            return false;
        }
        for (uint256 i = 0; i < input.accountIds.length; i++) {
            PerpPosition memory position = PERP.getUpdatedPositionInfo(marketId, input.accountIds[i]);
            if (position.base != 0) {
                console2.log("SYNTHETIC_REHEARSAL_FAILURE_NONZERO_BASE", uint256(marketId));
                console2.log("account", uint256(input.accountIds[i]));
                console2.logInt(position.base);
                return false;
            }
        }

        console2.log("SYNTHETIC_REHEARSAL_MARKET_CLOSED", uint256(marketId));
        return true;
    }

    function _readiness(MarketInput memory input) internal returns (Readiness memory result) {
        result.openInterest = PERP.getOpenBaseInterest(input.marketId);
        result.baseSpacing = PERP_V2.getMarketConfiguration(input.marketId).baseSpacing;

        for (uint256 i = 0; i < input.accountIds.length; i++) {
            uint128 accountId = input.accountIds[i];
            if (!marginCached[accountId]) {
                MarginInfo memory margin = CORE.getUsdNodeMarginInfo(accountId);
                marginCached[accountId] = true;
                liquidationDeltaByAccount[accountId] = margin.liquidationDelta;
                initialDeltaByAccount[accountId] = margin.initialDelta;
            }
            int256 liquidationDelta = liquidationDeltaByAccount[accountId];
            int256 initialDelta = initialDeltaByAccount[accountId];
            if (liquidationDelta < 0) {
                result.belowLmrCount++;
                console2.log("SYNTHETIC_REHEARSAL_BELOW_LMR_ACCOUNT", uint256(accountId));
                console2.logInt(liquidationDelta);
            }
            // PRO-394's current script checks this stricter but non-authoritative gate; retain it diagnostically.
            if (initialDelta < 0) {
                result.belowImrCount++;
                console2.log("SYNTHETIC_REHEARSAL_BELOW_IMR_ACCOUNT", uint256(accountId));
                console2.log("  initialDelta");
                console2.logInt(initialDelta);
                console2.log("  liquidationDelta");
                console2.logInt(liquidationDelta);
            }

            int256 base = PERP.getUpdatedPositionInfo(input.marketId, accountId).base;
            if (base > 0) {
                result.closedLong += uint256(base);
            } else if (base < 0) {
                result.closedShort += uint256(-base);
            } else {
                result.zeroBaseFixtureCount++;
                console2.log("SYNTHETIC_REHEARSAL_ZERO_BASE_FIXTURE_ACCOUNT", uint256(accountId));
            }
        }

        result.residualNet = _absDiff(result.closedLong, result.closedShort);
        result.residualOi = _absDiff(result.closedLong, result.openInterest);
        result.exactMaxResidual = result.residualNet > result.residualOi ? result.residualNet : result.residualOi;
    }

    function _enforceTerminalReadbacks() internal returns (uint256 failures) {
        for (uint128 marketId = 3; marketId <= 75; marketId++) {
            uint256 openInterest = PERP.getOpenBaseInterest(marketId);
            if (openInterest != 0) {
                failures++;
                console2.log("SYNTHETIC_REHEARSAL_FAILURE_REMAINING_OI", uint256(marketId));
                console2.log("openInterest", openInterest);
                continue;
            }
            // Markets that started with zero OI do not need forceCloseMarket, but the terminal suite requires every
            // non-ETH/BTC market to be inactive. Apply that final flag separately and prove the readback.
            if (_isMarketEnabled(marketId) && !_setMarketEnabled(marketId, false)) {
                failures++;
                continue;
            }
            if (_isMarketEnabled(marketId)) {
                failures++;
                console2.log("SYNTHETIC_REHEARSAL_FAILURE_REMAINING_ACTIVE", uint256(marketId));
            }
        }
    }

    function _printReadiness(uint128 marketId, uint256 accountCount, Readiness memory r) internal pure {
        console2.log("SYNTHETIC_REHEARSAL_READINESS_MARKET", uint256(marketId));
        console2.log("accounts", accountCount);
        console2.log("openInterest", r.openInterest);
        console2.log("closedLong", r.closedLong);
        console2.log("closedShort", r.closedShort);
        console2.log("residualNet", r.residualNet);
        console2.log("residualOi", r.residualOi);
        console2.log("exactMaxResidual", r.exactMaxResidual);
        console2.log("baseSpacing", r.baseSpacing);
        console2.log("belowLmrCount", r.belowLmrCount);
        console2.log("belowImrCountDiagnosticOnly", r.belowImrCount);
        console2.log("zeroBaseFixtureCount", r.zeroBaseFixtureCount);
    }

    function _setMarketEnabled(uint128 marketId, bool enabled) internal returns (bool) {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("marketEnabled")), marketId));
        bool ok = _send(address(PERP), abi.encodeCall(PERP.setFeatureFlagDenyAll, (flagId, !enabled)), "market-enabled");
        if (!ok) console2.log("SYNTHETIC_REHEARSAL_FAILURE_MARKET_ENABLED", uint256(marketId));
        return ok;
    }

    function _isMarketEnabled(uint128 marketId) internal view returns (bool) {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("marketEnabled")), marketId));
        return !PERP.getFeatureFlagDenyAll(flagId);
    }

    function _freshenOracleTree(bytes32 nodeId, uint256 depth) internal returns (bool) {
        if (nodeId == bytes32(0) || freshenedNodes[nodeId]) return true;
        if (depth > 16) return false;
        NodeDefinition.Data memory node = ORACLE.getNode(nodeId);
        for (uint256 i = 0; i < node.parents.length; i++) {
            if (!_freshenOracleTree(node.parents[i], depth + 1)) return false;
        }
        bool ok = _send(
            address(ORACLE),
            abi.encodeCall(ORACLE.setMaxStaleDuration, (nodeId, REHEARSAL_MAX_STALE_DURATION)),
            "oracle-staleness"
        );
        if (ok) freshenedNodes[nodeId] = true;
        return ok;
    }

    function _freshenCollateralOracles() internal returns (bool) {
        address[13] memory collaterals = [
            address(0x3B860c0b53f2e8bd5264AA7c3451d41263C933F2),
            0xa9F32a851B1800742e47725DA54a09A7Ef2556A3,
            0x6B48C2e6A32077ec17e8Ba0d98fFc676dfab1A30,
            0xa6Cf523f856f4a0aaB78848e251C1b042E6406d5,
            0xAAB18B45467eCe5e47F85CA6d3dc4DF2a350fd42,
            0x2339D41f410EA761F346a14c184385d15f7266c4,
            0x809B99df4DDd6fA90F2CF305E2cDC310C6AD3C2c,
            0x4D3fEB76ab1C7eF40388Cd7a2066edacE1a2237D,
            0x7ae54d5a9e5a975DFC3261d915f8151dCcA76bE0,
            0x162B78e827A8DB8173D13735C08c8D40Cb5cCdAB,
            0xb6A307Bb281BcA13d69792eAF5Db7c2BBe6De248,
            0x63FC3F743eE2e70e670864079978a1deB9c18b76,
            0x3ee6f82498d4e40DB33bac3adDABd8b41eCa1c9c
        ];
        for (uint256 i = 0; i < collaterals.length; i++) {
            try CORE.getCollateralConfig(1, collaterals[i]) returns (
                CollateralConfig memory, ParentCollateralConfig memory parentConfig, CachedCollateralConfig memory
            ) {
                if (!_freshenOracleTree(parentConfig.oracleNodeId, 0)) return false;
            } catch {
                console2.log("SYNTHETIC_REHEARSAL_FAILURE_COLLATERAL_CONFIG", collaterals[i]);
                return false;
            }
        }
        return true;
    }

    function _pushFreshMark(uint128 marketId, bytes32 oracleNodeId) internal returns (bool) {
        NodeOutput.Data memory oraclePrice = ORACLE.process(oracleNodeId);
        address publisher = vm.addr(ORACLE_PUBLISHER_PK);
        OracleDataPayload memory payload = OracleDataPayload({
            marketId: marketId,
            timestamp: block.timestamp,
            dataType: OracleDataType.MarkPrice,
            data: abi.encode(oraclePrice.price),
            publisher: publisher
        });
        uint256 deadline = block.timestamp + 1 hours;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ORACLE_PUBLISHER_PK, OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, address(PERP_V2))
        );
        PerpEIP712Signature memory signature = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });
        bool ok = _sendAs(
            publisher,
            address(PERP_V2),
            abi.encodeCall(PERP_V2.pushOracleData, (payload, signature)),
            "push synthetic mark"
        );
        if (!ok) console2.log("SYNTHETIC_REHEARSAL_FAILURE_MARK_PUSH", uint256(marketId));
        return ok;
    }

    function _restoreCarriedConfigs(MarketConfigurationDataV2[2] memory originalConfigs)
        internal
        returns (uint256 failures)
    {
        for (uint128 marketId = 1; marketId <= 2; marketId++) {
            if (
                !_send(
                    address(PERP_V2),
                    abi.encodeCall(PERP_V2.setMarketConfiguration, (marketId, originalConfigs[marketId - 1])),
                    "restore carried-market config"
                )
            ) {
                failures++;
                continue;
            }
            if (
                keccak256(abi.encode(PERP_V2.getMarketConfiguration(marketId)))
                    != keccak256(abi.encode(originalConfigs[marketId - 1]))
            ) {
                failures++;
                console2.log("SYNTHETIC_REHEARSAL_FAILURE_CARRIED_CONFIG_RESTORE", uint256(marketId));
            }
        }
    }

    function _send(address target, bytes memory data, string memory step) internal returns (bool ok) {
        return _sendAs(MULTISIG, target, data, step);
    }

    function _sendAs(
        address sender,
        address target,
        bytes memory data,
        string memory step
    )
        internal
        returns (bool ok)
    {
        vm.broadcast(sender);
        bytes memory result;
        (ok, result) = target.call(data);
        if (!ok) {
            console2.log("SYNTHETIC_REHEARSAL_TX_REVERT", step);
            console2.logBytes(result);
        }
    }

    function _absDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }
}
