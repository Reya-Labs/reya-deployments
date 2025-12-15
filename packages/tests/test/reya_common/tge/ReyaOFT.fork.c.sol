// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { IReyaOFT } from "../../../src/interfaces/IReyaOFT.sol";
import { ILayerZeroEndpointV2 } from "../../../src/interfaces/ILayerZeroEndpointV2.sol";
import { Test } from "forge-std/Test.sol";
contract BaseReyaOFTForkCheck is Test {

    address internal reya;
    address internal foundationMultisig;

    function _initOFTCheck(address _reya, address _foundationMultisig) internal {
        reya = _reya;
        foundationMultisig = _foundationMultisig;
    }
    
    /// @notice Encode LayerZero options for gas settings
    /// @param gasLimit Gas limit for execution on destination chain
    /// @return Encoded options bytes
    function encodeOptions(uint128 gasLimit) private pure returns (bytes memory) {
        // Options format: TYPE(2) + OPTION_TYPE(1) + LENGTH(1) + EXECUTION_TYPE(1) + GAS(16)
        // Original working: 0x0003 01 00 11 01 0000000000000000000000000000c350
        // Breaking it down:
        // 0x0003 = uint16(3) - options type v3
        // 0x01 = uint8(1) - option type (TYPE_3)
        // 0x00 = uint8(0) - reserved/padding
        // 0x11 = uint8(17) - length (17 bytes)
        // 0x01 = uint8(1) - execution type (lzReceive)
        // 0x0000...c350 = uint128(50000) - gas limit
        
        return abi.encodePacked(
            uint16(3),        // 0x0003 - options type v3
            uint8(1),         // 0x01 - option type
            uint8(0),         // 0x00 - padding
            uint8(17),        // 0x11 - length (17 bytes)
            uint8(1),         // 0x01 - execution type
            uint128(gasLimit) // gas limit as uint128 (16 bytes)
        );
    }
    
    /// @notice Test that all pausers can pause the contract
    function check_ReyaOFT_Permissions(
        address[] memory permissioned
    ) internal {
        IReyaOFT token = IReyaOFT(reya);
        for (uint256 i = 0; i < permissioned.length; i++) {
            // Unpause first if needed
            vm.prank(foundationMultisig);
            token.unpause();

            assertTrue(token.isFeatureAllowed(keccak256(bytes("global")), address(0)), "Token should be unpaused");

            // Each pauser should be able to pause
            vm.prank(permissioned[i]);
            token.pause();
            assertFalse(token.isFeatureAllowed(keccak256(bytes("global")), address(0)), "Token should be paused");

            address userToBlacklist = makeAddr("userToBlacklist");
        
            // Each pauser should be able to blacklist
            vm.prank(permissioned[i]);
            token.addToBlacklist(userToBlacklist);
            assertTrue(token.isBlacklisted(userToBlacklist), "User should be blacklisted");

            // Each pauser should be able to unblacklist
            vm.prank(permissioned[i]);
            token.removeFromBlacklist(userToBlacklist);
            assertFalse(token.isBlacklisted(userToBlacklist), "User should not be blacklisted");
        }

        // Non-foundationMultisig should not be able to unpause
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert();
        token.unpause();

        // non-admin cannot blacklist
        address userToBlacklist2 = makeAddr("userToBlacklist2");
        
        vm.prank(attacker);
        vm.expectRevert();
        token.addToBlacklist(userToBlacklist2);
    }
    
    /// @notice Test that blacklisted users cannot transfer
    function check_ReyaOFT_BlacklistedCannotTransfer(
        address blacklistAdmin
    ) internal {
        IReyaOFT token = IReyaOFT(reya);
        address user = makeAddr("user");
        address recipient = makeAddr("recipient");
        uint256 amount = 1000e18;

        // Give user some tokens
        deal(reya, user, amount);

        // Blacklist the user
        vm.prank(blacklistAdmin);
        token.addToBlacklist(user);

        // User should not be able to transfer
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IReyaOFT.AddressBlacklisted.selector, user));
        token.transfer(recipient, amount);
    }

    /// @notice Test that foundationMultisig can mint tokens
    function check_ReyaOFT_OwnerCanMint() internal {
        IReyaOFT token = IReyaOFT(reya);

        address recipient = makeAddr("recipient");
        uint256 amount = 1000e18;
        uint256 balanceBefore = token.balanceOf(recipient);

        vm.prank(foundationMultisig);
        token.mint(recipient, amount);

        uint256 balanceAfter = token.balanceOf(recipient);
        assertEq(balanceAfter - balanceBefore, amount, "Mint amount should match");
    }

    /// @notice Test that non-foundationMultisig cannot mint
    function checkFuzz_ReyaOFT_NonOwnerCannotMint(address attacker) internal {
        IReyaOFT token = IReyaOFT(reya);
        address recipient = makeAddr("recipient");
        uint256 amount = 1000e18;

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(IReyaOFT.OwnableUnauthorizedAccount.selector, attacker));
        token.mint(recipient, amount);
    }

    /// @notice Test transfers work when not paused and not blacklisted
    function check_ReyaOFT_NormalTransfer() internal {
        IReyaOFT token = IReyaOFT(reya);

        address sender = makeAddr("sender");
        address recipient = makeAddr("recipient");
        uint256 amount = 1000e18;

        // Ensure not paused
        vm.prank(foundationMultisig);
        token.unpause();

        // Give sender some tokens
        deal(reya, sender, amount);

        uint256 recipientBalanceBefore = token.balanceOf(recipient);

        vm.prank(sender);
        token.transfer(recipient, amount);

        uint256 recipientBalanceAfter = token.balanceOf(recipient);
        assertEq(recipientBalanceAfter - recipientBalanceBefore, amount, "Transfer amount should match");

        // Fails when paused
        vm.prank(foundationMultisig);
        token.pause();
        vm.prank(sender);
        vm.expectRevert(abi.encodeWithSelector(IReyaOFT.FeatureUnavailable.selector, keccak256(bytes("global"))));
        token.transfer(recipient, amount);
    }

    /// @notice Test that the LayerZero endpoint is set correctly
    function check_ReyaOFT_EndpointIsSet(address expectedEndpoint) internal view {
        IReyaOFT token = IReyaOFT(reya);
        address endpoint = token.endpoint();
        
        assertEq(endpoint, expectedEndpoint, "Endpoint should match expected address");
        assertTrue(endpoint != address(0), "Endpoint should not be zero address");
    }

    /// @notice Test that the endpoint has delegated to the foundationMultisig
    function check_ReyaOFT_EndpointDelegatedToOwner() internal view {
        IReyaOFT token = IReyaOFT(reya);
        address endpoint = token.endpoint();
        
        address delegate = ILayerZeroEndpointV2(endpoint).delegates(reya);
        assertEq(delegate, foundationMultisig, "Endpoint should delegate to owner");
        assertEq(token.owner(), foundationMultisig, "Token owner should match");
    }

    /// @notice Test that peers are configured correctly (Reya Cronos: 30131, Reya Mainnet: 30101)
    function check_ReyaOFT_PeersConfigured(uint32 eid) internal view {
        IReyaOFT token = IReyaOFT(reya);

        bytes32 peerCronos = token.peers(eid);
        assertTrue(peerCronos != bytes32(0), "Reya Cronos peer should be configured");
    }

    /// @notice Test that send() works and returns correct amounts (handles dust removal)
    function check_ReyaOFT_SendWorks(
        uint32 dstEid
    ) internal {
        IReyaOFT token = IReyaOFT(reya);
        
        uint256 amountToSend = 1000e18;
        
        // Give sender tokens
        address sender = makeAddr("sender");
        deal(reya, sender, amountToSend);

        uint128 gasLimit = 2_000_000; // Gas limit for destination chain execution
        bytes memory extraOptions = encodeOptions(gasLimit);
        
        // Prepare send parameters
        IReyaOFT.SendParam memory sendParam = IReyaOFT.SendParam({
            dstEid: dstEid,
            to: bytes32(uint256(uint160(sender))),
            amountLD: amountToSend,
            minAmountLD: amountToSend,
            extraOptions: extraOptions,
            composeMsg: "",
            oftCmd: ""
        });
        
        // Quote the send to get fee
        IReyaOFT.MessagingFee memory fee = token.quoteSend(sendParam, false);
        
        // Quote OFT to check amounts
        (
            IReyaOFT.OFTLimit memory limit,
            ,
            IReyaOFT.OFTReceipt memory receipt
        ) = token.quoteOFT(sendParam);
        
        // Verify limits are reasonable
        assertGe(limit.maxAmountLD, amountToSend, "Max limit should be >= amount to send");
        
        // Verify receipt shows correct amounts (may differ due to dust removal)
        assertLe(receipt.amountSentLD, amountToSend, "Amount sent should be <= requested amount");
        assertGt(receipt.amountSentLD, 0, "Amount sent should be > 0");
        
        // The received amount should match sent amount (1:1 for standard OFT)
        assertEq(receipt.amountReceivedLD, receipt.amountSentLD, "Received should match sent for standard OFT");
        
        uint256 senderBalanceBefore = token.balanceOf(sender);

        vm.deal(sender, fee.nativeFee);
        
        // Execute send
        vm.prank(sender);
        (IReyaOFT.MessagingReceipt memory msgReceipt, IReyaOFT.OFTReceipt memory actualReceipt) = 
            token.send{value: fee.nativeFee}(sendParam, fee, sender);
        
        uint256 senderBalanceAfter = token.balanceOf(sender);
        
        // Verify tokens were debited
        assertEq(
            senderBalanceBefore - senderBalanceAfter,
            actualReceipt.amountSentLD,
            "Sender balance should decrease by amount sent"
        );
        
        // Verify receipt is valid
        assertTrue(msgReceipt.guid != bytes32(0), "Message GUID should be set");
        assertTrue(msgReceipt.nonce > 0, "Nonce should be > 0");
    }

    /// @notice Test that send() respects blacklist
    function check_ReyaOFT_SendRespectsBlacklist(
        uint32 dstEid
    ) internal {
        IReyaOFT token = IReyaOFT(reya);
        address sender = makeAddr("sender");
        uint256 amountToSend = 1000e18;
        
        // Give sender tokens
        deal(reya, sender, amountToSend);
        
        // Blacklist sender
        vm.prank(foundationMultisig);
        token.addToBlacklist(sender);

        uint128 gasLimit = 2_000_000; // Gas limit for destination chain execution
        bytes memory extraOptions = encodeOptions(gasLimit);
        
        // Prepare send parameters
        IReyaOFT.SendParam memory sendParam = IReyaOFT.SendParam({
            dstEid: dstEid,
            to: bytes32(uint256(uint160(sender))),
            amountLD: amountToSend,
            minAmountLD: amountToSend,
            extraOptions: extraOptions,
            composeMsg: "",
            oftCmd: ""
        });
        
        // Quote to get fee
        IReyaOFT.MessagingFee memory fee = token.quoteSend(sendParam, false);

        vm.deal(sender, fee.nativeFee);
        
        // Send should fail for blacklisted address
        vm.prank(sender);
        vm.expectRevert(abi.encodeWithSelector(IReyaOFT.AddressBlacklisted.selector, sender));
        token.send{value: fee.nativeFee}(sendParam, fee, sender);
    }

    /// @notice Test that send() respects pause
    function check_ReyaOFT_SendRespectsPause(
        uint32 dstEid
    ) internal {
        IReyaOFT token = IReyaOFT(reya);
        address sender = makeAddr("sender");
        uint256 amountToSend = 1000e18;
        
        // Give sender tokens
        deal(reya, sender, amountToSend);
        
        // Pause the token
        vm.prank(foundationMultisig);
        token.pause();

        uint128 gasLimit = 2_000_000; // Gas limit for destination chain execution
        bytes memory extraOptions = encodeOptions(gasLimit);
        
        // Prepare send parameters
        IReyaOFT.SendParam memory sendParam = IReyaOFT.SendParam({
            dstEid: dstEid,
            to: bytes32(uint256(uint160(sender))),
            amountLD: amountToSend,
            minAmountLD: amountToSend,
            extraOptions: extraOptions,
            composeMsg: "",
            oftCmd: ""
        });
        
        // Quote to get fee
        IReyaOFT.MessagingFee memory fee = token.quoteSend(sendParam, false);

        vm.deal(sender, fee.nativeFee);
        
        // Send should fail when paused
        vm.prank(sender);
        vm.expectRevert(abi.encodeWithSelector(IReyaOFT.FeatureUnavailable.selector, keccak256(bytes("global"))));
        token.send{value: fee.nativeFee}(sendParam, fee, sender);
    }

    /// @notice Test that only the endpoint can call lzReceive
    function check_ReyaOFT_OnlyEndpointCanCallLzReceive() internal {
        IReyaOFT token = IReyaOFT(reya);
        address attacker = makeAddr("attacker");
        address recipient = makeAddr("recipient");
        
        // Prepare a fake message
        IReyaOFT.Origin memory origin = IReyaOFT.Origin({
            srcEid: 30131,
            sender: bytes32(uint256(uint160(address(token)))),
            nonce: 1
        });
        
        // Encode a transfer message (recipient address + amount)
        bytes memory message = abi.encodePacked(
            bytes32(uint256(uint160(recipient))),
            uint256(1000e18)
        );
        
        // Attacker tries to call lzReceive directly
        vm.prank(attacker);
        vm.expectRevert(); // Should revert because caller is not the endpoint
        token.lzReceive(origin, bytes32(uint256(1)), message, attacker, "");
    }

    /// @notice Test that lzReceive mints tokens to the recipient
    function check_ReyaOFT_LzReceiveMintsTokens(
        uint32 srcEid
    ) internal {
        IReyaOFT token = IReyaOFT(reya);
        address endpoint = token.endpoint();
        address recipient = makeAddr("recipient7226");
        uint256 amount = 1000e18;
        
        uint256 recipientBalanceBefore = token.balanceOf(recipient);
        
        // Prepare the origin (from source chain)
        IReyaOFT.Origin memory origin = IReyaOFT.Origin({
            srcEid: srcEid,
            sender: token.peers(srcEid), // The peer OFT on source chain
            nonce: 1
        });
        
        // Encode the OFT message: recipient address + amount
        bytes memory message = abi.encodePacked(
            bytes32(uint256(uint160(recipient))),
            uint64(amount / 1e12) // OFT uses uint64 for amount in message
        );
        
        // Simulate the endpoint calling lzReceive
        vm.prank(endpoint);
        token.lzReceive(origin, bytes32(uint256(1)), message, endpoint, "");
        
        uint256 recipientBalanceAfter = token.balanceOf(recipient);
        
        // Verify tokens were minted to recipient
        assertEq(
            recipientBalanceAfter - recipientBalanceBefore,
            amount,
            "Recipient should receive tokens from lzReceive"
        );
    }

    /// @notice Test that lzReceive respects pause
    function check_ReyaOFT_LzReceiveRespectsPause(
        uint32 srcEid
    ) internal {
        IReyaOFT token = IReyaOFT(reya);
        address endpoint = token.endpoint();
        address recipient = makeAddr("recipient");
        uint256 amount = 1000e18;
        
        // Pause the token
        vm.prank(foundationMultisig);
        token.pause();
        
        // Prepare the origin
        IReyaOFT.Origin memory origin = IReyaOFT.Origin({
            srcEid: srcEid,
            sender: token.peers(srcEid),
            nonce: 1
        });
        
        // Encode the message
        bytes memory message = abi.encodePacked(
            bytes32(uint256(uint160(recipient))),
            uint64(amount)
        );
        
        // lzReceive should fail when paused
        vm.prank(endpoint);
        vm.expectRevert(abi.encodeWithSelector(IReyaOFT.FeatureUnavailable.selector, keccak256(bytes("global"))));
        token.lzReceive(origin, bytes32(uint256(1)), message, endpoint, "");
    }
}

contract ReyaOFTForkCheck is BaseReyaOFTForkCheck, BaseReyaForkTest {
    constructor() {
        _initOFTCheck(sec.reya, sec.foundationMultisig);
    }
}