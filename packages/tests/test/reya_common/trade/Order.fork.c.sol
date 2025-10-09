pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";
import { ICoreProxy, CollateralInfo, MarginInfo } from "../../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy, GlobalFeeParameters, CacheStatus } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { sd, SD59x18, UNIT as ONE_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract OrderForkCheck is BaseReyaForkTest {
    int256 private constant BASIC_TIER_FEE_PERCENTAGE = 0.0004e18;

    function getMarketZeroFeesFeatureFlagId(uint128 marketId) internal pure returns (bytes32) {
        return keccak256(abi.encode(keccak256(bytes("marketZeroFees")), marketId));
    }

    function getExchangeZeroFeesFeatureFlagId(uint128 exchangeId) internal pure returns (bytes32) {
        return keccak256(abi.encode(keccak256(bytes("exchangeZeroFees")), exchangeId));
    }

    function getFeeConfigFeatureFlagId() internal pure returns (bytes32) {
        return keccak256(bytes("configureFees"));
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
        assertApproxEqAbs(paidFees, expectedFees, 0.001e6);
    }

    function check_MatchOrder_FeeDiscounts(uint128 marketId, bool ogDiscount, bool vltzDiscount) internal {
        removeMarketsOILimit();
        mockFreshPrices();

        IPassivePerpProxy perp = IPassivePerpProxy(sec.perp);

        (address bot,) = makeAddrAndKey("bot");

        vm.prank(sec.multisig);
        perp.addToFeatureFlagAllowlist(getFeeConfigFeatureFlagId(), bot);

        (address user,) = makeAddrAndKey("userFeeDiscounts");
        uint256 amount = 1_000_000e6;
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1_000_000e18);

        // deposit new margin account
        uint128 accountId = depositNewMA(user, sec.usdc, amount);

        GlobalFeeParameters memory config = perp.getGlobalFeeParameters();
        config.ogDiscount = ogDiscount ? 0.2e18 : 0;
        config.vltzDiscount = vltzDiscount ? 0.1e18 : 0;
        vm.prank(sec.multisig);
        perp.setGlobalFeeParameters(config);

        vm.prank(bot);
        perp.setAccountOwnerVltzStatusFeeConfig(user, true);
        vm.prank(bot);
        perp.setAccountOwnerOgStatusFeeConfig(user, true);

        CollateralInfo memory preOrderBalance = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.rusd);

        (UD60x18 orderPrice,) = executeCoreMatchOrder({
            marketId: marketId,
            sender: user,
            base: base,
            priceLimit: priceLimit,
            accountId: accountId
        });

        CollateralInfo memory postOrderBalance = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.rusd);
        SD59x18 fee = sd(BASIC_TIER_FEE_PERCENTAGE).mul(ONE_sd.sub(sd(int256(config.ogDiscount)))).mul(
            ONE_sd.sub(sd(int256(config.vltzDiscount)))
        );

        int256 expectedFees = orderPrice.intoSD59x18().mul(base).mul(fee).unwrap() / 1e12;
        int256 paidFees = preOrderBalance.realBalance - postOrderBalance.realBalance;
        assertApproxEqAbs(paidFees, expectedFees, 0.001e6);
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

            executeCoreMatchOrder({ marketId: 1, sender: user, base: base, priceLimit: priceLimit, accountId: accountId });

            CollateralInfo memory postOrderBalance = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.rusd);

            int256 paidFees = preOrderBalance.realBalance - postOrderBalance.realBalance;
            assertEq(paidFees, 0);
        }

        {
            CollateralInfo memory preOrderBalance = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.rusd);

            executeCoreMatchOrder({ marketId: 2, sender: user, base: base, priceLimit: priceLimit, accountId: accountId });

            CollateralInfo memory postOrderBalance = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.rusd);

            int256 paidFees = preOrderBalance.realBalance - postOrderBalance.realBalance;
            assertEq(paidFees, 0);
        }
    }

    function check_MatchOrder_CachedPoolNodeMarginInfo() internal {
        removeMarketsOILimit();
        mockFreshPrices();

        uint256 maxCacheDuration =
            IPassivePerpProxy(sec.perp).getMaxCacheDurationForPoolNodeMarginInfo(sec.passivePoolAccountId, sec.rusd);
        assertEq(maxCacheDuration, 60);

        (address user,) = makeAddrAndKey("user");
        uint256 amount = 1_000_000e6;
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1_000_000e18);

        // deposit new margin account
        uint128 accountId = depositNewMA(user, sec.usdc, amount);

        // this order should cache the node margin info
        vm.warp(block.timestamp + 60);
        mockFreshPrices();

        MarginInfo memory preOrderPoolNodeMarginInfo =
            ICoreProxy(sec.core).getNodeMarginInfo(sec.passivePoolAccountId, sec.rusd);
        executeCoreMatchOrder({ marketId: 1, sender: user, base: base, priceLimit: priceLimit, accountId: accountId });

        (CacheStatus status, MarginInfo memory postOrderPoolNodeMarginInfo) =
            IPassivePerpProxy(sec.perp).getCachedPoolNodeMarginInfoOrFetch(sec.passivePoolAccountId, sec.rusd);

        assertEq(status, CacheStatus.VALID);
        assertEq(postOrderPoolNodeMarginInfo, preOrderPoolNodeMarginInfo);

        vm.warp(block.timestamp + 59);
        mockFreshPrices();

        vm.expectCall(sec.core, abi.encodeWithSelector(ICoreProxy(sec.core).getNodeMarginInfo.selector), 0);

        uint256 secondMatchOrderGas = gasleft();
        executeCoreMatchOrder({ marketId: 2, sender: user, base: base, priceLimit: priceLimit, accountId: accountId });
        secondMatchOrderGas = secondMatchOrderGas - gasleft();

        assertLe(secondMatchOrderGas, 3_000_000);

        assertEq(status, CacheStatus.VALID);
        assertEq(postOrderPoolNodeMarginInfo, preOrderPoolNodeMarginInfo);
    }

    function assertEq(MarginInfo memory a, MarginInfo memory b) private pure {
        assertEq(a.collateral, b.collateral);
        assertEq(a.marginBalance, b.marginBalance);
        assertEq(a.realBalance, b.realBalance);
        assertEq(a.initialDelta, b.initialDelta);
        assertEq(a.maintenanceDelta, b.maintenanceDelta);
        assertEq(a.liquidationDelta, b.liquidationDelta);
        assertEq(a.dutchDelta, b.dutchDelta);
        assertEq(a.adlDelta, b.adlDelta);
        assertEq(a.initialBufferDelta, b.initialBufferDelta);
        assertEq(a.liquidationMarginRequirement, b.liquidationMarginRequirement);
    }

    function assertEq(CacheStatus a, CacheStatus b) private pure {
        assertEq(uint256(a), uint256(b));
    }
}
