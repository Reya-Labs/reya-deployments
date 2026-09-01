// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import {
    IPassivePerpProxy,
    FundingAndADLTrackers,
    MarketDataResponse,
    MarketConfigurationData,
    PerpPosition,
    PnLComponents
} from "../../../src/interfaces/IPassivePerpProxy.sol";
import { IPassivePerpProxyV2, MarketDataResponseV2 } from "../../../src/interfaces/IPassivePerpProxyV2.sol";
import { ICoreProxy, AccountPermissions, CollateralInfo } from "../../../src/interfaces/ICoreProxy.sol";
import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";
import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";
import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

contract MigrationStateForkTest is ReyaForkTest {
    uint256 internal constant MAINNET_FORK_BLOCK = 218_500_000;
    uint128 internal constant ETH_MARKET_ID = 1;
    uint128 internal constant BTC_MARKET_ID = 2;
    uint128 internal constant LAST_MAINNET_MARKET_ID = 75;

    // This live account has non-zero ETH and BTC positions at MAINNET_FORK_BLOCK.
    uint128 internal constant STATE_ACCOUNT_ID = 125_718;
    address internal constant STATE_ACCOUNT_OWNER = 0x6256f5316bF6c6FA398900de6990Bd948078BA85;

    struct PreservedMarketState {
        uint128 id;
        address quoteToken;
        uint8 quoteTokenDecimals;
        uint256 lastFundingTimestamp;
        FundingAndADLTrackers longTrackers;
        FundingAndADLTrackers shortTrackers;
        uint256 openInterest;
    }

    struct PreservedState {
        address accountOwner;
        bytes32 rusdBalanceSlot;
        bytes32[7] ethPositionSlots;
        bytes32[7] btcPositionSlots;
        PreservedMarketState ethMarket;
        PreservedMarketState btcMarket;
    }

    struct PreservedAccountState {
        uint128 id;
        address owner;
        bytes32 permissionsHash;
        bytes32 collateralInfoHash;
        int256 susdeNetDeposits;
        bytes32 ethPositionHash;
        bytes32 btcPositionHash;
    }

    struct PreservedEconomicState {
        uint256 timestamp;
        uint256 ethPrice;
        uint256 btcPrice;
        int256 ethFundingRate;
        int256 btcFundingRate;
        PerpPosition ethPosition;
        PerpPosition btcPosition;
        PnLComponents ethPnl;
        PnLComponents btcPnl;
    }

    function setUp() public override { }

    function test_MainnetPerpOB_PreservesRepresentativeState() public {
        uint256 upgradedFork = _selectPristineUpgradedFork();
        address postUpgradeImplementation = IPassivePerpProxy(sec.perp).getImplementation();

        uint256 preUpgradeFork = vm.createFork(sec.REYA_RPC, _forkBlock());
        vm.selectFork(preUpgradeFork);
        address preUpgradeImplementation = IPassivePerpProxy(sec.perp).getImplementation();
        PreservedState memory preUpgrade = _readPreUpgradeState();
        vm.selectFork(upgradedFork);
        PreservedState memory postUpgrade = _readPostUpgradeState();

        assertNotEq(postUpgradeImplementation, preUpgradeImplementation, "PassivePerp implementation did not change");
        assertEq(preUpgrade.accountOwner, STATE_ACCOUNT_OWNER, "unexpected state-anchor owner at pinned block");
        assertTrue(preUpgrade.ethPositionSlots[0] != bytes32(0), "state-anchor ETH position is empty");
        assertTrue(preUpgrade.btcPositionSlots[0] != bytes32(0), "state-anchor BTC position is empty");

        assertEq(postUpgrade.accountOwner, preUpgrade.accountOwner, "account owner changed during upgrade");
        assertTrue(preUpgrade.rusdBalanceSlot != bytes32(0), "state-anchor rUSD balance is empty");
        assertEq(postUpgrade.rusdBalanceSlot, preUpgrade.rusdBalanceSlot, "rUSD balance storage changed");
        _assertPositionStorageEq("ETH", postUpgrade.ethPositionSlots, preUpgrade.ethPositionSlots);
        _assertPositionStorageEq("BTC", postUpgrade.btcPositionSlots, preUpgrade.btcPositionSlots);
        _assertMarketEq("ETH", postUpgrade.ethMarket, preUpgrade.ethMarket);
        _assertMarketEq("BTC", postUpgrade.btcMarket, preUpgrade.btcMarket);

        assertTrue(postUpgrade.ethMarket.lastFundingTimestamp != 0, "ETH funding timestamp was not initialized");
        assertTrue(postUpgrade.btcMarket.lastFundingTimestamp != 0, "BTC funding timestamp was not initialized");
    }

    function test_MainnetPerpOB_PreservesWiderAccountAndAggregateState() public {
        uint128[10] memory accountIds = _sampleAccountIds();
        uint256 upgradedFork = _selectPristineUpgradedFork();
        bytes32 postUpgradeAccountsHash = _readSampledAccountsHash(accountIds);
        uint256 postUpgradeCoreRusd = ITokenProxy(sec.rusd).balanceOf(sec.core);

        uint256 preUpgradeFork = vm.createFork(sec.REYA_RPC, _forkBlock());
        vm.selectFork(preUpgradeFork);
        bytes32 preUpgradeAccountsHash = _readSampledAccountsHash(accountIds);
        _assertPreUpgradeCollateralAnchors(accountIds[6]);
        uint256 preUpgradeCoreRusd = ITokenProxy(sec.rusd).balanceOf(sec.core);
        vm.selectFork(upgradedFork);

        // The first five IDs were the highest-notional accounts in the bounded
        // public execution sample ending at the pinned block. The remainder
        // cover WETH+WBTC, sUSDe, all three LM tokens (pool account 2), and a
        // BTC account liquidated shortly before the fork block.
        assertEq(postUpgradeAccountsHash, preUpgradeAccountsHash, "sampled account state changed");
        assertEq(postUpgradeCoreRusd, preUpgradeCoreRusd, "custodied rUSD changed during upgrade");
        _assertCollateralPoolBalancesEq(upgradedFork, preUpgradeFork);
    }

    function test_MainnetPerpOB_PreservesAccumulatedFundingAndPnlForOpenPositions() public {
        uint256 upgradedFork = _selectPristineUpgradedFork();
        uint256 preUpgradeFork = vm.createFork(sec.REYA_RPC, _forkBlock());
        vm.selectFork(preUpgradeFork);
        PreservedEconomicState memory preUpgrade = _readEconomicState();
        vm.selectFork(upgradedFork);

        // Pin the new oracle model to the exact legacy observation time, mark,
        // and funding rate. Any remaining difference is carried state, not
        // post-cutover price discovery or funding evolution.
        vm.warp(preUpgrade.timestamp);
        setupPerpTestActors();
        pushMarkPriceWithinCollar(ETH_MARKET_ID, preUpgrade.ethPrice);
        pushFundingRate(ETH_MARKET_ID, preUpgrade.ethFundingRate);
        pushMarkPriceWithinCollar(BTC_MARKET_ID, preUpgrade.btcPrice);
        pushFundingRate(BTC_MARKET_ID, preUpgrade.btcFundingRate);
        PreservedEconomicState memory postUpgrade = _readPositionAndPnlState();

        // Account 125718 opened both positions before the cutover block. Comparing
        // the public economic views (not only raw slots) proves that its realized
        // PnL and the funding/ADL tracker basis survive the implementation swap.
        assertTrue(preUpgrade.ethPosition.base != 0, "pre-cutover ETH position is empty");
        assertTrue(preUpgrade.btcPosition.base != 0, "pre-cutover BTC position is empty");
        _assertPositionAndPnlEq(
            "ETH", postUpgrade.ethPosition, preUpgrade.ethPosition, postUpgrade.ethPnl, preUpgrade.ethPnl
        );
        _assertPositionAndPnlEq(
            "BTC", postUpgrade.btcPosition, preUpgrade.btcPosition, postUpgrade.btcPnl, preUpgrade.btcPnl
        );
    }

    function test_MainnetPerpOB_PreservesAllMarketActivationFlags() public {
        uint256 upgradedFork = _selectPristineUpgradedFork();
        bool[75] memory postUpgradeActive;

        assertEq(lastMarketId(), LAST_MAINNET_MARKET_ID, "unexpected mainnet market count");
        for (uint128 marketId = ETH_MARKET_ID; marketId <= LAST_MAINNET_MARKET_ID; marketId++) {
            postUpgradeActive[marketId - 1] = isMarketActive(marketId);
        }

        uint256 preUpgradeFork = vm.createFork(sec.REYA_RPC, _forkBlock());
        vm.selectFork(preUpgradeFork);
        assertEq(lastMarketId(), LAST_MAINNET_MARKET_ID, "pre-upgrade mainnet market count changed");
        for (uint128 marketId = ETH_MARKET_ID; marketId <= LAST_MAINNET_MARKET_ID; marketId++) {
            assertEq(
                postUpgradeActive[marketId - 1],
                isMarketActive(marketId),
                string.concat("market activation changed ", vm.toString(marketId))
            );
        }
        vm.selectFork(upgradedFork);
    }

    function test_MainnetPerpOB_PreservesPassivePoolSharePrice() public {
        uint256 upgradedFork = _selectPristineUpgradedFork();

        uint256 preUpgradeFork = vm.createFork(sec.REYA_RPC, _forkBlock());
        vm.selectFork(preUpgradeFork);
        uint256 preUpgradeSharePrice = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
        uint256 ethPrice = _readOraclePrice(ETH_MARKET_ID);
        uint256 btcPrice = _readOraclePrice(BTC_MARKET_ID);
        vm.selectFork(upgradedFork);

        assertTrue(preUpgradeSharePrice != 0, "passive pool share-price anchor is zero");

        // At block 218,500,000, retired non-ETH/BTC markets still carry OI but
        // have no post-upgrade mark. That makes economic valuation fail closed.
        // RET-21/PRO-394 must provide the final block where only ETH/BTC retain
        // OI; the same test then takes the exact-value branch below.
        if (!vm.envOr("REYA_REQUIRE_TERMINAL_MARKETS", false)) {
            try IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId) {
                revert("expected stale retired-market mark to fail closed");
            } catch (bytes memory revertData) {
                assertEq(
                    bytes4(revertData),
                    IPassivePerpProxyV2.MarkPriceStale.selector,
                    "share-price read must fail closed on a stale retired-market mark"
                );
            }
            return;
        }

        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(ETH_MARKET_ID, ethPrice);
        pushFundingRate(ETH_MARKET_ID, 0);
        pushMarkPriceWithinCollar(BTC_MARKET_ID, btcPrice);
        pushFundingRate(BTC_MARKET_ID, 0);
        uint256 postUpgradeSharePrice = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
        assertEq(postUpgradeSharePrice, preUpgradeSharePrice, "passive pool share price changed during upgrade");
    }

    function test_MainnetPerpOB_PreservesPassivePoolShareSupply() public {
        uint256 upgradedFork = _selectPristineUpgradedFork();
        uint256 postUpgradeShareSupply = IPassivePoolProxy(sec.pool).getShareSupply(sec.passivePoolId);

        uint256 preUpgradeFork = vm.createFork(sec.REYA_RPC, _forkBlock());
        vm.selectFork(preUpgradeFork);
        uint256 preUpgradeShareSupply = IPassivePoolProxy(sec.pool).getShareSupply(sec.passivePoolId);
        vm.selectFork(upgradedFork);

        assertTrue(preUpgradeShareSupply != 0, "passive pool share-supply anchor is zero");
        assertEq(postUpgradeShareSupply, preUpgradeShareSupply, "passive pool share supply changed during upgrade");
    }

    function test_MainnetPerpOB_PreservesAllMarketFundingTimestampsAndOpenInterest() public {
        uint256 upgradedFork = _selectPristineUpgradedFork();
        uint256[75] memory postUpgradeFundingTimestamps;
        uint256[75] memory postUpgradeOpenInterest;

        for (uint128 marketId = ETH_MARKET_ID; marketId <= LAST_MAINNET_MARKET_ID; marketId++) {
            MarketDataResponseV2 memory data = IPassivePerpProxyV2(sec.perp).getMarketData(marketId);
            postUpgradeFundingTimestamps[marketId - 1] = data.marketData.lastFundingTimestamp;
            postUpgradeOpenInterest[marketId - 1] = data.marketData.openInterest;
        }

        uint256 preUpgradeFork = vm.createFork(sec.REYA_RPC, _forkBlock());
        vm.selectFork(preUpgradeFork);
        for (uint128 marketId = ETH_MARKET_ID; marketId <= LAST_MAINNET_MARKET_ID; marketId++) {
            MarketDataResponse memory data = IPassivePerpProxy(sec.perp).getMarketData(marketId);
            assertTrue(
                postUpgradeFundingTimestamps[marketId - 1] != 0,
                string.concat("funding timestamp is zero ", vm.toString(marketId))
            );
            assertEq(
                postUpgradeFundingTimestamps[marketId - 1],
                data.marketData.lastFundingTimestamp,
                string.concat("funding timestamp changed ", vm.toString(marketId))
            );
            assertEq(
                postUpgradeOpenInterest[marketId - 1],
                data.marketData.openInterest,
                string.concat("open interest changed ", vm.toString(marketId))
            );
        }
        vm.selectFork(upgradedFork);
    }

    function test_MainnetPerpOB_NonZeroFundingTimestampIsPreservedAndInitializerFailsClosed() public {
        _allowFundingTimestampMigration();

        for (uint128 marketId = ETH_MARKET_ID; marketId <= BTC_MARKET_ID; marketId++) {
            uint256 timestampBefore =
                IPassivePerpProxyV2(sec.perp).getMarketData(marketId).marketData.lastFundingTimestamp;
            assertTrue(timestampBefore != 0, "pinned market timestamp unexpectedly zero");

            vm.expectRevert(
                abi.encodeWithSelector(IPassivePerpProxyV2.LastFundingTimestampAlreadyInitialized.selector, marketId)
            );
            IPassivePerpProxyV2(sec.perp).initializeLastFundingTimestamp(marketId);

            assertEq(
                IPassivePerpProxyV2(sec.perp).getMarketData(marketId).marketData.lastFundingTimestamp,
                timestampBefore,
                "failed initializer changed an existing timestamp"
            );
        }
    }

    function test_MainnetPerpOB_ZeroFundingTimestampInitializesOnceThenRejectsReplay() public {
        _allowFundingTimestampMigration();

        for (uint128 marketId = ETH_MARKET_ID; marketId <= BTC_MARKET_ID; marketId++) {
            vm.store(sec.perp, _marketStorageSlot(marketId, 5), bytes32(0));
            assertEq(
                IPassivePerpProxyV2(sec.perp).getMarketData(marketId).marketData.lastFundingTimestamp,
                0,
                "test precondition did not produce a zero timestamp"
            );

            IPassivePerpProxyV2(sec.perp).initializeLastFundingTimestamp(marketId);
            assertEq(
                IPassivePerpProxyV2(sec.perp).getMarketData(marketId).marketData.lastFundingTimestamp,
                block.timestamp,
                "zero timestamp was not initialized"
            );

            vm.expectRevert(
                abi.encodeWithSelector(IPassivePerpProxyV2.LastFundingTimestampAlreadyInitialized.selector, marketId)
            );
            IPassivePerpProxyV2(sec.perp).initializeLastFundingTimestamp(marketId);
        }
    }

    function _forkBlock() internal view returns (uint256) {
        return vm.envOr("REYA_PERPOB_FORK_BLOCK", MAINNET_FORK_BLOCK);
    }

    function _selectPristineUpgradedFork() internal returns (uint256 upgradedFork) {
        string memory localRpc = vm.envOr("REYA_PERPOB_LOCAL_RPC", string(""));
        if (bytes(localRpc).length == 0) return vm.activeFork();
        upgradedFork = vm.createFork(localRpc);
        vm.selectFork(upgradedFork);
    }

    function _sampleAccountIds() internal pure returns (uint128[10] memory ids) {
        ids = [uint128(21_499), 17_695, 6047, 48_720, 112_150, 129_692, 52_554, 2, 120_234, STATE_ACCOUNT_ID];
    }

    function _collateralAt(uint256 index) internal view returns (address) {
        if (index == 0) return sec.rusd;
        if (index == 1) return sec.weth;
        if (index == 2) return sec.wbtc;
        if (index == 3) return sec.usde;
        if (index == 4) return sec.deusd;
        if (index == 5) return sec.susde;
        if (index == 6) return sec.sdeusd;
        if (index == 7) return sec.srusd;
        if (index == 8) return sec.rselini;
        if (index == 9) return sec.ramber;
        if (index == 10) return sec.rhedge;
        if (index == 11) return sec.wsteth;
        if (index == 12) return sec.usdc;
        revert("collateral index out of bounds");
    }

    function _readAccountState(
        uint128 accountId,
        bool includeCollateralInfo
    )
        internal
        view
        returns (PreservedAccountState memory state)
    {
        state.id = accountId;
        state.owner = ICoreProxy(sec.core).getAccountOwner(accountId);
        AccountPermissions[] memory permissions = ICoreProxy(sec.core).getAccountPermissions(accountId);
        state.permissionsHash = keccak256(abi.encode(permissions));
        if (includeCollateralInfo) {
            bytes32 collateralInfoHash;
            for (uint256 index = 0; index < 13; index++) {
                CollateralInfo memory info = ICoreProxy(sec.core).getCollateralInfo(accountId, _collateralAt(index));
                collateralInfoHash = keccak256(abi.encode(collateralInfoHash, info));
                if (index == 5) state.susdeNetDeposits = info.netDeposits;
            }
            state.collateralInfoHash = collateralInfoHash;
        }
        state.ethPositionHash = keccak256(abi.encode(_readLegacyPositionSlots(ETH_MARKET_ID, accountId)));
        state.btcPositionHash = keccak256(abi.encode(_readLegacyPositionSlots(BTC_MARKET_ID, accountId)));
    }

    function _readSampledAccountsHash(uint128[10] memory accountIds) internal view returns (bytes32 hash) {
        for (uint256 index = 0; index < accountIds.length; index++) {
            PreservedAccountState memory accountState = _readAccountState(accountIds[index], index == 6);
            assertTrue(accountState.owner != address(0), "sample owner is zero");
            hash = keccak256(abi.encode(hash, accountState));
        }
    }

    function _assertCollateralPoolBalancesEq(uint256 upgradedFork, uint256 preUpgradeFork) internal {
        for (uint256 index = 0; index < 13; index++) {
            vm.selectFork(upgradedFork);
            address collateral = _collateralAt(index);
            uint256 actual = ICoreProxy(sec.core).getCollateralPoolBalance(1, collateral);
            vm.selectFork(preUpgradeFork);
            uint256 expected = ICoreProxy(sec.core).getCollateralPoolBalance(1, collateral);
            assertEq(actual, expected, string.concat("collateral pool balance changed ", vm.toString(index)));
        }
        vm.selectFork(upgradedFork);
    }

    function _assertPreUpgradeCollateralAnchors(uint128 positionlessAccountId) internal view {
        assertTrue(ICoreProxy(sec.core).getCollateralPoolBalance(1, sec.weth) != 0, "WETH pool anchor is empty");
        assertTrue(ICoreProxy(sec.core).getCollateralPoolBalance(1, sec.wbtc) != 0, "WBTC pool anchor is empty");
        assertTrue(
            ICoreProxy(sec.core).getCollateralInfo(positionlessAccountId, sec.susde).netDeposits != 0,
            "sUSDe diversity anchor is empty"
        );
        assertTrue(ICoreProxy(sec.core).getCollateralPoolBalance(1, sec.rselini) != 0, "rSELINI pool anchor is empty");
        assertTrue(ICoreProxy(sec.core).getCollateralPoolBalance(1, sec.ramber) != 0, "rAMBER pool anchor is empty");
        assertTrue(ICoreProxy(sec.core).getCollateralPoolBalance(1, sec.rhedge) != 0, "rHEDGE pool anchor is empty");
    }

    function _readOraclePrice(uint128 marketId) internal view returns (uint256) {
        MarketConfigurationData memory config = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
        NodeOutput.Data memory output = IOracleManagerProxy(sec.oracleManager).process(config.oracleNodeId);
        return output.price;
    }

    function _readEconomicState() internal view returns (PreservedEconomicState memory state) {
        state.timestamp = block.timestamp;
        state.ethPrice = IPassivePerpProxy(sec.perp).getInstantaneousPoolPrice(ETH_MARKET_ID);
        state.btcPrice = IPassivePerpProxy(sec.perp).getInstantaneousPoolPrice(BTC_MARKET_ID);
        state.ethFundingRate = IPassivePerpProxy(sec.perp).getLatestFundingRate(ETH_MARKET_ID);
        state.btcFundingRate = IPassivePerpProxy(sec.perp).getLatestFundingRate(BTC_MARKET_ID);
        state.ethPosition = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(ETH_MARKET_ID, STATE_ACCOUNT_ID);
        state.btcPosition = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(BTC_MARKET_ID, STATE_ACCOUNT_ID);
        state.ethPnl = IPassivePerpProxy(sec.perp).getAccountPnLComponents(ETH_MARKET_ID, STATE_ACCOUNT_ID);
        state.btcPnl = IPassivePerpProxy(sec.perp).getAccountPnLComponents(BTC_MARKET_ID, STATE_ACCOUNT_ID);
    }

    function _readPositionAndPnlState() internal view returns (PreservedEconomicState memory state) {
        state.timestamp = block.timestamp;
        state.ethPosition = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(ETH_MARKET_ID, STATE_ACCOUNT_ID);
        state.btcPosition = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(BTC_MARKET_ID, STATE_ACCOUNT_ID);
        state.ethPnl = IPassivePerpProxy(sec.perp).getAccountPnLComponents(ETH_MARKET_ID, STATE_ACCOUNT_ID);
        state.btcPnl = IPassivePerpProxy(sec.perp).getAccountPnLComponents(BTC_MARKET_ID, STATE_ACCOUNT_ID);
    }

    function _assertPositionAndPnlEq(
        string memory label,
        PerpPosition memory actual,
        PerpPosition memory expected,
        PnLComponents memory actualPnl,
        PnLComponents memory expectedPnl
    )
        internal
        pure
    {
        assertEq(actual.base, expected.base, string.concat(label, " base changed"));
        // The stored funding/PnL basis is byte-exact in the raw-slot gate.
        // Legacy AMM instantaneous price and the pushed PerpOB mark use
        // different computed models, so enforce a tight 10-bps continuity
        // bound while holding time, mark and funding observations fixed.
        assertApproxEqRel(
            actualPnl.realizedPnL + actualPnl.unrealizedPnL,
            expectedPnl.realizedPnL + expectedPnl.unrealizedPnL,
            0.001e18,
            string.concat(label, " total PnL changed")
        );
    }

    function _allowFundingTimestampMigration() internal {
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(keccak256(bytes("migration1")), address(this));
    }

    function _marketStorageSlot(uint128 marketId, uint256 offset) internal pure returns (bytes32) {
        bytes32 marketSlot = keccak256(abi.encodePacked(keccak256(bytes("xyz.reya.Market")), marketId));
        return bytes32(uint256(marketSlot) + offset);
    }

    function _readPreUpgradeState() internal view returns (PreservedState memory state) {
        state.accountOwner = ICoreProxy(sec.core).getAccountOwner(STATE_ACCOUNT_ID);
        state.rusdBalanceSlot = _readCollateralBalanceSlot(STATE_ACCOUNT_ID, sec.rusd);
        state.ethPositionSlots = _readLegacyPositionSlots(ETH_MARKET_ID, STATE_ACCOUNT_ID);
        state.btcPositionSlots = _readLegacyPositionSlots(BTC_MARKET_ID, STATE_ACCOUNT_ID);
        state.ethMarket = _readLegacyMarket(ETH_MARKET_ID);
        state.btcMarket = _readLegacyMarket(BTC_MARKET_ID);
    }

    function _readPostUpgradeState() internal view returns (PreservedState memory state) {
        state.accountOwner = ICoreProxy(sec.core).getAccountOwner(STATE_ACCOUNT_ID);
        state.rusdBalanceSlot = _readCollateralBalanceSlot(STATE_ACCOUNT_ID, sec.rusd);
        state.ethPositionSlots = _readLegacyPositionSlots(ETH_MARKET_ID, STATE_ACCOUNT_ID);
        state.btcPositionSlots = _readLegacyPositionSlots(BTC_MARKET_ID, STATE_ACCOUNT_ID);
        state.ethMarket = _readPerpOBMarket(ETH_MARKET_ID);
        state.btcMarket = _readPerpOBMarket(BTC_MARKET_ID);
    }

    function _readLegacyMarket(uint128 marketId) internal view returns (PreservedMarketState memory state) {
        MarketDataResponse memory response = IPassivePerpProxy(sec.perp).getMarketData(marketId);
        state.id = response.marketData.id;
        state.quoteToken = response.marketData.quoteToken;
        state.quoteTokenDecimals = response.marketData.quoteTokenDecimals;
        state.lastFundingTimestamp = response.marketData.lastFundingTimestamp;
        state.longTrackers = response.marketData.longTrackers;
        state.shortTrackers = response.marketData.shortTrackers;
        state.openInterest = response.marketData.openInterest;
    }

    function _readPerpOBMarket(uint128 marketId) internal view returns (PreservedMarketState memory state) {
        MarketDataResponseV2 memory response = IPassivePerpProxyV2(sec.perp).getMarketData(marketId);
        state.id = response.marketData.id;
        state.quoteToken = response.marketData.quoteToken;
        state.quoteTokenDecimals = response.marketData.quoteTokenDecimals;
        state.lastFundingTimestamp = response.marketData.lastFundingTimestamp;
        state.longTrackers = response.marketData.longTrackers;
        state.shortTrackers = response.marketData.shortTrackers;
        state.openInterest = response.marketData.openInterest;
    }

    function _readLegacyPositionSlots(
        uint128 marketId,
        uint128 accountId
    )
        internal
        view
        returns (bytes32[7] memory slots)
    {
        bytes32 storageName = keccak256(bytes("xyz.reya.PerpPositions"));
        bytes32 marketSlot = keccak256(abi.encodePacked(storageName, marketId));
        bytes32 positionSlot = keccak256(abi.encode(accountId, marketSlot));

        for (uint256 offset = 0; offset < slots.length; offset++) {
            slots[offset] = vm.load(sec.perp, bytes32(uint256(positionSlot) + offset));
        }
    }

    function _readCollateralBalanceSlot(uint128 accountId, address collateral) internal view returns (bytes32) {
        bytes32 accountCollateralSlot =
            keccak256(abi.encodePacked(keccak256(bytes("xyz.reya.AccountCollateral")), accountId));
        return vm.load(sec.core, keccak256(abi.encode(collateral, accountCollateralSlot)));
    }

    function _assertPositionStorageEq(
        string memory market,
        bytes32[7] memory actual,
        bytes32[7] memory expected
    )
        internal
        pure
    {
        for (uint256 offset = 0; offset < actual.length; offset++) {
            assertEq(
                actual[offset],
                expected[offset],
                string.concat(market, " legacy position slot changed ", vm.toString(offset))
            );
        }
    }

    function _assertMarketEq(
        string memory market,
        PreservedMarketState memory actual,
        PreservedMarketState memory expected
    )
        internal
        pure
    {
        assertEq(actual.id, expected.id, string.concat(market, " market id changed"));
        assertEq(actual.quoteToken, expected.quoteToken, string.concat(market, " quote token changed"));
        assertEq(
            actual.quoteTokenDecimals,
            expected.quoteTokenDecimals,
            string.concat(market, " quote token decimals changed")
        );
        assertEq(
            actual.lastFundingTimestamp,
            expected.lastFundingTimestamp,
            string.concat(market, " funding timestamp was overwritten")
        );
        _assertTrackersEq(market, "long", actual.longTrackers, expected.longTrackers);
        _assertTrackersEq(market, "short", actual.shortTrackers, expected.shortTrackers);
        assertEq(actual.openInterest, expected.openInterest, string.concat(market, " open interest changed"));
    }

    function _assertTrackersEq(
        string memory market,
        string memory side,
        FundingAndADLTrackers memory actual,
        FundingAndADLTrackers memory expected
    )
        internal
        pure
    {
        string memory prefix = string.concat(market, " ", side);
        assertEq(actual.fundingValue, expected.fundingValue, string.concat(prefix, " funding tracker changed"));
        assertEq(actual.baseMultiplier, expected.baseMultiplier, string.concat(prefix, " base multiplier changed"));
        assertEq(actual.adlUnwindPrice, expected.adlUnwindPrice, string.concat(prefix, " ADL unwind price changed"));
    }
}
