pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { ICoreProxy, ParentCollateralConfig, MarginInfo, CollateralInfo } from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { IERC20TokenModule } from "../../../src/interfaces/IERC20TokenModule.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract DeusdCollateralForkCheck is BaseReyaForkTest {
    function checkFuzz_DEUSDMintBurn(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        uint256 totalSupplyBefore = IERC20TokenModule(sec.deusd).totalSupply();

        // mint
        vm.prank(dec.socketController[sec.deusd]);
        IERC20TokenModule(sec.deusd).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.deusd).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.deusd).mint(user, amount);

        // burn
        vm.prank(dec.socketController[sec.deusd]);
        IERC20TokenModule(sec.deusd).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.deusd).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.deusd).burn(user, amount);

        uint256 totalSupplyAfter = IERC20TokenModule(sec.deusd).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }
}
