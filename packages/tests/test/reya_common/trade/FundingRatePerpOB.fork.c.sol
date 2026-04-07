pragma solidity >=0.8.19 <0.9.0;

import { PerpFillForkCheck } from "./PerpFill.fork.c.sol";

import {
    IPassivePerpProxy,
    OracleDataPayload,
    OracleDataType,
    PerpPosition,
    MarketDataResponse,
    EIP712Signature as PerpEIP712Signature
} from "../../../src/interfaces/IPassivePerpProxy.sol";
import { ICoreProxy, MarginInfo } from "../../../src/interfaces/ICoreProxy.sol";
import { OracleDataPayloadHashing } from "../../../src/utils/OracleDataPayloadHashing.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

/**
 * @title FundingRatePerpOBForkCheck
 * @notice Fork tests for push-based funding rates (perpOB model)
 * @dev Tests oracle-pushed funding rates via OraclePushModule.
 *      The legacy velocity-based FundingRateForkCheck is kept separately for cronos/mainnet.
 */
contract FundingRatePerpOBForkCheck is PerpFillForkCheck {
    address internal fundingPublisher;
    uint256 internal fundingPublisherPk;

    function setupFundingTestActors() internal {
        (fundingPublisher, fundingPublisherPk) = makeAddrAndKey("fundingPublisher");

        // Grant oracle pusher access (checks msg.sender)
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUSHERS_FLAG, fundingPublisher);

        // Grant oracle publisher access (checks payload.publisher signature)
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUBLISHERS_FLAG, fundingPublisher);
    }

    function _pushOracleData(uint128 marketId, OracleDataType dataType, bytes memory data) internal {
        OracleDataPayload memory payload = OracleDataPayload({
            marketId: marketId, timestamp: block.timestamp, dataType: dataType, data: data, publisher: fundingPublisher
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(fundingPublisherPk, OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp));

        PerpEIP712Signature memory sig = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        vm.prank(fundingPublisher);
        IPassivePerpProxy(sec.perp).pushOracleData(payload, sig);
    }

    /**
     * @notice Test pushing a funding rate and reading it back
     */
    function check_PushFundingRate(uint128 marketId) internal {
        setupFundingTestActors();
        mockFreshPrices();

        // Push a positive funding rate (1% annualized = 1e16)
        int256 fundingRate = 1e16;
        _pushOracleData(marketId, OracleDataType.FundingRate, abi.encode(fundingRate));

        // Read back via getMarketData (standalone getters not on router)
        MarketDataResponse memory mdr = IPassivePerpProxy(sec.perp).getMarketData(marketId);
        assertEq(mdr.marketData.fundingRate, fundingRate, "Stored funding rate should match pushed value");
        assertEq(mdr.marketData.fundingRateTimestamp, block.timestamp, "Funding rate timestamp should match");
    }

    /**
     * @notice Test that stale funding rate is detected
     */
    function check_FundingRateStaleness(uint128 marketId) internal {
        setupFundingTestActors();
        mockFreshPrices();

        // Push funding rate
        _pushOracleData(marketId, OracleDataType.FundingRate, abi.encode(int256(1e16)));

        // Warp past max stale duration
        vm.warp(block.timestamp + 3601);
        mockFreshPrices();

        // Reading should still work (staleness is checked during trade, not read)
        MarketDataResponse memory mdr = IPassivePerpProxy(sec.perp).getMarketData(marketId);
        assertTrue(block.timestamp > mdr.marketData.fundingRateTimestamp + 3600, "Funding rate should be stale");
    }

    /**
     * @notice Test pushing a mark price and reading it back
     */
    function check_PushMarkPrice(uint128 marketId) internal {
        setupFundingTestActors();
        mockFreshPrices();

        uint256 markPrice = 3000e18;
        _pushOracleData(marketId, OracleDataType.MarkPrice, abi.encode(markPrice));

        // Read back via getMarketData (standalone getters not on router)
        MarketDataResponse memory mdr = IPassivePerpProxy(sec.perp).getMarketData(marketId);
        assertEq(mdr.marketData.markPrice, markPrice, "Stored mark price should match pushed value");
        assertEq(mdr.marketData.markPriceTimestamp, block.timestamp, "Mark price timestamp should match");
    }

    /**
     * @notice Test that funding rate actually accrues on open positions
     * @dev Opens a long position, pushes a positive funding rate, warps forward,
     *      and verifies that the long's margin decreases (longs pay positive funding).
     */
    function check_FundingRateAccrual(uint128 marketId) internal {
        // Use PerpFill actors (we inherit from PerpFillForkCheck now)
        setupPerpTestActors();
        mockFreshPrices();

        // Push mark price and zero initial funding
        pushMarkPrice(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        // Open position: buyer goes long 1 ETH
        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 1e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        // Record margin immediately after open
        MarginInfo memory buyerMarginAfterOpen = ICoreProxy(sec.core).getUsdNodeMarginInfo(buyerAccountId);
        MarginInfo memory sellerMarginAfterOpen = ICoreProxy(sec.core).getUsdNodeMarginInfo(sellerAccountId);

        // Push a positive funding rate (longs pay, shorts receive)
        // 10% annualized = 0.1e18
        int256 positiveRate = 0.1e18;
        pushFundingRate(marketId, positiveRate);

        // Warp forward 1 hour
        vm.warp(block.timestamp + 3600);

        // Refresh prices and funding to a new timestamp so staleness doesn't interfere
        mockFreshPrices();
        pushMarkPrice(marketId, 3000e18); // same price — isolate funding effect
        pushFundingRate(marketId, positiveRate); // re-push at new timestamp

        // Check margin after funding accrual
        MarginInfo memory buyerMarginAfterFunding = ICoreProxy(sec.core).getUsdNodeMarginInfo(buyerAccountId);
        MarginInfo memory sellerMarginAfterFunding = ICoreProxy(sec.core).getUsdNodeMarginInfo(sellerAccountId);

        // Long pays positive funding → margin decreases
        assertLt(
            buyerMarginAfterFunding.marginBalance,
            buyerMarginAfterOpen.marginBalance,
            "Long should lose margin from positive funding"
        );

        // Short receives positive funding → margin increases
        assertGt(
            sellerMarginAfterFunding.marginBalance,
            sellerMarginAfterOpen.marginBalance,
            "Short should gain margin from positive funding"
        );
    }
}
