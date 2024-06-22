pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { IERC20TokenModule } from "../../../src/interfaces/IERC20TokenModule.sol";

contract WbtcCollateralForkCheck is BaseReyaForkTest {
    function checkFuzz_WBTCMintBurn(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        uint256 totalSupplyBefore = IERC20TokenModule(sec.wbtc).totalSupply();

        // mint
        vm.prank(dec.socketController[sec.wbtc]);
        IERC20TokenModule(sec.wbtc).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.wbtc).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.wbtc).mint(user, amount);

        // burn
        vm.prank(dec.socketController[sec.wbtc]);
        IERC20TokenModule(sec.wbtc).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.wbtc).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.wbtc).burn(user, amount);

        uint256 totalSupplyAfter = IERC20TokenModule(sec.wbtc).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }
}
