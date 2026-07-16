// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// This script replays exact multisig batch calldata; console logging and long hex literals are intentional.
// solhint-disable no-console, max-line-length

import { Script, console2 } from "forge-std/Script.sol";

import { ICoreProxy, GlobalCollateralConfig } from "../src/interfaces/ICoreProxy.sol";
import { ITokenProxy } from "../src/interfaces/ITokenProxy.sol";

/// @title AdHocBatch
/// @notice Replays the multisig's RAMBER-rebalance batch as its 5 underlying calls, each sent directly to its target
///         and broadcast as the multisig — exactly as the batch executor (selector 0x174dea71) would run them
///         internally, but unwrapped so each tx is visible and replays the literal calldata. The 5 calls are:
///           1. USDC.approve(RUSD, 250_000e6)
///           2. RUSD.deposit(250_000e6)
///           3. RUSD.approve(POOL, 250_000e6)
///           4. CORE.setGlobalCollateralConfig(RAMBER, ...)
///           5. POOL.triggerAutoRebalance(poolId=1, ... -> RAMBER, receiver=multisig)
///
/// @dev Pretend to be the batch caller (the multisig). Dry-run against a fork (no key needed) with `--unlocked`:
///        forge script script/AdHocBatch.s.sol:AdHocBatch \
///          --rpc-url https://rpc.reya.network --sender 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9 --unlocked -vvvv
///      To actually submit, add `--broadcast` and supply the caller's key (e.g. `--account <keystore>`).
contract AdHocBatch is Script {
    // Reya Network mainnet (chainId 1729).
    ICoreProxy constant CORE = ICoreProxy(payable(0xA763B6a5E09378434406C003daE6487FbbDc1a80));
    address constant USDC = 0x3B860c0b53f2e8bd5264AA7c3451d41263C933F2;
    address constant RUSD = 0xa9F32a851B1800742e47725DA54a09A7Ef2556A3;
    address constant POOL = 0xB4B77d6180cc14472A9a7BDFF01cc2459368D413;
    address constant RAMBER = 0x63FC3F743eE2e70e670864079978a1deB9c18b76;

    // The multisig: the originator of each call (and the impersonated caller).
    address constant BATCH_CALLER = 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9;

    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    /// @dev The 5 unwrapped calls, in order, with their exact on-chain calldata.
    function batchCalls() internal pure returns (Call[] memory calls) {
        calls = new Call[](5);

        // 1. USDC.approve(RUSD, 250_000e6)
        calls[0] = Call({
            target: USDC,
            value: 0,
            data: hex"095ea7b3000000000000000000000000a9f32a851b1800742e47725da54a09a7ef2556a30000000000000000000000000000000000000000000000000000008766ca29f0"
        });

        // 2. RUSD.deposit(250_000e6)
        calls[1] = Call({
            target: RUSD,
            value: 0,
            data: hex"b6b55f250000000000000000000000000000000000000000000000000000008766ca29f0"
        });

        // 3. RUSD.approve(POOL, 250_000e6)
        calls[2] = Call({
            target: RUSD,
            value: 0,
            data: hex"095ea7b3000000000000000000000000b4b77d6180cc14472a9a7bdff01cc2459368d4130000000000000000000000000000000000000000000000000000008766ca29f0"
        });


        // 5. POOL.triggerAutoRebalance(poolId=1, ... -> RAMBER, receiver=multisig)
        calls[3] = Call({
            target: POOL,
            value: 0,
            data: hex"91c743ab0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000a9f32a851b1800742e47725da54a09a7ef2556a30000000000000000000000000000000000000000000000000000008766ca29f000000000000000000000000063fc3f743ee2e70e670864079978a1deb9c18b7600000000000000000000000000000000000000000000000000000000000000000000000000000000000000001fe50318e5e3165742edc9c4a15d997bdb935eb9"
        });

        // 4. CORE.setGlobalCollateralConfig(RAMBER, ...)
        calls[4] = Call({
            target: address(CORE),
            value: 0,
            data: hex"3a05d82900000000000000000000000063fc3f743ee2e70e670864079978a1deb9c18b76000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000151800000000000000000000000000000000000000000000000000000000000000000"
        });
    }

    function run() external {
        uint256 usdcBefore = ITokenProxy(USDC).balanceOf(BATCH_CALLER);
        uint256 ramberBefore = ITokenProxy(RAMBER).balanceOf(BATCH_CALLER);
        console2.log("batch caller     :", BATCH_CALLER);
        console2.log("multisig USDC    :", usdcBefore);
        console2.log("multisig RAMBER  :", ramberBefore);

        Call[] memory calls = batchCalls();

        // Pretend to be the multisig and send each underlying call directly to its target as a separate tx.
        vm.startBroadcast(BATCH_CALLER);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool ok, bytes memory ret) = calls[i].target.call{ value: calls[i].value }(calls[i].data);
            require(ok, _revertReason(ret));
            console2.log("call ok | index:", i);
            console2.log("        | target:", calls[i].target);
        }
        vm.stopBroadcast();

        // Tx4 effect: RAMBER global collateral config was overwritten.
        (GlobalCollateralConfig memory cfg,) = CORE.getGlobalCollateralConfig(RAMBER);
        console2.log("ramber adapter   :", cfg.collateralAdapter);
        console2.log("ramber window    :", cfg.withdrawalWindowSize);
        console2.log("ramber tvl limit :", cfg.withdrawalTvlPercentageLimit);

        // Tx5 effect: auto-rebalance sent RAMBER to the multisig; the 250k USDC was wrapped into RUSD and consumed.
        console2.log("multisig USDC after  :", ITokenProxy(USDC).balanceOf(BATCH_CALLER));
        console2.log("multisig RAMBER after:", ITokenProxy(RAMBER).balanceOf(BATCH_CALLER));
    }

    function _revertReason(bytes memory ret) private pure returns (string memory) {
        if (ret.length == 0) return "call reverted (no reason)";
        return string(ret);
    }
}
