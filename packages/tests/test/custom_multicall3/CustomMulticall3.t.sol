pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { CustomMulticall3 } from "../../src/custom-multicall3/CustomMulticall3.sol";

contract CustomMulticall3Test is Test {
    error Custom1(uint256 a);
    error Custom2(string a);

    address target1 = vm.addr(1);
    bytes calldata1 = hex"0123";

    address target2 = vm.addr(2);
    bytes calldata2 = hex"0124";

    CustomMulticall3.Call[] calls;
    CustomMulticall3 multicall = new CustomMulticall3();

    function setUp() public {
        CustomMulticall3.Call memory call1 = CustomMulticall3.Call({
            target: target1,
            callData: calldata1
        });

        CustomMulticall3.Call memory call2 = CustomMulticall3.Call({
            target: target2,
            callData: calldata2
        });
    
        calls.push(call1);
        calls.push(call2);

        multicall = new CustomMulticall3();
    }

    function testFuzz_revert_all_but_optional(bytes memory revertData1, bytes memory revertData2) public {
        vm.mockCallRevert(target1, calldata1, revertData1);
        vm.mockCallRevert(target2, calldata2, revertData2);

        CustomMulticall3.Result[] memory result = multicall.tryAggregatePreservingError(false, calls);

        assertEq(result.length, 2);
        assertEq(result[0].success, false);
        assertEq(result[0].returnData, revertData1);
        assertEq(result[1].success, false);
        assertEq(result[1].returnData, revertData2);
    }

    function testFuzz_revert_all_strict(bytes memory revertData1, bytes memory revertData2) public {
        vm.mockCallRevert(target1, calldata1, revertData1);
        vm.mockCallRevert(target2, calldata2, revertData2);

        vm.expectRevert(revertData1);
        multicall.tryAggregatePreservingError(true, calls);
    }

    function testFuzz_revert_second_strict(bytes memory returnData1, bytes memory revertData2) public {
        vm.mockCall(target1, calldata1, returnData1);
        vm.mockCallRevert(target2, calldata2, revertData2);

        vm.expectRevert(revertData2);
        multicall.tryAggregatePreservingError(true, calls);
    }

    function testFuzz_revert_some_but_optional(bytes memory revertData1, bytes memory returnData2) public {
        vm.mockCallRevert(target1, calldata1, revertData1);
        vm.mockCall(target2, calldata2, returnData2);

        CustomMulticall3.Result[] memory result = multicall.tryAggregatePreservingError(false, calls);

        assertEq(result.length, 2);
        assertEq(result[0].success, false);
        assertEq(result[0].returnData, revertData1);
        assertEq(result[1].success, true);
        assertEq(result[1].returnData, returnData2);
    }

    function testFuzz_revert_none_optional(bytes memory returnData1, bytes memory returnData2) public {
        vm.mockCall(target1, calldata1, returnData1);
        vm.mockCall(target2, calldata2, returnData2);

        CustomMulticall3.Result[] memory result = multicall.tryAggregatePreservingError(false, calls);

        assertEq(result.length, 2);
        assertEq(result[0].success, true);
        assertEq(result[0].returnData, returnData1);
        assertEq(result[1].success, true);
        assertEq(result[1].returnData, returnData2);
    }

    function testFuzz_revert_none_strict(bytes memory returnData1, bytes memory returnData2) public {
        vm.mockCall(target1, calldata1, returnData1);
        vm.mockCall(target2, calldata2, returnData2);

        CustomMulticall3.Result[] memory result = multicall.tryAggregatePreservingError(true, calls);

        assertEq(result.length, 2);
        assertEq(result[0].success, true);
        assertEq(result[0].returnData, returnData1);
        assertEq(result[1].success, true);
        assertEq(result[1].returnData, returnData2);
    }
}
