/*
Licensed under the Reya License (the "License"); you
may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://github.com/Voltz-Protocol/v2-core/blob/main/core/LICENSE
*/
pragma solidity >=0.8.19 <0.9.0;

/**
 * @title Interface for the Socket bridging execution helper contract
 */
interface ISocketExecutionHelper {
    /**
     * @notice Returns the amount of tokens just bridged
     */
    function bridgeAmount() external view returns (uint256 bridgeAmount);
}
