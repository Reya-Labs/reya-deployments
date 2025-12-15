// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import { BaseEthereumForkTest } from "../BaseEthereumForkTest.sol";
import { IICO } from "../../../src/interfaces/IICO.sol";
import { IERC20 } from "../../../src/interfaces/IStakedReya.sol";
import { IReyaOFT } from "../../../src/interfaces/IReyaOFT.sol";

/// @dev Simple ERC20 mock for testing token rescue functionality
contract ERC20Mock {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }
}

contract ICODistributionForkCheck is BaseEthereumForkTest {
    address contractsOwner;

    function _initICOCheck(address _foundationMultisig, address _foundationEoa) internal {
        contractsOwner = IReyaOFT(sec.reya).owner();

        if (contractsOwner != _foundationEoa && contractsOwner != _foundationMultisig) {
            revert("Contracts owner is not the foundation EOA or the foundation multisig");
        }
    }
    /// @notice Test that configuration has correct REYA token address

    function check_ICO_TokenAddressIsCorrect() internal view {
        (IICO.Configuration memory config,,) = IICO(sec.ico).getStatus();

        assertEq(config.token, sec.reya, "Token address should be REYA");
    }

    /// @notice Test that owner can rescue tokens above total allocation
    function check_ICO_OwnerCanRescueExcessREYA() internal {
        address recipient = makeAddr("rescueRecipient");

        // Mint extra REYA to the ICO contract
        uint256 extraAmount = 5000e18;
        vm.prank(contractsOwner);
        IReyaOFT(sec.reya).mint(sec.ico, extraAmount);

        uint256 recipientBalanceBefore = IERC20(sec.reya).balanceOf(recipient);

        // Owner rescues excess REYA
        vm.prank(contractsOwner);
        IICO(sec.ico).rescueTokens(sec.reya, recipient);

        uint256 recipientBalanceAfter = IERC20(sec.reya).balanceOf(recipient);

        // Should rescue the extra amount that was minted
        assertEq(
            recipientBalanceAfter - recipientBalanceBefore, extraAmount, "Should rescue the extra REYA that was minted"
        );
    }

    /// @notice Test that owner can rescue any other ERC20 tokens
    function check_ICO_OwnerCanRescueOtherTokens() internal {
        ERC20Mock mockToken = new ERC20Mock("MockToken", "MT");
        address randomToken = address(mockToken);
        address recipient = makeAddr("recipient");
        uint256 amount = 1000e18;

        // Mint tokens to ICO contract
        mockToken.mint(sec.ico, amount);

        uint256 recipientBalanceBefore = IERC20(randomToken).balanceOf(recipient);

        // Owner rescues tokens
        vm.prank(contractsOwner);
        IICO(sec.ico).rescueTokens(randomToken, recipient);

        uint256 recipientBalanceAfter = IERC20(randomToken).balanceOf(recipient);
        assertEq(recipientBalanceAfter - recipientBalanceBefore, amount, "Recipient should receive all rescued tokens");
    }

    /// @notice Test that non-owner cannot rescue tokens
    function check_ICO_NonOwnerCannotRescueTokens() internal {
        address attacker = makeAddr("attacker");
        ERC20Mock mockToken = new ERC20Mock("RandomToken", "RT");
        address randomToken = address(mockToken);
        address recipient = makeAddr("recipient");

        // Mint tokens to ICO contract
        mockToken.mint(sec.ico, 1000e18);

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(IReyaOFT.OwnableUnauthorizedAccount.selector, attacker));
        IICO(sec.ico).rescueTokens(randomToken, recipient);
    }

    /// @notice Test that owner can set TGE date
    function check_ICO_OwnerCanSetTGEDate() internal {
        uint256 tgeDate = block.timestamp + 30 days;

        vm.prank(contractsOwner);
        IICO(sec.ico).setTGEDate(tgeDate);

        // Verify TGE date was set
        (IICO.Configuration memory config,,) = IICO(sec.ico).getStatus();
        assertEq(config.tgeDate, tgeDate, "TGE date should be set correctly");
    }

    /// @notice Test that non-owner cannot set TGE date
    function checkFuzz_ICO_NonOwnerCannotSetTGEDate(address attacker) internal {
        uint256 tgeDate = block.timestamp + 30 days;

        vm.prank(attacker);
        vm.expectRevert();
        IICO(sec.ico).setTGEDate(tgeDate);
    }

    /// @notice Test that owner can set allocations
    function check_ICO_OwnerCanSetAllocations() internal {
        IICO.AllocationInput[] memory allocations = new IICO.AllocationInput[](2);
        allocations[0] =
            IICO.AllocationInput({ user: makeAddr("user1"), initialAmount: 1000e18, monthlyAmount: 100e18 });
        allocations[1] =
            IICO.AllocationInput({ user: makeAddr("user2"), initialAmount: 2000e18, monthlyAmount: 200e18 });

        vm.prank(contractsOwner);
        IICO(sec.ico).setAllocations(allocations);

        // Verify allocations were set
        IICO.UserStatus memory user1Status = IICO(sec.ico).getUserStatus(makeAddr("user1"));
        assertEq(user1Status.initialAmount, 1000e18, "User1 initial amount should match");
        assertEq(user1Status.monthlyAmount, 100e18, "User1 monthly amount should match");

        IICO.UserStatus memory user2Status = IICO(sec.ico).getUserStatus(makeAddr("user2"));
        assertEq(user2Status.initialAmount, 2000e18, "User2 initial amount should match");
        assertEq(user2Status.monthlyAmount, 200e18, "User2 monthly amount should match");
    }

    /// @notice Test that non-owner cannot set allocations
    function checkFuzz_ICO_NonOwnerCannotSetAllocations(address attacker) internal {
        IICO.AllocationInput[] memory allocations = new IICO.AllocationInput[](1);
        allocations[0] =
            IICO.AllocationInput({ user: makeAddr("user1"), initialAmount: 1000e18, monthlyAmount: 100e18 });

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(IReyaOFT.OwnableUnauthorizedAccount.selector, attacker));
        IICO(sec.ico).setAllocations(allocations);
    }

    /// @notice Test that total allocated amount is tracked correctly
    function check_ICO_TotalAllocatedTracking() internal {
        (, uint256 initialTotalAllocated,) = IICO(sec.ico).getStatus();

        IICO.AllocationInput[] memory allocations = new IICO.AllocationInput[](2);
        allocations[0] =
            IICO.AllocationInput({ user: makeAddr("user1"), initialAmount: 1000e18, monthlyAmount: 100e18 });
        allocations[1] =
            IICO.AllocationInput({ user: makeAddr("user2"), initialAmount: 2000e18, monthlyAmount: 200e18 });

        vm.prank(contractsOwner);
        IICO(sec.ico).setAllocations(allocations);

        // Check total allocated
        (, uint256 totalAllocated,) = IICO(sec.ico).getStatus();

        // Total should include initial + monthly amounts for all users
        // user1: 1000e18 initial + 100e18 * 6 months = 1600e18
        // user2: 2000e18 initial + 200e18 * 6 months = 3200e18
        assertEq(totalAllocated, initialTotalAllocated + 1600e18 + 3200e18, "Total allocated is not right");
    }

    function isAllocated(address claimer) internal view returns (bool) {
        IICO.UserStatus memory status = IICO(sec.ico).getUserStatus(claimer);
        return status.totalAmount > 0;
    }

    function checkFuzz_ICO_ClaimingRevertsWhenNoAllocation(address claimer) internal {
        uint256 balanceBefore = IERC20(sec.reya).balanceOf(claimer);

        vm.prank(contractsOwner);
        IICO(sec.ico).setTGEDate(block.timestamp - 60 days);

        vm.prank(claimer);
        IICO(sec.ico).claim(new address[](1));

        uint256 balanceAfter = IERC20(sec.reya).balanceOf(claimer);
        assertEq(balanceBefore, balanceAfter, "Balance should not change on failed claim");
    }

    /// @notice Test that claiming works when TGE date is set and contract is funded
    function check_ICO_ClaimingWorks() internal {
        address claimer = makeAddr("claimer");
        uint256 initialAmount = 1000e18;
        uint256 monthlyAmount = 100e18;

        // Set allocation for claimer
        IICO.AllocationInput[] memory allocations = new IICO.AllocationInput[](1);
        allocations[0] =
            IICO.AllocationInput({ user: claimer, initialAmount: initialAmount, monthlyAmount: monthlyAmount });

        vm.prank(contractsOwner);
        IICO(sec.ico).setAllocations(allocations);

        // Set TGE date to now
        vm.prank(contractsOwner);
        IICO(sec.ico).setTGEDate(block.timestamp);

        // Fund the ICO contract with enough REYA
        uint256 totalNeeded = initialAmount + (monthlyAmount * 12); // 12 months of vesting
        vm.prank(contractsOwner);
        IReyaOFT(sec.reya).mint(sec.ico, totalNeeded);

        // Record balance before claim
        uint256 claimerBalanceBefore = IERC20(sec.reya).balanceOf(claimer);

        // Claim tokens
        address[] memory users = new address[](1);
        users[0] = claimer;

        uint256[] memory amounts = IICO(sec.ico).claim(users);

        // Verify tokens were delivered
        uint256 claimerBalanceAfter = IERC20(sec.reya).balanceOf(claimer);
        assertEq(amounts[0], initialAmount, "Claimed amount should match initial amount");
        assertEq(claimerBalanceAfter - claimerBalanceBefore, initialAmount, "Claimer should receive initial allocation");

        // Verify user status updated
        IICO.UserStatus memory status = IICO(sec.ico).getUserStatus(claimer);
        assertEq(status.claimedAmount, initialAmount, "Claimed amount should be recorded");

        {
            // Try to claim again immediately (no time passed)
            uint256[] memory secondClaimAmounts = IICO(sec.ico).claim(users);

            // Verify no additional tokens were given
            uint256 balanceAfterSecondClaim = IERC20(sec.reya).balanceOf(claimer);
            assertEq(secondClaimAmounts[0], 0, "Second claim should return 0");
            assertEq(balanceAfterSecondClaim, claimerBalanceAfter, "Balance should not change on second claim");
        }
    }
}
