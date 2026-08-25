pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SpotPerpOBForkCheck } from "../../reya_common/trade/SpotPerpOB.fork.c.sol";

import { ICoreProxy, SpotMarketConfig } from "../../../src/interfaces/ICoreProxy.sol";

contract SpotForkTest is ReyaForkTest, SpotPerpOBForkCheck {
    uint128 internal constant WETH_SPOT_MARKET_ID = 1;

    function test_Devnet_SpotExecuteFill_WETH() public {
        check_SpotExecuteFill_WETH(WETH_SPOT_MARKET_ID);
    }

    function test_Devnet_SpotBatchExecuteFill_WETH() public {
        check_SpotBatchExecuteFill_WETH(WETH_SPOT_MARKET_ID);
    }

    function test_Devnet_SpotExecuteFill_SmallQuantity_And_Price_WETH() public {
        check_SpotExecuteFill_SmallQuantity_And_Price_WETH(WETH_SPOT_MARKET_ID);
    }

    uint128 internal constant SRUSD_SPOT_MARKET_ID = 2;

    /// Core's spot deviation error (UD60x18 ABI-encodes as uint256). Distinct
    /// from the passive-perp 4-arg error of the same name.
    error PriceDeviationTooLarge(uint256 fillPrice, uint256 oraclePrice, uint256 oracleDeviation);

    /// Readback pin for the collar config, mirroring MAINNET (node + 5%),
    /// deliberately diverging from cronos (collar off). With deviation 0,
    /// Core skips the entire oracle block on spot fills -- no validation at
    /// all -- so a devnet without the collar never rehearses the admission
    /// path mainnet runs in production. SRUSDRUSD stays zero BY DESIGN: that
    /// market is never orderbook-enabled on devnet.
    function test_Devnet_SpotCollarConfig() public view {
        SpotMarketConfig memory weth = ICoreProxy(sec.core).getSpotMarketData(WETH_SPOT_MARKET_ID).config;
        require(weth.oracleNodeId == sec.ethUsdcStorkNodeId, "weth spot: collar node != ethUsdc (mainnet parity)");
        require(weth.oracleDeviation == 0.05e18, "weth spot: deviation != 5% (mainnet parity)");

        SpotMarketConfig memory srusd = ICoreProxy(sec.core).getSpotMarketData(SRUSD_SPOT_MARKET_ID).config;
        require(srusd.oracleNodeId == bytes32(0), "srusd spot: collar node should stay zero (market never enabled)");
        require(srusd.oracleDeviation == 0, "srusd spot: deviation should stay zero (market never enabled)");
    }

    /// The collar ADMITS an in-bounds fill. Unlike the shared checks above,
    /// this does NOT call removeOraclePriceDeviationConfig -- the whole point
    /// is to exercise the deployed collar.
    function test_Devnet_SpotFill_WithinCollar() public {
        setupSpotTestActors();
        mockFreshPrices();
        mockFreshPrice(sec.ethUsdcStorkNodeId, 3000e18);

        uint128 buyerAccountId = createOrGetSpotAccountWithRusdDeposit(spotBuyer, 10_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(spotSeller);
        depositWethToAccount(spotSeller, sellerAccountId, 1e18);

        // 2% above oracle: inside the 5% collar.
        executeSpotFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            spotMarketId: WETH_SPOT_MARKET_ID,
            baseDelta: 0.1e18,
            price: 3060e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        require(
            ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.weth).netDeposits == 0.1e18,
            "in-collar fill did not settle"
        );
    }

    /// And REJECTS an out-of-bounds one: 6.67% above oracle > 5% collar.
    function test_Devnet_SpotFill_OutsideCollar_Reverts() public {
        setupSpotTestActors();
        mockFreshPrices();
        mockFreshPrice(sec.ethUsdcStorkNodeId, 3000e18);

        uint128 buyerAccountId = createOrGetSpotAccountWithRusdDeposit(spotBuyer, 10_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(spotSeller);
        depositWethToAccount(spotSeller, sellerAccountId, 1e18);

        vm.expectRevert(abi.encodeWithSelector(PriceDeviationTooLarge.selector, 3200e18, 3000e18, 0.05e18));
        executeSpotFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            spotMarketId: WETH_SPOT_MARKET_ID,
            baseDelta: 0.1e18,
            price: 3200e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });
    }
}
