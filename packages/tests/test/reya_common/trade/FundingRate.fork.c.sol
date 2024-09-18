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

    function check_FundingVelocity() public {
        mockFreshPrices();

        uint128 fromMarketId = 1;
        uint128 toMarketId = lastMarketId();

        // lower price spacing such that order price is not significantly
        // affected by price rounding. this was we can compute p slippage
        // more accurately
        for (uint128 marketId = fromMarketId; marketId <= toMarketId; marketId += 1) {
            setPriceSpacing({ marketId: marketId, newPriceSpacing: 1 });
        }

        (address user,) = makeAddrAndKey("user");

        // deposit new margin account to be able to trade little to get pSlippage
        deal(sec.usdc, address(sec.periphery), 1_000_000e6);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], 1_000_000e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usdc) })
        );

        SD59x18[] memory pSlippage = new SD59x18[](toMarketId - fromMarketId + 1);
        for (uint128 marketId = fromMarketId; marketId <= toMarketId; marketId += 1) {
            (, pSlippage[marketId - fromMarketId]) = executeCoreMatchOrder({
                marketId: marketId,
                sender: user,
                base: sd(-1e18),
                priceLimit: ud(0),
                accountId: accountId
            });
        }

        int256[] memory fundingRate1 = new int256[](toMarketId - fromMarketId + 1);
        for (uint128 marketId = fromMarketId; marketId <= toMarketId; marketId += 1) {
            fundingRate1[marketId - fromMarketId] = IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId);
        }

        vm.warp(block.timestamp + 86_400);

        int256[] memory fundingRate2 = new int256[](toMarketId - fromMarketId + 1);
        for (uint128 marketId = fromMarketId; marketId <= toMarketId; marketId += 1) {
            fundingRate2[marketId - fromMarketId] = IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId);
        }

        for (uint128 marketId = fromMarketId; marketId <= toMarketId; marketId += 1) {
            MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
            assertApproxEqAbsDecimal(
                fundingRate2[marketId - fromMarketId] - fundingRate1[marketId - fromMarketId],
                pSlippage[marketId - fromMarketId].mul(sd(int256(marketConfig.velocityMultiplier))).unwrap(),
                1e3,
                18
            );
        }
    }
}
