/*
Licensed under the Reya License (the "License"); you
may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://github.com/Voltz-Protocol/v2-core/blob/main/core/LICENSE
*/
pragma solidity >=0.8.19 <0.9.0;

/**
 * @title Interface for the Socket token bridging contract
 */
interface ISocketControllerWithPayload {
    /**
     * @notice Bridges tokens between chains.
     * @dev This function allows bridging tokens between different chains.
     * @param receiver_ The address to receive the bridged tokens.
     * @param amount_ The amount of tokens to bridge.
     * @param msgGasLimit_ The gas limit for the execution of the bridging process.
     * @param connector_ The address of the connector contract responsible for the bridge.
     * @param execPayload_ The payload for executing the bridging process on the connector.
     * @param options_ Additional options for the bridging process.
     */
    function bridge(
        address receiver_,
        uint256 amount_,
        uint256 msgGasLimit_,
        address connector_,
        bytes calldata execPayload_,
        bytes calldata options_
    )
        external
        payable;

    /**
     * @notice Retrieves the minimum fees required for a transaction from a connector.
     * @dev This function returns the minimum fees required for a transaction from the specified connector,
     * based on the provided message gas limit and payload size.
     * @param connector_ The address of the connector.
     * @param msgGasLimit_ The gas limit for the transaction.
     * @param payloadSize_ The size of the payload for the transaction.
     * @return totalFees The total minimum fees required for the transaction.
     */
    function getMinFees(
        address connector_,
        uint256 msgGasLimit_,
        uint256 payloadSize_
    )
        external
        view
        returns (uint256 totalFees);
}
