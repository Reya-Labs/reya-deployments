pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import {
    IOracleAdaptersProxy,
    StorkSignedPayload,
    StorkPricePayload
} from "../../../src/interfaces/IOracleAdaptersProxy.sol";

contract OracleAdapterForkCheck is BaseReyaForkTest {
    bytes32 internal constant _PUBLISHER_FEATURE_FLAG = keccak256(bytes("publishers"));
    address internal futurePublisher;
    uint256 internal futurePublisherPK;

    function setUp() public {
        (futurePublisher, futurePublisherPK) = makeAddrAndKey("futurePublisher");
    }

    function calculatePricePayloadDigest(
        address oraclePubKey,
        StorkPricePayload memory pricePayload
    )
        internal
        pure
        returns (bytes32)
    {
        bytes32 hashedMessage = keccak256(
            abi.encodePacked(oraclePubKey, pricePayload.assetPairId, pricePayload.timestamp, pricePayload.price)
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedMessage));
        return digest;
    }

    function createSignedPricePayload(uint256 timestamp) internal view returns (StorkSignedPayload memory) {
        StorkPricePayload memory pricePayload =
            StorkPricePayload({ assetPairId: "ETH/USD", timestamp: timestamp, price: 3000e18 });

        bytes32 digest = calculatePricePayloadDigest(futurePublisher, pricePayload);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(futurePublisherPK, digest);

        StorkSignedPayload memory storkSignedPayload =
            StorkSignedPayload({ oraclePubKey: futurePublisher, pricePayload: pricePayload, r: r, s: s, v: v });

        return storkSignedPayload;
    }

    function check_fulfillOracleQuery_StorkOracleAdapter() public {
        // create a StorkPricePayload and sign it
        StorkSignedPayload memory storkSignedPayload = createSignedPricePayload(block.timestamp);

        // expect revert since the publisher is not authorized yet
        vm.prank(futurePublisher);
        vm.expectRevert(abi.encodeWithSelector(IOracleAdaptersProxy.UnauthorizedPublisher.selector, futurePublisher));
        IOracleAdaptersProxy(sec.oracleAdaptersProxy).fulfillOracleQuery(abi.encode(storkSignedPayload));

        // authorize the publisher
        vm.prank(sec.multisig);
        IOracleAdaptersProxy(sec.oracleAdaptersProxy).addToFeatureFlagAllowlist(
            _PUBLISHER_FEATURE_FLAG, futurePublisher
        );

        // expect successful update
        vm.prank(futurePublisher);
        IOracleAdaptersProxy(sec.oracleAdaptersProxy).fulfillOracleQuery(abi.encode(storkSignedPayload));

        // create an earlier StorkPricePayload and sign it
        StorkSignedPayload memory storkSignedPayload2 = createSignedPricePayload(block.timestamp - 1);

        // expect revert since we push an earlier price payload
        vm.prank(futurePublisher);
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
