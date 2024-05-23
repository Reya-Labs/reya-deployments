pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { ForkChecks } from "./ForkChecks.t.sol";
import { ICoreProxy, TriggerAutoExchangeInput, AutoExchangeAmounts } from "../interfaces/ICoreProxy.sol";
import { IPassivePerpProxy } from "../interfaces/IPassivePerpProxy.sol";
import { IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs } from "../interfaces/IPeripheryProxy.sol";
import { IOracleManagerProxy, NodeOutput } from "../interfaces/IOracleManagerProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract FundingRateFork is ForkChecks {
    function test_FundingVelocity() public {
        (user, userPk) = makeAddrAndKey("user");

        // deposit new margin account to be able to trade little to get pSlippage
        deal(usdc, address(periphery), 1_000_000e6);
        mockBridgedAmount(socketExecutionHelper[usdc], 1_000_000e6);
        vm.prank(socketExecutionHelper[usdc]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(usdc) }));

        (, SD59x18 ethPSlippage) = executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(-0.035e18),
            priceLimit: ud(0),
            accountId: accountId
        });

        (, SD59x18 btcPSlippage) = executeCoreMatchOrder({
            marketId: 2,
            sender: user,
            base: sd(-0.0015e18),
            priceLimit: ud(0),
            accountId: accountId
        });

        int256 ethFundingRate1 = IPassivePerpProxy(perp).getLatestFundingRate(1);
        int256 btcFundingRate1 = IPassivePerpProxy(perp).getLatestFundingRate(2);

        vm.warp(block.timestamp + 86_400);

        int256 ethFundingRate2 = IPassivePerpProxy(perp).getLatestFundingRate(1);
        int256 btcFundingRate2 = IPassivePerpProxy(perp).getLatestFundingRate(2);

        assertApproxEqAbsDecimal(
            ethFundingRate2 - ethFundingRate1, ethPSlippage.unwrap() * 0.0034246e18 / 1e18, 1e12, 18
        );
        assertApproxEqAbsDecimal(
            btcFundingRate2 - btcFundingRate1, btcPSlippage.unwrap() * 0.0034246e18 / 1e18, 1e12, 18
        );
    }
}
