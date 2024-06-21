pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

import {
    ICoreProxy,
    CollateralConfig,
    ParentCollateralConfig,
    CachedCollateralConfig,
    MarginInfo,
    CollateralInfo
} from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { IERC20TokenModule } from "../../../src/interfaces/IERC20TokenModule.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract WbtcCollateralForkTest is ReyaForkTest {
    function testFuzz_WBTCMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.wbtc]);

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
