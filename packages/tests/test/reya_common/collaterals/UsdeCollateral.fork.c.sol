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

contract UsdeCollateralForkCheck is BaseReyaForkTest {
    function checkFuzz_USDEMintBurn(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        uint256 totalSupplyBefore = IERC20TokenModule(sec.usde).totalSupply();

        // mint
        vm.prank(dec.socketController[sec.usde]);
        IERC20TokenModule(sec.usde).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.usde).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.usde).mint(user, amount);

        // burn
        vm.prank(dec.socketController[sec.usde]);
        IERC20TokenModule(sec.usde).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.usde).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.usde).burn(user, amount);

        uint256 totalSupplyAfter = IERC20TokenModule(sec.usde).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }

    function check_usde_view_functions() public {
        (address user,) = makeAddrAndKey("user");

        uint256 usdeAmount = 1e18;

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), usdeAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], usdeAmount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId =
            IPeripheryProxy(sec.periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: sec.usde }));

        vm.prank(user);
        ICoreProxy(sec.core).activateFirstMarketForAccount(accountId, 1);

        NodeOutput.Data memory ethUsdcNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdcNodeId);

        (, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.usde);
        SD59x18 usdeAmountInUSD = sd(int256(usdeAmount)).mul(sd(int256(ethUsdcNodeOutput.price))).mul(
            UNIT_sd.sub(sd(int256(parentCollateralConfig.priceHaircut)))
        );

        MarginInfo memory accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(accountUsdNodeMarginInfo.marginBalance, usdeAmountInUSD.unwrap(), 0.000001e18, 18);

        CollateralInfo memory accountUsdeCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.usde);
        assertEq(accountUsdeCollateralInfo.netDeposits, int256(usdeAmount));
        assertEq(accountUsdeCollateralInfo.marginBalance, int256(usdeAmount));
        assertEq(accountUsdeCollateralInfo.realBalance, int256(usdeAmount));

        uint256 usdcAmount = 1000e6;
        deal(sec.usdc, address(sec.periphery), usdcAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], usdcAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: accountId, token: sec.usdc })
        );

        accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(
            accountUsdNodeMarginInfo.marginBalance, usdeAmountInUSD.unwrap() + 1000e18, 0.000001e18, 18
        );

        accountUsdeCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.usde);
        assertEq(accountUsdeCollateralInfo.netDeposits, int256(usdeAmount));
        assertEq(accountUsdeCollateralInfo.marginBalance, int256(usdeAmount));
        assertEq(accountUsdeCollateralInfo.realBalance, int256(usdeAmount));
    }

    function check_usde_cap_exceeded() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 501e18; // denominated in usde
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        uint256 collateralPoolUsdeBalance = ICoreProxy(sec.core).getCollateralPoolBalance(1, sec.usde);

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                ICoreProxy.CollateralCapExceeded.selector, 1, sec.usde, 500e18, collateralPoolUsdeBalance + amount
            )
        );
        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);
    }

    function check_usde_deposit_withdraw() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 50e18; // denominated in usde

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        uint256 coreUsdeBalanceBefore = IERC20TokenModule(sec.usde).balanceOf(sec.core);
        uint256 peripheryUsdeBalanceBefore = IERC20TokenModule(sec.usde).balanceOf(sec.periphery);
        uint256 multisigUsdeBalanceBefore = IERC20TokenModule(sec.usde).balanceOf(sec.multisig);

        amount = 5e18;
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.usde, amount, arbitrumChainId);

        uint256 coreUsdeBalanceAfter = IERC20TokenModule(sec.usde).balanceOf(sec.core);
        uint256 peripheryUsdeBalanceAfter = IERC20TokenModule(sec.usde).balanceOf(sec.periphery);
        uint256 multisigUsdeBalanceAfter = IERC20TokenModule(sec.usde).balanceOf(sec.multisig);
        uint256 withdrawStaticFees = IPeripheryProxy(sec.periphery).getTokenStaticWithdrawFee(
            sec.usde, dec.socketConnector[sec.usde][arbitrumChainId]
        );

        assertEq(coreUsdeBalanceBefore - coreUsdeBalanceAfter, amount);
        assertEq(multisigUsdeBalanceAfter - multisigUsdeBalanceBefore, withdrawStaticFees);
        // we mock call to socket so funds remain in periphery
        assertEq(peripheryUsdeBalanceAfter - peripheryUsdeBalanceBefore, amount - withdrawStaticFees);
    }

    function check_trade_usdeCollateral_depositWithdraw() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 1e18; // denominated in usde
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        uint256 usdcAmount = 1000e6;
        deal(sec.usdc, address(sec.periphery), usdcAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], usdcAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: accountId, token: sec.usdc })
        );

        amount = 0.1e18;
        executePeripheryWithdrawMA(user, userPk, 2, accountId, sec.usde, amount, arbitrumChainId);

        checkPoolHealth();
    }

    function check_UsdeTradeWithUsdeCollateral() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");

        (, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.usde);
        uint256 priceHaircut = parentCollateralConfig.priceHaircut;

        // deposit 1 + 10 / (1-haircut) USDe
        uint256 amount = 1e18 + 10e18 * 1e18 / (1e18 - priceHaircut);
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        // user executes short trade on ETH
        (UD60x18 orderPrice,) = executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(-10e18),
            priceLimit: ud(0),
            accountId: accountId
        });

        // compute fees paid in rUSD
        uint256 fees = 0;
        {
            uint256 currentPrice = IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdcNodeId).price;
            fees = 10e6 * currentPrice / 1e18 * 0.001e18 / 1e18;
        }

        // withdraw 1 USDe
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.usde, 1e18, arbitrumChainId);

        int256 marginBalance0 = ICoreProxy(sec.core).getNodeMarginInfo(accountId, sec.rusd).marginBalance;
        // TODO: when collateral USDE price points to Stork, lower the acceptance to 10 * 0.01e6
        assertApproxEqAbsDecimal(marginBalance0 + int256(fees), 10e6 * int256(orderPrice.unwrap()) / 1e18, 10 * 10e6, 6);

        uint256[] memory randomPrices = new uint256[](4);
        randomPrices[0] = 3000e18;
        randomPrices[1] = 100_000e18;
        randomPrices[2] = orderPrice.unwrap() - 10e18;
        randomPrices[3] = orderPrice.unwrap() + 10e18;

        for (uint256 i = 0; i < 4; i++) {
            vm.mockCall(
                sec.oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcNodeId)),
                abi.encode(NodeOutput.Data({ price: randomPrices[i], timestamp: block.timestamp }))
            );

            vm.mockCall(
                sec.oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkFallbackNodeId)),
                abi.encode(NodeOutput.Data({ price: randomPrices[i], timestamp: block.timestamp }))
            );

            int256 marginBalance1 = ICoreProxy(sec.core).getNodeMarginInfo(accountId, sec.rusd).marginBalance;

            // TODO: when collateral USDE price points to Stork, lower the acceptance to 10 * 0.01e6
            assertApproxEqAbsDecimal(marginBalance0, marginBalance1, 10 * 10e6, 6);
        }
    }
}
