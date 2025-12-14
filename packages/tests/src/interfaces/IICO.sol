// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IICO {
    struct Configuration {
        address token;
        uint256 totalAllocation;
        uint256 tgeDate;
    }

    struct AllocationInput {
        address user;
        uint256 initialAmount;
        uint256 monthlyAmount;
    }

    struct UserStatus {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 initialAmount;
        uint256 monthlyAmount;
    }

    event UserStatusUpdated(address indexed user, UserStatus status);
    event ConfigurationUpdated(Configuration configuration);
    error TGEDateNotSet();
    error TGEDateNotReached();
    error AlreadyAllocated(address user);
    error TotalExpectedAllocationExceeded();

    function setTGEDate(uint256 tgeDate) external;
    function setAllocations(AllocationInput[] calldata allocations) external;
    function claim(address[] calldata users) external returns (uint256[] memory amounts);
    function rescueTokens(address token, address recipient) external;
    function getUserStatus(address user) external view returns (UserStatus memory);
    function getStatus()
        external
        view
        returns (Configuration memory, uint256 totalAllocatedAmount, uint256 totalClaimedAmount);


    // Ownable
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}
