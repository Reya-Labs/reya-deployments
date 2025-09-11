pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";
import { ICoreProxy, CollateralInfo } from "../../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract OrderForkCheck is BaseReyaForkTest {
    int256 private constant BASIC_TIER_FEE_PERCENTAGE = 0.0004e18;

    function getMarketZeroFeesFeatureFlagId(uint128 marketId) internal pure returns (bytes32) {
        return keccak256(abi.encode(keccak256(bytes("marketZeroFees")), marketId));
    }

    function getExchangeZeroFeesFeatureFlagId(uint128 exchangeId) internal pure returns (bytes32) {
        return keccak256(abi.encode(keccak256(bytes("exchangeZeroFees")), exchangeId));
    }

    function check_MatchOrder_Fees(uint128 marketId) internal {
        removeMarketsOILimit();
        mockFreshPrices();

        vm.prank(sec.setMarketZeroFeeBot);
        IPassivePerpProxy(sec.perp).setFeatureFlagAllowAll(getMarketZeroFeesFeatureFlagId(marketId), false);

        (address user,) = makeAddrAndKey("user");
        uint256 amount = 1_000_000e6;
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1_000_000e18);

        // deposit new margin account
        uint128 accountId = depositNewMA(user, sec.usdc, amount);

        CollateralInfo memory preOrderBalance = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.rusd);

        (UD60x18 orderPrice,) = executeCoreMatchOrder({
            marketId: marketId,
            sender: user,
            base: base,
            priceLimit: priceLimit,
            accountId: accountId
        });

        CollateralInfo memory postOrderBalance = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.rusd);

        int256 expectedFees = orderPrice.intoSD59x18().mul(base).mul(sd(BASIC_TIER_FEE_PERCENTAGE)).unwrap() / 1e12;
        int256 paidFees = preOrderBalance.realBalance - postOrderBalance.realBalance;
        assertApproxEqAbs(paidFees, expectedFees, 0.0001e6);
    }

    function check_MatchOrder_ZeroFees(uint128 marketId) internal {
        removeMarketsOILimit();
        mockFreshPrices();

        vm.prank(sec.setMarketZeroFeeBot);
        IPassivePerpProxy(sec.perp).setFeatureFlagAllowAll(getMarketZeroFeesFeatureFlagId(marketId), true);

        (address user,) = makeAddrAndKey("user");
        uint256 amount = 1_000_000e6;
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1_000_000e18);

        // deposit new margin account
        uint128 accountId = depositNewMA(user, sec.usdc, amount);

        CollateralInfo memory preOrderBalance = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.rusd);

        executeCoreMatchOrder({
            marketId: marketId,
            sender: user,
            base: base,
            priceLimit: priceLimit,
            accountId: accountId
        });

        CollateralInfo memory postOrderBalance = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.rusd);

        int256 paidFees = preOrderBalance.realBalance - postOrderBalance.realBalance;
        assertEq(paidFees, 0);
    }

    function check_ExchangeMatchOrder_ZeroFees() internal {
        removeMarketsOILimit();
        mockFreshPrices();

        vm.prank(sec.setMarketZeroFeeBot);
        IPassivePerpProxy(sec.perp).setFeatureFlagAllowAll(getExchangeZeroFeesFeatureFlagId(1), true);

        (address user,) = makeAddrAndKey("user");
        uint256 amount = 1_000_000e6;
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1_000_000e18);

        // deposit new margin account
        uint128 accountId = depositNewMA(user, sec.usdc, amount);

        {

            CollateralInfo memory preOrderBalance = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.rusd);

            executeCoreMatchOrder({
                marketId: 1,
                sender: user,
                base: base,
                priceLimit: priceLimit,
                accountId: accountId
            });

            CollateralInfo memory postOrderBalance = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.rusd);

            int256 paidFees = preOrderBalance.realBalance - postOrderBalance.realBalance;
            assertEq(paidFees, 0);

        }

        {

            CollateralInfo memory preOrderBalance = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.rusd);

            executeCoreMatchOrder({
                marketId: 2,
                sender: user,
                base: base,
                priceLimit: priceLimit,
                accountId: accountId
            });

            CollateralInfo memory postOrderBalance = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.rusd);

            int256 paidFees = preOrderBalance.realBalance - postOrderBalance.realBalance;
            assertEq(paidFees, 0);

        }

    }
}
