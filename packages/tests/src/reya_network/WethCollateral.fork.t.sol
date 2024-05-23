pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { ForkChecks } from "./ForkChecks.t.sol";
import {
    ICoreProxy,
    TriggerAutoExchangeInput,
    AutoExchangeAmounts,
    ParentCollateralConfig
} from "../interfaces/ICoreProxy.sol";
import { IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs } from "../interfaces/IPeripheryProxy.sol";
import { IOracleManagerProxy, NodeOutput } from "../interfaces/IOracleManagerProxy.sol";

import { sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract WethCollateral is ForkChecks {
    function test_WethTradeWithWethCollateral() public {
        (user, userPk) = makeAddrAndKey("user");

        (, ParentCollateralConfig memory parentCollateralConfig,) = ICoreProxy(core).getCollateralConfig(1, weth);
        uint256 priceHaircut = parentCollateralConfig.priceHaircut;

        // deposit 1 + 10 / (1-haircut) wETH
        uint256 amount = 1e18 + 10e18 * 1e18 / (1e18 - priceHaircut);
        deal(weth, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[weth], amount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(weth) }));

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
            uint256 currentPrice = IOracleManagerProxy(oracleManager).process(ethUsdcNodeId).price;
            fees = 10e6 * currentPrice / 1e18 * 0.0005e18 / 1e18;
        }

        // withdraw 1 wETH
        executePeripheryWithdrawMA(user, userPk, 1, accountId, weth, 1e18, arbitrumChainId);

        int256 marginBalance0 = ICoreProxy(core).getNodeMarginInfo(accountId, rusd).marginBalance;
        assertApproxEqAbsDecimal(marginBalance0 + int256(fees), 10e6 * int256(orderPrice.unwrap()) / 1e18, 0.1e6, 6);

        uint256[] memory randomPrices = new uint256[](4);
        randomPrices[0] = 3000e18;
        randomPrices[1] = 100_000e18;
        randomPrices[2] = orderPrice.unwrap() - 10e18;
        randomPrices[3] = orderPrice.unwrap() + 10e18;

        for (uint256 i = 0; i < 4; i++) {
            vm.mockCall(
                oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (ethUsdcNodeId)),
                abi.encode(NodeOutput.Data({ price: randomPrices[i], timestamp: block.timestamp }))
            );

            int256 marginBalance1 = ICoreProxy(core).getNodeMarginInfo(accountId, rusd).marginBalance;

            assertApproxEqAbsDecimal(marginBalance0, marginBalance1, 0.1e6, 6);
        }
    }
}
