pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import {
    CollateralConfig,
    ParentCollateralConfig,
    ICoreProxy,
    Action,
    ActionMetadata
} from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPassivePoolProxy,
    RebalanceAmounts,
    AutoRebalanceInput,
    AllocationConfigurationData,
    AddLiquidityV2Input,
    RemoveLiquidityV2Input
} from "../../../src/interfaces/IPassivePoolProxy.sol";
import {
    IPeripheryProxy,
    DepositNewMAInputs,
    DepositExistingMAInputs,
    DepositPassivePoolInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { ISocketExecutionHelper } from "../../../src/interfaces/ISocketExecutionHelper.sol";

import { IERC20TokenModule } from "../../../src/interfaces/IERC20TokenModule.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd } from "@prb/math/SD59x18.sol";
import { ud } from "@prb/math/UD60x18.sol";

contract PassivePoolForkCheck is BaseReyaForkTest {
    function setUp() public {
        removeCollateralCap(sec.rselini);
        removeCollateralCap(sec.ramber);

        removeCollateralWithdrawalLimit(sec.rselini);
        removeCollateralWithdrawalLimit(sec.ramber);
    }

    function check_PoolHealth() public {
        checkPoolHealth();
    }

    function checkFuzz_PoolDepositWithdraw(address user, address attacker) public {
        uint256 amount = 100e6;
        deal(sec.usdc, sec.periphery, amount);
        DepositPassivePoolInputs memory inputs =
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: user, minShares: 0 });
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(amount)
        );
        IPeripheryProxy(sec.periphery).depositPassivePool(inputs);

        uint256 userSharesAmount = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);
        assert(userSharesAmount > 0);

        vm.prank(attacker);
        vm.expectRevert();
        IPassivePoolProxy(sec.pool).removeLiquidity(
            sec.passivePoolId, userSharesAmount, 0, ActionMetadata({ action: Action.Unstake, onBehalfOf: attacker })
        );

        vm.prank(user);
        IPassivePoolProxy(sec.pool).removeLiquidity(
            sec.passivePoolId, userSharesAmount, 0, ActionMetadata({ action: Action.Unstake, onBehalfOf: user })
        );
    }

    function check_PassivePoolWithWeth() public {
        mockFreshPrices();

        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.weth);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.weth, collateralConfig, parentCollateralConfig);

        (address user, uint256 userPk) = makeAddrAndKey("user");

        uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        // add 1 wETH to the passive pool directly
        deal(sec.weth, address(sec.periphery), 1e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], 1e18);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: sec.passivePoolAccountId, token: address(sec.weth) })
        );

        uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
        assertApproxEqRelDecimal(sharePrice1, sharePrice0, 0.005e18, 18);

        // make sure that the passive pool deposit works
        deal(sec.usdc, sec.periphery, 10e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(10e6)
        );
        IPeripheryProxy(sec.periphery).depositPassivePool(
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: user, minShares: 0 })
        );

        uint256 sharesIn = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);

        // make sure that the passive pool withdrawal works
        vm.prank(user);
        uint256 amountOut = IPassivePoolProxy(sec.pool).removeLiquidity(
            sec.passivePoolId, sharesIn, 0, ActionMetadata({ action: Action.Unstake, onBehalfOf: user })
        );
        assertApproxEqAbsDecimal(amountOut, 10e6, 10, 6);

        // create new account and deposit 11 wETH in it
        deal(sec.weth, address(sec.periphery), 11e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], 11e18);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
        );

        // user executes short trade on ETH
        executeCoreMatchOrder({ marketId: 1, sender: user, base: sd(-10e18), priceLimit: ud(0), accountId: accountId });

        // user closes the short trade on ETH and goes same long
        executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(20e18),
            priceLimit: ud(type(uint256).max),
            accountId: accountId
        });

        // withdraw 1 wETH from account
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.weth, 1e18, sec.destinationChainId);
    }

    function check_PassivePoolWithUsde() public {
        mockFreshPrices();

        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.usde);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.usde, collateralConfig, parentCollateralConfig);

        (address user, uint256 userPk) = makeAddrAndKey("user");

        uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        // add 3000 USDe to the passive pool directly
        deal(sec.usde, address(sec.periphery), 3000e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], 3000e18);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: sec.passivePoolAccountId, token: address(sec.usde) })
        );

        uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
        assertApproxEqRelDecimal(sharePrice1, sharePrice0, 0.005e18, 18);

        // make sure that the passive pool deposit works
        deal(sec.usdc, sec.periphery, 10e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(10e6)
        );

        IPeripheryProxy(sec.periphery).depositPassivePool(
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: user, minShares: 0 })
        );

        uint256 sharesIn = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);

        // make sure that the passive pool withdrawal works
        vm.prank(user);
        uint256 amountOut = IPassivePoolProxy(sec.pool).removeLiquidity(
            sec.passivePoolId, sharesIn, 0, ActionMetadata({ action: Action.Unstake, onBehalfOf: user })
        );
        assertApproxEqAbsDecimal(amountOut, 10e6, 10, 6);

        // create new account and deposit 33000 USDe in it
        deal(sec.usde, address(sec.periphery), 33_000e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], 33_000e18);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        // user executes short trade on ETH
        executeCoreMatchOrder({ marketId: 1, sender: user, base: sd(-10e18), priceLimit: ud(0), accountId: accountId });

        // user closes the short trade on ETH and goes same long
        executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(20e18),
            priceLimit: ud(type(uint256).max),
            accountId: accountId
        });

        // withdraw 100 USDe from account
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.usde, 100e18, sec.destinationChainId);
    }

    function check_PassivePoolWithSusde() public {
        mockFreshPrices();

        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.susde);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.susde, collateralConfig, parentCollateralConfig);

        (address user, uint256 userPk) = makeAddrAndKey("user");

        uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        // add 3000 sUSDe to the passive pool directly
        deal(sec.susde, address(sec.periphery), 3000e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], 3000e18);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: sec.passivePoolAccountId, token: address(sec.susde) })
        );

        uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
        assertApproxEqRelDecimal(sharePrice1, sharePrice0, 0.005e18, 18);

        // make sure that the passive pool deposit works
        deal(sec.usdc, sec.periphery, 10e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(10e6)
        );

        IPeripheryProxy(sec.periphery).depositPassivePool(
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: user, minShares: 0 })
        );

        uint256 sharesIn = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);

        // make sure that the passive pool withdrawal works
        vm.prank(user);
        uint256 amountOut = IPassivePoolProxy(sec.pool).removeLiquidity(
            sec.passivePoolId, sharesIn, 0, ActionMetadata({ action: Action.Unstake, onBehalfOf: user })
        );
        assertApproxEqAbsDecimal(amountOut, 10e6, 10, 6);

        // create new account and deposit 33000 sUSDe in it
        deal(sec.susde, address(sec.periphery), 33_000e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], 33_000e18);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
        );

        // user executes short trade on ETH
        executeCoreMatchOrder({ marketId: 1, sender: user, base: sd(-10e18), priceLimit: ud(0), accountId: accountId });

        // user closes the short trade on ETH and goes same long
        executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(20e18),
            priceLimit: ud(type(uint256).max),
            accountId: accountId
        });

        // withdraw 100 sUSDe from account
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.susde, 100e18, sec.destinationChainId);
    }

    function check_PassivePoolWithDeusd() public {
        mockFreshPrices();

        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.deusd);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.deusd, collateralConfig, parentCollateralConfig);

        (address user, uint256 userPk) = makeAddrAndKey("user");

        uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        // add 3000 deUSD to the passive pool directly
        deal(sec.deusd, address(sec.periphery), 3000e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.deusd], 3000e18);
        vm.prank(dec.socketExecutionHelper[sec.deusd]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: sec.passivePoolAccountId, token: address(sec.deusd) })
        );

        uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
        assertApproxEqRelDecimal(sharePrice1, sharePrice0, 0.005e18, 18);

        // make sure that the passive pool deposit works
        deal(sec.usdc, sec.periphery, 10e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(10e6)
        );

        IPeripheryProxy(sec.periphery).depositPassivePool(
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: user, minShares: 0 })
        );

        uint256 sharesIn = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);

        // make sure that the passive pool withdrawal works
        vm.prank(user);
        uint256 amountOut = IPassivePoolProxy(sec.pool).removeLiquidity(
            sec.passivePoolId, sharesIn, 0, ActionMetadata({ action: Action.Unstake, onBehalfOf: user })
        );
        assertApproxEqAbsDecimal(amountOut, 10e6, 10, 6);

        // create new account and deposit 33000 deUSD in it
        deal(sec.deusd, address(sec.periphery), 33_000e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.deusd], 33_000e18);
        vm.prank(dec.socketExecutionHelper[sec.deusd]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.deusd) })
        );

        // user executes short trade on ETH
        executeCoreMatchOrder({ marketId: 1, sender: user, base: sd(-10e18), priceLimit: ud(0), accountId: accountId });

        // user closes the short trade on ETH and goes same long
        executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(20e18),
            priceLimit: ud(type(uint256).max),
            accountId: accountId
        });

        // withdraw 100 deUSD from account
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.deusd, 100e18, sec.destinationChainId);
    }

    function check_PassivePoolWithSdeusd() public {
        mockFreshPrices();

        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.sdeusd);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.sdeusd, collateralConfig, parentCollateralConfig);

        (address user, uint256 userPk) = makeAddrAndKey("user");

        uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        // add 3000 sdeUSD to the passive pool directly
        deal(sec.sdeusd, address(sec.periphery), 3000e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.sdeusd], 3000e18);
        vm.prank(dec.socketExecutionHelper[sec.sdeusd]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: sec.passivePoolAccountId, token: address(sec.sdeusd) })
        );

        // check that the new 3000 sdeUSD does not influence the share price
        uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
        assertApproxEqRelDecimal(sharePrice1, sharePrice0, 0.005e18, 18);

        // make sure that the passive pool deposit works
        deal(sec.usdc, sec.periphery, 10e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(10e6)
        );

        IPeripheryProxy(sec.periphery).depositPassivePool(
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: user, minShares: 0 })
        );

        uint256 sharesIn = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);

        // make sure that the passive pool withdrawal works
        vm.prank(user);
        uint256 amountOut = IPassivePoolProxy(sec.pool).removeLiquidity(
            sec.passivePoolId, sharesIn, 0, ActionMetadata({ action: Action.Unstake, onBehalfOf: user })
        );
        assertApproxEqAbsDecimal(amountOut, 10e6, 10, 6);

        // create new account and deposit 33000 sdeUSD in it
        deal(sec.sdeusd, address(sec.periphery), 33_000e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.sdeusd], 33_000e18);
        vm.prank(dec.socketExecutionHelper[sec.sdeusd]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.sdeusd) })
        );

        // user executes short trade on ETH
        executeCoreMatchOrder({ marketId: 1, sender: user, base: sd(-10e18), priceLimit: ud(0), accountId: accountId });

        // user closes the short trade on ETH and goes same long
        executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(20e18),
            priceLimit: ud(type(uint256).max),
            accountId: accountId
        });

        // withdraw 100 sdeUSD from account
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.sdeusd, 100e18, sec.destinationChainId);
    }

    function check_PassivePoolWithRselini() public {
        mockFreshPrices();

        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.rselini);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.rselini, collateralConfig, parentCollateralConfig);

        (address user, uint256 userPk) = makeAddrAndKey("user");

        uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        // add 3000 rselini to the passive pool directly
        deal(sec.rselini, address(user), 3000e18);
        vm.prank(user);
        IERC20TokenModule(sec.rselini).approve(sec.core, 3000e18);
        vm.prank(user);
        ICoreProxy(sec.core).deposit({
            accountId: sec.passivePoolAccountId,
            collateral: address(sec.rselini),
            amount: 3000e6
        });

        // check that the new 3000 rselini does not influence the share price
        uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
        assertApproxEqRelDecimal(sharePrice1, sharePrice0, 0.005e18, 18);

        // make sure that the passive pool deposit works
        deal(sec.usdc, sec.periphery, 10e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(10e6)
        );

        IPeripheryProxy(sec.periphery).depositPassivePool(
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: user, minShares: 0 })
        );

        uint256 sharesIn = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);

        // make sure that the passive pool withdrawal works
        vm.prank(user);
        uint256 amountOut = IPassivePoolProxy(sec.pool).removeLiquidity(
            sec.passivePoolId, sharesIn, 0, ActionMetadata({ action: Action.Unstake, onBehalfOf: user })
        );
        assertApproxEqAbsDecimal(amountOut, 10e6, 10, 6);

        // create new account and deposit 33000 rselini in it
        uint128 accountId = depositNewMA(user, sec.rselini, 33_000e18);

        // user executes short trade on ETH
        executeCoreMatchOrder({ marketId: 1, sender: user, base: sd(-10e18), priceLimit: ud(0), accountId: accountId });

        // user closes the short trade on ETH and goes same long
        executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(20e18),
            priceLimit: ud(type(uint256).max),
            accountId: accountId
        });

        // withdraw 100 reselini from account
        withdrawMA(accountId, sec.rselini, 100e18);
    }

    function check_PassivePoolWithRamber() public {
        mockFreshPrices();

        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.ramber);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.ramber, collateralConfig, parentCollateralConfig);

        (address user, uint256 userPk) = makeAddrAndKey("user");

        uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        // add 3000 ramber to the passive pool directly

        deal(sec.ramber, address(user), 3000e18);
        vm.prank(user);
        IERC20TokenModule(sec.ramber).approve(sec.core, 3000e18);
        vm.prank(user);
        ICoreProxy(sec.core).deposit({
            accountId: sec.passivePoolAccountId,
            collateral: address(sec.ramber),
            amount: 3000e6
        });

        // check that the new 3000 ramber does not influence the share price
        uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
        assertApproxEqRelDecimal(sharePrice1, sharePrice0, 0.005e18, 18);

        // make sure that the passive pool deposit works
        deal(sec.usdc, sec.periphery, 10e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(10e6)
        );

        IPeripheryProxy(sec.periphery).depositPassivePool(
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: user, minShares: 0 })
        );

        uint256 sharesIn = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);

        // make sure that the passive pool withdrawal works
        vm.prank(user);
        uint256 amountOut = IPassivePoolProxy(sec.pool).removeLiquidity(
            sec.passivePoolId, sharesIn, 0, ActionMetadata({ action: Action.Unstake, onBehalfOf: user })
        );
        assertApproxEqAbsDecimal(amountOut, 10e6, 10, 6);

        // create new account and deposit 33000 ramber in it
        uint128 accountId = depositNewMA(user, sec.ramber, 33_000e18);

        // user executes short trade on ETH
        executeCoreMatchOrder({ marketId: 1, sender: user, base: sd(-10e18), priceLimit: ud(0), accountId: accountId });

        // user closes the short trade on ETH and goes same long
        executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(20e18),
            priceLimit: ud(type(uint256).max),
            accountId: accountId
        });

        // withdraw 100 reselini from account
        withdrawMA(accountId, sec.ramber, 100e18);
    }

    function autoRebalancePool(bool partialAutoRebalance, bool mintLmTokens) internal {
        removeCollateralWithdrawalLimit(sec.rusd);
        removeCollateralWithdrawalLimit(sec.deusd);
        removeCollateralWithdrawalLimit(sec.sdeusd);
        removeCollateralWithdrawalLimit(sec.rselini);
        removeCollateralWithdrawalLimit(sec.ramber);

        removeCollateralCap(sec.rselini);
        removeCollateralCap(sec.ramber);

        address quoteToken = sec.rusd;
        address[] memory supportingTokens = IPassivePoolProxy(sec.pool).getQuoteSupportingCollaterals(sec.passivePoolId);

        address[] memory allTokens = new address[](supportingTokens.length + 1);
        allTokens[0] = quoteToken;
        for (uint256 i = 0; i < supportingTokens.length; i++) {
            allTokens[i + 1] = supportingTokens[i];
        }

        for (uint256 i = 0; i < allTokens.length; i++) {
            for (uint256 j = 0; j < allTokens.length; j++) {
                if (i == j) {
                    continue;
                }

                address tokenIn = allTokens[i];
                address tokenOut = allTokens[j];

                uint256 amountIn = 100_000_000 * (10 ** IERC20TokenModule(tokenIn).decimals());

                RebalanceAmounts memory rebalanceAmounts =
                    IPassivePoolProxy(sec.pool).getRebalanceAmounts(sec.passivePoolId, tokenIn, tokenOut, amountIn);

                if (rebalanceAmounts.amountIn != 0) {
                    uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

                    if (partialAutoRebalance) {
                        rebalanceAmounts.amountIn = rebalanceAmounts.amountIn / 2;
                    }

                    if (isLmToken(tokenIn) && mintLmTokens) {
                        vm.prank(sec.poolRebalancer);
                        IERC20TokenModule(tokenIn).mint(sec.poolRebalancer, rebalanceAmounts.amountIn);
                    } else {
                        deal(tokenIn, sec.poolRebalancer, rebalanceAmounts.amountIn);
                    }

                    vm.prank(sec.poolRebalancer);
                    IERC20TokenModule(tokenIn).approve(sec.pool, rebalanceAmounts.amountIn);

                    vm.prank(sec.poolRebalancer);
                    IPassivePoolProxy(sec.pool).triggerAutoRebalance(
                        sec.passivePoolId,
                        AutoRebalanceInput({
                            tokenIn: tokenIn,
                            amountIn: rebalanceAmounts.amountIn,
                            tokenOut: tokenOut,
                            minPrice: rebalanceAmounts.priceInToOut,
                            receiverAddress: sec.periphery
                        })
                    );

                    uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

                    assertLe(sharePrice0, sharePrice1 + 1e6);
                    assertApproxEqAbsDecimal(sharePrice0, sharePrice1, 1e11, 18);

                    if (partialAutoRebalance) {
                        return;
                    }

                    vm.warp(block.timestamp + 1);
                }
            }
        }
    }

    function check_autoRebalance_currentTargets(bool mintLmTokens) public {
        autoRebalancePool(false, mintLmTokens);
    }

    function check_autoRebalance_differentTargets(bool partialAutoRebalance, bool mintLmTokens) public {
        removeCollateralCap(sec.rselini);
        removeCollateralCap(sec.ramber);

        vm.prank(sec.multisig);
        IPassivePoolProxy(sec.pool).setAllocationConfiguration(
            sec.passivePoolId, AllocationConfigurationData({ quoteTokenTargetRatio: 0.353535e18 })
        );

        vm.prank(sec.multisig);
        IPassivePoolProxy(sec.pool).setTargetRatioPostQuote(sec.passivePoolId, sec.sdeusd, 0.454545e18);
        vm.prank(sec.multisig);
        IPassivePoolProxy(sec.pool).setTargetRatioPostQuote(sec.passivePoolId, sec.rselini, 0.2e18);
        vm.prank(sec.multisig);
        IPassivePoolProxy(sec.pool).setTargetRatioPostQuote(sec.passivePoolId, sec.ramber, 1e18 - 0.454545e18 - 0.2e18);

        autoRebalancePool(partialAutoRebalance, mintLmTokens);
    }

    function check_autoRebalance_noSharePriceChange() public {
        check_autoRebalance_differentTargets(false, false);
    }

    function check_autoRebalance_maxExposure() public {
        (uint256 maxExposureShort0, uint256 maxExposureLong0) =
            IPassivePerpProxy(sec.perp).getPoolMaxExposures(sec.passivePoolId);

        check_autoRebalance_differentTargets(false, false);

        (uint256 maxExposureShort1, uint256 maxExposureLong1) =
            IPassivePerpProxy(sec.perp).getPoolMaxExposures(sec.passivePoolId);

        assertNotEq(maxExposureShort0, maxExposureShort1);
        assertNotEq(maxExposureLong0, maxExposureLong1);
        assertApproxEqRelDecimal(maxExposureShort0, maxExposureShort1, 0.075e18, 18);
        assertApproxEqRelDecimal(maxExposureLong0, maxExposureLong1, 0.075e18, 18);
    }

    function check_autoRebalance_instantaneousPrice() public {
        uint128 marketId = 1;
        int256 baseDelta = 10_000e18;

        uint256 simulatedPrice0 = IPassivePerpProxy(sec.perp).getSimulatedPoolPrice(marketId, baseDelta);
        check_autoRebalance_differentTargets(false, false);
        uint256 simulatedPrice1 = IPassivePerpProxy(sec.perp).getSimulatedPoolPrice(marketId, baseDelta);

        assertNotEq(simulatedPrice0, simulatedPrice1);
        assertApproxEqRelDecimal(simulatedPrice0, simulatedPrice1, 0.075e18, 18);
    }

    function check_sharePriceChangesWhenAssetPriceChanges() public {
        autoRebalancePool(false, false);

        uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        (, ParentCollateralConfig memory deusdParentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.deusd);
        (, ParentCollateralConfig memory sdeusdParentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.sdeusd);

        NodeOutput.Data memory deusdOutput =
            IOracleManagerProxy(sec.oracleManager).process(deusdParentCollateralConfig.oracleNodeId);
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (deusdParentCollateralConfig.oracleNodeId)),
            abi.encode(
                NodeOutput.Data({ price: ud(deusdOutput.price).mul(ud(0.99e18)).unwrap(), timestamp: block.timestamp })
            )
        );

        NodeOutput.Data memory sdeusdOutput =
            IOracleManagerProxy(sec.oracleManager).process(sdeusdParentCollateralConfig.oracleNodeId);
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sdeusdParentCollateralConfig.oracleNodeId)),
            abi.encode(
                NodeOutput.Data({ price: ud(sdeusdOutput.price).mul(ud(1.01e18)).unwrap(), timestamp: block.timestamp })
            )
        );

        uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        assertNotEq(sharePrice0, sharePrice1);
        assertApproxEqRelDecimal(sharePrice0, sharePrice1, 0.01e18, 18);
    }

    function check_autoRebalance_revertWhenSenderIsNotRebalancer() public {
        vm.prank(address(5555));
        vm.expectRevert(
            abi.encodeWithSelector(
                IPassivePoolProxy.FeatureUnavailable.selector,
                keccak256(abi.encode(keccak256(bytes("autoRebalance")), sec.passivePoolId))
            )
        );
        IPassivePoolProxy(sec.pool).triggerAutoRebalance(
            sec.passivePoolId,
            AutoRebalanceInput({
                tokenIn: address(0),
                amountIn: 0,
                tokenOut: address(0),
                minPrice: 0,
                receiverAddress: address(0)
            })
        );
    }

    function checkFuzz_depositWithdrawV2_noSharePriceChange(
        uint128[] memory tokensFuzz,
        int256[] memory amountsFuzz
    )
        public
    {
        vm.assume(tokensFuzz.length <= 10);
        vm.assume(amountsFuzz.length <= 10);

        uint256 len = (tokensFuzz.length < amountsFuzz.length) ? tokensFuzz.length : amountsFuzz.length;

        address[] memory tokens = new address[](len);
        int256[] memory amounts = new int256[](len);

        for (uint256 i = 0; i < len; i++) {
            address token;
            uint128 tokenFuzz = tokensFuzz[i] % 4;
            if (tokenFuzz == 0) {
                token = sec.rusd;
            } else if (tokenFuzz == 1) {
                token = sec.sdeusd;
            } else if (tokenFuzz == 2) {
                token = sec.rselini;
            } else if (tokenFuzz == 3) {
                token = sec.ramber;
            }
            tokens[i] = token;
            if (amountsFuzz[i] < 0) {
                if (amountsFuzz[i] == type(int256).min) {
                    amountsFuzz[i] += 1;
                }
                amounts[i] = (-1000 + int256((uint256(-amountsFuzz[i]) % 1000)))
                    * int256(10 ** IERC20TokenModule(token).decimals());
            } else {
                amounts[i] =
                    int256((uint256(amountsFuzz[i]) % 1000)) * int256(10 ** IERC20TokenModule(token).decimals());
            }
        }

        address owner = vm.addr(333_222);
        vm.prank(sec.multisig);
        IPassivePoolProxy(sec.pool).addToFeatureFlagAllowlist(
            keccak256(abi.encode(keccak256(bytes("v2Liquidity")), sec.passivePoolId)), owner
        );

        for (uint256 i = 0; i < len; i++) {
            uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
            if (amounts[i] > 0) {
                uint256 amount = uint256(amounts[i]);
                if (amount == 0) {
                    continue;
                }

                deal(tokens[i], owner, amount);
                vm.prank(owner);
                IERC20TokenModule(tokens[i]).approve(sec.pool, amount);
                vm.prank(owner);
                IPassivePoolProxy(sec.pool).addLiquidityV2({
                    poolId: sec.passivePoolId,
                    input: AddLiquidityV2Input({ token: tokens[i], amount: amount, owner: owner, minShares: 0 }),
                    actionMetadata: ActionMetadata({ action: Action.Stake, onBehalfOf: owner })
                });
            } else {
                uint256 amount = uint256(-amounts[i]);

                uint256 poolTokenBalance =
                    uint256(ICoreProxy(sec.core).getTokenMarginInfo(sec.passivePoolId, tokens[i]).marginBalance);
                if (amount > poolTokenBalance) {
                    amount = poolTokenBalance;
                }

                uint256 sharesAmount = amount * 99 / 100 * 10 ** (30 - IERC20TokenModule(tokens[i]).decimals());
                uint256 ownerSharesAmount = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, owner);
                if (ownerSharesAmount < sharesAmount) {
                    sharesAmount = ownerSharesAmount;
                }

                if (sharesAmount == 0) {
                    continue;
                }

                vm.prank(owner);
                IPassivePoolProxy(sec.pool).removeLiquidityV2({
                    poolId: sec.passivePoolId,
                    input: RemoveLiquidityV2Input({
                        token: tokens[i],
                        sharesAmount: sharesAmount,
                        receiver: owner,
                        minOut: 0
                    }),
                    actionMetadata: ActionMetadata({ action: Action.Unstake, onBehalfOf: owner })
                });
            }

            uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

            assertLe(sharePrice0, sharePrice1);
            assertApproxEqRelDecimal(sharePrice0, sharePrice1, 1e12, 18);
        }
    }

    function check_depositWithdrawV2_revertWhenOwnerIsNotAuthorized() public {
        address owner = vm.addr(333_222);

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(IPassivePoolProxy.UnauthorizedV2Liquidity.selector, sec.passivePoolAccountId, owner)
        );
        IPassivePoolProxy(sec.pool).addLiquidityV2({
            poolId: sec.passivePoolId,
            input: AddLiquidityV2Input({ token: sec.rusd, amount: 0, owner: owner, minShares: 0 }),
            actionMetadata: ActionMetadata({ action: Action.Stake, onBehalfOf: owner })
        });
    }

    function check_depositV2_revertWhenTokenHasZeroTargetRatio(address token) public {
        address owner = vm.addr(333_222);

        vm.prank(sec.multisig);
        IPassivePoolProxy(sec.pool).addToFeatureFlagAllowlist(
            keccak256(abi.encode(keccak256(bytes("v2Liquidity")), sec.passivePoolId)), owner
        );

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IPassivePoolProxy.TokenNotEligibleForShares.selector, token));
        IPassivePoolProxy(sec.pool).addLiquidityV2({
            poolId: sec.passivePoolId,
            input: AddLiquidityV2Input({ token: token, amount: 1e18, owner: owner, minShares: 0 }),
            actionMetadata: ActionMetadata({ action: Action.Stake, onBehalfOf: owner })
        });
    }

    function check_setTokenTargetRatio_revertWhenTokenIsNotSupportingCollateral(address token) public {
        vm.prank(sec.multisig);
        vm.expectRevert(abi.encodeWithSelector(IPassivePoolProxy.TokenNotSupportingCollateral.selector, token));
        IPassivePoolProxy(sec.pool).setTargetRatioPostQuote(sec.passivePoolId, token, 0.1e18);
    }
}
