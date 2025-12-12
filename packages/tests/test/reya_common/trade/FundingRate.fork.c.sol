pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { IPassivePerpProxy, MarketConfigurationData } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud } from "@prb/math/UD60x18.sol";

contract FundingRateForkCheck is BaseReyaForkTest {
    function refreshingTrade(uint128 marketId) public {
        (address user,) = makeAddrAndKey("user");

        // deposit new margin account to be able to trade little to get pSlippage
        deal(sec.usdc, address(sec.periphery), 1_000_000e6);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], 1_000_000e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usdc) })
        );

        executeCoreMatchOrder({
            marketId: marketId,
            sender: user,
            base: sd(-1e18),
            priceLimit: ud(0),
            accountId: accountId
        });
    }

    function check_FundingVelocity(uint128 marketId) public {
        check_FundingVelocity(marketId, 1e9);
    }

    function check_FundingVelocity(uint128 marketId, uint256 eps) public {
        mockFreshPrices();
        removeMarketsOILimit();

        refreshingTrade(marketId);
        SD59x18 pSlippage = sd(IPassivePerpProxy(sec.perp).getPSlippage(marketId));

        int256 fundingRate1 = IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId);
        vm.warp(block.timestamp + 86_400);
        int256 fundingRate2 = IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId);

        MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
        assertApproxEqAbsDecimal(
            fundingRate2 - fundingRate1, pSlippage.mul(sd(int256(marketConfig.velocityMultiplier))).unwrap(), eps, 18
        );
    }
}
