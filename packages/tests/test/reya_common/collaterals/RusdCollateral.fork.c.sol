pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

import { IRUSDProxy } from "../../../src/interfaces/IRUSDProxy.sol";

contract RusdCollateralForkCheck is BaseReyaForkTest {
    function checkFuzz_USDCMintBurn(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        uint256 amount = 10e6;

        uint256 totalSupplyBefore = ITokenProxy(sec.usdc).totalSupply();

        // mint
        vm.prank(dec.socketController[sec.usdc]);
        ITokenProxy(sec.usdc).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        ITokenProxy(sec.usdc).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        ITokenProxy(sec.usdc).mint(user, amount);

        // burn
        vm.prank(dec.socketController[sec.usdc]);
        ITokenProxy(sec.usdc).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        ITokenProxy(sec.usdc).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        ITokenProxy(sec.usdc).burn(user, amount);

        uint256 totalSupplyAfter = ITokenProxy(sec.usdc).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }

    function checkFuzz_rUSD() public {
        assertEq(IRUSDProxy(sec.rusd).getUnderlyingAsset(), sec.usdc);

        uint256 rusdTotalSupply = IRUSDProxy(sec.rusd).totalSupply();
        uint256 usdcTotalSupply = ITokenProxy(sec.rusd).totalSupply();
        assert(rusdTotalSupply <= usdcTotalSupply);

        (address user,) = makeAddrAndKey("user");
        uint256 amount = 10e6;

        deal(sec.usdc, user, amount);
        vm.prank(user);
        ITokenProxy(sec.usdc).approve(sec.rusd, amount);
        vm.prank(user);
        IRUSDProxy(sec.rusd).deposit(amount);
        assertEq(IRUSDProxy(sec.rusd).totalSupply(), rusdTotalSupply + amount);
        assertEq(IRUSDProxy(sec.rusd).balanceOf(user), amount);
        assertEq(IRUSDProxy(sec.usdc).balanceOf(user), 0);
        rusdTotalSupply += amount;

        deal(sec.usdc, sec.periphery, amount);
        vm.prank(sec.periphery);
        ITokenProxy(sec.usdc).approve(sec.rusd, amount);
        vm.prank(sec.periphery);
        IRUSDProxy(sec.rusd).depositTo(amount, user);
        assertEq(IRUSDProxy(sec.rusd).totalSupply(), rusdTotalSupply + amount);
        assertEq(IRUSDProxy(sec.rusd).balanceOf(user), 2 * amount);
        assertEq(IRUSDProxy(sec.usdc).balanceOf(user), 0);
        assertEq(IRUSDProxy(sec.rusd).balanceOf(sec.periphery), 0);
        assertEq(IRUSDProxy(sec.usdc).balanceOf(sec.periphery), 0);
        rusdTotalSupply += amount;

        vm.prank(user);
        IRUSDProxy(sec.rusd).withdraw(amount);
        assertEq(IRUSDProxy(sec.rusd).totalSupply(), rusdTotalSupply - amount);
        assertEq(IRUSDProxy(sec.rusd).balanceOf(user), amount);
        assertEq(IRUSDProxy(sec.usdc).balanceOf(user), amount);
        assertEq(IRUSDProxy(sec.rusd).balanceOf(sec.periphery), 0);
        assertEq(IRUSDProxy(sec.usdc).balanceOf(sec.periphery), 0);
        rusdTotalSupply -= amount;

        vm.prank(user);
        IRUSDProxy(sec.rusd).withdrawTo(amount, sec.periphery);
        assertEq(IRUSDProxy(sec.rusd).totalSupply(), rusdTotalSupply - amount);
        assertEq(IRUSDProxy(sec.rusd).balanceOf(user), 0);
        assertEq(IRUSDProxy(sec.usdc).balanceOf(user), amount);
        assertEq(IRUSDProxy(sec.rusd).balanceOf(sec.periphery), 0);
        assertEq(IRUSDProxy(sec.usdc).balanceOf(sec.periphery), amount);
        rusdTotalSupply -= amount;
    }
}
