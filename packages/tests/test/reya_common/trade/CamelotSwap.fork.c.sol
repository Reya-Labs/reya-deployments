pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { IYakRouter } from "../../../src/interfaces/IYakRouter.sol";
import { ICoreProxy, Command as Command_Core, CommandType } from "../../../src/interfaces/ICoreProxy.sol";
import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";
import { IAdapter } from "../../../src/interfaces/IAdapter.sol";

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

    function check_DepositRusdAndSwapWeth_NoCP() internal {
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
        vm.prank(alice);
        ICoreProxy(sec.core).execute(accountId, commands);
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

        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] =
            getCamelotSwapCommand(sec.rusd, rusdAmount - takerFees / 1e12 * 1.01e18 / 1e18, sec.weth, minWethAmount);
        vm.prank(alice);
        ICoreProxy(sec.core).execute(accountId, commands);
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
        // vm.expectRevert(abi.encodeWithSelector(ICoreProxy.GlobalLockOn.selector));
        ICoreProxy(sec.core).execute(accountId, commands);
    }
}
