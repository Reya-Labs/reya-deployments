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
    SendParam,
    MessagingFee,
    MessagingReceipt,
    OFTReceipt,
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

        vm.prank(IReyaToken(sec.reya).owner());
        IReyaToken(sec.reya).mint(sec.periphery, amount);

        bytes memory composeMsg = abi.encode(LzComposerOperationType.DEPOSIT_SPOT_ACCOUNT, abi.encode(user));
        bytes memory message = abi.encodePacked(
            uint64(1), // nonce
            uint32(101), // dstEid
            amount, // amount
            bytes32(uint256(uint160(address(sec.periphery)))), // receiver
            composeMsg
        );
        vm.prank(sec.layerZeroEndpoint);
        IPeripheryProxy(sec.periphery).lzCompose(
            sec.reya, // The OFT token address
            0, // Message GUID
            message, // The composed message
            address(0), // Executor address
            bytes("") // Extra data
        );

        accountId = ICoreProxy(sec.core).createOrGetSpotAccount(user);
        assertEq(IReyaToken(sec.reya).balanceOf(sec.periphery), 0);
        assertEq(getNetDeposits(accountId, sec.reya), int256(amount));
    }

    function check_ReyaBridgeIntoNormalMAFails() public {
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 10e6;

        vm.prank(IReyaToken(sec.reya).owner());
        IReyaToken(sec.reya).mint(sec.periphery, amount);

        // account id 8 has traded on both networks
        bytes memory composeMsg = abi.encode(LzComposerOperationType.DEPOSIT_ACCOUNT, abi.encode(8));
        bytes memory message = abi.encodePacked(
            uint64(1), // nonce
            uint32(101), // dstEid
            amount, // amount
            bytes32(uint256(uint160(address(sec.periphery)))), // receiver
            composeMsg
        );

        vm.prank(sec.layerZeroEndpoint);

        vm.expectRevert(abi.encodeWithSignature("CollateralNotConfigured(uint128,address)", uint128(1), sec.reya));
        IPeripheryProxy(sec.periphery).lzCompose(
            sec.reya, // The OFT token address
            0, // Message GUID
            message, // The composed message
            address(0), // Executor address
            bytes("") // Extra data
        );
    }

    function check_ReyaStaking() public returns (uint128 account) {
        (user, userPk) = makeAddrAndKey("user");
        uint256 stakeAmount = 8e18;

        account = check_ReyaBridgeIntoSpotMA();

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: 1,
            inputs: abi.encode(sec.reya, stakeAmount),
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

        assertEq(getNetDeposits(account, sec.reya), int256(2e18));
        assertEq(getNetDeposits(account, sec.sreya), int256(stakeAmount));
    }

    function check_ReyaUnstaking() public {
        uint128 account = check_ReyaStaking();
        uint256 unstakeAmount = 4e18;

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: 1,
            inputs: abi.encode(sec.sreya, unstakeAmount),
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

        assertEq(getNetDeposits(account, sec.reya), int256(2e18 + unstakeAmount));
        assertEq(getNetDeposits(account, sec.sreya), int256(8e18 - unstakeAmount));
    }

    function check_ReyaFailsToUnstakeWhenMinAssetAmountIsTooHigh() public {
        uint128 account = check_ReyaStaking();
        uint256 unstakeAmount = 4e18;

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: 1,
            inputs: abi.encode(sec.sreya, unstakeAmount),
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

        uint128 account = check_ReyaBridgeIntoSpotMA();

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: 1,
            inputs: abi.encode(sec.reya, stakeAmount),
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

    function check_ReyaBridgingPermissions() public {
        // try pausing and call lzCompose (expect failure)
        {
            vm.prank(sec.multisig);
            IPeripheryProxy(sec.periphery).setFeatureFlagDenyAll(keccak256(bytes("global")), true);

            vm.expectRevert(
                abi.encodeWithSelector(IPeripheryProxy.FeatureUnavailable.selector, keccak256(bytes("global")))
            );
            IPeripheryProxy(sec.periphery).lzCompose(
                sec.reya, // The OFT token address
                0, // Message GUID
                bytes(""), // The composed message
                address(0), // Executor address
                bytes("") // Extra data
            );

            vm.prank(sec.multisig);
            IPeripheryProxy(sec.periphery).setFeatureFlagDenyAll(keccak256(bytes("global")), false);
        }

        // use wrong endpoint and call lzCompose (expect failure)
        {
            vm.expectRevert(
                abi.encodeWithSelector(IPeripheryProxy.CallerIsNotLayerZeroEndpoint.selector, address(6333))
            );
            vm.prank(address(6333));
            IPeripheryProxy(sec.periphery).lzCompose(
                sec.reya, // The OFT token address
                0, // Message GUID
                bytes(""), // The composed message
                address(0), // Executor address
                bytes("") // Extra data
            );
        }

        // try calling from unauthorized oapp
        {
            vm.prank(sec.layerZeroEndpoint);
            vm.expectRevert(abi.encodeWithSelector(IPeripheryProxy.UnauthorizedOFT.selector, address(1_245_363)));
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
                    token: sec.reya,
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

        // try pausing and call stake (expect failure)
        {
            vm.prank(sec.multisig);
            IPeripheryProxy(sec.periphery).setFeatureFlagAllowAll(keccak256(bytes("global")), false);

            Command_Periphery[] memory commands = new Command_Periphery[](1);
            commands[0] = Command_Periphery({
                commandType: 1,
                inputs: abi.encode(sec.reya, stakeAmount),
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
                inputs: abi.encode(sec.reya, stakeAmount),
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
            vm.prank(IReyaToken(sec.reya).owner());
            IReyaToken(sec.reya).pause();

            Command_Periphery[] memory commands = new Command_Periphery[](1);
            commands[0] = Command_Periphery({
                commandType: 1,
                inputs: abi.encode(sec.reya, stakeAmount),
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

            vm.prank(IReyaToken(sec.reya).owner());
            IReyaToken(sec.reya).unpause();
        }

        // pause the sREYA contract and call unstake (expect failure)
        {
            vm.prank(IStakedReyaToken(sec.sreya).owner());
            IStakedReyaToken(sec.sreya).pause();

            Command_Periphery[] memory commands = new Command_Periphery[](1);
            commands[0] = Command_Periphery({
                commandType: 1,
                inputs: abi.encode(sec.reya, stakeAmount),
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

            vm.prank(IStakedReyaToken(sec.sreya).owner());
            IStakedReyaToken(sec.sreya).unpause();
        }
    }

    function check_ReyaWithdrawMALZ() public {
        uint128 accountId = check_ReyaBridgeIntoSpotMA();
        uint256 withdrawAmount = 5e18;
        uint32 dstEid = sec.lzDstEid;
        address receiver = user;

        // set a static fee for the destination
        uint256 staticFee = 0.01e18;
        vm.prank(sec.multisig);
        IPeripheryProxy(sec.periphery).setTokenStaticWithdrawFee(sec.reya, address(uint160(dstEid)), staticFee);

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: 1,
            inputs: abi.encode(sec.reya, withdrawAmount),
            marketId: 0,
            exchangeId: 0
        });
        bytes memory extraData = abi.encode("withdrawMALZ", receiver, dstEid);
        EIP712Signature memory sig = getEIP712SignatureForPeripheryCommands(accountId, commands, userPk, 1, extraData);

        IPeripheryProxy(sec.periphery).withdrawMALZ(
            WithdrawMALZInputs({
                accountId: accountId,
                token: sec.reya,
                tokenAmount: withdrawAmount,
                sig: sig,
                dstEid: dstEid,
                receiver: receiver
            })
        );

        assertEq(getNetDeposits(accountId, sec.reya), int256(10e18 - withdrawAmount));
    }

    function check_ReyaWithdrawMALZAboveSharedDecimals() public {
        uint128 accountId = check_ReyaBridgeIntoSpotMA();
        uint256 withdrawAmount = 5.432198e18;
        uint32 dstEid = sec.lzDstEid;
        address receiver = user;

        // set a static fee for the destination
        uint256 staticFee = 0.01e18;
        vm.prank(sec.multisig);
        IPeripheryProxy(sec.periphery).setTokenStaticWithdrawFee(sec.reya, address(uint160(dstEid)), staticFee);

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: 1,
            inputs: abi.encode(sec.reya, withdrawAmount),
            marketId: 0,
            exchangeId: 0
        });
        bytes memory extraData = abi.encode("withdrawMALZ", receiver, dstEid);
        EIP712Signature memory sig = getEIP712SignatureForPeripheryCommands(accountId, commands, userPk, 1, extraData);

        uint256 initPeripheryBalance = IReyaToken(sec.reya).balanceOf(sec.periphery);

        IPeripheryProxy(sec.periphery).withdrawMALZ(
            WithdrawMALZInputs({
                accountId: accountId,
                token: sec.reya,
                tokenAmount: withdrawAmount,
                sig: sig,
                dstEid: dstEid,
                receiver: receiver
            })
        );

        assertEq(getNetDeposits(accountId, sec.reya), int256(10e18 - withdrawAmount));
        assertEq(
            IReyaToken(sec.reya).balanceOf(sec.periphery),
            initPeripheryBalance + withdrawAmount - (withdrawAmount / 1e12) * 1e12
        );
    }

    function check_ReyaWithdrawMALZFailsBelowSharedDecimals() public {
        uint128 accountId = check_ReyaBridgeIntoSpotMA();
        uint256 withdrawAmount = 5.4321981e18;
        uint32 dstEid = sec.lzDstEid;
        address receiver = user;

        // set a static fee for the destination
        uint256 staticFee = 0.01e18;
        vm.prank(sec.multisig);
        IPeripheryProxy(sec.periphery).setTokenStaticWithdrawFee(sec.reya, address(uint160(dstEid)), staticFee);

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: 1,
            inputs: abi.encode(sec.reya, withdrawAmount),
            marketId: 0,
            exchangeId: 0
        });
        bytes memory extraData = abi.encode("withdrawMALZ", receiver, dstEid);
        EIP712Signature memory sig = getEIP712SignatureForPeripheryCommands(accountId, commands, userPk, 1, extraData);

        uint256 amountAfterFee = withdrawAmount - staticFee;
        vm.expectRevert(
            abi.encodeWithSignature("SlippageExceeded(uint256,uint256)", amountAfterFee / 1e12 * 1e12, amountAfterFee)
        );
        IPeripheryProxy(sec.periphery).withdrawMALZ(
            WithdrawMALZInputs({
                accountId: accountId,
                token: sec.reya,
                tokenAmount: withdrawAmount,
                sig: sig,
                dstEid: dstEid,
                receiver: receiver
            })
        );
    }

    function check_ReyaWithdrawMALZFailsWhenNotEnoughFees() public {
        uint128 accountId = check_ReyaBridgeIntoSpotMA();
        uint32 dstEid = sec.lzDstEid;
        address receiver = user;

        // set a static fee higher than the withdraw amount
        uint256 staticFee = 2e18;
        vm.prank(sec.multisig);
        IPeripheryProxy(sec.periphery).setTokenStaticWithdrawFee(sec.reya, address(uint160(dstEid)), staticFee);

        uint256 withdrawAmount = 1e18;

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: 1,
            inputs: abi.encode(sec.reya, withdrawAmount),
            marketId: 0,
            exchangeId: 0
        });
        bytes memory extraData = abi.encode("withdrawMALZ", receiver, dstEid);
        EIP712Signature memory sig = getEIP712SignatureForPeripheryCommands(accountId, commands, userPk, 1, extraData);

        vm.expectRevert(abi.encodeWithSelector(IPeripheryProxy.NotEnoughFees.selector, withdrawAmount, staticFee));
        IPeripheryProxy(sec.periphery).withdrawMALZ(
            WithdrawMALZInputs({
                accountId: accountId,
                token: sec.reya,
                tokenAmount: withdrawAmount,
                sig: sig,
                dstEid: dstEid,
                receiver: receiver
            })
        );
    }

    function check_ReyaWithdrawMALZFailsForUnauthorizedOFT() public {
        (user, userPk) = makeAddrAndKey("user");

        vm.expectRevert(abi.encodeWithSelector(IPeripheryProxy.UnauthorizedOFT.selector, sec.usdc));
        IPeripheryProxy(sec.periphery).withdrawMALZ(
            WithdrawMALZInputs({
                accountId: 1,
                token: sec.usdc,
                tokenAmount: 1000,
                sig: EIP712Signature({ v: 0, r: bytes32(0), s: bytes32(0), deadline: 0 }),
                dstEid: 1,
                receiver: address(123_456_789)
            })
        );
    }

    function check_ReyaWithdrawMALZFailsWhenPaused() public {
        (user, userPk) = makeAddrAndKey("user");

        vm.prank(sec.multisig);
        IPeripheryProxy(sec.periphery).setFeatureFlagDenyAll(keccak256(bytes("global")), true);

        vm.expectRevert(abi.encodeWithSelector(IPeripheryProxy.FeatureUnavailable.selector, keccak256(bytes("global"))));
        IPeripheryProxy(sec.periphery).withdrawMALZ(
            WithdrawMALZInputs({
                accountId: 1,
                token: sec.reya,
                tokenAmount: 1000,
                sig: EIP712Signature({ v: 0, r: bytes32(0), s: bytes32(0), deadline: 0 }),
                dstEid: 1,
                receiver: address(123_456_789)
            })
        );

        vm.prank(sec.multisig);
        IPeripheryProxy(sec.periphery).setFeatureFlagDenyAll(keccak256(bytes("global")), false);
    }

    // ==================== REYA / sREYA View Functions ====================

    function check_ReyaViewFunctions() public {
        (address viewUser,) = makeAddrAndKey("viewUser");
        uint256 amount = 100e18;

        // create spot account and deposit REYA
        uint128 spotAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(viewUser);
        deal(sec.reya, viewUser, amount);
        vm.startPrank(viewUser);
        ITokenProxy(sec.reya).approve(sec.core, amount);
        ICoreProxy(sec.core).deposit(spotAccountId, sec.reya, amount);
        vm.stopPrank();

        // verify collateral info
        CollateralInfo memory reyaInfo = ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.reya);
        assertEq(reyaInfo.netDeposits, int256(amount), "REYA netDeposits mismatch");
        assertEq(reyaInfo.marginBalance, int256(amount), "REYA marginBalance mismatch");
        assertEq(reyaInfo.realBalance, int256(amount), "REYA realBalance mismatch");
    }

    function check_SreyaViewFunctions() public {
        (address viewUser,) = makeAddrAndKey("viewUser");
        uint256 amount = 100e18;

        // create spot account and deposit sREYA
        uint128 spotAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(viewUser);
        deal(sec.sreya, viewUser, amount);
        vm.startPrank(viewUser);
        ITokenProxy(sec.sreya).approve(sec.core, amount);
        ICoreProxy(sec.core).deposit(spotAccountId, sec.sreya, amount);
        vm.stopPrank();

        // verify collateral info
        CollateralInfo memory sreyaInfo = ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.sreya);
        assertEq(sreyaInfo.netDeposits, int256(amount), "sREYA netDeposits mismatch");
        assertEq(sreyaInfo.marginBalance, int256(amount), "sREYA marginBalance mismatch");
        assertEq(sreyaInfo.realBalance, int256(amount), "sREYA realBalance mismatch");
    }
}
