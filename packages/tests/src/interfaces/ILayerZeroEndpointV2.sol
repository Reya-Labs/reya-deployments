// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILayerZeroEndpointV2 {
    function delegates(address oapp) external view returns (address);
}
