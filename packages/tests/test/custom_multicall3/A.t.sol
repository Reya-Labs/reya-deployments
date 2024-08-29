pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { Multicall3 } from "./Multicall3.sol";

contract A is Test {

    error Custom1(uint256 a);
    error Custom2(string a);

    function test_sample() public {
        address target1 = vm.addr(1);
        bytes memory calldata1 = hex"0123";
        bool allowFailure1 = false;

        address target2 = vm.addr(2);
        bytes memory calldata2 = hex"0124";
        bool allowFailure2 = true;

        vm.mockCallRevert(target1, calldata1, abi.encodeWithSelector(Custom1.selector, 1));
        vm.mockCallRevert(target2, calldata2, abi.encode(Custom2.selector, "abc"));

        Multicall3.Call3 memory call1 = Multicall3.Call3({
            target: target1,
            callData: calldata1,
            allowFailure: allowFailure1
        });

        Multicall3.Call3 memory call2 = Multicall3.Call3({
            target: target2,
            callData: calldata2,
            allowFailure: allowFailure2
        });

        Multicall3 multicall = new Multicall3();

        Multicall3.Call3[] memory calls = new Multicall3.Call3[](2);
        calls[0] = call1;
        calls[1] = call2;

        multicall.aggregate3PreservingError(calls);
    }
}
