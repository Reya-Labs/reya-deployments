// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface IOracleAdaptersProxy {
    function setConfiguration(Configuration memory config) external;

    function getConfiguration() external pure returns (Configuration memory);

    function oracleId() external view returns (bytes32 oracleId);

    function fulfillOracleQuery(bytes calldata signedOffchainData) external payable;

    function getLatestPricePayload(
        string memory assetPairId
    ) external view returns (StorkPricePayload memory);

    function addToFeatureFlagAllowlist(bytes32 feature, address account)
        external;

    function removeFromFeatureFlagAllowlist(bytes32 feature, address account)
        external;

    error StorkPayloadSignatureInvalid(StorkSignedPayload storkSignedPayload);

    error StorkPayloadOlderThanLatest(
        StorkPricePayload currentPricePayload,
        StorkPricePayload latestPricePayload
    );

    error UnauthorizedPublisher(address unathorizedPublisher);
}

struct StorkSignedPayload {
    address oraclePubKey;
    StorkPricePayload pricePayload;
    bytes32 r;
    bytes32 s;
    uint8 v;
}

struct StorkPricePayload {
    string assetPairId;
    uint256 timestamp;
    uint256 price;
}

struct Configuration {
    address storkVerifyContract;
}
