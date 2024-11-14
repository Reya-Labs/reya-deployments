pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { IYakRouter } from "../../../src/interfaces/IYakRouter.sol";
import { ICoreProxy, Command as Command_Core, CommandType } from "../../../src/interfaces/ICoreProxy.sol";
import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

contract CamelotSwapForkCheck is BaseReyaForkTest {
    address alice;
    uint256 alicePk;

    constructor() {
        (alice, alicePk) = makeAddrAndKey("alice");
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
}
