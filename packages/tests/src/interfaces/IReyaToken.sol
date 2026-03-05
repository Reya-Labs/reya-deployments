// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IReyaToken {
    function pause() external;
    function unpause() external;
    function mint(address to, uint256 amount) external;
    function balanceOf(address owner) external view returns (uint256);
    function owner() external view returns (address);

    error NotEnoughBalance(address owner, uint256 balance, uint256 amount);
}

interface IStakedReyaToken {
    function pause() external;
    function unpause() external;
    function balanceOf(address owner) external view returns (uint256);
    function owner() external view returns (address);
}