pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import {
    ICoreProxy,
    CollateralConfig,
    ParentCollateralConfig,
    MarginInfo,
    CollateralInfo
} from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract WethCollateralForkCheck is BaseReyaForkTest {
    address user;
    uint256 userPk;

    function check_WethTradeWithWethCollateral() public {
        mockFreshPrices();

        (user, userPk) = makeAddrAndKey("user");

        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.weth);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.weth, collateralConfig, parentCollateralConfig);

        uint256 priceHaircut = parentCollateralConfig.priceHaircut;

        // deposit 1 + 10 / (1-haircut) wETH
        uint256 amount = 1e18 + 10e18 * 1e18 / (1e18 - priceHaircut);
        deal(sec.weth, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], amount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
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
            uint256 currentPrice =
                IOracleManagerProxy(sec.oracleManager).process(dec.oracleNodes["ethUsdStorkMark"]).price;
            fees = 10e6 * currentPrice / 1e18 * 0.001e18 / 1e18;
        }

        // withdraw 1 wETH
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.weth, 1e18, sec.destinationChainId);

        int256 marginBalance0 = ICoreProxy(sec.core).getNodeMarginInfo(accountId, sec.rusd).marginBalance;
        // TODO: when collateral WETH price points to Stork, lower the acceptance to 10 * 0.01e6
        assertApproxEqAbsDecimal(marginBalance0 + int256(fees), 10e6 * int256(orderPrice.unwrap()) / 1e18, 10 * 10e6, 6);

        uint256[] memory randomPrices = new uint256[](4);
        randomPrices[0] = 3000e18;
        randomPrices[1] = 100_000e18;
        randomPrices[2] = orderPrice.unwrap() - 10e18;
        randomPrices[3] = orderPrice.unwrap() + 10e18;

        for (uint256 i = 0; i < 4; i++) {
            vm.mockCall(
                sec.oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (dec.oracleNodes["ethUsdcStork"])),
                abi.encode(NodeOutput.Data({ price: randomPrices[i], timestamp: block.timestamp }))
            );

            vm.mockCall(
                sec.oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (dec.oracleNodes["ethUsdcStorkMark"])),
                abi.encode(NodeOutput.Data({ price: randomPrices[i], timestamp: block.timestamp }))
            );

            int256 marginBalance1 = ICoreProxy(sec.core).getNodeMarginInfo(accountId, sec.rusd).marginBalance;

            // TODO: when collateral WETH price points to Stork, lower the acceptance to 10 * 0.01e6
            assertApproxEqAbsDecimal(marginBalance0, marginBalance1, 10 * 10e6, 6);
        }
    }
}
