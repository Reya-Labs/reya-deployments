// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { IPassivePerpProxy, PerpPosition } from "../../../src/interfaces/IPassivePerpProxy.sol";
import { IPassivePerpProxyV2, MarketConfigurationDataV2 } from "../../../src/interfaces/IPassivePerpProxyV2.sol";
import { IOrdersGatewayProxyV2, OrdersGatewayConfigurationV2 } from "../../../src/interfaces/IOrdersGatewayProxyV2.sol";

contract DustSettlementForkTest is ReyaForkTest {
    uint128 internal constant ETH_MARKET_ID = 1;
    bytes32 internal constant SETTLE_DUST_FLAG = keccak256(bytes("settle_dust"));

    function setUp() public override { }

    function test_MainnetPerpOB_DustSettlementHappyPath() public {
        _disableFillPriceDeviationForPriceZeroDust();
        (uint128 buyerAccountId,) = _openSignedPosition();
        address dustOwner = makeAddr("dustOwner");
        uint128 dustAccountId = depositNewMA(dustOwner, sec.rusd, 10_000e6);
        address keeper = makeAddr("dustKeeper");

        _configureDustAccount(dustAccountId);
        _allowDustKeeper(keeper);
        _seedLegacyDust(buyerAccountId);

        vm.prank(keeper);
        IOrdersGatewayProxyV2(sec.ordersGateway).settleDust(buyerAccountId, ETH_MARKET_ID);

        PerpPosition memory buyerPosition =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(ETH_MARKET_ID, buyerAccountId);
        PerpPosition memory dustPosition =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(ETH_MARKET_ID, dustAccountId);
        assertEq(buyerPosition.base, 0.5e18, "long was not rounded toward zero");
        assertEq(dustPosition.base, 0.0005e18, "dust sink did not receive the residual long");
    }

    function test_MainnetPerpOB_DustSettlementRejectsPriceZeroWithFillCollarEnabled() public {
        (uint128 buyerAccountId,) = _openSignedPosition();
        address dustOwner = makeAddr("dustOwner");
        uint128 dustAccountId = depositNewMA(dustOwner, sec.rusd, 10_000e6);
        address keeper = makeAddr("dustKeeper");

        _configureDustAccount(dustAccountId);
        _allowDustKeeper(keeper);
        _seedLegacyDust(buyerAccountId);

        vm.expectRevert(
            abi.encodeWithSelector(
                IPassivePerpProxyV2.PriceDeviationTooLarge.selector, ETH_MARKET_ID, 0, 3000e18, 0.05e18
            )
        );
        vm.prank(keeper);
        IOrdersGatewayProxyV2(sec.ordersGateway).settleDust(buyerAccountId, ETH_MARKET_ID);
    }

    function test_MainnetPerpOB_DustSettlementRejectsUnauthorizedCaller() public {
        address unauthorized = makeAddr("unauthorizedDustKeeper");
        vm.expectRevert(abi.encodeWithSelector(IOrdersGatewayProxyV2.FeatureUnavailable.selector, SETTLE_DUST_FLAG));
        vm.prank(unauthorized);
        IOrdersGatewayProxyV2(sec.ordersGateway).settleDust(1, ETH_MARKET_ID);
    }

    function test_MainnetPerpOB_DustSettlementFailsWhenSinkIsUnconfigured() public {
        address keeper = makeAddr("dustKeeper");
        _allowDustKeeper(keeper);

        vm.expectRevert(IOrdersGatewayProxyV2.DustAccountNotConfigured.selector);
        vm.prank(keeper);
        IOrdersGatewayProxyV2(sec.ordersGateway).settleDust(1, ETH_MARKET_ID);
    }

    function test_MainnetPerpOB_DustSettlementRejectsSinkItself() public {
        address keeper = makeAddr("dustKeeper");
        address dustOwner = makeAddr("dustOwner");
        uint128 dustAccountId = depositNewMA(dustOwner, sec.rusd, 10_000e6);
        _configureDustAccount(dustAccountId);
        _allowDustKeeper(keeper);

        vm.expectRevert(abi.encodeWithSelector(IOrdersGatewayProxyV2.CannotSettleDustAccount.selector, dustAccountId));
        vm.prank(keeper);
        IOrdersGatewayProxyV2(sec.ordersGateway).settleDust(dustAccountId, ETH_MARKET_ID);
    }

    function test_MainnetPerpOB_DustSettlementRejectsNetShortSink() public {
        (uint128 buyerAccountId, uint128 sellerAccountId) = _openSignedPosition();
        address keeper = makeAddr("dustKeeper");
        _configureDustAccount(sellerAccountId);
        _allowDustKeeper(keeper);
        _seedLegacyDust(buyerAccountId);

        vm.expectRevert(
            abi.encodeWithSelector(IOrdersGatewayProxyV2.DustAccountNetShort.selector, sellerAccountId, ETH_MARKET_ID)
        );
        vm.prank(keeper);
        IOrdersGatewayProxyV2(sec.ordersGateway).settleDust(buyerAccountId, ETH_MARKET_ID);
    }

    function _openSignedPosition() internal returns (uint128 buyerAccountId, uint128 sellerAccountId) {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(ETH_MARKET_ID, 3000e18);
        pushFundingRate(ETH_MARKET_ID, 0);

        buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);
        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: ETH_MARKET_ID,
            baseDelta: 0.5e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });
    }

    function _configureDustAccount(uint128 dustAccountId) internal {
        OrdersGatewayConfigurationV2 memory config = IOrdersGatewayProxyV2(sec.ordersGateway).getConfiguration();
        config.dustAccountId = dustAccountId;
        vm.prank(sec.multisig);
        IOrdersGatewayProxyV2(sec.ordersGateway).setConfiguration(config);
    }

    function _allowDustKeeper(address keeper) internal {
        vm.prank(sec.multisig);
        IOrdersGatewayProxyV2(sec.ordersGateway).addToFeatureFlagAllowlist(SETTLE_DUST_FLAG, keeper);
    }

    function _disableFillPriceDeviationForPriceZeroDust() internal {
        MarketConfigurationDataV2 memory config = IPassivePerpProxyV2(sec.perp).getMarketConfiguration(ETH_MARKET_ID);
        config.fillPriceMaxDeviation = 0;
        vm.prank(sec.multisig);
        IPassivePerpProxyV2(sec.perp).setMarketConfiguration(ETH_MARKET_ID, config);
    }

    function _seedLegacyDust(uint128 accountId) internal {
        bytes32 positionsSlot = keccak256(
            abi.encode(
                accountId, keccak256(abi.encodePacked(keccak256(bytes("xyz.reya.PerpPositions")), ETH_MARKET_ID))
            )
        );
        vm.store(sec.perp, positionsSlot, bytes32(uint256(0.5005e18)));
    }
}
