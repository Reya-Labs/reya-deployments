pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import {
    ICoreProxy,
    CollateralConfig,
    ParentCollateralConfig,
    MarginInfo,
    CollateralInfo,
    Command,
    EIP712Signature,
    GlobalCollateralConfig
} from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPeripheryProxy,
    DepositNewMAInputs,
    DepositExistingMAInputs,
    LzComposerOperationType,
    StakeReyaInputs,
    UnstakeStakedReyaInputs,
    WithdrawMALZInputs,
    Command as Command_Periphery
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

import { IReyaToken, IStakedReyaToken } from "../../../src/interfaces/IReyaToken.sol";
import { ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";

contract ReyaBridgingForkCheck is BaseReyaForkTest {
    address user;
    uint256 userPk;

    function check_ReyaBridgeIntoSpotMA() public returns (uint128 accountId) {
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        address reyaToken = IPeripheryProxy(sec.periphery).getGlobalConfiguration().REYAProxy;

        vm.prank(sec.multisig);
        IReyaToken(reyaToken).mint(sec.periphery, amount);

        bytes memory composeMsg = abi.encode(LzComposerOperationType.DEPOSIT_SPOT_ACCOUNT, abi.encode(user));
        bytes memory message = abi.encodePacked(
            uint64(1), // nonce
            uint32(101), // dstEid
            amount, // amount
            bytes32(uint256(uint160(address(sec.periphery)))), // receiver
            composeMsg
        );
        vm.prank(IPeripheryProxy(sec.periphery).getGlobalConfiguration().layerZeroEndpoint);
        IPeripheryProxy(sec.periphery).lzCompose(
            reyaToken, // The OFT token address
            0, // Message GUID
            message, // The composed message
            address(0), // Executor address
            bytes("") // Extra data
        );

        accountId = ICoreProxy(sec.core).createOrGetSpotAccount(user);
        assertEq(IReyaToken(reyaToken).balanceOf(sec.periphery), 0);
        assertEq(getNetDeposits(accountId, reyaToken), int256(amount));
    }

    function check_ReyaBridgeIntoNormalMAFails() public {
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 10e6;

        address reyaToken = IPeripheryProxy(sec.periphery).getGlobalConfiguration().REYAProxy;

        vm.prank(sec.multisig);
        IReyaToken(reyaToken).mint(sec.periphery, amount);

        // account id 8 has traded on both networks
        bytes memory composeMsg = abi.encode(LzComposerOperationType.DEPOSIT_ACCOUNT, abi.encode(8));
        bytes memory message = abi.encodePacked(
            uint64(1), // nonce
            uint32(101), // dstEid
            amount, // amount
            bytes32(uint256(uint160(address(sec.periphery)))), // receiver
            composeMsg
        );

        vm.prank(IPeripheryProxy(sec.periphery).getGlobalConfiguration().layerZeroEndpoint);

        vm.expectRevert(abi.encodeWithSignature("CollateralNotConfigured(uint128,address)", uint128(1), reyaToken));
        IPeripheryProxy(sec.periphery).lzCompose(
            reyaToken, // The OFT token address
            0, // Message GUID
            message, // The composed message
            address(0), // Executor address
            bytes("") // Extra data
        );
    }

    function check_ReyaStaking() public returns (uint128 account) {
        uint256 stakeAmount = 8e18;
        address reyaToken = IPeripheryProxy(sec.periphery).getGlobalConfiguration().REYAProxy;
        address stakedReya = IPeripheryProxy(sec.periphery).getGlobalConfiguration().sREYAProxy;

        account = check_ReyaBridgeIntoSpotMA();

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: 1,
            inputs: abi.encode(reyaToken, stakeAmount),
            marketId: 0, // core command, marketId is not necessary
            exchangeId: 0 // core command, does not involve exchange,
         });
        bytes memory extraData = abi.encode("stakeReya", stakeAmount);
        EIP712Signature memory sig = getEIP712SignatureForPeripheryCommands(account, commands, userPk, 1, extraData);

        IPeripheryProxy(sec.periphery).stakeReya(
            StakeReyaInputs({
                accountId: account,
                assetAmount: stakeAmount,
                minShareAmount: stakeAmount,
                withdrawSig: sig
            })
        );

        assertEq(getNetDeposits(account, reyaToken), int256(2e18));
        assertEq(getNetDeposits(account, stakedReya), int256(stakeAmount));
    }

    function check_ReyaUnstaking() public {
        uint128 account = check_ReyaStaking();
        uint256 unstakeAmount = 4e18;
        address reyaToken = IPeripheryProxy(sec.periphery).getGlobalConfiguration().REYAProxy;
        address stakedReya = IPeripheryProxy(sec.periphery).getGlobalConfiguration().sREYAProxy;

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: 1,
            inputs: abi.encode(stakedReya, unstakeAmount),
            marketId: 0, // core command, marketId is not necessary
            exchangeId: 0 // core command, does not involve exchange,
         });
        bytes memory extraData = abi.encode("unstakeStakedReya", unstakeAmount);
        EIP712Signature memory sig = getEIP712SignatureForPeripheryCommands(
            account,
            commands,
            userPk,
            2, // nonce (staking before)
            extraData
        );

        IPeripheryProxy(sec.periphery).unstakeStakedReya(
            UnstakeStakedReyaInputs({
                accountId: account,
                shareAmount: unstakeAmount,
                minAssetAmount: unstakeAmount,
                withdrawSig: sig
            })
        );

        assertEq(getNetDeposits(account, reyaToken), int256(2e18 + unstakeAmount));
        assertEq(getNetDeposits(account, stakedReya), int256(8e18 - unstakeAmount));
    }

    function check_ReyaFailsToUnstakeWhenMinAssetAmountIsTooHigh() public {
        uint128 account = check_ReyaStaking();
        uint256 unstakeAmount = 4e18;

        address stakedReya = IPeripheryProxy(sec.periphery).getGlobalConfiguration().sREYAProxy;

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: 1,
            inputs: abi.encode(stakedReya, unstakeAmount),
            marketId: 0, // core command, marketId is not necessary
            exchangeId: 0 // core command, does not involve exchange,
         });
        bytes memory extraData = abi.encode("unstakeStakedReya", unstakeAmount * 2);
        EIP712Signature memory sig = getEIP712SignatureForPeripheryCommands(
            account,
            commands,
            userPk,
            2, // nonce (staking before)
            extraData
        );

        vm.expectRevert(
            abi.encodeWithSelector(IPeripheryProxy.UnacceptableAssetAmount.selector, unstakeAmount, unstakeAmount * 2)
        );
        IPeripheryProxy(sec.periphery).unstakeStakedReya(
            UnstakeStakedReyaInputs({
                accountId: account,
                shareAmount: unstakeAmount,
                minAssetAmount: unstakeAmount * 2,
                withdrawSig: sig
            })
        );
    }

    function check_ReyaFailsToStakeWhenMinShareAmountIsTooHigh() public {
        uint256 stakeAmount = 8e18;
        address reyaToken = IPeripheryProxy(sec.periphery).getGlobalConfiguration().REYAProxy;

        uint128 account = check_ReyaBridgeIntoSpotMA();

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: 1,
            inputs: abi.encode(reyaToken, stakeAmount),
            marketId: 0, // core command, marketId is not necessary
            exchangeId: 0 // core command, does not involve exchange,
         });
        bytes memory extraData = abi.encode("stakeReya", stakeAmount + 1);
        EIP712Signature memory sig = getEIP712SignatureForPeripheryCommands(account, commands, userPk, 1, extraData);

        vm.expectRevert(
            abi.encodeWithSelector(IPeripheryProxy.UnacceptableShareAmount.selector, stakeAmount, stakeAmount + 1)
        );
        IPeripheryProxy(sec.periphery).stakeReya(
            StakeReyaInputs({
                accountId: account,
                assetAmount: stakeAmount,
                minShareAmount: stakeAmount + 1,
                withdrawSig: sig
            })
        );
    }

    function check_ReyaWithdrawLimitInWindowSizes() public {
        address reyaToken = IPeripheryProxy(sec.periphery).getGlobalConfiguration().REYAProxy;

        (GlobalCollateralConfig memory globalCollateralConfig,) =
            ICoreProxy(sec.core).getGlobalCollateralConfig(reyaToken);

        if (globalCollateralConfig.withdrawalTvlPercentageLimit == 1e18) {
            return; // no limit
        }

        vm.expectRevert(abi.encodeWithSelector(ICoreProxy.GlobalWithdrawLimitReached.selector, reyaToken));
        executePeripheryWithdrawMA(user, userPk, 1, 0, reyaToken, 8_000_000_001e18, sec.destinationChainId);
    }

    function check_StakedReyaWithdrawLimitInWindowSizes() public {
        (user, userPk) = makeAddrAndKey("user");
        address stakedReya = IPeripheryProxy(sec.periphery).getGlobalConfiguration().sREYAProxy;

        (GlobalCollateralConfig memory globalCollateralConfig,) =
            ICoreProxy(sec.core).getGlobalCollateralConfig(stakedReya);

        if (globalCollateralConfig.withdrawalTvlPercentageLimit == 1e18) {
            return;
        }

        vm.expectRevert(abi.encodeWithSelector(ICoreProxy.GlobalWithdrawLimitReached.selector, stakedReya));
        executePeripheryWithdrawMA(user, userPk, 1, 0, stakedReya, 8_000_000_001e18, sec.destinationChainId);
    }

    function check_ReyaBridgingPermissions() public {
        address reyaToken = IPeripheryProxy(sec.periphery).getGlobalConfiguration().REYAProxy;

        // try pausing and call lzCompose (expect failure)
        {
            vm.prank(sec.multisig);
            IPeripheryProxy(sec.periphery).setFeatureFlagDenyAll(keccak256(bytes("global")), true);

            vm.expectRevert(
                abi.encodeWithSelector(IPeripheryProxy.FeatureUnavailable.selector, keccak256(bytes("global")))
            );
            IPeripheryProxy(sec.periphery).lzCompose(
                reyaToken, // The OFT token address
                0, // Message GUID
                bytes(""), // The composed message
                address(0), // Executor address
                bytes("") // Extra data
            );

            vm.prank(sec.multisig);
            IPeripheryProxy(sec.periphery).setFeatureFlagDenyAll(keccak256(bytes("global")), false);
        }

        // try wrong oapp and call lzCompose (expect failure)
        {
            vm.expectRevert(
                abi.encodeWithSelector(IPeripheryProxy.CallerIsNotLayerZeroEndpoint.selector, address(6333))
            );
            vm.prank(address(6333));
            IPeripheryProxy(sec.periphery).lzCompose(
                reyaToken, // The OFT token address
                0, // Message GUID
                bytes(""), // The composed message
                address(0), // Executor address
                bytes("") // Extra data
            );
        }

        // try calling from unauthorized oapp
        {
            vm.prank(IPeripheryProxy(sec.periphery).getGlobalConfiguration().layerZeroEndpoint);
            vm.expectRevert(abi.encodeWithSelector(IPeripheryProxy.UnauthorizedOft.selector, address(1_245_363)));
            IPeripheryProxy(sec.periphery).lzCompose(
                address(1_245_363), // The OFT token address
                0, // Message GUID
                bytes(""), // The composed message
                address(0), // Executor address
                bytes("") // Extra data
            );
        }

        // try pausing and withdraw (expect failure)
        {
            vm.prank(sec.multisig);
            IPeripheryProxy(sec.periphery).setFeatureFlagAllowAll(keccak256(bytes("global")), false);

            vm.expectRevert(
                abi.encodeWithSelector(IPeripheryProxy.FeatureUnavailable.selector, keccak256(bytes("global")))
            );
            IPeripheryProxy(sec.periphery).withdrawMALZ(
                WithdrawMALZInputs({
                    accountId: 1,
                    token: reyaToken,
                    tokenAmount: 1000,
                    sig: EIP712Signature({ v: 0, r: bytes32(0), s: bytes32(0), deadline: 0 }),
                    dstEid: 1,
                    receiver: address(123_456_789)
                })
            );

            vm.prank(sec.multisig);
            IPeripheryProxy(sec.periphery).setFeatureFlagDenyAll(keccak256(bytes("global")), false);
        }
    }

    function check_ReyaStakingPermissions() public {
        (user, userPk) = makeAddrAndKey("user");
        uint256 stakeAmount = 8e18;
        address reyaToken = IPeripheryProxy(sec.periphery).getGlobalConfiguration().REYAProxy;
        address stakedReya = IPeripheryProxy(sec.periphery).getGlobalConfiguration().sREYAProxy;

        // try pausing and call stake (expect failure)
        {
            vm.prank(sec.multisig);
            IPeripheryProxy(sec.periphery).setFeatureFlagAllowAll(keccak256(bytes("global")), false);

            Command_Periphery[] memory commands = new Command_Periphery[](1);
            commands[0] = Command_Periphery({
                commandType: 1,
                inputs: abi.encode(reyaToken, stakeAmount),
                marketId: 0,
                exchangeId: 0
            });
            bytes memory extraData = abi.encode("stakeReya", stakeAmount);
            EIP712Signature memory sig = getEIP712SignatureForPeripheryCommands(1, commands, userPk, 1, extraData);

            vm.expectRevert(
                abi.encodeWithSelector(IPeripheryProxy.FeatureUnavailable.selector, keccak256(bytes("global")))
            );
            IPeripheryProxy(sec.periphery).stakeReya(
                StakeReyaInputs({ accountId: 1, assetAmount: stakeAmount, minShareAmount: stakeAmount, withdrawSig: sig })
            );

            vm.prank(sec.multisig);
            IPeripheryProxy(sec.periphery).setFeatureFlagDenyAll(keccak256(bytes("global")), false);
        }

        // try pausing and call unstake (expect failure)
        {
            vm.prank(sec.multisig);
            IPeripheryProxy(sec.periphery).setFeatureFlagDenyAll(keccak256(bytes("global")), true);

            Command_Periphery[] memory commands = new Command_Periphery[](1);
            commands[0] = Command_Periphery({
                commandType: 1,
                inputs: abi.encode(reyaToken, stakeAmount),
                marketId: 0,
                exchangeId: 0
            });
            bytes memory extraData = abi.encode("stakeReya", stakeAmount);
            EIP712Signature memory sig = getEIP712SignatureForPeripheryCommands(1, commands, userPk, 1, extraData);

            vm.expectRevert(
                abi.encodeWithSelector(IPeripheryProxy.FeatureUnavailable.selector, keccak256(bytes("global")))
            );
            IPeripheryProxy(sec.periphery).unstakeStakedReya(
                UnstakeStakedReyaInputs({
                    accountId: 1,
                    shareAmount: stakeAmount,
                    minAssetAmount: stakeAmount,
                    withdrawSig: sig
                })
            );

            vm.prank(sec.multisig);
            IPeripheryProxy(sec.periphery).setFeatureFlagDenyAll(keccak256(bytes("global")), false);
        }

        // pause the REYA contract and call stake (expect failure)
        {
            vm.prank(sec.multisig);
            IReyaToken(reyaToken).pause();

            Command_Periphery[] memory commands = new Command_Periphery[](1);
            commands[0] = Command_Periphery({
                commandType: 1,
                inputs: abi.encode(reyaToken, stakeAmount),
                marketId: 0,
                exchangeId: 0
            });
            bytes memory extraData = abi.encode("stakeReya", stakeAmount);
            EIP712Signature memory sig = getEIP712SignatureForPeripheryCommands(1, commands, userPk, 1, extraData);

            vm.expectRevert(
                abi.encodeWithSelector(IPeripheryProxy.FeatureUnavailable.selector, keccak256(bytes("global")))
            );
            IPeripheryProxy(sec.periphery).stakeReya(
                StakeReyaInputs({ accountId: 1, assetAmount: stakeAmount, minShareAmount: stakeAmount, withdrawSig: sig })
            );

            vm.prank(sec.multisig);
            IReyaToken(reyaToken).unpause();
        }

        // pause the sREYA contract and call unstake (expect failure)
        {
            vm.prank(sec.multisig);
            IStakedReyaToken(stakedReya).pause();

            Command_Periphery[] memory commands = new Command_Periphery[](1);
            commands[0] = Command_Periphery({
                commandType: 1,
                inputs: abi.encode(reyaToken, stakeAmount),
                marketId: 0,
                exchangeId: 0
            });
            bytes memory extraData = abi.encode("stakeReya", stakeAmount);
            EIP712Signature memory sig = getEIP712SignatureForPeripheryCommands(1, commands, userPk, 1, extraData);

            vm.expectRevert(
                abi.encodeWithSelector(IPeripheryProxy.FeatureUnavailable.selector, keccak256(bytes("global")))
            );
            IPeripheryProxy(sec.periphery).unstakeStakedReya(
                UnstakeStakedReyaInputs({
                    accountId: 1,
                    shareAmount: stakeAmount,
                    minAssetAmount: stakeAmount,
                    withdrawSig: sig
                })
            );

            vm.prank(IStakedReyaToken(stakedReya).owner());
            IStakedReyaToken(stakedReya).unpause();
        }
    }
}
