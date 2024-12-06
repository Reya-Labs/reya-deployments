pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { IYakRouter } from "../../../src/interfaces/IYakRouter.sol";
import {
    ICoreProxy,
    Command as Command_Core,
    CommandType,
    ProtocolConfiguration,
    MarginInfo
} from "../../../src/interfaces/ICoreProxy.sol";
import {
    IPeripheryProxy,
    DepositNewMAInputs,
    Command as Command_Periphery,
    DepositExistingMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";
import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";
import { IAdapter } from "../../../src/interfaces/IAdapter.sol";
import { IERC20TokenModule } from "../../../src/interfaces/IERC20TokenModule.sol";

import { ud, UD60x18 } from "@prb/math/UD60x18.sol";
import { sd, SD59x18 } from "@prb/math/SD59x18.sol";

contract MaliciousAdapter is IAdapter {
    IAdapter public immutable originalAdapter;
    uint128 public liquidatableAccountId;
    uint128 public keeperAccountId;
    ICoreProxy public core;
    address public rusd;

    constructor(IAdapter _originalAdapter, uint128 _liquidatableAccountId, ICoreProxy _core, address _rusd) {
        originalAdapter = _originalAdapter;
        liquidatableAccountId = _liquidatableAccountId;
        core = _core;
        rusd = _rusd;

        keeperAccountId = core.createAccount(address(this));
    }

    function name() external view override returns (string memory) {
        return originalAdapter.name();
    }

    function swapGasEstimate() external view override returns (uint256) {
        return originalAdapter.swapGasEstimate();
    }

    function swap(
        uint256 amountIn,
        uint256 param1,
        address token1,
        address token2,
        address recipient
    )
        external
        override
    {
        core.executeBackstopLiquidation({
            liquidatableAccountId: liquidatableAccountId,
            keeperAccountId: keeperAccountId,
            quoteCollateral: rusd,
            backstopPercentage: 1e18
        });
        originalAdapter.swap(amountIn, param1, token1, token2, recipient);
    }

    function query(
        uint256 amountIn,
        address token1,
        address token2
    )
        external
        view
        override
        returns (uint256, address)
    {
        return originalAdapter.query(amountIn, token1, token2);
    }
}

contract CamelotSwapForkCheck is BaseReyaForkTest {
    address alice;
    uint256 alicePk;

    constructor() {
        (alice, alicePk) = makeAddrAndKey("alice");
        vm.prank(sec.multisig);
        ICoreProxy(sec.core).addToFeatureFlagAllowlist(keccak256(bytes("camelotSwapPublisher")), alice);
    }

    function setUp() public {
        mockFreshPrices();
    }

    function getCamelotSwapCommand(
        address fromToken,
        uint256 fromTokenAmount,
        address toToken,
        uint256 minToTokenAmount
    )
        internal
        view
        returns (Command_Core memory)
    {
        address[] memory supportingCollaterals = ICoreProxy(sec.core).getSupportingCollaterals(1, sec.rusd);
        address[] memory trustedTokens = new address[](supportingCollaterals.length + 1);
        trustedTokens[0] = fromToken;
        for (uint256 i = 0; i < supportingCollaterals.length; i++) {
            trustedTokens[i + 1] = supportingCollaterals[i];
        }

        IYakRouter.FormattedOffer memory formattedOffer = IYakRouter(sec.camelotYakRouter).findBestPath({
            _amountIn: fromTokenAmount,
            _tokenIn: fromToken,
            _tokenOut: toToken,
            _trustedTokens: trustedTokens,
            _maxSteps: 4
        });

        Command_Core memory command = Command_Core({
            commandType: uint8(CommandType.CamelotSwap),
            inputs: abi.encode(
                IYakRouter.Trade({
                    amountIn: fromTokenAmount,
                    amountOut: minToTokenAmount,
                    path: formattedOffer.path,
                    adapters: formattedOffer.adapters,
                    recipients: formattedOffer.recipients
                })
            ),
            marketId: 0,
            exchangeId: 0
        });

        return command;
    }

    function executeCamelotSwap(
        uint128 accountId,
        address fromToken,
        uint256 fromTokenAmount,
        address toToken,
        uint256 minToTokenAmount
    )
        internal
    {
        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] = getCamelotSwapCommand(fromToken, fromTokenAmount, toToken, minToTokenAmount);

        uint256 coreFromTokenBalanceBefore = IERC20TokenModule(fromToken).balanceOf(sec.core);
        uint256 coreToTokenBalanceBefore = IERC20TokenModule(toToken).balanceOf(sec.core);

        vm.prank(alice);
        ICoreProxy(sec.core).execute(accountId, commands);

        uint256 coreFromTokenBalanceAfter = IERC20TokenModule(fromToken).balanceOf(sec.core);
        uint256 coreToTokenBalanceAfter = IERC20TokenModule(toToken).balanceOf(sec.core);

        assertEq(coreFromTokenBalanceBefore - coreFromTokenBalanceAfter, fromTokenAmount);
        assertGt(coreToTokenBalanceAfter - coreToTokenBalanceBefore, minToTokenAmount);
    }

    function check_DepositRusdAndSwapWeth_NoCP() internal {
        uint256 rusdAmount = 100e6;
        uint256 minWethAmount = 0.02e18;

        deal(sec.usdc, address(sec.periphery), rusdAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], rusdAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: alice, token: address(sec.usdc) })
        );

        executeCamelotSwap(accountId, sec.rusd, rusdAmount, sec.weth, minWethAmount);
    }

    function check_DepositRusdAndTradeAndSwapWeth() internal {
        uint256 rusdAmount = 100e6;
        uint256 minWethAmount = 0.02e18;
        uint128 marketId = 1;
        SD59x18 base = sd(0.01e18);
        UD60x18 tier0Fee = ud(0.0005e18);

        deal(sec.usdc, address(sec.periphery), rusdAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], rusdAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: alice, token: address(sec.usdc) })
        );

        executePeripheryMatchOrder({
            userPrivateKey: alicePk,
            incrementedNonce: 1,
            marketId: marketId,
            base: base,
            priceLimit: ud(10_000e18),
            accountId: accountId
        });

        uint256 takerFees = baseToExposure(marketId, base).intoUD60x18().mul(tier0Fee).unwrap();

        executeCamelotSwap(accountId, sec.rusd, rusdAmount - takerFees / 1e12 * 1.01e18 / 1e18, sec.weth, minWethAmount);
    }

    function check_DepositRusdAndTradeAndSwapWeth_Periphery() internal {
        uint256 rusdAmount = 100e6;
        uint256 minWethAmount = 0.02e18;
        uint128 marketId = 1;
        SD59x18 base = sd(0.01e18);
        UD60x18 tier0Fee = ud(0.0005e18);

        deal(sec.usdc, address(sec.periphery), rusdAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], rusdAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: alice, token: address(sec.usdc) })
        );

        uint256 takerFees = baseToExposure(marketId, base).intoUD60x18().mul(tier0Fee).unwrap();

        Command_Periphery[] memory commands = new Command_Periphery[](2);
        commands[0] = getMatchOrderPeripheryCommand(marketId, base, ud(10_000e18));
        commands[1] = convertCoreCommandToPeripheryCommand(
            getCamelotSwapCommand(sec.rusd, rusdAmount - takerFees / 1e12 * 1.01e18 / 1e18, sec.weth, minWethAmount)
        );

        vm.prank(sec.multisig);
        ICoreProxy(sec.core).addToFeatureFlagAllowlist(keccak256(bytes("camelotSwapPublisher")), sec.periphery);
        executePeripheryCommands(accountId, commands, alicePk, 1);
    }

    function check_SwapAEAccount() internal {
        // deposit 0.1 weth
        uint256 wethAmount = 0.1e18;
        deal(sec.weth, address(sec.periphery), wethAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], wethAmount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: alice, token: address(sec.weth) })
        );

        uint256 ethUsdcPrice = IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdcStorkNodeId).price;

        // user executes short trade on ETH
        (UD60x18 orderPrice,) = executeCoreMatchOrder({
            marketId: 1,
            sender: alice,
            base: sd(-0.1e18),
            priceLimit: ud(0),
            accountId: accountId
        });

        // price moves by 600 USD
        uint256 bumpedEthPrice = orderPrice.unwrap() + 600e18;
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkNodeId)),
            abi.encode(NodeOutput.Data({ price: bumpedEthPrice, timestamp: block.timestamp }))
        );
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkMarkNodeId)),
            abi.encode(NodeOutput.Data({ price: bumpedEthPrice, timestamp: block.timestamp }))
        );

        // assert account is healthy but AE-able
        MarginInfo memory accountMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertGtDecimal(accountMarginInfo.initialDelta, 0, 18);
        uint256 maxQuoteToCover = ICoreProxy(sec.core).calculateMaxQuoteToCoverInAutoExchange(accountId, sec.rusd);
        assertGtDecimal(maxQuoteToCover, 0, 18);

        // swap max quote to cover
        // liquidity is thin, going to add big buffer
        uint256 maxQuoteToCoverInWETHWithBuffer =
            ud(maxQuoteToCover * 1e12).div(ud(ethUsdcPrice)).mul(ud(1.5e18)).unwrap();
        executeCamelotSwap(accountId, sec.weth, maxQuoteToCoverInWETHWithBuffer, sec.rusd, maxQuoteToCover);

        // assert account is healthy and not AE-able
        accountMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertGtDecimal(accountMarginInfo.initialDelta, 0, 18);
        maxQuoteToCover = ICoreProxy(sec.core).calculateMaxQuoteToCoverInAutoExchange(accountId, sec.rusd);
        assertEq(maxQuoteToCover, 0);
    }

    function check_RevertWhen_DepositRusdAndTradeAndSwapWeth_AttemptBackstopLiquidation() internal {
        uint256 rusdAmount = 100e6;
        uint256 minWethAmount = 0.02e18;
        uint128 marketId = 1;
        SD59x18 base = sd(0.01e18);
        UD60x18 tier0Fee = ud(0.0005e18);

        deal(sec.usdc, address(sec.periphery), rusdAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], rusdAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: alice, token: address(sec.usdc) })
        );

        executePeripheryMatchOrder({
            userPrivateKey: alicePk,
            incrementedNonce: 1,
            marketId: marketId,
            base: base,
            priceLimit: ud(10_000e18),
            accountId: accountId
        });

        uint256 takerFees = baseToExposure(marketId, base).intoUD60x18().mul(tier0Fee).unwrap();

        // get camelot command and use malicious adapter
        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] =
            getCamelotSwapCommand(sec.rusd, rusdAmount - takerFees / 1e12 * 1.01e18 / 1e18, sec.weth, minWethAmount);
        IYakRouter.Trade memory trade = abi.decode(commands[0].inputs, (IYakRouter.Trade));
        trade.adapters[0] =
            address(new MaliciousAdapter(IAdapter(trade.adapters[0]), accountId, ICoreProxy(sec.core), sec.rusd));
        commands[0].inputs = abi.encode(trade);

        // account will not have much rusd in the account, but it will have exposure
        // account is eligible for backstop liquidation without any upnl mocking

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ICoreProxy.GlobalLockOn.selector));
        ICoreProxy(sec.core).execute(accountId, commands);
    }

    function check_RevertWhen_DepositRusdAndSwapMore_NoCP() internal {
        uint256 rusdAmount = 100e6;
        uint256 minWethAmount = 0.02e18;

        deal(sec.usdc, address(sec.periphery), rusdAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], rusdAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: alice, token: address(sec.usdc) })
        );

        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] = getCamelotSwapCommand(sec.rusd, rusdAmount + 1, sec.weth, minWethAmount);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ICoreProxy.NegativeAccountRealBalance.selector, accountId, -1));
        ICoreProxy(sec.core).execute(accountId, commands);
    }

    function check_RevertWhen_DepositRusdAndTradeAndSwapUnsupportedTokenWbtc() internal {
        uint256 rusdAmount = 100e6;
        uint128 marketId = 1;
        SD59x18 base = sd(0.01e18);

        deal(sec.usdc, address(sec.periphery), rusdAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], rusdAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: alice, token: address(sec.usdc) })
        );

        executePeripheryMatchOrder({
            userPrivateKey: alicePk,
            incrementedNonce: 1,
            marketId: marketId,
            base: base,
            priceLimit: ud(10_000e18),
            accountId: accountId
        });

        address[] memory path = new address[](2);
        path[0] = sec.rusd;
        path[1] = sec.wbtc;

        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] = Command_Core({
            commandType: uint8(CommandType.CamelotSwap),
            inputs: abi.encode(
                IYakRouter.Trade({
                    amountIn: 1,
                    amountOut: 0,
                    path: path,
                    adapters: new address[](0),
                    recipients: new address[](0)
                })
            ),
            marketId: 0,
            exchangeId: 0
        });

        vm.mockCall(
            sec.camelotYakRouter,
            abi.encodeCall(
                IYakRouter.swapNoSplit,
                (
                    IYakRouter.Trade({
                        amountIn: 1,
                        amountOut: 0,
                        path: path,
                        adapters: new address[](0),
                        recipients: new address[](0)
                    }),
                    0,
                    sec.core
                )
            ),
            abi.encode()
        );

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ICoreProxy.GlobalCollateralNotFound.selector, sec.wbtc));
        ICoreProxy(sec.core).execute(accountId, commands);
    }

    function check_RevertWhen_YakRouterIsZero() internal {
        uint256 rusdAmount = 100e6;
        uint256 minWethAmount = 0.02e18;

        deal(sec.usdc, address(sec.periphery), rusdAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], rusdAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: alice, token: address(sec.usdc) })
        );

        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] = getCamelotSwapCommand(sec.rusd, rusdAmount, sec.weth, minWethAmount);

        ProtocolConfiguration.Data memory protocolConfig = ICoreProxy(sec.core).getProtocolConfiguration();
        protocolConfig.yakRouterAddress = address(0);
        vm.prank(sec.multisig);
        ICoreProxy(sec.core).configureProtocol(protocolConfig);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ICoreProxy.ZeroAddress.selector));
        ICoreProxy(sec.core).execute(accountId, commands);
    }

    function check_RevertWhen_MinAmountIsHigher() internal {
        uint256 rusdAmount = 100e6;
        uint256 minWethAmount = 0.1e18;

        deal(sec.usdc, address(sec.periphery), rusdAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], rusdAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: alice, token: address(sec.usdc) })
        );

        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] = getCamelotSwapCommand(sec.rusd, rusdAmount, sec.weth, minWethAmount);

        vm.prank(alice);
        vm.expectRevert("YakRouter: Insufficient output amount");
        ICoreProxy(sec.core).execute(accountId, commands);
    }

    function check_RevertWhen_WithdrawLimitIsBreached() internal {
        uint256 rusdAmount = 100_000_000e6;
        uint256 minWethAmount = 0.1e18;

        deal(sec.usdc, address(sec.periphery), rusdAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], rusdAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: alice, token: address(sec.usdc) })
        );

        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] = getCamelotSwapCommand(sec.rusd, rusdAmount, sec.weth, minWethAmount);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ICoreProxy.GlobalWithdrawLimitReached.selector, sec.rusd));
        ICoreProxy(sec.core).execute(accountId, commands);
    }

    // function check_RevertWhen_SwapAEAccount() internal {
    //     // deposit 0.1 weth
    //     uint256 wethAmount = 0.1e18;
    //     deal(sec.weth, address(sec.periphery), wethAmount);
    //     mockBridgedAmount(dec.socketExecutionHelper[sec.weth], wethAmount);
    //     vm.prank(dec.socketExecutionHelper[sec.weth]);
    //     uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
    //         DepositNewMAInputs({ accountOwner: alice, token: address(sec.weth) })
    //     );

    //     uint256 ethUsdcPrice = IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdcStorkNodeId).price;

    //     // user executes short trade on ETH
    //     (UD60x18 orderPrice,) = executeCoreMatchOrder({
    //         marketId: 1,
    //         sender: alice,
    //         base: sd(-0.1e18),
    //         priceLimit: ud(0),
    //         accountId: accountId
    //     });

    //     // price moves by 600 USD
    //     uint256 bumpedEthPrice = orderPrice.unwrap() + 600e18;
    //     vm.mockCall(
    //         sec.oracleManager,
    //         abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkNodeId)),
    //         abi.encode(NodeOutput.Data({ price: bumpedEthPrice, timestamp: block.timestamp }))
    //     );
    //     vm.mockCall(
    //         sec.oracleManager,
    //         abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkMarkNodeId)),
    //         abi.encode(NodeOutput.Data({ price: bumpedEthPrice, timestamp: block.timestamp }))
    //     );

    //     // assert account is healthy but AE-able
    //     MarginInfo memory accountMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
    //     assertGtDecimal(accountMarginInfo.initialDelta, 0, 18);
    //     uint256 maxQuoteToCover = ICoreProxy(sec.core).calculateMaxQuoteToCoverInAutoExchange(accountId, sec.rusd);
    //     assertGtDecimal(maxQuoteToCover, 0, 18);

    //     // swap weth for rusd and make sure it reverts
    //     Command_Core[] memory commands = new Command_Core[](1);
    //     commands[0] = getCamelotSwapCommand(sec.rusd, 1, sec.weth, 0);
    //     vm.prank(alice);
    //     vm.expectRevert(abi.encodeWithSelector(ICoreProxy.NegativeAccountRealBalance.selector, accountId,
    // -int256(maxQuoteToCover) - 1));
    //     ICoreProxy(sec.core).execute(accountId, commands);

    //     // deposit just a bit less than max quote to cover
    //     uint256 rusdAmount = maxQuoteToCover;
    //     deal(sec.usdc, address(sec.periphery), rusdAmount);
    //     mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], rusdAmount);
    //     vm.prank(dec.socketExecutionHelper[sec.usdc]);
    //     IPeripheryProxy(sec.periphery).depositExistingMA(
    //         DepositExistingMAInputs({ accountId: accountId, token: address(sec.usdc) })
    //     );

    //     // swap weth for rusd and make sure it reverts
    //     commands[0] = getCamelotSwapCommand(sec.rusd, 1, sec.weth, 0);
    //     vm.prank(alice);
    //     vm.expectRevert(abi.encodeWithSelector(ICoreProxy.NegativeAccountRealBalance.selector, accountId, -1));
    //     ICoreProxy(sec.core).execute(accountId, commands);
    // }

    function check_RevertWhen_SwapAndUnhealthyAccount() internal {
        removeMarketsOILimit();

        uint256 rusdAmount = 1_000_000e6;
        uint256 minWethAmount = 0.02e18;
        uint128 marketId = 1;
        SD59x18 base = sd(100e18);
        UD60x18 tier0Fee = ud(0.0005e18);

        deal(sec.usdc, address(sec.periphery), rusdAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], rusdAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: alice, token: address(sec.usdc) })
        );

        executePeripheryMatchOrder({
            userPrivateKey: alicePk,
            incrementedNonce: 1,
            marketId: marketId,
            base: base,
            priceLimit: ud(10_000e18),
            accountId: accountId
        });

        uint256 takerFees = baseToExposure(marketId, base).intoUD60x18().mul(tier0Fee).unwrap();

        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] =
            getCamelotSwapCommand(sec.rusd, rusdAmount - takerFees / 1e12 * 1.01e18 / 1e18, sec.weth, minWethAmount);
        vm.prank(alice);
        vm.expectPartialRevert(ICoreProxy.AccountBelowIM.selector);
        ICoreProxy(sec.core).execute(accountId, commands);
    }
}
