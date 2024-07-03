pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud } from "@prb/math/UD60x18.sol";

contract FundingRateForkCheck is BaseReyaForkTest {
    function check_FundingVelocity() public {
        (address user,) = makeAddrAndKey("user");

        // deposit new margin account to be able to trade little to get pSlippage
        deal(sec.usdc, address(sec.periphery), 1_000_000e6);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], 1_000_000e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usdc) })
        );

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

        (, SD59x18 solPSlippage) = executeCoreMatchOrder({
            marketId: 3,
            sender: user,
            base: sd(-0.7e18),
            priceLimit: ud(0),
            accountId: accountId
        });

        int256 ethFundingRate1 = IPassivePerpProxy(sec.perp).getLatestFundingRate(1);
        int256 btcFundingRate1 = IPassivePerpProxy(sec.perp).getLatestFundingRate(2);
        int256 solFundingRate1 = IPassivePerpProxy(sec.perp).getLatestFundingRate(3);

        vm.warp(block.timestamp + 86_400);

        int256 ethFundingRate2 = IPassivePerpProxy(sec.perp).getLatestFundingRate(1);
        int256 btcFundingRate2 = IPassivePerpProxy(sec.perp).getLatestFundingRate(2);
        int256 solFundingRate2 = IPassivePerpProxy(sec.perp).getLatestFundingRate(3);

        // todo: p1: double check with 0.26
        assertApproxEqAbsDecimal(ethFundingRate2 - ethFundingRate1, ethPSlippage.unwrap() * 1e18 / 1e18, 1e13, 18);
        assertApproxEqAbsDecimal(btcFundingRate2 - btcFundingRate1, btcPSlippage.unwrap() * 1e18 / 1e18, 1e13, 18);
        assertApproxEqAbsDecimal(solFundingRate2 - solFundingRate1, solPSlippage.unwrap() * 1e18 / 1e18, 1e13, 18);
    }
}
