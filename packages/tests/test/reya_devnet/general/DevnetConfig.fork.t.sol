pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PerpFillForkCheck } from "../../reya_common/trade/PerpFill.fork.c.sol";

import {
    ICoreProxy,
    CollateralConfig,
    ParentCollateralConfig,
    LimitConfig,
    InsuranceFundConfig,
    RiskMultipliers,
    BackstopLPConfig
} from "../../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxyV2, FeeTierParameters } from "../../../src/interfaces/IPassivePerpProxyV2.sol";
import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";
import { IOrdersGatewayProxy } from "../../../src/interfaces/IOrdersGatewayProxy.sol";
import { IPeripheryProxy, GlobalConfiguration } from "../../../src/interfaces/IPeripheryProxy.sol";

interface IOwnableProxy {
    function owner() external view returns (address);
    function nominatedOwner() external view returns (address);
}

/**
 * @title DevnetConfigForkTest
 * @notice Deployment-config readbacks and intent pins for devnet.
 * @dev Two kinds of test live here, both existing because cannon SKIPS a
 *      failing step with a warning instead of failing the build:
 *
 *      1. Config readbacks — every value the deployment claims to set is
 *         read back from chain, so a silently-skipped step turns into a red
 *         test instead of a quietly missing config.
 *      2. Intent pins — deliberate devnet decisions that live only in toml
 *         comments (SRUSDRUSD spot never orderbook-enabled, the legacy
 *         Cronos sRUSD entry permanently retired) become failures if someone
 *         re-enables them by accident.
 *
 *      Expected values mirror omnibus/reya_devnet.toml; when a setting
 *      changes there, this file is the paired change.
 */
