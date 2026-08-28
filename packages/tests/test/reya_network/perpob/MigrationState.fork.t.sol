// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { IPassivePerpProxy, FundingAndADLTrackers, MarketDataResponse } from "../../../src/interfaces/IPassivePerpProxy.sol";
import { IPassivePerpProxyV2, MarketDataResponseV2 } from "../../../src/interfaces/IPassivePerpProxyV2.sol";
import { ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";

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
        bytes32[7] ethPositionSlots;
        bytes32[7] btcPositionSlots;
        PreservedMarketState ethMarket;
        PreservedMarketState btcMarket;
    }

    function test_MainnetPerpOB_PreservesRepresentativeState() public {
        uint256 upgradedFork = vm.activeFork();

        uint256 preUpgradeFork = vm.createFork(sec.REYA_RPC, MAINNET_FORK_BLOCK);
        vm.selectFork(preUpgradeFork);
        PreservedState memory preUpgrade = _readPreUpgradeState();
        vm.selectFork(upgradedFork);
        PreservedState memory postUpgrade = _readPostUpgradeState();

        assertEq(preUpgrade.accountOwner, STATE_ACCOUNT_OWNER, "unexpected state-anchor owner at pinned block");
        assertTrue(preUpgrade.ethPositionSlots[0] != bytes32(0), "state-anchor ETH position is empty");
        assertTrue(preUpgrade.btcPositionSlots[0] != bytes32(0), "state-anchor BTC position is empty");

        assertEq(postUpgrade.accountOwner, preUpgrade.accountOwner, "account owner changed during upgrade");
        _assertPositionStorageEq("ETH", postUpgrade.ethPositionSlots, preUpgrade.ethPositionSlots);
        _assertPositionStorageEq("BTC", postUpgrade.btcPositionSlots, preUpgrade.btcPositionSlots);
        _assertMarketEq("ETH", postUpgrade.ethMarket, preUpgrade.ethMarket);
        _assertMarketEq("BTC", postUpgrade.btcMarket, preUpgrade.btcMarket);

        assertTrue(postUpgrade.ethMarket.lastFundingTimestamp != 0, "ETH funding timestamp was not initialized");
        assertTrue(postUpgrade.btcMarket.lastFundingTimestamp != 0, "BTC funding timestamp was not initialized");
    }

    function test_MainnetPerpOB_PreservesAllMarketActivationFlags() public {
        uint256 upgradedFork = vm.activeFork();
        bool[75] memory postUpgradeActive;

        assertEq(lastMarketId(), LAST_MAINNET_MARKET_ID, "unexpected mainnet market count");
        for (uint128 marketId = ETH_MARKET_ID; marketId <= LAST_MAINNET_MARKET_ID; marketId++) {
            postUpgradeActive[marketId - 1] = isMarketActive(marketId);
        }

        uint256 preUpgradeFork = vm.createFork(sec.REYA_RPC, MAINNET_FORK_BLOCK);
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

    function test_MainnetPerpOB_PreservesAllMarketFundingTimestampsAndOpenInterest() public {
        uint256 upgradedFork = vm.activeFork();
        uint256[75] memory postUpgradeFundingTimestamps;
        uint256[75] memory postUpgradeOpenInterest;

        for (uint128 marketId = ETH_MARKET_ID; marketId <= LAST_MAINNET_MARKET_ID; marketId++) {
            MarketDataResponseV2 memory data = IPassivePerpProxyV2(sec.perp).getMarketData(marketId);
            postUpgradeFundingTimestamps[marketId - 1] = data.marketData.lastFundingTimestamp;
            postUpgradeOpenInterest[marketId - 1] = data.marketData.openInterest;
        }

        uint256 preUpgradeFork = vm.createFork(sec.REYA_RPC, MAINNET_FORK_BLOCK);
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

    function _readPreUpgradeState() internal view returns (PreservedState memory state) {
        state.accountOwner = ICoreProxy(sec.core).getAccountOwner(STATE_ACCOUNT_ID);
        state.ethPositionSlots = _readLegacyPositionSlots(ETH_MARKET_ID, STATE_ACCOUNT_ID);
        state.btcPositionSlots = _readLegacyPositionSlots(BTC_MARKET_ID, STATE_ACCOUNT_ID);
        state.ethMarket = _readLegacyMarket(ETH_MARKET_ID);
        state.btcMarket = _readLegacyMarket(BTC_MARKET_ID);
    }

    function _readPostUpgradeState() internal view returns (PreservedState memory state) {
        state.accountOwner = ICoreProxy(sec.core).getAccountOwner(STATE_ACCOUNT_ID);
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
