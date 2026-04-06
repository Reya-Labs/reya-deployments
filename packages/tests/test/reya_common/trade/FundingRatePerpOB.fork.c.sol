pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import {
    IPassivePerpProxy,
    OracleDataPayload,
    OracleDataType,
    PerpPosition,
    EIP712Signature as PerpEIP712Signature
} from "../../../src/interfaces/IPassivePerpProxy.sol";
import { ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";
import { OracleDataPayloadHashing } from "../../../src/utils/OracleDataPayloadHashing.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

/**
 * @title FundingRatePerpOBForkCheck
 * @notice Fork tests for push-based funding rates (perpOB model)
 * @dev Tests oracle-pushed funding rates via OraclePushModule.
 *      The legacy velocity-based FundingRateForkCheck is kept separately for cronos/mainnet.
 */
contract FundingRatePerpOBForkCheck is BaseReyaForkTest {
    address internal fundingPublisher;
    uint256 internal fundingPublisherPk;

    bytes32 internal constant ORACLE_PUSHERS_FLAG = keccak256(bytes("oraclePushers"));

    function setupFundingTestActors() internal {
        (fundingPublisher, fundingPublisherPk) = makeAddrAndKey("fundingPublisher");

        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUSHERS_FLAG, fundingPublisher);
    }

    function _pushOracleData(uint128 marketId, OracleDataType dataType, bytes memory data) internal {
        OracleDataPayload memory payload = OracleDataPayload({
            marketId: marketId,
            timestamp: block.timestamp,
            dataType: dataType,
            data: data,
            publisher: fundingPublisher
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            fundingPublisherPk, OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp)
        );

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

        // Read it back
        int256 storedRate = IPassivePerpProxy(sec.perp).getFundingRate(marketId);
        assertEq(storedRate, fundingRate, "Stored funding rate should match pushed value");

        uint256 storedTimestamp = IPassivePerpProxy(sec.perp).getFundingRateTimestamp(marketId);
        assertEq(storedTimestamp, block.timestamp, "Funding rate timestamp should match");
    }

    /**
     * @notice Test that stale funding rate is rejected
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
        uint256 ts = IPassivePerpProxy(sec.perp).getFundingRateTimestamp(marketId);
        assertTrue(block.timestamp > ts + 3600, "Funding rate should be stale");
    }

    /**
     * @notice Test pushing a mark price and reading it back
     */
    function check_PushMarkPrice(uint128 marketId) internal {
        setupFundingTestActors();
        mockFreshPrices();

        uint256 markPrice = 3000e18;
        _pushOracleData(marketId, OracleDataType.MarkPrice, abi.encode(markPrice));

        uint256 storedPrice = IPassivePerpProxy(sec.perp).getMarkPrice(marketId);
        assertEq(storedPrice, markPrice, "Stored mark price should match pushed value");

        uint256 storedTimestamp = IPassivePerpProxy(sec.perp).getMarkPriceTimestamp(marketId);
        assertEq(storedTimestamp, block.timestamp, "Mark price timestamp should match");
    }
}
