pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

contract WbtcCollateralForkCheck is BaseReyaForkTest {
    function checkFuzz_WBTCMintBurn(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        uint256 totalSupplyBefore = ITokenProxy(sec.wbtc).totalSupply();

        // mint
        vm.prank(dec.socketController[sec.wbtc]);
        ITokenProxy(sec.wbtc).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        ITokenProxy(sec.wbtc).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        ITokenProxy(sec.wbtc).mint(user, amount);

        // burn
        vm.prank(dec.socketController[sec.wbtc]);
        ITokenProxy(sec.wbtc).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        ITokenProxy(sec.wbtc).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        ITokenProxy(sec.wbtc).burn(user, amount);

        uint256 totalSupplyAfter = ITokenProxy(sec.wbtc).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }
}
