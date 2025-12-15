// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import { EthereumForkTest } from "../EthereumForkTest.sol";
import { ICODistributionForkCheck } from "../../ethereum_common/tge/ICODistribution.fork.c.sol";

contract ICODistributionForkTest is EthereumForkTest, ICODistributionForkCheck {
    constructor() {
        _initICOCheck(sec.foundationMultisig, sec.foundationEoa);
    }

    function test_ICO_TokenAddressIsCorrect() public view {
        check_ICO_TokenAddressIsCorrect();
    }

    function test_ICO_OwnerCanRescueExcessREYA() public {
        check_ICO_OwnerCanRescueExcessREYA();
    }

    function test_ICO_OwnerCanRescueOtherTokens() public {
        check_ICO_OwnerCanRescueOtherTokens();
    }

    function test_ICO_NonOwnerCannotRescueTokens() public {
        check_ICO_NonOwnerCannotRescueTokens();
    }

    function test_ICO_OwnerCanSetTGEDate() public {
        check_ICO_OwnerCanSetTGEDate();
    }

    function testFuzz_ICO_NonOwnerCannotSetTGEDate(address attacker) public {
        vm.assume(attacker != sec.foundationMultisig);
        checkFuzz_ICO_NonOwnerCannotSetTGEDate(attacker);
    }

    function test_ICO_OwnerCanSetAllocations() public {
        check_ICO_OwnerCanSetAllocations();
    }

    function testFuzz_ICO_NonOwnerCannotSetAllocations(address attacker) public {
        vm.assume(attacker != sec.foundationMultisig);
        checkFuzz_ICO_NonOwnerCannotSetAllocations(attacker);
    }

    function test_ICO_TotalAllocatedTracking() public {
        check_ICO_TotalAllocatedTracking();
    }

    function testFuzz_ICO_ClaimingRevertsWhenNoAllocation(address claimer) public {
        vm.assume(!isAllocated(claimer));
        checkFuzz_ICO_ClaimingRevertsWhenNoAllocation(claimer);
    }

    function test_ICO_ClaimingWorks() public {
        check_ICO_ClaimingWorks();
    }
}
