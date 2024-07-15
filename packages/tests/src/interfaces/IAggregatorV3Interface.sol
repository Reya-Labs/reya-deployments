/*
// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

/**
 * @title Interface an aggregator needs to adhere.
 */
interface IAggregatorV3Interface {
    /**
     * @notice Decimals used by the aggregator
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Aggregator's description
     */
    function description() external view returns (string memory);

    /**
     * @notice Aggregator's version
     */
    function version() external view returns (uint256);

    /**
     * @notice Returns round data for requested id
     * @notice getRoundData and latestRoundData should both raise "No data present"
     * if they do not have data to report, instead of returning unset values
     * which could be misinterpreted as actual reported values.
     */
    function getRoundData(uint80 id)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    /**
     * @notice Returns latest round data
     */
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