contract DevnetConfigForkTest is ReyaForkTest, PerpFillForkCheck {
    bytes32 internal constant GLOBAL_FLAG = keccak256(bytes("global"));

    // ------------------------------------------------------------------
    // A2: ownership across every fresh proxy
    // ------------------------------------------------------------------

    /// All eight devnet-owned proxies: deployed, owned by the devnet
    /// multisig, and with NO pending ownership nomination (a stale or
    /// hostile nomination is invisible until acceptOwnership, so the only
    /// safe steady-state value is zero).
    function test_Devnet_AllProxiesOwned() public view {
        address[8] memory proxies = [
            sec.core,
            sec.perp,
            sec.ordersGateway,
            sec.periphery,
            sec.pool,
            sec.oracleManager,
            sec.oracleAdaptersProxy,
            sec.srusd
        ];
        string[8] memory names = [
            "core",
            "passivePerp",
            "ordersGateway",
            "periphery",
            "passivePool",
            "oracleManager",
            "oracleAdapters",
            "srusd"
        ];
        for (uint256 i = 0; i < proxies.length; i++) {
            require(proxies[i].code.length > 0, string.concat(names[i], ": no code"));
            require(IOwnableProxy(proxies[i]).owner() == sec.multisig, string.concat(names[i], ": owner != multisig"));
            require(
                IOwnableProxy(proxies[i]).nominatedOwner() == address(0),
                string.concat(names[i], ": pending ownership nomination")
            );
        }
    }

    /// `configureRiskBlock` must be granted to the system owner, by ALLOWLIST.
    ///
    /// PassivePerp.setRiskBlockId is gated on this flag, and the gate is
    /// checked BEFORE ownership -- so with allowAll=false and an empty
    /// allowlist (the state devnet and mainnet were both in) the call reverts
    /// FeatureUnavailable for every caller including the owner, and risk
    /// blocks silently never get assigned. Market 1 hid this for months
    /// because its risk-block step is cached in the deployment baseline and
    /// never re-runs; the mainnet market mirror surfaced it by adding 74 more.
    ///
    /// allowAll is asserted false for the usual reason: with it set, the
    /// membership check below passes for the owner AND for everyone else, so
    /// this test would go green while the permission was wide open.
    function test_Devnet_RiskBlockConfiguratorAccess() public view {
        bytes32 flag = keccak256(bytes("configureRiskBlock"));

        require(
            !IPassivePerpProxy(sec.perp).getFeatureFlagAllowAll(flag),
            "configureRiskBlock: allowAll must stay false, or the allowlist below means nothing"
        );

        address[] memory allowed = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(flag);
        require(allowed.length == 1, "configureRiskBlock: allowlist should hold exactly the system owner");
        require(allowed[0] == sec.multisig, "configureRiskBlock: allowlist member != system owner");
    }

    // ------------------------------------------------------------------
    // A3: orders gateway + periphery config readbacks
    // ------------------------------------------------------------------

    /// perpOB settlement authorization hangs on these two allowlists; both
    /// are asserted as EXACT sets so a dropped or extra entry fails.
    ///
    /// The allowAll/denyAll assertions are load-bearing, not decoration: an
    /// allowlist only restricts anything while allowAll is FALSE. With it
    /// set, the arrays below are unchanged and every expected bot still
    /// reports allowed — but so does every unlisted caller, so a membership
    /// check alone is a false green. denyAll is asserted for the opposite
    /// failure: it would silently disable settlement entirely.
    function test_Devnet_OrdersGatewayAuthorization() public view {
        IOrdersGatewayProxy og = IOrdersGatewayProxy(sec.ordersGateway);

        require(og.getFeatureFlagAllowAll(GLOBAL_FLAG), "og: global flag not opened");

        bytes32 mePublisherFlag = keccak256(bytes("matching_engine_publisher"));
        bytes32 coBotsFlag = keccak256(bytes("conditional_orders"));
        require(
            !og.getFeatureFlagAllowAll(mePublisherFlag), "og: matching_engine_publisher is allow-all (unrestricted)"
        );
        require(!og.getFeatureFlagDenyAll(mePublisherFlag), "og: matching_engine_publisher is deny-all");
        require(!og.getFeatureFlagAllowAll(coBotsFlag), "og: conditional_orders is allow-all (unrestricted)");
        require(!og.getFeatureFlagDenyAll(coBotsFlag), "og: conditional_orders is deny-all");

        address[] memory publishers = og.getFeatureFlagAllowlist(keccak256(bytes("matching_engine_publisher")));
        require(publishers.length == 1, "og: expected exactly one matching-engine publisher");
        require(publishers[0] == 0xD3D5911FE8ab109645f931Cf65B341d5dd672eFB, "og: wrong ME publisher");

        address[] memory bots = og.getFeatureFlagAllowlist(keccak256(bytes("conditional_orders")));
        require(bots.length == 3, "og: expected exactly three co-execution bots");
        require(og.isFeatureAllowed(keccak256(bytes("conditional_orders")), sec.coExecutionBot), "og: co_bot1 missing");
        require(
            og.isFeatureAllowed(keccak256(bytes("conditional_orders")), 0x6623C4a8e54549d5dB1ACb666B13f9c046DFD5B2),
            "og: ws-exec relayer (co_bot2) missing"
        );
        require(
            og.isFeatureAllowed(keccak256(bytes("conditional_orders")), 0xB04ce54876A8017ae7785A3f4218308BC8fBb724),
            "og: wallet-manager relayer (co_bot3) missing"
        );
    }

    function test_Devnet_PeripheryGlobalConfig() public view {
        GlobalConfiguration.Data memory cfg = IPeripheryProxy(sec.periphery).getGlobalConfiguration();
        require(cfg.coreProxy == sec.core, "periphery: wrong core");
        require(cfg.rUSDProxy == sec.rusd, "periphery: wrong rUSD");
        require(cfg.passivePoolProxy == sec.pool, "periphery: wrong passive pool (must be devnet's own)");
        require(cfg.layerZeroEndpoint == 0x6C7Ab2202C98C4227C5c46f1417D81144DA716Ff, "periphery: wrong LZ endpoint");
    }

    // ------------------------------------------------------------------
    // A6: config-group readbacks
    // ------------------------------------------------------------------

    function test_Devnet_FeeTierParameters() public view {
        uint256[7] memory takerFees =
            [uint256(0.0003e18), 0.00028e18, 0.00026e18, 0.00024e18, 0.00022e18, 0.00021e18, 0.0002e18];
        for (uint256 tier = 0; tier < takerFees.length; tier++) {
            FeeTierParameters memory p = IPassivePerpProxyV2(sec.perp).getFeeTierParameters(tier);
            require(p.takerFee == takerFees[tier], "fee tier takerFee mismatch");
        }
    }

    function test_Devnet_CollateralPoolLimits() public view {
        LimitConfig memory limits = ICoreProxy(sec.core).getCollateralPoolLimits(1);
        // 75 mirrors mainnet: the full mainnet market list is registered
        // on-chain. Was 1 (ETH only) -- every market past the first reverts
        // CollateralLimitBreached at the old cap. Which of those 75 may
        // actually take exposure is pinned by MarketMirror, not here.
        require(limits.maxMarkets == 75, "cp1: maxMarkets != 75");
        // 13, not mainnet's 12: devnet registers mainnet's full 12-token set
        // AND still carries the legacy Cronos sRUSD entry, which Core has no
        // path to deregister. The limit counts the rUSD quote collateral, so
        // 12 supporting + rUSD = 13. (Was 2, then 12 — each bump unblocked the
        // next token; the old cap reverted CollateralLimitBreached.)
        require(limits.maxCollaterals == 13, "cp1: maxCollaterals != 13");
    }

    function test_Devnet_InsuranceFundConfig() public view {
        InsuranceFundConfig memory cfg = ICoreProxy(sec.core).getCollateralPoolInsuranceFundConfiguration(1);
        require(cfg.accountId != 0, "cp1: insurance fund account unset");
        require(cfg.liquidationFee == 0.35e18, "cp1: IF liquidation fee != 0.35");
    }

    function test_Devnet_RiskMultipliers() public view {
        RiskMultipliers memory rm = ICoreProxy(sec.core).getRiskMultipliers(1);
        require(rm.imMultiplier == 1.3e18, "cp1: imMultiplier != 1.3");
        require(rm.mmrMultiplier == 1e18, "cp1: mmrMultiplier != 1");
        require(rm.dutchMultiplier == 1e18, "cp1: dutchMultiplier != 1");
        require(rm.adlMultiplier == 0.65e18, "cp1: adlMultiplier != 0.65");
        require(rm.imBufferMultiplier == 9.15e18, "cp1: imBufferMultiplier != 9.15");
    }

    /// Auto-exchange economics per collateral, straight from the omnibus.
    function test_Devnet_CollateralAutoExchangeParams() public view {
        (CollateralConfig memory wethCfg, ParentCollateralConfig memory wethParent,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.weth);
        require(wethCfg.autoExchangeInsuranceFee == 0.01e18, "weth: AE insurance fee != 0.01");
        require(wethParent.priceHaircut == 0.1e18, "weth: haircut != 0.10");
        require(wethParent.autoExchangeDiscount == 0.02e18, "weth: AE discount != 0.02");
        require(wethParent.oracleNodeId == sec.ethUsdcStorkNodeId, "weth: wrong oracle node");

        (CollateralConfig memory srusdCfg, ParentCollateralConfig memory srusdParent,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.srusd);
        require(srusdCfg.depositingEnabled, "srusd: depositing should be enabled");
        require(srusdCfg.autoExchangeInsuranceFee == 0.005e18, "srusd: AE insurance fee != 0.005");
        require(srusdParent.priceHaircut == 0.1e18, "srusd: haircut != 0.10");
        require(srusdParent.autoExchangeDiscount == 0, "srusd: AE discount != 0");
        // Mainnet parity: sRUSD margin prices via the Stork SRUSDRUSD_RR feed
        // (cheaper margin walks; consistent with the ME risk engine). The
        // pool node stays registered as the share-price reference.
        require(
            srusdParent.oracleNodeId == sec.srusdRusd_RRStorkNodeId,
            "srusd: parent oracle != SRUSDRUSD_RR (mainnet parity)"
        );
    }

    /// Core's CONFIGURED backstop LP, read from Core rather than assumed.
    ///
    /// Reading getBackstopLPConfig is the point: hard-coding account 23 and
    /// checking that account is funded proves only that an independently
    /// chosen account exists — it stays green if the config step is skipped,
    /// if Core points at a different account, or if the 15% liquidation
    /// economics drift. The configured account is then what the funded and
    /// market-active checks below run against.
    function test_Devnet_BackstopLPConfig() public {
        // Any margin read on a market-active account walks its exposure and
        // trips MarkPriceStale once the fork drifts past the live pusher's
        // last mark — so push a fresh one first (same fix as the funding
        // tests).
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(1, 3000e18);

        BackstopLPConfig memory backstop = ICoreProxy(sec.core).getBackstopLPConfig(1);
        require(backstop.accountId == 23, "cp1: backstop LP account != 23");
        require(backstop.liquidationFee == 0.15e18, "cp1: backstop liquidation fee != 0.15");
        require(backstop.minFreeCollateralThresholdInUSD == 0, "cp1: backstop free-collateral threshold != 0");
        require(backstop.withdrawCooldownDurationInSeconds_DEPRECATED == 0, "cp1: deprecated cooldown non-zero");
        require(backstop.withdrawDurationInSeconds_DEPRECATED == 0, "cp1: deprecated withdraw duration non-zero");

        uint128 backstopAccountId = backstop.accountId;
        InsuranceFundConfig memory ifCfg = ICoreProxy(sec.core).getCollateralPoolInsuranceFundConfiguration(1);
        require(ifCfg.accountId != backstopAccountId, "backstop must not be the IF account");
        require(
            ICoreProxy(sec.core).getCollateralPoolIdOfAccount(backstopAccountId) == 1,
            "backstop account not active on cp1 (firstMarketId unset?)"
        );
        require(
            ICoreProxy(sec.core).getUsdNodeMarginInfo(backstopAccountId).marginBalance > 0, "backstop account unfunded"
        );
    }

    // ------------------------------------------------------------------
    // A5: intent pins for deliberate devnet divergences
    // ------------------------------------------------------------------

    /// SRUSDRUSD (spot market 2) exists for /v2 asset-definition metadata
    /// ONLY. It is deliberately not orderbook-enabled: its oracle node id is
    /// zero, so enabling it would open a book with no price validation.
    function test_Devnet_SrusdRusdSpotMarket_NotEnabled() public view {
        bytes32 wethSpotFlag = keccak256(abi.encode(keccak256(bytes("spotMarketEnabled")), uint128(1)));
        bytes32 srusdSpotFlag = keccak256(abi.encode(keccak256(bytes("spotMarketEnabled")), uint128(2)));
        require(ICoreProxy(sec.core).getFeatureFlagAllowAll(wethSpotFlag), "WETHRUSD spot should be enabled");
        require(
            !ICoreProxy(sec.core).getFeatureFlagAllowAll(srusdSpotFlag),
            "SRUSDRUSD spot must stay disabled: zero oracle node, metadata-only market"
        );
    }

    /// The legacy Cronos sRUSD entry cannot be deregistered from Core, so
    /// its retired state is pinned: deposits off, cap zero, priced by the
    /// inert rUSD constant, and nobody holds any.
    function test_Devnet_LegacySrusd_StaysRetired() public view {
        address legacySrusd = 0xb9F531A54Fc0E9AdCa1b931d9533B4e49bB2fAD6;
        (CollateralConfig memory cfg, ParentCollateralConfig memory parent,) =
            ICoreProxy(sec.core).getCollateralConfig(1, legacySrusd);
        require(!cfg.depositingEnabled, "legacy srusd: deposits must stay disabled");
        require(cfg.cap == 0, "legacy srusd: cap must stay zero");
        require(parent.oracleNodeId == sec.rusdUsdNodeId, "legacy srusd: must stay on the rUSD constant node");
        require(
            ICoreProxy(sec.core).getCollateralPoolBalance(1, legacySrusd) == 0,
            "legacy srusd: pool balance must stay zero"
        );
    }
}
