pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { IPassivePerpProxy, MarketConfigurationData } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud } from "@prb/math/UD60x18.sol";

contract FundingRateForkCheck is BaseReyaForkTest {
    function setPriceSpacing(uint128 marketId, uint256 newPriceSpacing) private {
        MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
        marketConfig.priceSpacing = newPriceSpacing;

        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).setMarketConfiguration(marketId, marketConfig);
    }

    function check_FundingVelocity(uint128 marketId) public {
        mockFreshPrices();
        removeMarketsOILimit();

        setPriceSpacing({ marketId: marketId, newPriceSpacing: 1 });

        (address user,) = makeAddrAndKey("user");

        // deposit new margin account to be able to trade little to get pSlippage
        deal(sec.usdc, address(sec.periphery), 1_000_000e6);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], 1_000_000e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usdc) })
        );

        (, SD59x18 pSlippage) = executeCoreMatchOrder({
                marketId: marketId,
                sender: user,
                base: sd(-1e18),
                priceLimit: ud(0),
                accountId: accountId
            });

        int256 fundingRate1 = IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId);
        vm.warp(block.timestamp + 86_400);
        int256 fundingRate2 = IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId);

        MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
        assertApproxEqAbsDecimal(
            fundingRate2 - fundingRate1,
            pSlippage.mul(sd(int256(marketConfig.velocityMultiplier))).unwrap(),
            1e5,
            18
        );
    }
}
