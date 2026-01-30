pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import {
    ICoreProxy,
    CollateralConfig,
    ParentCollateralConfig,
    GlobalCollateralConfig,
    GlobalCachedCollateralConfig,
    SpotMarketData,
    SpotMarketConfig
} from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPeripheryProxy, DepositNewMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

struct WbtcCollateralConfigExpectations {
    bool depositingEnabled;
    uint256 cap;
    uint256 autoExchangeThreshold;
    uint256 autoExchangeInsuranceFee;
    uint256 autoExchangeDustThreshold;
    uint256 priceHaircut;
    uint256 autoExchangeDiscount;
}

struct WbtcSpotMarketConfigExpectations {
    uint128 spotMarketId;
    uint256 oracleDeviation;
    uint256 minimumOrderBase;
    uint256 baseSpacing;
    uint256 priceSpacing;
}

contract WbtcCollateralForkCheck is BaseReyaForkTest {
    address user;
    uint256 userPk;

    function check_wbtc_collateral_config(WbtcCollateralConfigExpectations memory expected) internal view {
        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.wbtc);

        assertEq(collateralConfig.depositingEnabled, expected.depositingEnabled, "depositingEnabled mismatch");
        assertEq(collateralConfig.cap, expected.cap, "cap mismatch");
        assertEq(collateralConfig.autoExchangeThreshold, expected.autoExchangeThreshold, "autoExchangeThreshold mismatch");
        assertEq(collateralConfig.autoExchangeInsuranceFee, expected.autoExchangeInsuranceFee, "autoExchangeInsuranceFee mismatch");
        assertEq(collateralConfig.autoExchangeDustThreshold, expected.autoExchangeDustThreshold, "autoExchangeDustThreshold mismatch");

        assertEq(parentCollateralConfig.collateralAddress, sec.rusd, "parent collateral should be rUSD");
        assertEq(parentCollateralConfig.priceHaircut, expected.priceHaircut, "priceHaircut mismatch");
        assertEq(parentCollateralConfig.autoExchangeDiscount, expected.autoExchangeDiscount, "autoExchangeDiscount mismatch");
    }

    function check_wbtc_global_collateral_config() internal view {
        (GlobalCollateralConfig memory globalConfig,) = ICoreProxy(sec.core).getGlobalCollateralConfig(sec.wbtc);

        assertEq(globalConfig.collateralAdapter, address(0), "collateralAdapter should be zero address");
        assertEq(globalConfig.withdrawalWindowSize, 1, "withdrawalWindowSize mismatch");
        assertEq(globalConfig.withdrawalTvlPercentageLimit, 1e18, "withdrawalTvlPercentageLimit mismatch");
    }

    function check_wbtc_spot_market_config(WbtcSpotMarketConfigExpectations memory expected) internal view {
        SpotMarketData memory spotMarketData = ICoreProxy(sec.core).getSpotMarketData(expected.spotMarketId);

        assertEq(spotMarketData.baseToken, sec.wbtc, "baseToken should be WBTC");
        assertEq(spotMarketData.quoteToken, sec.rusd, "quoteToken should be rUSD");

        SpotMarketConfig memory config = spotMarketData.config;
        assertEq(config.oracleDeviation, expected.oracleDeviation, "oracleDeviation mismatch");
        assertEq(config.minimumOrderBase, expected.minimumOrderBase, "minimumOrderBase mismatch");
        assertEq(config.baseSpacing, expected.baseSpacing, "baseSpacing mismatch");
        assertEq(config.priceSpacing, expected.priceSpacing, "priceSpacing mismatch");
    }

    function check_wbtc_spot_market_enabled(uint128 spotMarketId) internal view {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("spotMarketEnabled")), spotMarketId));
        bool isEnabled = ICoreProxy(sec.core).getFeatureFlagAllowAll(flagId);
        assertTrue(isEnabled, "WBTC spot market should be enabled");
    }

    function check_wbtc_auto_exchange_enabled() internal view {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("autoExchange")), sec.wbtc));
        bool isEnabled = ICoreProxy(sec.core).getFeatureFlagAllowAll(flagId);
        assertTrue(isEnabled, "WBTC auto exchange should be enabled");
    }

    function check_WbtcTradeWithWbtcCollateral() public {
        mockFreshPrices();

        (user, userPk) = makeAddrAndKey("user");

        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.wbtc);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.wbtc, collateralConfig, parentCollateralConfig);

        // Mock WBTC collateral price (the fork may not have fresh WBTC price data)
        uint256 wbtcPrice = 100_000e18; // $100k per BTC
        mockFreshPrice(parentCollateralConfig.oracleNodeId, wbtcPrice);

        uint256 priceHaircut = parentCollateralConfig.priceHaircut;

        // deposit 0.01 + 0.1 / (1-haircut) wBTC (using 8 decimals)
        uint256 amount = 0.01e8 + 0.1e8 * 1e18 / (1e18 - priceHaircut);
        deal(sec.wbtc, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.wbtc], amount);
        vm.prank(dec.socketExecutionHelper[sec.wbtc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.wbtc) })
        );

        // user executes short trade on BTC (market ID 2)
        (UD60x18 orderPrice,) = executeCoreMatchOrder({
            marketId: 2,
            sender: user,
            base: sd(-0.1e18),
            priceLimit: ud(0),
            accountId: accountId
        });

        // compute fees paid in rUSD
        uint256 fees = 0;
        {
            uint256 currentPrice = IOracleManagerProxy(sec.oracleManager).process(sec.btcUsdStorkMarkNodeId).price;
            fees = 0.1e6 * currentPrice / 1e18 * 0.001e18 / 1e18;
        }

        // withdraw 0.01 wBTC
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.wbtc, 0.01e8, sec.destinationChainId);

        int256 marginBalance0 = ICoreProxy(sec.core).getNodeMarginInfo(accountId, sec.rusd).marginBalance;
        // Higher tolerance due to BTC price volatility and oracle price differences
        assertApproxEqAbsDecimal(marginBalance0 + int256(fees), 0.1e6 * int256(orderPrice.unwrap()) / 1e18, 2000 * 1e6, 6);

        uint256[] memory randomPrices = new uint256[](4);
        randomPrices[0] = 50_000e18;
        randomPrices[1] = 150_000e18;
        randomPrices[2] = orderPrice.unwrap() - 100e18;
        randomPrices[3] = orderPrice.unwrap() + 100e18;

        for (uint256 i = 0; i < 4; i++) {
            vm.mockCall(
                sec.oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (sec.btcUsdStorkMarkNodeId)),
                abi.encode(NodeOutput.Data({ price: randomPrices[i], timestamp: block.timestamp }))
            );

            vm.mockCall(
                sec.oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (sec.btcUsdcStorkMarkNodeId)),
                abi.encode(NodeOutput.Data({ price: randomPrices[i], timestamp: block.timestamp }))
            );

            // Also mock the WBTC collateral price to match
            vm.mockCall(
                sec.oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (parentCollateralConfig.oracleNodeId)),
                abi.encode(NodeOutput.Data({ price: randomPrices[i], timestamp: block.timestamp }))
            );

            int256 marginBalance1 = ICoreProxy(sec.core).getNodeMarginInfo(accountId, sec.rusd).marginBalance;

            // Higher tolerance for WBTC due to haircut and oracle path differences
            assertApproxEqAbsDecimal(marginBalance0, marginBalance1, 2000 * 1e6, 6);
        }
    }
}
