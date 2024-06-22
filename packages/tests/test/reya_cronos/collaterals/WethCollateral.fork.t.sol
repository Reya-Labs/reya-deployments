pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import "../../reya_network/DataTypes.sol";

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

contract WethCollateralForkTest is ReyaForkTest {
    function testFuzz_WETHMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.weth]);

        (address user,) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        uint256 totalSupplyBefore = IERC20TokenModule(sec.weth).totalSupply();

        // mint
        vm.prank(dec.socketController[sec.weth]);
        IERC20TokenModule(sec.weth).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.weth).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.weth).mint(user, amount);

        // burn
        vm.prank(dec.socketController[sec.weth]);
        IERC20TokenModule(sec.weth).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.weth).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.weth).burn(user, amount);

        uint256 totalSupplyAfter = IERC20TokenModule(sec.weth).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }

    function test_weth_view_functions() public {
        (address user,) = makeAddrAndKey("user");

        // deposit WETH into new margin account
        uint256 wethAmount = 1e18;
        uint128 accountId = 0;
        {
            deal(sec.weth, address(sec.periphery), wethAmount);
            mockBridgedAmount(dec.socketExecutionHelper[sec.weth], wethAmount);
            vm.prank(dec.socketExecutionHelper[sec.weth]);
            accountId = IPeripheryProxy(sec.periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: sec.weth }));
        }

        // activate first market for account
        {
            vm.prank(user);
            ICoreProxy(sec.core).activateFirstMarketForAccount(accountId, 1);
        }

        // fetch WETH/USDC price
        uint256 ethUsdcPrice = IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdcNodeId).price;

        // fetch collateral configuration of WETH
        (, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.weth);
        
        // convert WETH amount to USDC
        SD59x18 wethAmountInUSD = sd(int256(wethAmount)).mul(sd(int256(ethUsdcPrice))).mul(
            UNIT_sd.sub(sd(int256(parentCollateralConfig.priceHaircut)))
        );

        // check the account total margin balance
        {
            MarginInfo memory accountUsdNodeMarginInfo = ICoreProxy(sec.core).getNodeMarginInfo(accountId, sec.rusd);
            assertApproxEqAbsDecimal(accountUsdNodeMarginInfo.marginBalance * 1e12, wethAmountInUSD.unwrap(), 0.000001e18, 18);
        }

        // check the account collateral balance in WETH
        {
            CollateralInfo memory accountWethCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.weth);
            assertEq(accountWethCollateralInfo.netDeposits, int256(wethAmount));
            assertEq(accountWethCollateralInfo.marginBalance, int256(wethAmount));
            assertEq(accountWethCollateralInfo.realBalance, int256(wethAmount));
        }

        // deposit USDC into the existing account
        uint256 usdcAmount = 1000e6;
        {
            deal(sec.usdc, address(sec.periphery), usdcAmount);
            mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], usdcAmount);
            vm.prank(dec.socketExecutionHelper[sec.usdc]);
            IPeripheryProxy(sec.periphery).depositExistingMA(
                DepositExistingMAInputs({ accountId: accountId, token: sec.usdc })
            );
        }

        // check the account total margin balance
        {
            MarginInfo memory accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
            assertApproxEqAbsDecimal(
                accountUsdNodeMarginInfo.marginBalance, wethAmountInUSD.unwrap() + 1000e18, 0.000001e18, 18
            );
        }

        // check the account collateral balance in WETH
        {
            CollateralInfo memory accountWethCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.weth);
            assertEq(accountWethCollateralInfo.netDeposits, int256(wethAmount));
            assertEq(accountWethCollateralInfo.marginBalance, int256(wethAmount));
            assertEq(accountWethCollateralInfo.realBalance, int256(wethAmount));
        }
    }

    // function test_weth_deposit_withdraw_cronos() public {
    //     (address user, uint256 userPk) = makeAddrAndKey("user");

    //     // deposit WETH into new margin account
    //     uint256 amount1 = 50e18; // denominated in weth
    //     uint128 accountId = 0;
    //     {
    //         deal(sec.weth, address(sec.periphery), amount1);
    //         mockBridgedAmount(dec.socketExecutionHelper[sec.weth], amount1);
    //         vm.prank(dec.socketExecutionHelper[sec.weth]);
    //         accountId = IPeripheryProxy(sec.periphery).depositNewMA(
    //             DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
    //         );
    //     }

    //     // capture balance before withdrawal
    //     uint256 coreWethBalanceBefore = IERC20TokenModule(sec.weth).balanceOf(sec.core);
    //     uint256 peripheryWethBalanceBefore = IERC20TokenModule(sec.weth).balanceOf(sec.periphery);
    //     uint256 multisigWethBalanceBefore = IERC20TokenModule(sec.weth).balanceOf(sec.multisig);

    //     // withdraw WETH from margin account
    //     uint256 amount2 = 5e18;
    //     executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.weth, amount2, ethereumSepoliaChainId);

    //     // capture balances after withdrawal
    //     uint256 coreWethBalanceAfter = IERC20TokenModule(sec.weth).balanceOf(sec.core);
    //     uint256 peripheryWethBalanceAfter = IERC20TokenModule(sec.weth).balanceOf(sec.periphery);
    //     uint256 multisigWethBalanceAfter = IERC20TokenModule(sec.weth).balanceOf(sec.multisig);

    //     // get static fees of withdrawal
    //     uint256 withdrawStaticFees = IPeripheryProxy(sec.periphery).getTokenStaticWithdrawFee(
    //         sec.weth, dec.socketConnector[sec.weth][ethereumSepoliaChainId]
    //     );

    //     // check the delta balances are as expected
    //     assertEq(coreWethBalanceBefore - coreWethBalanceAfter, amount2);
    //     assertEq(multisigWethBalanceAfter - multisigWethBalanceBefore, withdrawStaticFees);
    //     // we mock call to socket so funds remain in periphery
    //     assertEq(peripheryWethBalanceAfter - peripheryWethBalanceBefore, amount2 - withdrawStaticFees);
    // }
}
