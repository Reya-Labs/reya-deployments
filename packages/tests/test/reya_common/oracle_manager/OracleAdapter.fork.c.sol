pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import {
    IOracleAdaptersProxy,
    StorkSignedPayload,
    StorkPricePayload
} from "../../../src/interfaces/IOracleAdaptersProxy.sol";

contract OracleAdapterForkCheck is BaseReyaForkTest {
    function check_fulfillOracleQuery_StorkOracleAdapter() public {
        (address futurePublisher, uint256 futurePublisherPK) = makeAddrAndKey("futurePublisher");

        // Use an existing allowlisted executor — the offchain wallets we run in production —
        // so the feature-flag gate passes and the call reaches the publisher check below.
        address[] memory executors =
            IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowlist(keccak256(bytes("executors")));
        require(executors.length > 0, "no allowlisted executors");
        address executor = executors[0];

        // create a StorkPricePayload and sign it
        StorkSignedPayload memory storkSignedPayload =
            createSignedPricePayload(futurePublisher, futurePublisherPK, block.timestamp);

        // expect revert since the publisher is not authorized yet
        vm.prank(executor);
        vm.expectRevert(abi.encodeWithSelector(IOracleAdaptersProxy.UnauthorizedPublisher.selector, futurePublisher));
        IOracleAdaptersProxy(sec.oracleAdaptersProxy).fulfillOracleQuery(abi.encode(storkSignedPayload));

        // authorize the publisher
        vm.prank(sec.multisig);
        IOracleAdaptersProxy(sec.oracleAdaptersProxy).addToFeatureFlagAllowlist(
            keccak256(bytes("publishers")), futurePublisher
        );

        // expect successful update
        vm.prank(executor);
        IOracleAdaptersProxy(sec.oracleAdaptersProxy).fulfillOracleQuery(abi.encode(storkSignedPayload));

        // create an earlier StorkPricePayload and sign it
        StorkSignedPayload memory storkSignedPayload2 =
            createSignedPricePayload(futurePublisher, futurePublisherPK, block.timestamp - 1);

        // expect revert since we push an earlier price payload
        vm.prank(executor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IOracleAdaptersProxy.StorkPayloadOlderThanLatest.selector,
                storkSignedPayload2.pricePayload,
                storkSignedPayload.pricePayload
            )
        );
        IOracleAdaptersProxy(sec.oracleAdaptersProxy).fulfillOracleQuery(abi.encode(storkSignedPayload2));

        // check the final state of the oracle adapter
        StorkPricePayload memory existingPricePayload =
            IOracleAdaptersProxy(sec.oracleAdaptersProxy).getLatestPricePayload("ETH/USD");
        assertEq(existingPricePayload.assetPairId, "ETH/USD");
        assertEq(existingPricePayload.timestamp, block.timestamp);
        assertEq(existingPricePayload.price, 3000e18);
    }
}
