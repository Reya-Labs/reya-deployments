pragma solidity ^0.8.4;

interface IElixirSdeusd {
  function convertToAssets(uint256 shares) external view returns (uint256);
}