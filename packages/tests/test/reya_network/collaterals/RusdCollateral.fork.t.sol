pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

import { IERC20TokenModule } from "../../../src/interfaces/IERC20TokenModule.sol";

import { IRUSDProxy } from "../../../src/interfaces/IRUSDProxy.sol";

contract RusdCollateralForkTest is ReyaForkTest {
    function testFuzz_USDCMintBurn(address attacker) public {
        vm.assume(attacker != socketController[usdc]);

        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 10e6;

        uint256 totalSupplyBefore = IERC20TokenModule(usdc).totalSupply();

        // mint
        vm.prank(socketController[usdc]);
        IERC20TokenModule(usdc).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(usdc).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(usdc).mint(user, amount);

        // burn
        vm.prank(socketController[usdc]);
        IERC20TokenModule(usdc).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(usdc).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(usdc).burn(user, amount);

        uint256 totalSupplyAfter = IERC20TokenModule(usdc).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }

    function testFuzz_rUSD() public {
        assertEq(IRUSDProxy(rusd).getUnderlyingAsset(), usdc);

        uint256 rusdTotalSupply = IRUSDProxy(rusd).totalSupply();
        uint256 usdcTotalSupply = IERC20TokenModule(rusd).totalSupply();
        assert(rusdTotalSupply <= usdcTotalSupply);

        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 10e6;

        deal(usdc, user, amount);
        vm.prank(user);
        IERC20TokenModule(usdc).approve(rusd, amount);
        vm.prank(user);
        IRUSDProxy(rusd).deposit(amount);
        assertEq(IRUSDProxy(rusd).totalSupply(), rusdTotalSupply + amount);
        assertEq(IRUSDProxy(rusd).balanceOf(user), amount);
        assertEq(IRUSDProxy(usdc).balanceOf(user), 0);
        rusdTotalSupply += amount;

        deal(usdc, periphery, amount);
        vm.prank(periphery);
        IERC20TokenModule(usdc).approve(rusd, amount);
        vm.prank(periphery);
        IRUSDProxy(rusd).depositTo(amount, user);
        assertEq(IRUSDProxy(rusd).totalSupply(), rusdTotalSupply + amount);
        assertEq(IRUSDProxy(rusd).balanceOf(user), 2 * amount);
        assertEq(IRUSDProxy(usdc).balanceOf(user), 0);
        assertEq(IRUSDProxy(rusd).balanceOf(periphery), 0);
        assertEq(IRUSDProxy(usdc).balanceOf(periphery), 0);
        rusdTotalSupply += amount;

        vm.prank(user);
        IRUSDProxy(rusd).withdraw(amount);
        assertEq(IRUSDProxy(rusd).totalSupply(), rusdTotalSupply - amount);
        assertEq(IRUSDProxy(rusd).balanceOf(user), amount);
        assertEq(IRUSDProxy(usdc).balanceOf(user), amount);
        assertEq(IRUSDProxy(rusd).balanceOf(periphery), 0);
        assertEq(IRUSDProxy(usdc).balanceOf(periphery), 0);
        rusdTotalSupply -= amount;

        vm.prank(user);
        IRUSDProxy(rusd).withdrawTo(amount, periphery);
        assertEq(IRUSDProxy(rusd).totalSupply(), rusdTotalSupply - amount);
        assertEq(IRUSDProxy(rusd).balanceOf(user), 0);
        assertEq(IRUSDProxy(usdc).balanceOf(user), amount);
        assertEq(IRUSDProxy(rusd).balanceOf(periphery), 0);
        assertEq(IRUSDProxy(usdc).balanceOf(periphery), amount);
        rusdTotalSupply -= amount;
    }
}
